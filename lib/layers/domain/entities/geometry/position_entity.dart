class PositionEntity {
  final double x;
  final double y;

  const PositionEntity({required this.x, required this.y});

  PositionEntity copyWith({double? x, double? y}) {
    return PositionEntity(x: x ?? this.x, y: y ?? this.y);
  }

  @override
  bool operator ==(Object other) => other is PositionEntity && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PositionEntity(x: $x, y: $y)';
}
