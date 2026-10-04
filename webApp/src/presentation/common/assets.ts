/**
 * Textures built from Liberated Pixel Cup (LPC) art by asset-packs/lpc/build_assets.py.
 * Licences require attribution: see shared/assets/lpc/CREDITS.md.
 */
export const TILE_SIZE = 32;
/** Pixel art is drawn at native size; the camera zooms in by this integer factor. */
export const CAMERA_ZOOM = 2;

const BASE_URL = 'assets/lpc';

export const Sheets = {
  GROUND: { key: 'ground', url: `${BASE_URL}/ground.png` },
} as const;

/** LPC character sheets: one row per facing direction, in FACING_DIRECTIONS order. */
export const CharacterSheets = {
  WALK: { key: 'hero-walk', url: `${BASE_URL}/hero-walk.png` },
  IDLE: { key: 'hero-idle', url: `${BASE_URL}/hero-idle.png` },
  WALK_AXE: { key: 'hero-walk-axe', url: `${BASE_URL}/hero-walk-axe.png` },
  IDLE_AXE: { key: 'hero-idle-axe', url: `${BASE_URL}/hero-idle-axe.png` },
} as const;

/** Work animations use bigger frames so the swinging tool fits. */
export const WorkSheets = {
  CHOP: { key: 'hero-chop', url: `${BASE_URL}/hero-chop.png` },
  HAMMER: { key: 'hero-hammer', url: `${BASE_URL}/hero-hammer.png` },
} as const;

/** Atlas whose frames carry their own pivot (trunk base for trees, bottom-centre for the rest). */
export const ForestAtlas = {
  key: 'forest',
  textureUrl: `${BASE_URL}/forest.png`,
  atlasUrl: `${BASE_URL}/forest.json`,
  STUMP: 'stump',
  AXE_PICKUP: 'axe-pickup',
  HOUSE: 'house',
} as const;

/** Small particle textures generated at load time (no image file). */
export const GeneratedTextures = {
  WOOD_CHIP: 'wood-chip',
  DUST: 'dust',
} as const;

export const GroundFrames = {
  GRASS: 0,
} as const;

export const CHARACTER_FRAME_SIZE = 64;
/** Feet sit 2px above the bottom of each 64px frame. */
export const CHARACTER_ORIGIN_Y = 62 / 64;
export const FACING_DIRECTIONS = ['up', 'left', 'down', 'right'] as const;
export type FacingDirection = (typeof FACING_DIRECTIONS)[number];

/** Walk rows have 9 columns: column 0 is a standing pose, 1-8 are the step cycle. */
export const WalkSheet = { COLUMNS: 9, FIRST_STEP: 1, LAST_STEP: 8, FRAME_RATE: 10 } as const;
/** Idle rows have 2 columns: a gentle breathing loop. */
export const IdleSheet = { COLUMNS: 2, FRAME_RATE: 2 } as const;

/**
 * Work sheets: 128px frames, 6 columns of the LPC slash cycle per row. Each sequence covers one
 * swing and ends on the impact frame, which is shown exactly when the domain registers the hit.
 */
export const WorkSheet = {
  FRAME_SIZE: 128,
  COLUMNS: 6,
  /** Feet of the 64px body, centred in the 128px cell. */
  ORIGIN_Y: (32 + 62) / 128,
  CHOP_SEQUENCE: [0, 0, 5, 5, 4, 4, 3, 1],
  HAMMER_SEQUENCE: [0, 0, 5, 5, 4, 4, 1],
} as const;

/**
 * The house sprite's pivot is the bottom of its front wall. In the 3/4 view the building's ground
 * footprint (centred on its domain position) lies behind that wall, so the sprite is drawn lower.
 */
export const HOUSE_FRONT_OFFSET = 24;
