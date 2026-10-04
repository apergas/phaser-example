import type { LevelDefinition, LevelSource } from '../../application/ports/LevelSource';
import { seededRandom } from '../../shared/seededRandom';

const WIDTH = 1600;
const HEIGHT = 1200;
const PLAYER_START = { x: WIDTH / 2, y: HEIGHT / 2 };
/** Close to the spawn point, so it is the first thing the player finds. */
const AXE = { id: 'axe', kind: 'axe', x: PLAYER_START.x + 56, y: PLAYER_START.y + 8 } as const;
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

type TreeDefinition = LevelDefinition['trees'][number];

/**
 * A forest generated from a fixed seed: the same layout on every run. Replaceable by a Tiled map
 * loader implementing the same `LevelSource` port.
 */
export class ProceduralForestLevel implements LevelSource {
  load(): LevelDefinition {
    return {
      width: WIDTH,
      height: HEIGHT,
      playerStart: PLAYER_START,
      trees: scatterTrees(),
      items: [AXE],
    };
  }
}

/** Places trees at random but reproducible spots, keeping them apart and away from the spawn. */
function scatterTrees(): TreeDefinition[] {
  const random = seededRandom(SEED);
  const trees: TreeDefinition[] = [];
  const distance = (a: { x: number; y: number }, b: { x: number; y: number }) => Math.hypot(a.x - b.x, a.y - b.y);

  for (let attempt = 0; attempt < TREE_COUNT * 50 && trees.length < TREE_COUNT; attempt++) {
    const candidate = {
      x: BORDER_MARGIN + random() * (WIDTH - BORDER_MARGIN * 2),
      y: BORDER_MARGIN + random() * (HEIGHT - BORDER_MARGIN * 2),
    };
    const clearOfSpawn = distance(candidate, PLAYER_START) >= SPAWN_CLEARANCE;
    if (clearOfSpawn && trees.every((tree) => distance(candidate, tree) >= MIN_TREE_SPACING)) {
      const wood = WOOD_PER_TREE.min + Math.floor(random() * (WOOD_PER_TREE.max - WOOD_PER_TREE.min + 1));
      trees.push({ id: `tree-${trees.length + 1}`, ...candidate, wood });
    }
  }

  return trees;
}
