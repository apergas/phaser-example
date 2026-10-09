import 'package:meta/meta.dart';

import '../../../core/config/constants/enum/chop_result.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/building/blueprint_entity.dart';
import '../entities/building/building_entity.dart';
import '../entities/decoration/decoration_entity.dart';
import '../entities/game/construction_result_entity.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/hero/hero_entity.dart';
import '../entities/item/ground_item_entity.dart';
import '../entities/player/activity_entity.dart';
import '../entities/player/intent_entity.dart';
import '../entities/player/inventory_entity.dart';
import '../entities/player/player_entity.dart';
import '../entities/tree/tree_entity.dart';
import 'construction.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'navigation.dart';
import 'pick_up_items.dart';
import 'woodcutting.dart';
import 'work.dart';
import 'world_state.dart';

class World {
  World({
    required double width,
    required double height,
    required PlayerEntity player,
    required List<TreeEntity> trees,
    List<GroundItemEntity> items = const [],
    List<DecorationEntity> decorations = const [],
    HeroEntity hero = const HeroEntity(),
  }) : this._(
         WorldState(
           width: width,
           height: height,
           player: player,
           trees: trees,
           items: items,
           decorations: decorations,
           hero: hero,
         ),
       );

  World._(this._state) : _navigation = Navigation(_state);

  final WorldState _state;
  final Navigation _navigation;

  double get width => _state.width;

  double get height => _state.height;

  PlayerEntity get player => _state.player;

  List<TreeEntity> get trees => _state.trees.values.toList();

  List<GroundItemEntity> get items => _state.items.values.toList();

  List<DecorationEntity> get decorations => _state.decorations;

  List<BuildingEntity> get buildings => _state.buildings.values.toList();

  HeroEntity get hero => _state.hero;

  List<ObstacleEntity> get obstacles => _state.obstacles();

  double get workProgress {
    final activity = player.activity;
    if (activity is! WorkingActivityEntity) return 0;
    return activity.elapsedMs / workFor(activity.intent).intervalMs;
  }

  PositionEntity? get playerTarget => switch (player.activity) {
    WalkingActivityEntity(:final destination) => destination,
    WorkingActivityEntity(:final intent) => workFor(intent).target(_state)?.position,
    IdleActivityEntity() => null,
  };

  void movePlayerTo(PositionEntity destination) => _navigation.walkTo(destination);

  ChopResult orderChop(String treeId) {
    final result = Woodcutting.check(_state, treeId);
    if (result == ChopResult.ok) _navigation.goWorkOn(ChopIntentEntity(treeId: treeId));
    return result;
  }

  ConstructionResultEntity orderConstruction(BlueprintEntity blueprint, PositionEntity position) {
    final result = Construction.place(_state, blueprint, position);
    if (result is ConstructionStartedEntity) {
      _navigation.goWorkOn(ConstructIntentEntity(buildingId: result.building.id));
    }
    return result;
  }

  bool canPlace(BlueprintEntity blueprint, PositionEntity position) =>
      Construction.canPlace(_state, blueprint, position);

  InventoryEntity get funds => _state.player.inventory;

  void earn(Map<Resource, int> reward) {
    var inventory = _state.player.inventory;
    for (final MapEntry(key: resource, value: quantity) in reward.entries) {
      if (quantity > 0) inventory = inventory.add(resource, quantity);
    }
    _state.player = _state.player.copyWith(inventory: inventory);
  }

  bool spend(Map<Resource, int> cost) {
    final remaining = _state.player.inventory.spend(cost);
    if (remaining == null) return false;
    _state.player = _state.player.copyWith(inventory: remaining);
    return true;
  }

  void updateHero(HeroEntity Function(HeroEntity hero) transform) {
    _state.hero = transform(_state.hero);
  }

  List<GameEventEntity> advance(double deltaMs) {
    final events = <GameEventEntity>[];
    switch (player.activity) {
      case final WalkingActivityEntity walking:
        _navigation.step(deltaMs, walking, events);
      case final WorkingActivityEntity working:
        _work(deltaMs, working, events);
      case IdleActivityEntity():
        break;
    }
    pickUpItems(_state, events);
    return events;
  }

  @visibleForTesting
  void updatePlayer(PlayerEntity Function(PlayerEntity player) transform) {
    _state.player = transform(_state.player);
  }

  void _work(double deltaMs, WorkingActivityEntity activity, List<GameEventEntity> events) {
    final work = workFor(activity.intent);
    if (work.target(_state) == null) {
      _state.player = _state.player.stop();
      return;
    }
    final elapsed = activity.elapsedMs + deltaMs;
    if (elapsed < work.intervalMs) {
      _state.player = _state.player.continueWork(elapsed);
      return;
    }
    _state.player = _state.player.continueWork(elapsed - work.intervalMs);
    if (work.impact(_state, events)) _state.player = _state.player.stop();
  }
}
