import type { QuestKey } from './keys';

export interface QuestProgress {
  readonly id: QuestKey;
  readonly progress: number;
  readonly target: number;
  readonly completed: boolean;
  /** The first unfinished quest: what the player should do next. */
  readonly current: boolean;
}
