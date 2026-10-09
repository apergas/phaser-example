import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/i18n/internationalize.dart';
import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/di/locator.dart';
import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../../domain/use-cases/arena/get_arena_use_case.dart';
import '../../../domain/use-cases/arena/start_fight_use_case.dart';
import '../../../domain/use-cases/hero/get_hero_status_use_case.dart';
import '../../theme/colors/custom_colors.dart';
import '../../theme/styles/custom_text_styles.dart';
import '../forest/widgets/hud_button.dart';
import '../forest/widgets/hud_panel.dart';
import 'bloc/arena_bloc.dart';
import 'game/arena_game.dart';
import 'game/atlas/arena_assets_loader.dart';
import 'models/arena_level_item_data.dart';
import 'models/arena_result_data.dart';
import 'widgets/arena_hud.dart';

class ArenaPage extends StatelessWidget {
  const ArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ArenaBloc>(
      create: (_) => ArenaBloc(
        getArenaUseCase: locator.get<GetArenaUseCase>(),
        startFightUseCase: locator.get<StartFightUseCase>(),
        getHeroStatusUseCase: locator.get<GetHeroStatusUseCase>(),
        navigationService: locator.get<NavigationService>(),
      )..add(const ArenaStarted()),
      child: const _ArenaView(),
    );
  }
}

typedef _HudView = ({
  List<ArenaLevelItemData> levels,
  ArenaLevelId? selected,
  int heroPower,
  bool isReplaying,
  bool canFight,
  ArenaResultData? result,
});

class _ArenaView extends StatefulWidget {
  const _ArenaView();

  @override
  State<_ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<_ArenaView> {
  ArenaBloc get bloc => context.read<ArenaBloc>();

  late ArenaGame _game = _createGame();

  ArenaGame _createGame() => ArenaGame(
    bloc: bloc,
    assetsLoader: ArenaAssetsLoader(bundle: DefaultAssetBundle.of(context)),
  );

  void _restartGame() {
    setState(() => _game = _createGame());
    bloc.add(const ArenaStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.black,
      body: BlocBuilder<ArenaBloc, ArenaState>(
        buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
        builder: (context, state) => _bodyByState(state),
      ),
    );
  }

  Widget _bodyByState(ArenaState state) {
    return switch (state) {
      ArenaInitial() => _loadingBody(),
      ArenaInProgress() => _loadingBody(),
      ArenaSuccess() => _arenaBody(),
      ArenaFailure() => _errorBody(state),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator(color: CustomColors.hudAccent));
  }

  Widget _arenaBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          container: true,
          label: Internationalize.arenaAccessibilityStage,
          child: GameWidget<ArenaGame>(
            game: _game,
            autofocus: false,
            errorBuilder: (context, error) => _gameErrorBody(),
          ),
        ),
        SafeArea(child: _hud()),
      ],
    );
  }

  Widget _hud() {
    return BlocSelector<ArenaBloc, ArenaState, _HudView>(
      selector: (state) => (
        levels: state.data.levels,
        selected: state.data.selected,
        heroPower: state.data.heroPower,
        isReplaying: state.data.isReplaying,
        canFight: state.data.canFight,
        result: state.data.result,
      ),
      builder: (context, view) => ArenaHud(
        levels: view.levels,
        selected: view.selected,
        heroPower: view.heroPower,
        isReplaying: view.isReplaying,
        canFight: view.canFight,
        result: view.result,
        onLevelSelected: (levelId) => bloc.add(ArenaLevelSelected(levelId: levelId)),
        onFight: () => bloc.add(const ArenaFightRequested()),
        onSkip: () => bloc.add(const ArenaReplaySkipped()),
        onBack: () => bloc.add(const ArenaClosed()),
      ),
    );
  }

  Widget _errorBody(ArenaFailure state) {
    return _errorPanel(title: state.exception.title, message: state.exception.message, onRetry: null);
  }

  Widget _gameErrorBody() {
    const exception = GenericException();
    return _errorPanel(title: exception.title, message: exception.message, onRetry: _restartGame);
  }

  Widget _errorPanel({required String title, required String message, required VoidCallback? onRetry}) {
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
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (onRetry != null) HudButton(label: Internationalize.arenaRetry, onPressed: onRetry),
                  HudButton(label: Internationalize.arenaBack, onPressed: () => bloc.add(const ArenaClosed())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
