class PointDBO {
  final double? x;
  final double? y;

  const PointDBO({this.x, this.y});

  @override
  bool operator ==(Object other) => other is PointDBO && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PointDBO(x: $x, y: $y)';
}
