import type { World } from '../world/World';

/** Provides the world a new game starts in. Implemented in `data/` (procedural today, Tiled later). */
export interface LevelRepository {
  load(): World;
}
