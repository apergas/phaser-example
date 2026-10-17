import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveHeroDBO {
  final int? weaponTier;
  final int? armorTier;
  final Map<String, int>? skillLevels;
  final List<String>? clearedLevels;
  final int? fightsFought;

  const SaveHeroDBO({this.weaponTier, this.armorTier, this.skillLevels, this.clearedLevels, this.fightsFought});

  factory SaveHeroDBO.fromJson(Map<String, dynamic> json) => SaveHeroDBO(
    weaponTier: json['weaponTier'] as int?,
    armorTier: json['armorTier'] as int?,
    skillLevels: readIntMap(json['skillLevels']),
    clearedLevels: readStringList(json['clearedLevels']),
    fightsFought: json['fightsFought'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'weaponTier': weaponTier,
    'armorTier': armorTier,
    'skillLevels': skillLevels,
    'clearedLevels': clearedLevels,
    'fightsFought': fightsFought,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveHeroDBO &&
      other.weaponTier == weaponTier &&
      other.armorTier == armorTier &&
      const MapEquality<String, int>().equals(other.skillLevels, skillLevels) &&
      const ListEquality<String>().equals(other.clearedLevels, clearedLevels) &&
      other.fightsFought == fightsFought;

  @override
  int get hashCode => Object.hash(
    weaponTier,
    armorTier,
    const MapEquality<String, int>().hash(skillLevels),
    const ListEquality<String>().hash(clearedLevels),
    fightsFought,
  );

  @override
  String toString() =>
      'SaveHeroDBO(weaponTier: $weaponTier, armorTier: $armorTier, skillLevels: $skillLevels, '
      'clearedLevels: $clearedLevels, fightsFought: $fightsFought)';
}
