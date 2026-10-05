import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/can_place_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_build_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_world_snapshot_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

import '../../../core/services/navigation_service_mocks.mocks.dart';
import '../../../domain/repositories/repository_mocks.mocks.dart';

abstract final class ForestBlocMock {
  static const double frameMs = 16;

  static ForestBloc make(World world, {required MockNavigationService navigationService, Object? loadError}) {
    final levelRepository = MockLevelRepository();
    final sessionRepository = MockGameSessionRepository();
    GameSessionEntity? session;
    if (loadError != null) {
      when(levelRepository.load()).thenThrow(loadError);
    } else {
      when(levelRepository.load()).thenReturn(world);
    }
    when(sessionRepository.save(any)).thenAnswer((invocation) {
      session = invocation.positionalArguments.first as GameSessionEntity;
    });
    when(sessionRepository.current()).thenAnswer((_) => session!);
    return ForestBloc(
      startGameUseCase: StartGameUseCase(levelRepository: levelRepository, sessionRepository: sessionRepository),
      movePlayerUseCase: MovePlayerUseCase(sessionRepository: sessionRepository),
      chopTreeUseCase: ChopTreeUseCase(sessionRepository: sessionRepository),
      canPlaceBuildingUseCase: CanPlaceBuildingUseCase(sessionRepository: sessionRepository),
      constructBuildingUseCase: ConstructBuildingUseCase(sessionRepository: sessionRepository),
      advanceGameUseCase: AdvanceGameUseCase(sessionRepository: sessionRepository),
      getPlayerStatusUseCase: GetPlayerStatusUseCase(sessionRepository: sessionRepository),
      getWorldSnapshotUseCase: GetWorldSnapshotUseCase(sessionRepository: sessionRepository),
      getBuildOptionsUseCase: GetBuildOptionsUseCase(sessionRepository: sessionRepository),
      getQuestsUseCase: GetQuestsUseCase(sessionRepository: sessionRepository),
      navigationService: navigationService,
    );
  }

  static void tickFor(ForestBloc bloc, double totalMs) {
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      bloc.add(const ForestTicked(deltaMs: frameMs));
      elapsed += frameMs;
    }
  }

  static Future<void> processEvents() => Future<void>.delayed(Duration.zero);

  static List<ForestEffect> collectEffects(ForestBloc bloc) {
    final effects = <ForestEffect>[];
    bloc.stream.listen((state) => effects.addAll(state.data.effects));
    return effects;
  }

  static List<String> shownMessages(MockNavigationService navigationService) {
    return verify(navigationService.showSnackbar(message: captureAnyNamed('message'))).captured.cast<String>();
  }
}
