import type { Point } from './Point';

export type ActivityKind = 'idle' | 'walking' | 'chopping' | 'constructing';

export interface PlayerState {
  readonly position: Point;
  readonly activity: ActivityKind;
  /** What the player is walking to or working on, if anything. */
  readonly target: Point | null;
  /** Progress of the current swing, 0..1, when chopping or constructing. */
  readonly swingProgress: number;
  readonly wood: number;
  readonly hasAxe: boolean;
}
