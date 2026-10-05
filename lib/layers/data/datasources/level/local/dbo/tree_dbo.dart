class TreeDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;
  final int? wood;

  const TreeDBO({this.id, this.kind, this.x, this.y, this.wood});

  @override
  bool operator ==(Object other) =>
      other is TreeDBO && other.id == id && other.kind == kind && other.x == x && other.y == y && other.wood == wood;

  @override
  int get hashCode => Object.hash(id, kind, x, y, wood);

  @override
  String toString() => 'TreeDBO(id: $id, kind: $kind, x: $x, y: $y, wood: $wood)';
}
