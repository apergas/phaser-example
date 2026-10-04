import type { WorldEvent } from '../events';
import { Rules } from '../rules';
import { Position } from '../value-objects/Position';
import type { Blueprint } from './Blueprint';
import { Building } from './Building';
import type { GroundItem } from './GroundItem';
import type { Obstacle } from './Obstacle';
import type { Activity, Intent, Player } from './Player';
import type { Tree } from './Tree';

export type ChopOrderResult = 'ok' | 'no-axe' | 'unknown-tree';
export type ConstructionOrderResult =
  | { readonly ok: true; readonly building: Building }
  | { readonly ok: false; readonly reason: 'not-enough-wood' | 'blocked' };

/** Extra distance, beyond touching footprints, from which the player can still work on a target. */
const REACH_TOLERANCE = 6;

/**
 * Aggregate that owns the player, trees, ground items and buildings, and enforces every rule:
 * movement and collisions, picking up tools, chopping trees into wood and constructing buildings.
 */
export class World {
  readonly width: number;
  readonly height: number;
  readonly player: Player;
  private readonly treesById = new Map<string, Tree>();
  private readonly itemsById = new Map<string, GroundItem>();
  private readonly buildingsById = new Map<string, Building>();
  private buildingsCreated = 0;

  constructor(width: number, height: number, player: Player, trees: readonly Tree[], items: readonly GroundItem[] = []) {
    if (width <= 0 || height <= 0) throw new Error('World size must be positive');
    this.width = width;
    this.height = height;
    this.player = player;
    trees.forEach((tree) => this.treesById.set(tree.id, tree));
    items.forEach((item) => this.itemsById.set(item.id, item));
  }

  get trees(): readonly Tree[] {
    return [...this.treesById.values()];
  }

  get items(): readonly GroundItem[] {
    return [...this.itemsById.values()];
  }

  get buildings(): readonly Building[] {
    return [...this.buildingsById.values()];
  }

  /** Every footprint that blocks movement: standing trees and buildings (finished or not). */
  get obstacles(): readonly Obstacle[] {
    return [...this.trees.map((tree) => tree.footprint), ...this.buildings.map((building) => building.footprint)];
  }

  /** Sends the player towards `destination`, clamped so its footprint stays inside the world. */
  movePlayerTo(destination: Position): void {
    this.player.walkTo(this.clampToWorld(destination, this.player.radius));
  }

  /** Sends the player to chop a tree. Requires an axe. */
  orderChop(treeId: string): ChopOrderResult {
    const tree = this.treesById.get(treeId);
    if (!tree) return 'unknown-tree';
    if (!this.player.inventory.hasTool('axe')) return 'no-axe';

    this.goWorkOn(tree.footprint, { kind: 'chop', treeId });
    return 'ok';
  }

  /** Pays for a building, places its site at `position` and sends the player to construct it. */
  orderConstruction(blueprint: Blueprint, position: Position): ConstructionOrderResult {
    if (this.player.inventory.wood < blueprint.woodCost) return { ok: false, reason: 'not-enough-wood' };
    if (!this.canPlace(blueprint, position)) return { ok: false, reason: 'blocked' };

    this.player.inventory.spendWood(blueprint.woodCost);
    this.buildingsCreated += 1;
    const building = new Building(`building-${this.buildingsCreated}`, blueprint, position);
    this.buildingsById.set(building.id, building);

    this.goWorkOn(building.footprint, { kind: 'construct', buildingId: building.id });
    return { ok: true, building };
  }

  /** Whether a building with this blueprint fits at `position` without overlapping anything. */
  canPlace(blueprint: Blueprint, position: Position): boolean {
    const radius = blueprint.footprintRadius;
    const insideWorld = this.clampToWorld(position, radius).equals(position);
    const overlapsObstacle = this.obstacles.some((obstacle) => obstacle.blocks(position, radius));
    const overlapsPlayer = position.distanceTo(this.player.position) < radius + this.player.radius;
    const overlapsItem = this.items.some((item) => position.distanceTo(item.position) < radius);

    return insideWorld && !overlapsObstacle && !overlapsPlayer && !overlapsItem;
  }

  advance(deltaMs: number): WorldEvent[] {
    const events: WorldEvent[] = [];
    const activity = this.player.activity;

    if (activity.kind === 'walking') this.walk(deltaMs, activity, events);
    else if (activity.kind === 'chopping') this.chop(deltaMs, activity, events);
    else if (activity.kind === 'constructing') this.construct(deltaMs, activity, events);

    this.pickUpItems(events);
    return events;
  }

