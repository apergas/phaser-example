import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/hero/hero_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class SkillScenarioMock {
  static const PositionEntity towerSite = PositionEntity(x: 300, y: 100);
  static const double buildMs = 10000;

  static World withoutTower({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    return WorldMock.withHero(hero)..earn(funds);
  }

  static World withTower({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero)..earn(Blueprints.mageTower.cost);
    world.orderConstruction(Blueprints.mageTower, towerSite);
    world.advanceFor(buildMs);
    return world..earn(funds);
  }

  static World withTowerUnderConstruction({Map<Resource, int> funds = const {}}) {
    final world = WorldMock.make()..earn(Blueprints.mageTower.cost);
    world.orderConstruction(Blueprints.mageTower, towerSite);
    return world..earn(funds);
  }
}
