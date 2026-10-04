import type { BlueprintKey } from './keys';

export interface BuildOption {
  readonly blueprintId: BlueprintKey;
  readonly woodCost: number;
  readonly affordable: boolean;
}
