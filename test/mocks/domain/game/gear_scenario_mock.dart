import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/building/blueprint_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/hero/hero_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class GearScenarioMock {
  static const PositionEntity forgeSite = PositionEntity(x: 300, y: 100);
  static const PositionEntity armorySite = PositionEntity(x: 500, y: 100);
  static const PositionEntity mageTowerSite = PositionEntity(x: 700, y: 100);
  static const double buildMs = 10000;

  static World withoutWorkshops({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    return WorldMock.withHero(hero)..earn(funds);
  }

  static World withForge({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero);
    _build(world, Blueprints.forge, forgeSite);
    return world..earn(funds);
  }

  static World withForgeAndArmory({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero);
    _build(world, Blueprints.forge, forgeSite);
    _build(world, Blueprints.armory, armorySite);
    return world..earn(funds);
  }

  static World withAllWorkshops({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero);
    _build(world, Blueprints.forge, forgeSite);
    _build(world, Blueprints.armory, armorySite);
    _build(world, Blueprints.mageTower, mageTowerSite, ms: buildMs * 2);
    return world..earn(funds);
  }

  static World withForgeUnderConstruction({Map<Resource, int> funds = const {}}) {
    final world = WorldMock.make()..earn(Blueprints.forge.cost);
    world.orderConstruction(Blueprints.forge, forgeSite);
    return world..earn(funds);
  }

  static void _build(World world, BlueprintEntity blueprint, PositionEntity site, {double ms = buildMs}) {
    world.earn(blueprint.cost);
    world.orderConstruction(blueprint, site);
    world.advanceFor(ms);
  }
}
