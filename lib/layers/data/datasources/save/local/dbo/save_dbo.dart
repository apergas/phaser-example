import 'package:collection/collection.dart';

import 'save_building_dbo.dart';
import 'save_decoration_dbo.dart';
import 'save_hero_dbo.dart';
import 'save_json.dart';
import 'save_player_dbo.dart';
import 'save_rock_dbo.dart';
import 'save_stats_dbo.dart';
import 'save_stock_dbo.dart';
import 'save_stump_dbo.dart';
import 'save_tree_dbo.dart';

class SaveDBO {
  static const int currentVersion = 3;

  final int? version;
  final double? width;
  final double? height;
  final SavePlayerDBO? player;
  final SaveHeroDBO? hero;
  final SaveStatsDBO? stats;
  final SaveStockDBO? stock;
  final List<SaveTreeDBO>? trees;
  final List<SaveStumpDBO>? stumps;
  final List<SaveRockDBO>? rocks;
  final List<SaveDecorationDBO>? decorations;
  final List<SaveBuildingDBO>? buildings;
  final Map<String, int>? idCounters;
  final List<String>? completedQuests;

  const SaveDBO({
    this.version,
    this.width,
    this.height,
    this.player,
    this.hero,
    this.stats,
    this.stock,
    this.trees,
    this.stumps,
    this.rocks,
    this.decorations,
    this.buildings,
    this.idCounters,
    this.completedQuests,
  });

  factory SaveDBO.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>?;
    final hero = json['hero'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final stock = json['stock'] as Map<String, dynamic>?;
    return SaveDBO(
      version: json['version'] as int?,
      width: readDouble(json['width']),
      height: readDouble(json['height']),
      player: player == null ? null : SavePlayerDBO.fromJson(player),
      hero: hero == null ? null : SaveHeroDBO.fromJson(hero),
      stats: stats == null ? null : SaveStatsDBO.fromJson(stats),
      stock: stock == null ? null : SaveStockDBO.fromJson(stock),
      trees: readObjectList(json['trees'], SaveTreeDBO.fromJson),
      stumps: readObjectList(json['stumps'], SaveStumpDBO.fromJson),
      rocks: readObjectList(json['rocks'], SaveRockDBO.fromJson),
      decorations: readObjectList(json['decorations'], SaveDecorationDBO.fromJson),
      buildings: readObjectList(json['buildings'], SaveBuildingDBO.fromJson),
      idCounters: readIntMap(json['idCounters']),
      completedQuests: readStringList(json['completedQuests']),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'width': width,
    'height': height,
    'player': player?.toJson(),
    'hero': hero?.toJson(),
    'stats': stats?.toJson(),
    'stock': stock?.toJson(),
    'trees': trees?.map((tree) => tree.toJson()).toList(),
    'stumps': stumps?.map((stump) => stump.toJson()).toList(),
    'rocks': rocks?.map((rock) => rock.toJson()).toList(),
    'decorations': decorations?.map((decoration) => decoration.toJson()).toList(),
    'buildings': buildings?.map((building) => building.toJson()).toList(),
    'idCounters': idCounters,
    'completedQuests': completedQuests,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveDBO &&
      other.version == version &&
      other.width == width &&
      other.height == height &&
      other.player == player &&
      other.hero == hero &&
      other.stats == stats &&
      other.stock == stock &&
      const ListEquality<SaveTreeDBO>().equals(other.trees, trees) &&
      const ListEquality<SaveStumpDBO>().equals(other.stumps, stumps) &&
      const ListEquality<SaveRockDBO>().equals(other.rocks, rocks) &&
      const ListEquality<SaveDecorationDBO>().equals(other.decorations, decorations) &&
      const ListEquality<SaveBuildingDBO>().equals(other.buildings, buildings) &&
      const MapEquality<String, int>().equals(other.idCounters, idCounters) &&
      const ListEquality<String>().equals(other.completedQuests, completedQuests);

  @override
  int get hashCode => Object.hash(
    version,
    width,
    height,
    player,
    hero,
    stats,
    stock,
    const ListEquality<SaveTreeDBO>().hash(trees),
    const ListEquality<SaveStumpDBO>().hash(stumps),
    const ListEquality<SaveRockDBO>().hash(rocks),
    const ListEquality<SaveDecorationDBO>().hash(decorations),
    const ListEquality<SaveBuildingDBO>().hash(buildings),
    const MapEquality<String, int>().hash(idCounters),
    const ListEquality<String>().hash(completedQuests),
  );

  @override
  String toString() =>
      'SaveDBO(version: $version, width: $width, height: $height, player: $player, hero: $hero, stats: $stats, '
      'stock: $stock, trees: $trees, stumps: $stumps, rocks: $rocks, decorations: $decorations, '
      'buildings: $buildings, idCounters: $idCounters, completedQuests: $completedQuests)';
}
