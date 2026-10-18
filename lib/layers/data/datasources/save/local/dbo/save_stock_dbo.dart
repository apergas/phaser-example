import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveStockDBO {
  final Map<String, int>? resources;

  const SaveStockDBO({this.resources});

  factory SaveStockDBO.fromJson(Map<String, dynamic> json) => SaveStockDBO(resources: readIntMap(json['resources']));

  Map<String, dynamic> toJson() => {'resources': resources};

  @override
  bool operator ==(Object other) =>
      other is SaveStockDBO && const MapEquality<String, int>().equals(other.resources, resources);

  @override
  int get hashCode => const MapEquality<String, int>().hash(resources);

  @override
  String toString() => 'SaveStockDBO(resources: $resources)';
}
