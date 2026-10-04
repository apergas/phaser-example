import { AdvanceWorldUseCase } from '../../../../src/domain/usecases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from '../../../../src/domain/usecases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from '../../../../src/domain/usecases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from '../../../../src/domain/usecases/GetGameStateUseCase';
import { MovePlayerToUseCase } from '../../../../src/domain/usecases/MovePlayerToUseCase';
import type { World } from '../../../../src/domain/world/World';
import { ForestViewModel } from '../../../../src/presentation/screens/forest/ForestViewModel';
import { sessionFor } from '../../../fixtures';

/** A view model wired to real use cases over `world`, as main.ts does. */
export function viewModelFor(world: World): ForestViewModel {
  const sessions = sessionFor(world);
  return new ForestViewModel({
    movePlayerTo: new MovePlayerToUseCase(sessions),
    chopTree: new ChopTreeUseCase(sessions),
    constructBuilding: new ConstructBuildingUseCase(sessions),
    advanceWorld: new AdvanceWorldUseCase(sessions),
    gameState: new GetGameStateUseCase(sessions),
  });
}

/** Ticks the view model in 16ms steps, collecting every effect. */
export function tickFor(viewModel: ForestViewModel, totalMs: number) {
  const effects = [];
  for (let elapsed = 0; elapsed < totalMs; elapsed += 16) effects.push(...viewModel.tick(16));
  return effects;
}
