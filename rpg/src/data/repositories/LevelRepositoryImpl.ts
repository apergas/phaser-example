import type { LevelRepository } from '../../domain/repositories/LevelRepository';
import type { World } from '../../domain/world/World';
import type { LevelDataSource } from '../datasources/LevelDataSource';
import { toWorld } from '../mappers/LevelMapper';

export class LevelRepositoryImpl implements LevelRepository {
  private readonly dataSource: LevelDataSource;

  constructor(dataSource: LevelDataSource) {
    this.dataSource = dataSource;
  }

  load(): World {
    return toWorld(this.dataSource.fetch());
  }
}
