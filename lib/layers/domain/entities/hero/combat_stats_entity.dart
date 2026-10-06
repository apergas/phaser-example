class CombatStatsEntity {
  final int attack;
  final int defense;
  final int health;

  const CombatStatsEntity({required this.attack, required this.defense, required this.health})
    : assert(attack >= 0),
      assert(defense >= 0),
      assert(health > 0);

  int get power => attack * 3 + defense * 4 + health ~/ 2;

  CombatStatsEntity copyWith({int? attack, int? defense, int? health}) {
    return CombatStatsEntity(
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      health: health ?? this.health,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CombatStatsEntity && other.attack == attack && other.defense == defense && other.health == health;

  @override
  int get hashCode => Object.hash(attack, defense, health);

  @override
  String toString() => 'CombatStatsEntity(attack: $attack, defense: $defense, health: $health)';
}
