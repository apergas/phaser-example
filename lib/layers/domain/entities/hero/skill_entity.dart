import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class SkillEntity {
  final SkillId id;
  final List<Map<Resource, int>> costs;

  const SkillEntity({required this.id, required this.costs});

  int get maxLevel => costs.length;

  Map<Resource, int> costOf(int level) => costs[level - 1];

  SkillEntity copyWith({SkillId? id, List<Map<Resource, int>>? costs}) {
    return SkillEntity(id: id ?? this.id, costs: costs ?? this.costs);
  }

  static const ListEquality<Map<Resource, int>> _costsEquality = ListEquality(MapEquality<Resource, int>());

  @override
  bool operator ==(Object other) => other is SkillEntity && other.id == id && _costsEquality.equals(other.costs, costs);

  @override
  int get hashCode => Object.hash(id, _costsEquality.hash(costs));

  @override
  String toString() => 'SkillEntity(id: $id, costs: $costs)';
}
