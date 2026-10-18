import 'package:farming/layers/domain/entities/stock/stock_entity.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/building/building_entity.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/entities/game/stats_entity.dart';
import 'package:farming/layers/domain/entities/rock/rock_entity.dart';
import 'package:farming/layers/domain/entities/tree/stump_entity.dart';
import 'package:farming/layers/domain/entities/hero/hero_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';
import 'package:farming/layers/domain/entities/tree/tree_entity.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../entities/hero/hero_entity_mock.dart';
import '../entities/player/player_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';
import 'funds_mock.dart';

abstract final class WorldMock {
  static World make({
    PlayerEntity player = PlayerEntityMock.mock,
    List<TreeEntity> trees = const [],
    List<RockEntity> rocks = const [],
    List<BuildingEntity> buildings = const [],
    HeroEntity hero = HeroEntityMock.mock,
  }) {
    return World(
      width: 1000,
      height: 1000,
      player: player,
      trees: trees,
      rocks: rocks,
      buildings: buildings,
      hero: hero,
    );
  }

  static World withHero(HeroEntity hero) => make(hero: hero);

  static World restored({
    PlayerEntity player = PlayerEntityMock.mock,
    List<TreeEntity> trees = const [],
    List<StumpEntity> stumps = const [],
    List<RockEntity> rocks = const [],
    List<BuildingEntity> buildings = const [],
    HeroEntity hero = HeroEntityMock.mock,
    StatsEntity stats = const StatsEntity(),
    StockEntity stock = const StockEntity(),
    Map<String, int> idCounters = const {},
  }) {
    return World.restore(
      width: 1000,
      height: 1000,
      player: player,
      trees: trees,
      stumps: stumps,
      rocks: rocks,
      decorations: const [],
      buildings: buildings,
      hero: hero,
      stats: stats,
      stock: stock,
      idCounters: idCounters,
    );
  }

  static World withStock(Map<Resource, int> stock, {PlayerEntity player = PlayerEntityMock.mock}) =>
      make(player: player)..earn(stock);

  static World small() {
    return World(width: 200, height: 100, player: PlayerEntityMock.centered, trees: const []);
  }

  static World withAxeAndTree() => make(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.mock]);

  static World withAxeAndTreeWithNeighbour() {
    return make(player: PlayerEntityMock.withAxeBelowTree, trees: [TreeEntityMock.mock, TreeEntityMock.neighbour]);
  }

  static World withAxeAndTreeInTheWay() {
    return make(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.farEast, TreeEntityMock.inTheWay]);
  }

  static World withTreeBlockingPath() => make(trees: [TreeEntityMock.blockingPath]);

  static World withFifteenWood() => withStock(FundsMock.fifteenWood);

  static World withSeventeenWood() => withStock(FundsMock.seventeenWood);

  static World withFifteenWoodAndTreeAtSite() {
    return make(trees: [TreeEntityMock.atSite])..earn(FundsMock.fifteenWood);
  }
}

extension WorldAdvanceFor on World {
  List<GameEventEntity> advanceFor(double totalMs, {double stepMs = 16, bool Function()? until}) {
    final events = <GameEventEntity>[];
    var elapsed = 0.0;
    while (elapsed < totalMs && !(until?.call() ?? false)) {
      events.addAll(advance(stepMs));
      elapsed += stepMs;
    }
    return events;
  }
}
