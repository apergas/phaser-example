import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/chop_result.dart';
import '../../../../../core/config/constants/enum/construction_rejection.dart';
import '../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../core/config/constants/enum/player_activity.dart';
import '../../../../../core/config/constants/enum/resource.dart';
import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../../core/services/navigation/source/navigation_service.dart';
import '../../../../domain/entities/game/build_option_entity.dart';
import '../../../../domain/entities/game/construction_result_entity.dart';
import '../../../../domain/entities/game/game_event_entity.dart';
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
import '../../../../domain/world/extensions/inventory_rules.dart';
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
  bool _hasGreeted = false;

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
      _hasGreeted = false;
      _placement = null;
      _facing = Facing.down;
      _lastPosition = _getPlayerStatusUseCase().position;
      emit(ForestSuccess(data: _buildData(effects: const [])));
    } on AppException catch (exception) {
      _navigationService.showErrorPopUp(
        title: exception.title,
        message: exception.message,
        buttonTitle: Internationalize.commonAccept,
      );
      emit(ForestFailure(data: state.data, exception: exception));
    }
  }

  Future<void> _onTicked(ForestTicked event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    if (!_hasGreeted) {
      _hasGreeted = true;
      _showMessage(Internationalize.forestMessageWelcome);
    }
    final effects = <ForestEffect>[];
    final fromX = _getPlayerStatusUseCase().position.x;
    for (final gameEvent in _advanceGameUseCase(deltaMs: event.deltaMs)) {
      _react(gameEvent, fromX: fromX, effects: effects);
    }
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }

  Future<void> _onMapClicked(ForestMapClicked event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    final effects = <ForestEffect>[];
    final placement = _placement;
    if (placement != null) {
      if (event.isSecondary) {
        _placement = null;
      } else {
        _place(placement.blueprint, event.position, effects: effects);
      }
    } else if (!event.isSecondary) {
      _orderAt(event.position, treeId: event.treeId);
    }
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }

  Future<void> _onPointerMoved(ForestPointerMoved event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _movePlacement(event.position);
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }

  Future<void> _onBuildRequested(ForestBuildRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _openPlacement(event.blueprint);
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }

  Future<void> _onPlacementCancelled(ForestPlacementCancelled event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _placement = null;
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }

  void _orderAt(PositionEntity position, {required String? treeId}) {
    if (treeId == null) {
      _movePlayerUseCase(x: position.x, y: position.y);
      return;
    }
    if (_chopTreeUseCase(treeId: treeId) == ChopResult.noAxe) {
      _showMessage(Internationalize.forestMessageNeedAxe);
    }
  }

  void _movePlacement(PositionEntity position) {
    final placement = _placement;
    if (placement == null) return;
    _placement = placement.copyWith(
      position: position,
      isValid: _canPlaceBuildingUseCase(blueprint: placement.blueprint, x: position.x, y: position.y),
    );
  }

  void _openPlacement(BlueprintId blueprint) {
    final option = _getBuildOptionsUseCase().firstWhereOrNull((option) => option.blueprint == blueprint);
    if (option == null || !option.isAffordable) {
      _showMessage(Internationalize.forestMessageNotEnoughResources);
      return;
    }
    final position = _lastPosition ?? _getPlayerStatusUseCase().position;
    _placement = PlacementData(blueprint: blueprint, position: position, isValid: false);
    _movePlacement(position);
    _showMessage(Internationalize.forestMessagePlacing(name: Internationalize.forestBlueprint(id: blueprint)));
  }

  void _place(BlueprintId blueprint, PositionEntity position, {required List<ForestEffect> effects}) {
    switch (_constructBuildingUseCase(blueprint: blueprint, x: position.x, y: position.y)) {
      case ConstructionStartedEntity(:final building):
        _placement = null;
        _showMessage(Internationalize.forestMessageBuildingStarted);
        effects.add(BuildingPlacedEffect(building: building));
      case ConstructionRejectedEntity(reason: ConstructionRejection.blocked):
        _showMessage(Internationalize.forestMessageBlockedSite);
      case ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources):
        _placement = null;
        _showMessage(Internationalize.forestMessageNotEnoughResources);
    }
  }

  void _react(GameEventEntity gameEvent, {required double fromX, required List<ForestEffect> effects}) {
    switch (gameEvent) {
      case ItemPickedUpEventEntity(:final itemId):
        _showMessage(Internationalize.forestMessagePickedUpAxe);
        effects.add(ItemPickedUpEffect(itemId: itemId));
      case PlayerBlockedEventEntity():
        _showMessage(Internationalize.forestMessageBlockedPath);
      case TreeHitEventEntity(:final treeId):
        effects.add(TreeHitEffect(treeId: treeId, fromX: fromX));
      case TreeFelledEventEntity(:final treeId, :final wood):
        _showMessage(Internationalize.forestMessageWoodGained(wood: wood));
        effects.add(TreeFelledEffect(treeId: treeId, fromX: fromX));
      case BuildingHammeredEventEntity(:final buildingId, :final progress):
        effects.add(BuildingHammeredEffect(buildingId: buildingId, progress: progress));
      case BuildingCompletedEventEntity(:final buildingId, :final blueprint):
        _showMessage(
          Internationalize.forestMessageBuildingCompleted(name: Internationalize.forestBlueprint(id: blueprint)),
        );
        effects.add(BuildingCompletedEffect(buildingId: buildingId));
      case QuestCompletedEventEntity(:final questId):
        final allDone = _getQuestsUseCase().every((quest) => quest.isCompleted);
        _showMessage(
          allDone
              ? Internationalize.forestMessageAllQuestsCompleted
              : Internationalize.forestMessageQuestCompleted(title: Internationalize.forestQuestTitle(id: questId)),
        );
    }
  }

  void _showMessage(String message) {
    _navigationService.showSnackbar(message: message);
  }

  ForestData _buildData({required List<ForestEffect> effects}) {
    final status = _getPlayerStatusUseCase();
    final quests = _getQuestsUseCase();
    final world = _getWorldSnapshotUseCase();
    final player = _playerRenderData(status);
    final hud = _hudData(status, quests);
    _facing = player.facing;
    _lastPosition = status.position;

    return state.data.copyWith(
      world: () => world,
      player: () => player,
      hud: () => hud,
      placement: () => _placement,
      effects: effects,
    );
  }

  PlayerRenderData _playerRenderData(PlayerStatusEntity status) {
    final lastPosition = _lastPosition ?? status.position;
    final dx = status.position.x - lastPosition.x;
    final dy = status.position.y - lastPosition.y;
    final isMoving = dx != 0 || dy != 0;
    final isWorking = status.activity == PlayerActivity.chopping || status.activity == PlayerActivity.constructing;
    final target = status.target;
    var facing = _facing;
    if (isWorking && target != null) {
      facing = _facingFor(target.x - status.position.x, target.y - status.position.y);
    } else if (isMoving) {
      facing = _facingFor(dx, dy);
    }

    final PlayerPose pose = switch ((isWorking, isMoving)) {
      (true, _) => WorkPose(
        tool: status.activity == PlayerActivity.chopping ? WorkTool.axe : WorkTool.hammer,
        swingProgress: status.swingProgress,
      ),
      (false, true) => WalkPose(withAxe: status.inventory.hasTool(ToolKind.axe)),
      (false, false) => IdlePose(withAxe: status.inventory.hasTool(ToolKind.axe)),
    };
    return PlayerRenderData(position: status.position, facing: facing, pose: pose);
  }

  Facing _facingFor(double dx, double dy) {
    if (dx.abs() > dy.abs()) return dx < 0 ? Facing.left : Facing.right;
    return dy < 0 ? Facing.up : Facing.down;
  }

  HudData _hudData(PlayerStatusEntity status, List<QuestProgressEntity> quests) {
    return HudData(
      wood: status.inventory.amount(Resource.wood),
      hasAxe: status.inventory.hasTool(ToolKind.axe),
      questBadge: '${quests.where((quest) => quest.isCompleted).length}/${quests.length}',
      quests: [for (final quest in quests) _questItem(quest)],
      buildItems: [for (final option in _getBuildOptionsUseCase()) _buildItem(option)],
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

  BuildItemData _buildItem(BuildOptionEntity option) {
    return BuildItemData(
      blueprint: option.blueprint,
      name: Internationalize.forestBlueprint(id: option.blueprint),
      costText: _amounts(option.cost),
      missingText: option.isAffordable ? null : Internationalize.forestMissing(amounts: _amounts(option.missing)),
      isEnabled: option.isAffordable,
    );
  }

  String _amounts(Map<Resource, int> amounts) {
    return amounts.entries
        .sortedBy<num>((entry) => entry.key.index)
        .map((entry) => Internationalize.forestAmount(resource: entry.key, amount: entry.value))
        .join(', ');
  }
}
