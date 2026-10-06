import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../../domain/entities/building/building_entity.dart';
import '../../../../domain/entities/game/world_snapshot_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../bloc/forest_bloc.dart';
import '../models/forest_effect.dart';
import '../models/placement_data.dart';
import '../models/player_render_data.dart';
import 'atlas/lpc_assets.dart';
import 'atlas/sprite_names.dart';
import 'components/atlas_sprite_component.dart';
import 'components/building_component.dart';
import 'components/ground_component.dart';
import 'components/ground_item_component.dart';
import 'components/placement_ghost_component.dart';
import 'components/player_component.dart';
import 'components/tree_component.dart';
import 'particles/particle_burst_component.dart';
import 'particles/particle_bursts.dart';
import 'render/render_depth.dart';

class ForestSceneComponent extends Component {
  final LpcAssets _assets;
  final math.Random _random;
  final Map<String, TreeComponent> _trees = {};
  final Map<String, GroundItemComponent> _items = {};
  final Map<String, BuildingComponent> _buildings = {};
  final List<AtlasSpriteComponent> _clutter = [];
  PlayerComponent? _player;
  PlacementGhostComponent? _ghost;
  bool _isBuilt = false;

  ForestSceneComponent({required this._assets, math.Random? random}) : _random = random ?? math.Random();

  Map<String, TreeComponent> get trees => Map.unmodifiable(_trees);

  Map<String, GroundItemComponent> get items => Map.unmodifiable(_items);

  Map<String, BuildingComponent> get buildings => Map.unmodifiable(_buildings);

  List<AtlasSpriteComponent> get clutter => List.unmodifiable(_clutter);

  PlayerComponent? get player => _player;

  PlacementGhostComponent? get ghost => _ghost;

  void show(ForestData data) {
    final world = data.world;
    if (world == null) return;
    if (!_isBuilt) _build(world);
    for (final effect in data.effects) {
      _play(effect);
    }
    _reconcile(world);
    final player = data.player;
    if (player != null) _showPlayer(player);
    _showGhost(data.placement);
  }

  String? treeAt(Vector2 point) {
    TreeComponent? best;
    for (final tree in _trees.values) {
      if (!tree.containsPoint(point)) continue;
      if (best == null || tree.priority > best.priority) best = tree;
    }
    return best?.treeId;
  }

  void _build(WorldSnapshotEntity world) {
    _isBuilt = true;
    add(GroundComponent(tile: _assets.ground, worldWidth: world.width, worldHeight: world.height));
    for (final decoration in world.decorations) {
      _addClutter(SpriteNames.decoration(decoration.kind), decoration.position, decoration.position.y);
    }
  }

  void _play(ForestEffect effect) {
    switch (effect) {
      case ItemPickedUpEffect(:final itemId):
        _onItemPickedUp(itemId);
      case TreeHitEffect(:final treeId, :final fromX):
        _onTreeHit(treeId, fromX);
      case TreeFelledEffect(:final treeId, :final fromX):
        _onTreeFelled(treeId, fromX);
      case BuildingPlacedEffect(:final building):
        _onBuildingPlaced(building);
      case BuildingHammeredEffect(:final buildingId, :final progress):
        _onBuildingHammered(buildingId, progress);
      case BuildingCompletedEffect(:final buildingId):
        _onBuildingCompleted(buildingId);
    }
  }

  void _onItemPickedUp(String itemId) {
    _items.remove(itemId)?.pickUp();
  }

  void _onTreeHit(String treeId, double fromX) {
    final tree = _trees[treeId];
    if (tree == null) return;
    tree.hit(fromX);
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.woodChips(trunkBase: tree.base, playerOnLeft: fromX < tree.base.x, random: _random),
        sortY: ParticleBursts.chipsSortY(tree.base),
      ),
    );
  }

  void _onTreeFelled(String treeId, double fromX) {
    final tree = _trees.remove(treeId);
    if (tree == null) return;
    tree.fell(fromX);
    _addClutter(SpriteNames.stump, tree.base, tree.base.y - 1);
  }

  void _onBuildingPlaced(BuildingEntity building) {
    _clearClutterUnder(_building(building));
  }

  void _onBuildingHammered(String buildingId, double progress) {
    final building = _buildings[buildingId];
    if (building == null) return;
    building.hammered(progress);
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.dust(front: building.front, random: _random),
        sortY: ParticleBursts.dustSortY(building.front),
      ),
    );
  }

  void _onBuildingCompleted(String buildingId) {
    _buildings[buildingId]?.complete();
  }

  BuildingComponent _building(BuildingEntity building) {
    return _buildings.putIfAbsent(
      building.id,
      () => _added(BuildingComponent(assets: _assets, building: building)),
    );
  }

  void _reconcile(WorldSnapshotEntity world) {
    final treeIds = {for (final tree in world.trees) tree.id};
    for (final id in _trees.keys.where((id) => !treeIds.contains(id)).toList()) {
      _trees.remove(id)!.removeFromParent();
    }
    for (final tree in world.trees) {
      _trees.putIfAbsent(tree.id, () => _added(TreeComponent(assets: _assets, tree: tree)));
    }

    final itemIds = {for (final item in world.items) item.id};
    for (final id in _items.keys.where((id) => !itemIds.contains(id)).toList()) {
      final item = _items.remove(id)!;
      item.shadow.removeFromParent();
      item.removeFromParent();
    }
    for (final item in world.items) {
      _items.putIfAbsent(item.id, () {
        final component = GroundItemComponent(assets: _assets, item: item);
        add(component.shadow);
        return _added(component);
      });
    }

    for (final building in world.buildings) {
      final component = _building(building);
      if (!component.isComplete && component.progress != building.progress) component.progress = building.progress;
    }
  }

  void _showPlayer(PlayerRenderData player) {
    final current = _player;
    if (current != null) {
      current.show(player);
      return;
    }
    final component = PlayerComponent(assets: _assets, player: player);
    _player = component;
    add(component.shadow);
    add(component);
  }

  void _showGhost(PlacementData? placement) {
    final existing = _ghost;
    if (placement == null || (existing != null && existing.blueprint != placement.blueprint)) {
      existing?.removeFromParent();
      _ghost = null;
    }
    if (placement == null) return;
    final ghost = _ghost;
    if (ghost != null) {
      ghost.show(placement);
      return;
    }
    final created = PlacementGhostComponent(assets: _assets, blueprint: placement.blueprint)..show(placement);
    _ghost = created;
    add(created);
  }

  void _addClutter(String frameName, PositionEntity at, double sortY) {
    _clutter.add(
      _added(AtlasSpriteComponent(assets: _assets, frameName: frameName, at: at, priority: RenderDepth.bySortY(sortY))),
    );
  }

  void _clearClutterUnder(BuildingComponent building) {
    _clutter.removeWhere((sprite) {
      if (!building.boundsContain(sprite.position)) return false;
      sprite.removeFromParent();
      return true;
    });
  }

  T _added<T extends Component>(T component) {
    add(component);
    return component;
  }
}
