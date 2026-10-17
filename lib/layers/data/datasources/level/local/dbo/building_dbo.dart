class BuildingDBO {
  final String? id;
  final String? blueprint;
  final double? x;
  final double? y;

  const BuildingDBO({this.id, this.blueprint, this.x, this.y});

  @override
  bool operator ==(Object other) =>
      other is BuildingDBO && other.id == id && other.blueprint == blueprint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, blueprint, x, y);

  @override
  String toString() => 'BuildingDBO(id: $id, blueprint: $blueprint, x: $x, y: $y)';
}
