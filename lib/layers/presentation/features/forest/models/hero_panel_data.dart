import 'package:collection/collection.dart';

import 'gear_row_data.dart';
import 'skill_item_data.dart';

class HeroPanelData {
  final int power;
  final String attack;
  final int defense;
  final int health;
  final List<GearRowData> rows;
  final List<SkillItemData> skills;
  final bool isChampion;

  const HeroPanelData({
    required this.power,
    required this.attack,
    required this.defense,
    required this.health,
    required this.rows,
    this.skills = const [],
    this.isChampion = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeroPanelData &&
          other.power == power &&
          other.attack == attack &&
          other.defense == defense &&
          other.health == health &&
          const ListEquality<GearRowData>().equals(other.rows, rows) &&
          const ListEquality<SkillItemData>().equals(other.skills, skills) &&
          other.isChampion == isChampion;

  @override
  int get hashCode =>
      Object.hash(power, attack, defense, health, Object.hashAll(rows), Object.hashAll(skills), isChampion);

  @override
  String toString() =>
      'HeroPanelData(power: $power, $attack/$defense/$health, rows: $rows, skills: $skills, isChampion: $isChampion)';
}