  private walk(deltaMs: number, activity: Extract<Activity, { kind: 'walking' }>, events: WorldEvent[]): void {
    const next = this.player.nextPosition(deltaMs);
    if (!next) return;

    if (this.obstacles.some((obstacle) => obstacle.blocks(next, this.player.radius))) {
      if (activity.intent && this.isWithinReach(activity.intent)) return this.startWork(activity.intent);
      if (activity.intent) events.push({ type: 'player-blocked' });
      this.player.stop();
      return;
    }

    this.player.placeAt(next);
    if (next.equals(activity.destination)) {
      if (activity.intent) this.startWork(activity.intent);
      else this.player.stop();
    }
  }

  private chop(deltaMs: number, activity: Extract<Activity, { kind: 'chopping' }>, events: WorldEvent[]): void {
    const tree = this.treesById.get(activity.treeId);
    if (!tree) return this.player.stop();

    const elapsed = activity.elapsedMs + deltaMs;
    if (elapsed < Rules.CHOP_INTERVAL_MS) return this.player.continueWork(elapsed);

    this.player.continueWork(elapsed - Rules.CHOP_INTERVAL_MS);
    tree.hit();
    events.push({ type: 'tree-hit', treeId: tree.id, hitsRemaining: tree.hitsRemaining });

    if (tree.isFelled) {
      this.treesById.delete(tree.id);
      this.player.inventory.addWood(tree.woodYield);
      events.push({ type: 'tree-felled', treeId: tree.id, wood: tree.woodYield });
      this.player.stop();
    }
  }

  private construct(deltaMs: number, activity: Extract<Activity, { kind: 'constructing' }>, events: WorldEvent[]): void {
    const building = this.buildingsById.get(activity.buildingId);
    if (!building || building.isComplete) return this.player.stop();

    const elapsed = activity.elapsedMs + deltaMs;
    if (elapsed < Rules.HAMMER_INTERVAL_MS) return this.player.continueWork(elapsed);

    this.player.continueWork(elapsed - Rules.HAMMER_INTERVAL_MS);
    building.hammer();
    events.push({ type: 'building-hammered', buildingId: building.id, progress: building.progress });

    if (building.isComplete) {
      events.push({ type: 'building-completed', buildingId: building.id });
      this.player.stop();
    }
  }

  private pickUpItems(events: WorldEvent[]): void {
    for (const item of this.items) {
      if (item.position.distanceTo(this.player.position) > Rules.PICK_UP_RANGE) continue;

      this.itemsById.delete(item.id);
      this.player.inventory.addTool(item.kind);
      events.push({ type: 'item-picked-up', itemId: item.id, kind: item.kind });
    }
  }

  /** Walks up to the target, or starts working right away if it is already within reach. */
  private goWorkOn(target: Obstacle, intent: Intent): void {
    if (this.isWithinReach(intent)) return this.startWork(intent);
    this.player.walkTo(this.workSpot(target, intent), intent);
  }

  /**
   * Where to stand to work on a target. Trees are chopped from the side nearest the player and
   * buildings are built from the front, slightly south of the target so the player stays in view
   * in the 3/4 perspective. Falls back to the closest point on the player's side when those spots
   * are blocked or outside the world.
   */
  private workSpot(target: Obstacle, intent: Intent): Position {
    const distance = target.radius + this.player.radius + Rules.WORK_GAP;
    const { x, y } = target.position;
    const side = this.player.position.x < x ? -1 : 1;

    const preferred =
      intent.kind === 'chop'
        ? [new Position(x + side * distance, y + 1), new Position(x - side * distance, y + 1)]
        : [new Position(x, y + distance)];
    const fallback = target.position.pointAtDistance(distance, this.player.position);

    const isFree = (spot: Position) =>
      this.clampToWorld(spot, this.player.radius).equals(spot) &&
      !this.obstacles.some((obstacle) => obstacle.blocks(spot, this.player.radius));
    return preferred.find(isFree) ?? this.clampToWorld(fallback, this.player.radius);
  }

  private startWork(intent: Intent): void {
    if (intent.kind === 'chop' && this.treesById.has(intent.treeId)) return this.player.startChopping(intent.treeId);
    if (intent.kind === 'construct' && this.buildingsById.has(intent.buildingId)) {
      return this.player.startConstructing(intent.buildingId);
    }
    this.player.stop();
  }

  private isWithinReach(intent: Intent): boolean {
    const target = this.targetOf(intent);
    if (!target) return false;

    const reach = target.radius + this.player.radius + Rules.WORK_GAP + REACH_TOLERANCE;
    return this.player.position.distanceTo(target.position) <= reach;
  }

  private targetOf(intent: Intent): Obstacle | undefined {
    return intent.kind === 'chop'
      ? this.treesById.get(intent.treeId)?.footprint
      : this.buildingsById.get(intent.buildingId)?.footprint;
  }

  private clampToWorld(position: Position, margin: number): Position {
    const clamp = (value: number, max: number) => Math.min(Math.max(value, margin), max - margin);
    return new Position(clamp(position.x, this.width), clamp(position.y, this.height));
  }
}
