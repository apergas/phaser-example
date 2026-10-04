import type { Blueprint } from '../entities/Blueprint';
import type { Building } from '../entities/Building';
import type { GroundItem } from '../entities/GroundItem';
import type { Obstacle } from '../entities/Obstacle';
import type { Activity, Player } from '../entities/Player';
import type { Tree } from '../entities/Tree';
import type { WorldEvent } from '../events';
import type { Position } from '../value-objects/Position';
import { Construction, type ConstructionOrderResult } from './Construction';
import { Navigation } from './Navigation';
import { pickUpItems } from './Pickup';
import { type ChopOrderResult, Woodcutting } from './Woodcutting';
import { type WorkRegistry, workFor } from './Work';
import { WorldState } from './WorldState';

export type { ChopOrderResult, ConstructionOrderResult };

/**
 * Aggregate root: the only entry point to change the world. It owns the state and delegates each
 * rule to a system (navigation, woodcutting, construction, pick-up). New work mechanics plug in
 * through the `WorkRegistry`.
 */
export class World {
  private readonly state: WorldState;
  private readonly registry: WorkRegistry = { chop: Woodcutting, construct: Construction };
  private readonly navigation: Navigation;

  constructor(width: number, height: number, player: Player, trees: readonly Tree[], items: readonly GroundItem[] = []) {
    this.state = new WorldState(width, height, player, trees, items);
    this.navigation = new Navigation(this.state, this.registry);
  }

  get width(): number {
    return this.state.width;
  }

  get height(): number {
    return this.state.height;
  }

  get player(): Player {
    return this.state.player;
  }

  get trees(): readonly Tree[] {
    return [...this.state.trees.values()];
  }

  get items(): readonly GroundItem[] {
    return [...this.state.items.values()];
  }

  get buildings(): readonly Building[] {
    return [...this.state.buildings.values()];
  }

  get obstacles(): readonly Obstacle[] {
    return this.state.obstacles();
  }

  /** Progress of the current impact cycle, 0..1, or 0 when not working. */
  get workProgress(): number {
    const activity = this.player.activity;
    if (activity.kind !== 'working') return 0;
    return activity.elapsedMs / workFor(this.registry, activity.intent).intervalMs;
  }

  /** Where the player is heading or what it is working on, if anything. */
  get playerTarget(): Position | null {
    const activity = this.player.activity;
    if (activity.kind === 'walking') return activity.destination;
    if (activity.kind === 'working') return workFor(this.registry, activity.intent).target(this.state, activity.intent)?.position ?? null;
    return null;
  }

  movePlayerTo(destination: Position): void {
    this.navigation.walkTo(destination);
  }

  /** Sends the player to chop a tree. Requires an axe. */
  orderChop(treeId: string): ChopOrderResult {
    const result = Woodcutting.check(this.state, treeId);
    if (result === 'ok') this.navigation.goWorkOn({ kind: 'chop', treeId });
    return result;
  }

  /** Pays for a building, places its site at `position` and sends the player to construct it. */
  orderConstruction(blueprint: Blueprint, position: Position): ConstructionOrderResult {
    const result = Construction.place(this.state, blueprint, position);
    if (result.ok) this.navigation.goWorkOn({ kind: 'construct', buildingId: result.building.id });
    return result;
  }

  canPlace(blueprint: Blueprint, position: Position): boolean {
    return Construction.canPlace(this.state, blueprint, position);
  }

  advance(deltaMs: number): WorldEvent[] {
    const events: WorldEvent[] = [];
    const activity = this.player.activity;

    if (activity.kind === 'walking') this.navigation.step(deltaMs, activity, events);
    else if (activity.kind === 'working') this.work(deltaMs, activity, events);

    pickUpItems(this.state, events);
    return events;
  }

  /** Generic work loop: one impact per interval until the work reports it is finished. */
  private work(deltaMs: number, activity: Extract<Activity, { kind: 'working' }>, events: WorldEvent[]): void {
    const work = workFor(this.registry, activity.intent);
    if (!work.target(this.state, activity.intent)) return this.player.stop();

    const elapsed = activity.elapsedMs + deltaMs;
    if (elapsed < work.intervalMs) return this.player.continueWork(elapsed);

    this.player.continueWork(elapsed - work.intervalMs);
    if (work.impact(this.state, activity.intent, events)) this.player.stop();
  }
}
