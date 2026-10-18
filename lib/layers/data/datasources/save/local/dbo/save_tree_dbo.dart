import 'save_json.dart';

class SaveTreeDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;
  final int? hitsTaken;

  const SaveTreeDBO({this.id, this.kind, this.x, this.y, this.hitsTaken});

  factory SaveTreeDBO.fromJson(Map<String, dynamic> json) => SaveTreeDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    hitsTaken: json['hitsTaken'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y, 'hitsTaken': hitsTaken};

  @override
  bool operator ==(Object other) =>
      other is SaveTreeDBO &&
      other.id == id &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, kind, x, y, hitsTaken);

  @override
  String toString() => 'SaveTreeDBO(id: $id, kind: $kind, x: $x, y: $y, hitsTaken: $hitsTaken)';
}
