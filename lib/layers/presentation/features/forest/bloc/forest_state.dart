part of 'forest_bloc.dart';

class ForestData {
  final WorldSnapshotEntity? world;
  final PlayerRenderData? player;
  final HudData? hud;
  final PlacementData? placement;
  final List<ForestEffect> effects;

  const ForestData({this.world, this.player, this.hud, this.placement, this.effects = const []});

  ForestData copyWith({
    ValueGetter<WorldSnapshotEntity?>? world,
    ValueGetter<PlayerRenderData?>? player,
    ValueGetter<HudData?>? hud,
    ValueGetter<PlacementData?>? placement,
    List<ForestEffect>? effects,
  }) {
    return ForestData(
      world: world != null ? world() : this.world,
      player: player != null ? player() : this.player,
      hud: hud != null ? hud() : this.hud,
      placement: placement != null ? placement() : this.placement,
      effects: effects ?? this.effects,
    );
  }
}

sealed class ForestState {
  final ForestData data;

  const ForestState({required this.data});
}

final class ForestInitial extends ForestState {
  const ForestInitial() : super(data: const ForestData());
}

final class ForestInProgress extends ForestState {
  const ForestInProgress({required super.data});
}

final class ForestSuccess extends ForestState {
  const ForestSuccess({required super.data});
}

final class ForestFailure extends ForestState {
  final CustomException exception;

  const ForestFailure({required super.data, required this.exception});
}
