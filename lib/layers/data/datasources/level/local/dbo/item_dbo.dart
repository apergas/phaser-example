class ItemDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const ItemDBO({this.id, this.kind, this.x, this.y});

  @override
  bool operator ==(Object other) =>
      other is ItemDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'ItemDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
