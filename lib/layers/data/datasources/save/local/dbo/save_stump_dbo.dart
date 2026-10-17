import 'save_json.dart';

class SaveStumpDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;
  final double? elapsedMs;

  const SaveStumpDBO({this.id, this.kind, this.x, this.y, this.elapsedMs});

  factory SaveStumpDBO.fromJson(Map<String, dynamic> json) => SaveStumpDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    elapsedMs: readDouble(json['elapsedMs']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y, 'elapsedMs': elapsedMs};

  @override
  bool operator ==(Object other) =>
      other is SaveStumpDBO &&
      other.id == id &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(id, kind, x, y, elapsedMs);

  @override
  String toString() => 'SaveStumpDBO(id: $id, kind: $kind, x: $x, y: $y, elapsedMs: $elapsedMs)';
}
