import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveInventoryDBO {
  final Map<String, int>? resources;
  final List<String>? tools;
  final Map<String, int>? toolLevels;

  const SaveInventoryDBO({this.resources, this.tools, this.toolLevels});

  factory SaveInventoryDBO.fromJson(Map<String, dynamic> json) => SaveInventoryDBO(
    resources: readIntMap(json['resources']),
    tools: readStringList(json['tools']),
    toolLevels: readIntMap(json['toolLevels']),
  );

  Map<String, dynamic> toJson() => {
    if (resources != null) 'resources': resources,
    'tools': tools,
    'toolLevels': toolLevels,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveInventoryDBO &&
      const MapEquality<String, int>().equals(other.resources, resources) &&
      const ListEquality<String>().equals(other.tools, tools) &&
      const MapEquality<String, int>().equals(other.toolLevels, toolLevels);

  @override
  int get hashCode => Object.hash(
    const MapEquality<String, int>().hash(resources),
    const ListEquality<String>().hash(tools),
    const MapEquality<String, int>().hash(toolLevels),
  );

  @override
  String toString() => 'SaveInventoryDBO(resources: $resources, tools: $tools, toolLevels: $toolLevels)';
}
