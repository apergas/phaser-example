/** Tuning values for the gathering and building loop. Times are in milliseconds. */
export const Rules = {
  /** Axe swings needed to fell a tree. */
  HITS_TO_FELL_TREE: 5,
  /** Time between two axe impacts while chopping. */
  CHOP_INTERVAL_MS: 750,
  /** Time between two hammer impacts while constructing. */
  HAMMER_INTERVAL_MS: 650,
  /** Gap left between the player's footprint and the target's when walking up to work on it. */
  WORK_GAP: 2,
  /** The player picks up items whose position is within this distance of its feet. */
  PICK_UP_RANGE: 14,
  /** Walking speed in world units (native art pixels) per second. */
  PLAYER_SPEED: 110,
  /** Radius of the player's footprint on the ground. */
  PLAYER_RADIUS: 8,
  /** Radius of a tree trunk's footprint on the ground. */
  TREE_TRUNK_RADIUS: 12,
} as const;
