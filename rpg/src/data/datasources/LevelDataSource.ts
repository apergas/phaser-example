import type { LevelDto } from '../dtos/LevelDto';

/** Where level data comes from. Swap the implementation to load levels from a different source. */
export interface LevelDataSource {
  fetch(): LevelDto;
}
