/**
 * Textures built from Liberated Pixel Cup (LPC) art by asset-packs/lpc/build_assets.py.
 * Licences require attribution: see public/assets/lpc/CREDITS.md.
 */
export const TILE_SIZE = 32;
/** Pixel art is drawn at native size; the camera zooms in by this integer factor. */
export const CAMERA_ZOOM = 2;

const BASE_URL = 'assets/lpc';

export const Sheets = {
  GROUND: { key: 'ground', url: `${BASE_URL}/ground.png` },
  HERO_WALK: { key: 'hero-walk', url: `${BASE_URL}/hero-walk.png` },
  HERO_IDLE: { key: 'hero-idle', url: `${BASE_URL}/hero-idle.png` },
} as const;

/** Atlas whose frames carry their own pivot (trunk base for trees, bottom-centre for decor). */
export const ForestAtlas = {
  key: 'forest',
  textureUrl: `${BASE_URL}/forest.png`,
  atlasUrl: `${BASE_URL}/forest.json`,
  TREES: [
    'tree-slim',
    'tree-round',
    'tree-wide',
    'tree-broad',
    'tree-twisted',
    'tree-branches',
    'tree-leaning',
    'tree-lumpy',
    'tree-pine',
    'tree-dome',
    'tree-oak',
    'tree-dense',
    'tree-old',
    'tree-big',
  ],
  /** Repeated names weight the random pick: mostly greenery, the odd rock or mushroom. */
  DECOR: [
    'decor-tall-grass',
    'decor-tall-grass',
    'decor-tall-grass',
    'decor-leaves',
    'decor-leaves',
    'decor-mushrooms',
    'decor-rock',
  ],
} as const;

export const GroundFrames = {
  GRASS: 0,
} as const;

/** LPC character sheets: 64x64 frames, one row per facing direction in this order. */
export const CHARACTER_FRAME_SIZE = 64;
/** Feet sit 2px above the bottom of each frame. */
export const CHARACTER_ORIGIN_Y = 62 / 64;
export const FACING_DIRECTIONS = ['up', 'left', 'down', 'right'] as const;
export type FacingDirection = (typeof FACING_DIRECTIONS)[number];

/** Walk rows have 9 columns: column 0 is a standing pose, 1-8 are the step cycle. */
export const WalkSheet = { COLUMNS: 9, FIRST_STEP: 1, LAST_STEP: 8, FRAME_RATE: 10 } as const;
/** Idle rows have 2 columns: a gentle breathing loop. */
export const IdleSheet = { COLUMNS: 2, FRAME_RATE: 2 } as const;
