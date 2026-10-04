import { seededRandom } from '../../shared/seededRandom';

/**
 * Level data as plain values, so it can later be replaced by a Tiled map loader
 * without touching the domain. Positions are the base (feet / trunk) of each element.
 */
export interface LevelData {
  readonly width: number;
  readonly height: number;
  readonly playerStart: { readonly x: number; readonly y: number };
  readonly trees: readonly { readonly id: string; readonly x: number; readonly y: number; readonly wood: number }[];
  readonly axe: { readonly x: number; readonly y: number };
}

const WIDTH = 1600;
const HEIGHT = 1200;
const PLAYER_START = { x: WIDTH / 2, y: HEIGHT / 2 };
/** Close to the spawn point, so it is the first thing the player finds. */
const AXE_POSITION = { x: PLAYER_START.x + 56, y: PLAYER_START.y + 8 };
const TREE_COUNT = 70;
const MIN_TREE_SPACING = 120;
/**
 * Trees keep this far from the spawn point. Canopies are tall and drawn above the trunk, so a tree
 * just below the spawn would hide the player and the axe.
 */
const SPAWN_CLEARANCE = 200;
const BORDER_MARGIN = 60;
/** Each tree yields between these amounts of wood (inclusive). */
const WOOD_PER_TREE = { min: 5, max: 6 };
const SEED = 42;

export const forestLevel: LevelData = {
  width: WIDTH,
  height: HEIGHT,
  playerStart: PLAYER_START,
  trees: scatterTrees(),
  axe: AXE_POSITION,
};

/** Places trees at random but reproducible spots, keeping them apart and away from the spawn. */
function scatterTrees(): LevelData['trees'][number][] {
  const random = seededRandom(SEED);
  const trees: LevelData['trees'][number][] = [];
  const isFarEnough = (a: { x: number; y: number }, b: { x: number; y: number }) =>
    Math.hypot(a.x - b.x, a.y - b.y) >= MIN_TREE_SPACING;

  for (let attempt = 0; attempt < TREE_COUNT * 50 && trees.length < TREE_COUNT; attempt++) {
    const candidate = {
      x: BORDER_MARGIN + random() * (WIDTH - BORDER_MARGIN * 2),
      y: BORDER_MARGIN + random() * (HEIGHT - BORDER_MARGIN * 2),
    };
    const clearOfSpawn = Math.hypot(candidate.x - PLAYER_START.x, candidate.y - PLAYER_START.y) >= SPAWN_CLEARANCE;
    if (clearOfSpawn && trees.every((tree) => isFarEnough(candidate, tree))) {
      const wood = WOOD_PER_TREE.min + Math.floor(random() * (WOOD_PER_TREE.max - WOOD_PER_TREE.min + 1));
      trees.push({ id: `tree-${trees.length + 1}`, ...candidate, wood });
    }
  }

  return trees;
}
