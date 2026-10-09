class CombatStatsEntity {
  final int attackMin;
  final int attackMax;
  final int defense;
  final int health;

  const CombatStatsEntity({
    required this.attackMin,
    required this.attackMax,
    required this.defense,
    required this.health,
  }) : assert(attackMin >= 0),
       assert(attackMax >= attackMin),
       assert(defense >= 0),
       assert(health > 0);

  int get power => (attackMin + attackMax) * 3 ~/ 2 + defense * 4 + health ~/ 2;

  CombatStatsEntity copyWith({int? attackMin, int? attackMax, int? defense, int? health}) {
    return CombatStatsEntity(
      attackMin: attackMin ?? this.attackMin,
      attackMax: attackMax ?? this.attackMax,
      defense: defense ?? this.defense,
      health: health ?? this.health,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CombatStatsEntity &&
      other.attackMin == attackMin &&
      other.attackMax == attackMax &&
      other.defense == defense &&
      other.health == health;

  @override
  int get hashCode => Object.hash(attackMin, attackMax, defense, health);

  @override
  String toString() =>
      'CombatStatsEntity(attackMin: $attackMin, attackMax: $attackMax, defense: $defense, health: $health)';
}
