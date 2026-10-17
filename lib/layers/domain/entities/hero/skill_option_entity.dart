import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_option_state.dart';
import 'skill_entity.dart';

class SkillOptionEntity {
  final SkillEntity skill;
  final int level;
  final SkillOptionState state;
  final Map<Resource, int> missing;

  const SkillOptionEntity({required this.skill, required this.level, required this.state, this.missing = const {}})
    : assert(level >= 0);

  int? get nextLevel => level < skill.maxLevel ? level + 1 : null;

  Map<Resource, int>? get nextCost {
    final next = nextLevel;
    return next == null ? null : skill.costOf(next);
  }

  bool get canLearn => state == SkillOptionState.available;

  SkillOptionEntity copyWith({SkillEntity? skill, int? level, SkillOptionState? state, Map<Resource, int>? missing}) {
    return SkillOptionEntity(
      skill: skill ?? this.skill,
      level: level ?? this.level,
      state: state ?? this.state,
      missing: missing ?? this.missing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SkillOptionEntity &&
      other.skill == skill &&
      other.level == level &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(skill, level, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'SkillOptionEntity(skill: ${skill.id}, level: $level, state: $state, missing: $missing)';
}
