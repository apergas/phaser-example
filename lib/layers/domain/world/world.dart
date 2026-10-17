import '../../../core/config/constants/enum/chop_result.dart';
import '../../../core/config/constants/enum/construction_rejection.dart';
import '../../../core/config/constants/enum/deposit_result.dart';
import '../../../core/config/constants/enum/mine_result.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/resume_construction_result.dart';
import '../entities/building/blueprint_entity.dart';
import '../entities/building/building_entity.dart';
import '../entities/decoration/decoration_entity.dart';
import '../entities/game/construction_result_entity.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/game/stats_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/hero/hero_entity.dart';
import '../entities/item/ground_item_entity.dart';
import '../entities/player/activity_entity.dart';
import '../entities/player/intent_entity.dart';
import '../entities/player/inventory_entity.dart';
import '../entities/player/player_entity.dart';
import '../entities/rock/rock_entity.dart';
import '../entities/tree/stump_entity.dart';
import '../entities/tree/tree_entity.dart';
import 'construction.dart';
import 'depositing.dart';
import 'mining.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'navigation.dart';
import 'pick_up_items.dart';
import 'regrowth.dart';
import 'stats_recording.dart';
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
    List<RockEntity> rocks = const [],
    List<BuildingEntity> buildings = const [],
    HeroEntity hero = const HeroEntity(),
  }) : this._(
         WorldState(
           width: width,
           height: height,
           player: player,
           trees: trees,
           items: items,
           decorations: decorations,
           rocks: rocks,
           buildings: buildings,
           hero: hero,
         ),
       );

  World.restore({
    required double width,
    required double height,
    required PlayerEntity player,
    required List<TreeEntity> trees,
    required List<StumpEntity> stumps,
    required List<RockEntity> rocks,
    required List<GroundItemEntity> items,
    required List<DecorationEntity> decorations,
    required List<BuildingEntity> buildings,
    required HeroEntity hero,
    required StatsEntity stats,
    required InventoryEntity stock,
    required Map<String, int> idCounters,
  }) : this._(
         WorldState(
           width: width,
           height: height,
           player: player,
           trees: trees,
           items: items,
           decorations: decorations,
           rocks: rocks,
           buildings: buildings,
           hero: hero,
           stumps: stumps,
           stats: stats,
           stock: stock,
           idCounters: idCounters,
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

  List<StumpEntity> get stumps => _state.stumps.values.toList();

  List<RockEntity> get rocks => _state.rocks.values.toList();

  StatsEntity get stats => _state.stats;

  InventoryEntity get stock => _state.stock;

  Map<String, int> get idCounters => _state.idCounters;

  HeroEntity get hero => _state.hero;

  List<ObstacleEntity> get obstacles => _state.obstacles();

  double get workProgress {
    final activity = player.activity;
    if (activity is! WorkingActivityEntity) return 0;
    return activity.elapsedMs / workFor(activity.intent).intervalMs(_state);
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

  MineResult orderMine(String rockId) {
    final result = Mining.check(_state, rockId);
    if (result == MineResult.ok) _navigation.goWorkOn(MineIntentEntity(rockId: rockId));
    return result;
  }

  DepositResult orderDeposit(String buildingId) {
    final result = Depositing.check(_state, buildingId);
    if (result == DepositResult.ok) _navigation.goWorkOn(DepositIntentEntity(buildingId: buildingId));
    return result;
  }

  ConstructionResultEntity orderConstruction(BlueprintEntity blueprint, PositionEntity position) {
    final result = Construction.place(_state, blueprint, position);
    if (result is ConstructionStartedEntity) {
      _navigation.goWorkOn(ConstructIntentEntity(buildingId: result.building.id));
    }
    return result;
  }

  ResumeConstructionResult orderResumeConstruction(String buildingId) {
    final building = _state.buildings[buildingId];
    if (building == null) return ResumeConstructionResult.unknownBuilding;
    if (building.isComplete) return ResumeConstructionResult.alreadyComplete;
    _navigation.goWorkOn(ConstructIntentEntity(buildingId: buildingId));
    return ResumeConstructionResult.ok;
  }

  ConstructionRejection? placementRejection(BlueprintEntity blueprint, PositionEntity position) =>
      Construction.rejection(_state, blueprint, position);

  InventoryEntity get funds => _state.stock;

  void earn(Map<Resource, int> reward) {
    _state.stock = _state.stock.adding(reward);
  }

  bool spend(Map<Resource, int> cost) => _state.pay(cost);

  void updateHero(HeroEntity Function(HeroEntity hero) transform) {
    _state.hero = transform(_state.hero);
  }

  List<GameEventEntity> advance(double deltaMs) {
    final events = <GameEventEntity>[];
    Regrowth.advance(_state, deltaMs, events);
    switch (player.activity) {
      case final WalkingActivityEntity walking:
        _navigation.step(deltaMs, walking, events);
      case final WorkingActivityEntity working:
        _work(deltaMs, working, events);
      case IdleActivityEntity():
        break;
    }
    pickUpItems(_state, events);
    StatsRecording.record(_state, events);
    return events;
  }

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
    final intervalMs = work.intervalMs(_state);
    if (elapsed < intervalMs) {
      _state.player = _state.player.continueWork(elapsed);
      return;
    }
    _state.player = _state.player.continueWork(elapsed - intervalMs);
    if (work.impact(_state, events)) _state.player = _state.player.stop();
  }
}
