part of 'forest_bloc.dart';

sealed class ForestEvent {
  const ForestEvent();
}

final class ForestStarted extends ForestEvent {
  const ForestStarted();
}

final class ForestTicked extends ForestEvent {
  final double deltaMs;

  const ForestTicked({required this.deltaMs});
}

final class ForestMapClicked extends ForestEvent {
  final PositionEntity position;
  final String? treeId;
  final bool isSecondary;

  const ForestMapClicked({required this.position, this.treeId, this.isSecondary = false});
}

final class ForestPointerMoved extends ForestEvent {
  final PositionEntity position;

  const ForestPointerMoved({required this.position});
}

final class ForestBuildRequested extends ForestEvent {
  final BlueprintId blueprint;

  const ForestBuildRequested({required this.blueprint});
}

final class ForestPlacementCancelled extends ForestEvent {
  const ForestPlacementCancelled();
}
