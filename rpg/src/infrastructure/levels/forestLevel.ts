import { seededRandom } from '../../shared/seededRandom';

/**
 * Level data as plain values, so it can later be replaced by a Tiled map loader
 * without touching the domain. Positions are the base (feet / trunk) of each element.
 */
export interface LevelData {
  readonly width: number;
  readonly height: number;
  readonly playerStart: { readonly x: number; readonly y: number };
  readonly trees: readonly { readonly x: number; readonly y: number }[];
}

const WIDTH = 1600;
const HEIGHT = 1200;
const PLAYER_START = { x: WIDTH / 2, y: HEIGHT / 2 };
const TREE_COUNT = 70;
const MIN_TREE_SPACING = 120;
const BORDER_MARGIN = 60;
const SEED = 42;

export const forestLevel: LevelData = {
  width: WIDTH,
  height: HEIGHT,
  playerStart: PLAYER_START,
  trees: scatterTrees(),
};

/** Places trees at random but reproducible spots, keeping them apart and away from the spawn. */
function scatterTrees(): { x: number; y: number }[] {
  const random = seededRandom(SEED);
  const trees: { x: number; y: number }[] = [];
  const isFarEnough = (a: { x: number; y: number }, b: { x: number; y: number }) =>
    Math.hypot(a.x - b.x, a.y - b.y) >= MIN_TREE_SPACING;

  for (let attempt = 0; attempt < TREE_COUNT * 50 && trees.length < TREE_COUNT; attempt++) {
    const candidate = {
      x: BORDER_MARGIN + random() * (WIDTH - BORDER_MARGIN * 2),
      y: BORDER_MARGIN + random() * (HEIGHT - BORDER_MARGIN * 2),
    };
    if (isFarEnough(candidate, PLAYER_START) && trees.every((tree) => isFarEnough(candidate, tree))) {
      trees.push(candidate);
    }
  }

  return trees;
}
