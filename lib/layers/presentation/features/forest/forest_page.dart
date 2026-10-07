import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/i18n/internationalize.dart';
import '../../../../core/config/di/locator.dart';
import '../../../../core/error-handling/exceptions/app_exceptions.dart';
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
import '../../theme/colors/custom_colors.dart';
import '../../theme/styles/custom_text_styles.dart';
import 'game/atlas/lpc_assets_loader.dart';
import 'game/forest_game.dart';
import 'models/hud_data.dart';
import 'models/placement_data.dart';
import 'widgets/hud_button.dart';
import 'widgets/hud_overlay.dart';
import 'widgets/hud_panel.dart';
import 'widgets/placement_bar.dart';

class ForestPage extends StatelessWidget {
  const ForestPage({super.key, required this.routeObserver});

  final RouteObserver<ModalRoute<void>> routeObserver;

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
      child: _ForestView(routeObserver: routeObserver),
    );
  }
}

class _ForestView extends StatefulWidget {
  const _ForestView({required this.routeObserver});

  final RouteObserver<ModalRoute<void>> routeObserver;

  @override
  State<_ForestView> createState() => _ForestViewState();
}

class _ForestViewState extends State<_ForestView> with RouteAware {
  ForestBloc get bloc => context.read<ForestBloc>();

  late ForestGame _game = _createGame();

  bool get _isTouchPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };

  ForestGame _createGame() => ForestGame(
    bloc: bloc,
    assetsLoader: LpcAssetsLoader(bundle: DefaultAssetBundle.of(context)),
  );

  void _restartGame() {
    setState(() => _game = _createGame());
    bloc.add(const ForestStarted());
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) widget.routeObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _game.pauseEngine();

  @override
  void didPopNext() => _game.resumeEngine();

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.black,
      body: BlocBuilder<ForestBloc, ForestState>(
        buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
        builder: (context, state) => _bodyByState(state),
      ),
      bottomNavigationBar: _isTouchPlatform ? _placementBar() : null,
    );
  }

  Widget _bodyByState(ForestState state) {
    return switch (state) {
      ForestInitial() => _loadingBody(),
      ForestInProgress() => _loadingBody(),
      ForestSuccess() => _gameBody(),
      ForestFailure() => _errorBody(state),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator(color: CustomColors.hudAccent));
  }

  Widget _gameBody() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => bloc.add(const ForestPlacementCancelled()),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              container: true,
              label: Internationalize.forestAccessibilityGameWorld,
              child: GameWidget<ForestGame>(
                game: _game,
                autofocus: false,
                errorBuilder: (context, error) => _gameErrorBody(),
              ),
            ),
            SafeArea(child: _hud()),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    return BlocSelector<ForestBloc, ForestState, HudData?>(
      selector: (state) => state.data.hud,
      builder: (context, hud) => _hudOverlay(hud: hud),
    );
  }

  Widget _hudOverlay({required HudData? hud}) {
    if (hud == null) return const SizedBox.shrink();
    return HudOverlay(
      hud: hud,
      onBuildSelected: (blueprint) => bloc.add(ForestBuildRequested(blueprint: blueprint)),
      onArenaPressed: () => bloc.add(const ForestArenaRequested()),
    );
  }

  Widget _placementBar() {
    return BlocSelector<ForestBloc, ForestState, PlacementData?>(
      selector: (state) => state.data.placement,
      builder: (context, placement) => _placementActions(placement: placement),
    );
  }

  Widget _placementActions({required PlacementData? placement}) {
    if (placement == null) return const SizedBox.shrink();
    return PlacementBar(
      onConfirm: () => bloc.add(ForestMapClicked(position: placement.position)),
      onCancel: () => bloc.add(const ForestPlacementCancelled()),
    );
  }

  Widget _errorBody(ForestFailure state) {
    return _errorPanel(
      title: state.exception.title,
      message: state.exception.message,
      onRetry: () => bloc.add(const ForestStarted()),
    );
  }

  Widget _gameErrorBody() {
    const exception = GenericException();
    return _errorPanel(title: exception.title, message: exception.message, onRetry: _restartGame);
  }

  Widget _errorPanel({required String title, required String message, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HudPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: CustomTextStyles.system18w600.copyWith(color: CustomColors.hudAccent),
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
              HudButton(label: Internationalize.forestRetry, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
