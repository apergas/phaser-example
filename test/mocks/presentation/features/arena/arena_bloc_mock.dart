import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

import '../../../core/services/navigation_service_mocks.mocks.dart';
import '../../../domain/entities/game/game_session_entity_mock.dart';
import '../../../domain/repositories/repository_mocks.mocks.dart';

abstract final class ArenaBlocMock {
  static const double frameMs = 16;

  static ArenaBloc make(World world, {required MockNavigationService navigationService, Exception? error}) {
    final sessionRepository = MockGameSessionRepository();
    final session = GameSessionEntityMock.playing(world);
    when(sessionRepository.current()).thenAnswer((_) {
      if (error != null) throw error;
      return session;
    });
    return ArenaBloc(
      getArenaUseCase: GetArenaUseCase(sessionRepository: sessionRepository),
      startFightUseCase: StartFightUseCase(sessionRepository: sessionRepository),
      getHeroStatusUseCase: GetHeroStatusUseCase(sessionRepository: sessionRepository),
      navigationService: navigationService,
    );
  }

  static void tickFor(ArenaBloc bloc, double totalMs) {
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      bloc.add(const ArenaReplayTicked(deltaMs: frameMs));
      elapsed += frameMs;
    }
  }

  static List<ArenaEffect> collectEffects(ArenaBloc bloc) {
    final effects = <ArenaEffect>[];
    bloc.stream.listen((state) => effects.addAll(state.data.effects));
    return effects;
  }
}
