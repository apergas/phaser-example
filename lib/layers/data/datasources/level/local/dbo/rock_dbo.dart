class RockDBO {
  final String? id;
  final double? x;
  final double? y;

  const RockDBO({this.id, this.x, this.y});

  @override
  bool operator ==(Object other) => other is RockDBO && other.id == id && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, x, y);

  @override
  String toString() => 'RockDBO(id: $id, x: $x, y: $y)';
}
