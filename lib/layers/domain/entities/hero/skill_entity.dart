import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class SkillEntity {
  final SkillId id;
  final Map<Resource, int> cost;

  const SkillEntity({required this.id, required this.cost});

  SkillEntity copyWith({SkillId? id, Map<Resource, int>? cost}) {
    return SkillEntity(id: id ?? this.id, cost: cost ?? this.cost);
  }

  @override
  bool operator ==(Object other) =>
      other is SkillEntity && other.id == id && const MapEquality<Resource, int>().equals(other.cost, cost);

  @override
  int get hashCode => Object.hash(id, const MapEquality<Resource, int>().hash(cost));

  @override
  String toString() => 'SkillEntity(id: $id, cost: $cost)';
}
