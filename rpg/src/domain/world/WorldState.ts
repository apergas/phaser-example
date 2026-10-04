import type { Building } from '../entities/Building';
import type { GroundItem } from '../entities/GroundItem';
import type { Obstacle } from '../entities/Obstacle';
import type { Player } from '../entities/Player';
import type { Tree } from '../entities/Tree';
import { Position } from '../value-objects/Position';

/**
 * The world's data, shared by the systems that implement its rules (navigation, woodcutting,
 * construction, pick-up). Only `World` creates it; nothing outside the `world` module touches it.
 */
export class WorldState {
  readonly width: number;
  readonly height: number;
  readonly player: Player;
  readonly trees = new Map<string, Tree>();
  readonly items = new Map<string, GroundItem>();
  readonly buildings = new Map<string, Building>();
  private readonly idCounters = new Map<string, number>();

  constructor(width: number, height: number, player: Player, trees: readonly Tree[], items: readonly GroundItem[]) {
    if (width <= 0 || height <= 0) throw new Error('World size must be positive');
    this.width = width;
    this.height = height;
    this.player = player;
    trees.forEach((tree) => this.trees.set(tree.id, tree));
    items.forEach((item) => this.items.set(item.id, item));
  }

  /** Every footprint that blocks movement: standing trees and buildings (finished or not). */
  obstacles(): Obstacle[] {
    return [
      ...[...this.trees.values()].map((tree) => tree.footprint),
      ...[...this.buildings.values()].map((building) => building.footprint),
    ];
  }

  isBlocked(position: Position, radius: number): boolean {
    return this.obstacles().some((obstacle) => obstacle.blocks(position, radius));
  }

  /** Keeps a footprint of `margin` radius inside the world. */
  clamp(position: Position, margin: number): Position {
    const clamp = (value: number, max: number) => Math.min(Math.max(value, margin), max - margin);
    return new Position(clamp(position.x, this.width), clamp(position.y, this.height));
  }

  isInside(position: Position, margin: number): boolean {
    return this.clamp(position, margin).equals(position);
  }

  /** Sequential ids per prefix: `building-1`, `building-2`... */
  nextId(prefix: string): string {
    const next = (this.idCounters.get(prefix) ?? 0) + 1;
    this.idCounters.set(prefix, next);
    return `${prefix}-${next}`;
  }
}
