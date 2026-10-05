import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../core/config/constants/enum/player_activity.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../../core/services/navigation/source/navigation_service.dart';
import '../../../../domain/entities/game/build_option_entity.dart';
import '../../../../domain/entities/game/player_status_entity.dart';
import '../../../../domain/entities/game/quest_progress_entity.dart';
import '../../../../domain/entities/game/world_snapshot_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/use-cases/game/advance_game_use_case.dart';
import '../../../../domain/use-cases/game/can_place_building_use_case.dart';
import '../../../../domain/use-cases/game/chop_tree_use_case.dart';
import '../../../../domain/use-cases/game/construct_building_use_case.dart';
import '../../../../domain/use-cases/game/get_build_options_use_case.dart';
import '../../../../domain/use-cases/game/get_player_status_use_case.dart';
import '../../../../domain/use-cases/game/get_quests_use_case.dart';
import '../../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
import '../../../../domain/use-cases/game/move_player_use_case.dart';
import '../../../../domain/use-cases/game/start_game_use_case.dart';
import '../models/build_item_data.dart';
import '../models/forest_effect.dart';
import '../models/hud_data.dart';
import '../models/placement_data.dart';
import '../models/player_pose.dart';
import '../models/player_render_data.dart';
import '../models/quest_item_data.dart';

part 'forest_event.dart';
part 'forest_state.dart';

class ForestBloc extends Bloc<ForestEvent, ForestState> {
  final StartGameUseCase _startGameUseCase;
  final MovePlayerUseCase _movePlayerUseCase;
  final ChopTreeUseCase _chopTreeUseCase;
  final CanPlaceBuildingUseCase _canPlaceBuildingUseCase;
  final ConstructBuildingUseCase _constructBuildingUseCase;
  final AdvanceGameUseCase _advanceGameUseCase;
  final GetPlayerStatusUseCase _getPlayerStatusUseCase;
  final GetWorldSnapshotUseCase _getWorldSnapshotUseCase;
  final GetBuildOptionsUseCase _getBuildOptionsUseCase;
  final GetQuestsUseCase _getQuestsUseCase;
  final NavigationService _navigationService;

  PositionEntity? _lastPosition;
  Facing _facing = Facing.down;
  PlacementData? _placement;

  ForestBloc({
    required this._startGameUseCase,
    required this._movePlayerUseCase,
    required this._chopTreeUseCase,
    required this._canPlaceBuildingUseCase,
    required this._constructBuildingUseCase,
    required this._advanceGameUseCase,
    required this._getPlayerStatusUseCase,
    required this._getWorldSnapshotUseCase,
    required this._getBuildOptionsUseCase,
    required this._getQuestsUseCase,
    required this._navigationService,
  }) : super(const ForestInitial()) {
    on<ForestEvent>((event, emit) async {
      await switch (event) {
        ForestStarted() => _onStarted(event, emit),
        ForestTicked() => _onTicked(event, emit),
        ForestMapClicked() => _onMapClicked(event, emit),
        ForestPointerMoved() => _onPointerMoved(event, emit),
        ForestBuildRequested() => _onBuildRequested(event, emit),
        ForestPlacementCancelled() => _onPlacementCancelled(event, emit),
      };
    });
  }

  Future<void> _onStarted(ForestStarted event, Emitter<ForestState> emit) async {
    emit(ForestInProgress(data: state.data));

    try {
      _startGameUseCase();
      _lastPosition = _getPlayerStatusUseCase().position;
      emit(ForestSuccess(data: _buildData(effects: const [])));
    } on AppException catch (exception) {
      _navigationService.showErrorPopUp(
        title: exception.title,
        message: exception.message,
        buttonTitle: Internationalize.commonError,
      );
      emit(ForestFailure(data: state.data, exception: exception));
    }
  }

  Future<void> _onTicked(ForestTicked event, Emitter<ForestState> emit) async {}

  Future<void> _onMapClicked(ForestMapClicked event, Emitter<ForestState> emit) async {}

  Future<void> _onPointerMoved(ForestPointerMoved event, Emitter<ForestState> emit) async {}

  Future<void> _onBuildRequested(ForestBuildRequested event, Emitter<ForestState> emit) async {}

  Future<void> _onPlacementCancelled(ForestPlacementCancelled event, Emitter<ForestState> emit) async {}

  ForestData _buildData({required List<ForestEffect> effects}) {
    final status = _getPlayerStatusUseCase();
    final quests = _getQuestsUseCase();
    return state.data.copyWith(
      world: () => _getWorldSnapshotUseCase(),
      player: () => _playerRenderData(status),
      hud: () => _hudData(status, quests),
      placement: () => _placement,
      effects: effects,
    );
  }

  PlayerRenderData _playerRenderData(PlayerStatusEntity status) {
    final lastPosition = _lastPosition ?? status.position;
    final dx = status.position.x - lastPosition.x;
    final dy = status.position.y - lastPosition.y;
    final isMoving = dx != 0 || dy != 0;
    _lastPosition = status.position;

    final isWorking = status.activity == PlayerActivity.chopping || status.activity == PlayerActivity.constructing;
    final target = status.target;
    if (isWorking && target != null) {
      _facing = _facingFor(target.x - status.position.x, target.y - status.position.y);
    } else if (isMoving) {
      _facing = _facingFor(dx, dy);
    }

    final PlayerPose pose = switch ((isWorking, isMoving)) {
      (true, _) => WorkPose(
        tool: status.activity == PlayerActivity.chopping ? WorkTool.axe : WorkTool.hammer,
        swingProgress: status.swingProgress,
      ),
      (false, true) => WalkPose(withAxe: status.hasAxe),
      (false, false) => IdlePose(withAxe: status.hasAxe),
    };
    return PlayerRenderData(position: status.position, facing: _facing, pose: pose);
  }

  Facing _facingFor(double dx, double dy) {
    if (dx.abs() > dy.abs()) return dx < 0 ? Facing.left : Facing.right;
    return dy < 0 ? Facing.up : Facing.down;
  }

  HudData _hudData(PlayerStatusEntity status, List<QuestProgressEntity> quests) {
    return HudData(
      wood: status.wood,
      hasAxe: status.hasAxe,
      questBadge: '${quests.where((quest) => quest.isCompleted).length}/${quests.length}',
      quests: [for (final quest in quests) _questItem(quest)],
      buildItems: [for (final option in _getBuildOptionsUseCase()) _buildItem(option, wood: status.wood)],
      isBuildLocked: _placement != null,
    );
  }

  QuestItemData _questItem(QuestProgressEntity quest) {
    return QuestItemData(
      title: Internationalize.forestQuestTitle(id: quest.id),
      progressText: switch (quest) {
        QuestProgressEntity(isCompleted: true) => Internationalize.forestQuestDone,
        QuestProgressEntity(target: > 1) => '${quest.progress}/${quest.target}',
        _ => '',
      },
      status: switch (quest) {
        QuestProgressEntity(isCompleted: true) => QuestItemStatus.done,
        QuestProgressEntity(isCurrent: true) => QuestItemStatus.current,
        _ => QuestItemStatus.pending,
      },
    );
  }

  BuildItemData _buildItem(BuildOptionEntity option, {required int wood}) {
    return BuildItemData(
      blueprint: option.blueprint,
      name: Internationalize.forestBlueprint(id: option.blueprint),
      costText: Internationalize.forestCost(wood: option.woodCost),
      missingText: option.isAffordable ? null : Internationalize.forestMissing(wood: option.woodCost - wood),
      isEnabled: option.isAffordable,
    );
  }
}
