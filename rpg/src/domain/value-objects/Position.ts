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
}
