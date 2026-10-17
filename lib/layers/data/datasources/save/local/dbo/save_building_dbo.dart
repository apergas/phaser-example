import 'save_json.dart';

class SaveBuildingDBO {
  final String? id;
  final String? blueprint;
  final double? x;
  final double? y;
  final int? hitsDone;

  const SaveBuildingDBO({this.id, this.blueprint, this.x, this.y, this.hitsDone});

  factory SaveBuildingDBO.fromJson(Map<String, dynamic> json) => SaveBuildingDBO(
    id: json['id'] as String?,
    blueprint: json['blueprint'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    hitsDone: json['hitsDone'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'blueprint': blueprint, 'x': x, 'y': y, 'hitsDone': hitsDone};

  @override
  bool operator ==(Object other) =>
      other is SaveBuildingDBO &&
      other.id == id &&
      other.blueprint == blueprint &&
      other.x == x &&
      other.y == y &&
      other.hitsDone == hitsDone;

  @override
  int get hashCode => Object.hash(id, blueprint, x, y, hitsDone);

  @override
  String toString() => 'SaveBuildingDBO(id: $id, blueprint: $blueprint, x: $x, y: $y, hitsDone: $hitsDone)';
}
