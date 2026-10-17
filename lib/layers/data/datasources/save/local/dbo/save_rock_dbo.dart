import 'save_json.dart';

class SaveRockDBO {
  final String? id;
  final double? x;
  final double? y;
  final int? hitsTaken;

  const SaveRockDBO({this.id, this.x, this.y, this.hitsTaken});

  factory SaveRockDBO.fromJson(Map<String, dynamic> json) => SaveRockDBO(
    id: json['id'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    hitsTaken: json['hitsTaken'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y, 'hitsTaken': hitsTaken};

  @override
  bool operator ==(Object other) =>
      other is SaveRockDBO && other.id == id && other.x == x && other.y == y && other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, x, y, hitsTaken);

  @override
  String toString() => 'SaveRockDBO(id: $id, x: $x, y: $y, hitsTaken: $hitsTaken)';
}
