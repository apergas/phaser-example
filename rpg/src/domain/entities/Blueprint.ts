export type BlueprintId = 'house';

/** What it takes to construct a kind of building. */
export interface Blueprint {
  readonly id: BlueprintId;
  readonly woodCost: number;
  /** Hammer hits needed to finish it. */
  readonly hitsToBuild: number;
  /** Radius of the circular footprint that blocks movement. */
  readonly footprintRadius: number;
}

export const Blueprints: Readonly<Record<BlueprintId, Blueprint>> = {
  house: { id: 'house', woodCost: 15, hitsToBuild: 8, footprintRadius: 40 },
};
