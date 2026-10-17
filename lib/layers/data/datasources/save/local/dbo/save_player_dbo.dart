import 'save_inventory_dbo.dart';
import 'save_json.dart';

class SavePlayerDBO {
  final double? x;
  final double? y;
  final SaveInventoryDBO? inventory;

  const SavePlayerDBO({this.x, this.y, this.inventory});

  factory SavePlayerDBO.fromJson(Map<String, dynamic> json) {
    final inventory = json['inventory'] as Map<String, dynamic>?;
    return SavePlayerDBO(
      x: readDouble(json['x']),
      y: readDouble(json['y']),
      inventory: inventory == null ? null : SaveInventoryDBO.fromJson(inventory),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'inventory': inventory?.toJson()};

  @override
  bool operator ==(Object other) =>
      other is SavePlayerDBO && other.x == x && other.y == y && other.inventory == inventory;

  @override
  int get hashCode => Object.hash(x, y, inventory);

  @override
  String toString() => 'SavePlayerDBO(x: $x, y: $y, inventory: $inventory)';
}
