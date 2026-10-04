import { AdvanceWorldUseCase } from '../../src/application/use-cases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from '../../src/application/use-cases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from '../../src/application/use-cases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from '../../src/application/use-cases/GetGameStateUseCase';
import { MovePlayerToUseCase } from '../../src/application/use-cases/MovePlayerToUseCase';
import type { World } from '../../src/domain/world/World';
import { GameViewModel } from '../../src/presentation/viewmodels/GameViewModel';
import { sessionFor } from '../fixtures';

/** A view model wired to real use cases over `world`, as main.ts does. */
export function viewModelFor(world: World): GameViewModel {
  const sessions = sessionFor(world);
  return new GameViewModel({
    movePlayerTo: new MovePlayerToUseCase(sessions),
    chopTree: new ChopTreeUseCase(sessions),
    constructBuilding: new ConstructBuildingUseCase(sessions),
    advanceWorld: new AdvanceWorldUseCase(sessions),
    gameState: new GetGameStateUseCase(sessions),
  });
}

/** Ticks the view model in 16ms steps, collecting every effect. */
export function tickFor(viewModel: GameViewModel, totalMs: number) {
  const effects = [];
  for (let elapsed = 0; elapsed < totalMs; elapsed += 16) effects.push(...viewModel.tick(16));
  return effects;
}
