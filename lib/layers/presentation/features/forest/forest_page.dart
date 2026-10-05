import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/di/locator.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../../domain/use-cases/game/advance_game_use_case.dart';
import '../../../domain/use-cases/game/can_place_building_use_case.dart';
import '../../../domain/use-cases/game/chop_tree_use_case.dart';
import '../../../domain/use-cases/game/construct_building_use_case.dart';
import '../../../domain/use-cases/game/get_build_options_use_case.dart';
import '../../../domain/use-cases/game/get_player_status_use_case.dart';
import '../../../domain/use-cases/game/get_quests_use_case.dart';
import '../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
import '../../../domain/use-cases/game/move_player_use_case.dart';
import '../../../domain/use-cases/game/start_game_use_case.dart';
import 'bloc/forest_bloc.dart';
import 'game/forest_game.dart';

class ForestPage extends StatelessWidget {
  const ForestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForestBloc>(
      create: (_) => ForestBloc(
        startGameUseCase: locator.get<StartGameUseCase>(),
        movePlayerUseCase: locator.get<MovePlayerUseCase>(),
        chopTreeUseCase: locator.get<ChopTreeUseCase>(),
        canPlaceBuildingUseCase: locator.get<CanPlaceBuildingUseCase>(),
        constructBuildingUseCase: locator.get<ConstructBuildingUseCase>(),
        advanceGameUseCase: locator.get<AdvanceGameUseCase>(),
        getPlayerStatusUseCase: locator.get<GetPlayerStatusUseCase>(),
        getWorldSnapshotUseCase: locator.get<GetWorldSnapshotUseCase>(),
        getBuildOptionsUseCase: locator.get<GetBuildOptionsUseCase>(),
        getQuestsUseCase: locator.get<GetQuestsUseCase>(),
        navigationService: locator.get<NavigationService>(),
      )..add(const ForestStarted()),
      child: const _ForestView(),
    );
  }
}

class _ForestView extends StatefulWidget {
  const _ForestView();

  @override
  State<_ForestView> createState() => _ForestViewState();
}

class _ForestViewState extends State<_ForestView> {
  late final ForestGame _game = ForestGame(bloc: context.read<ForestBloc>());

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<ForestGame>(game: _game);
  }
}
