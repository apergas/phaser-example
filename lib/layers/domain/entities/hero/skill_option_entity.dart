import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_option_state.dart';
import 'skill_entity.dart';

class SkillOptionEntity {
  final SkillEntity skill;
  final SkillOptionState state;
  final Map<Resource, int> missing;

  const SkillOptionEntity({required this.skill, required this.state, this.missing = const {}});

  bool get canLearn => state == SkillOptionState.available;

  SkillOptionEntity copyWith({SkillEntity? skill, SkillOptionState? state, Map<Resource, int>? missing}) {
    return SkillOptionEntity(
      skill: skill ?? this.skill,
      state: state ?? this.state,
      missing: missing ?? this.missing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SkillOptionEntity &&
      other.skill == skill &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(skill, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'SkillOptionEntity(skill: ${skill.id}, state: $state, missing: $missing)';
}
