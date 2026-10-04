export class Position {
  readonly x: number;
  readonly y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  distanceTo(other: Position): number {
    return Math.hypot(other.x - this.x, other.y - this.y);
  }

  equals(other: Position): boolean {
    return this.x === other.x && this.y === other.y;
  }

  /** Returns a new position moved towards `target` by at most `maxStep`, never overshooting. */
  moveTowards(target: Position, maxStep: number): Position {
    const distance = this.distanceTo(target);
    if (distance <= maxStep) return target;

    const ratio = maxStep / distance;
    return new Position(this.x + (target.x - this.x) * ratio, this.y + (target.y - this.y) * ratio);
  }

  /**
   * The point at exactly `distance` from this position, in the direction of `towards`.
   * When both positions coincide there is no direction, so the point is placed below (south).
   */
  pointAtDistance(distance: number, towards: Position): Position {
    const length = this.distanceTo(towards);
    if (length === 0) return new Position(this.x, this.y + distance);

    const ratio = distance / length;
    return new Position(this.x + (towards.x - this.x) * ratio, this.y + (towards.y - this.y) * ratio);
  }
}
