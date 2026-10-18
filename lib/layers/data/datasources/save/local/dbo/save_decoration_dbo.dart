import 'save_json.dart';

class SaveDecorationDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const SaveDecorationDBO({this.id, this.kind, this.x, this.y});

  factory SaveDecorationDBO.fromJson(Map<String, dynamic> json) => SaveDecorationDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      other is SaveDecorationDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'SaveDecorationDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
