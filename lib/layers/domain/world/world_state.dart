import 'dart:math';

import '../../../core/config/constants/enum/resource.dart';
import '../entities/building/building_entity.dart';
import '../entities/decoration/decoration_entity.dart';
import '../entities/game/stats_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/hero/hero_entity.dart';
import '../entities/item/ground_item_entity.dart';
import '../entities/player/inventory_entity.dart';
import '../entities/player/player_entity.dart';
import '../entities/rock/rock_entity.dart';
import '../entities/tree/stump_entity.dart';
import '../entities/tree/tree_entity.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/obstacle_rules.dart';

class WorldState {
  WorldState({
    required this.width,
    required this.height,
    required this.player,
    required List<TreeEntity> trees,
    required List<GroundItemEntity> items,
    required List<DecorationEntity> decorations,
    required List<RockEntity> rocks,
    required List<BuildingEntity> buildings,
    this.hero = const HeroEntity(),
    List<StumpEntity> stumps = const [],
    this.stats = const StatsEntity(),
    this.stock = const InventoryEntity(),
    Map<String, int> idCounters = const {},
  }) : assert(width > 0 && height > 0),
       trees = {for (final tree in trees) tree.id: tree},
       items = {for (final item in items) item.id: item},
       rocks = {for (final rock in rocks) rock.id: rock},
       buildings = {for (final building in buildings) building.id: building},
       stumps = {for (final stump in stumps) stump.id: stump},
       _idCounters = {...idCounters},
       decorations = List.unmodifiable(decorations);

  final double width;
  final double height;
  PlayerEntity player;
  HeroEntity hero;
  final List<DecorationEntity> decorations;
  final Map<String, TreeEntity> trees;
  final Map<String, GroundItemEntity> items;
  final Map<String, RockEntity> rocks;
  final Map<String, BuildingEntity> buildings;
  final Map<String, StumpEntity> stumps;
  StatsEntity stats;
  InventoryEntity stock;
  final Map<String, int> _idCounters;

  Map<String, int> get idCounters => Map.unmodifiable(_idCounters);

  List<ObstacleEntity> obstacles() => [
    for (final tree in trees.values) tree.footprint,
    for (final rock in rocks.values) rock.footprint,
    for (final building in buildings.values) building.footprint,
  ];

  bool isBlocked(PositionEntity position, double radius) =>
      obstacles().any((obstacle) => obstacle.blocks(position, radius));

  PositionEntity clamp(PositionEntity position, double margin) {
    double clampValue(double value, double limit) => min(max(value, margin), limit - margin);
    return PositionEntity(x: clampValue(position.x, width), y: clampValue(position.y, height));
  }

  bool isInside(PositionEntity position, double margin) => clamp(position, margin) == position;

  bool pay(Map<Resource, int> cost) {
    final remaining = stock.spend(cost);
    if (remaining == null) return false;
    stock = remaining;
    return true;
  }

  String nextId(String prefix) {
    final next = (_idCounters[prefix] ?? 0) + 1;
    _idCounters[prefix] = next;
    return '$prefix-$next';
  }
}
