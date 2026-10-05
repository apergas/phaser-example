class DecorationDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const DecorationDBO({this.id, this.kind, this.x, this.y});

  @override
  bool operator ==(Object other) =>
      other is DecorationDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'DecorationDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
