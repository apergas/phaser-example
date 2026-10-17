sealed class PlacementRuleEntity {
  const PlacementRuleEntity();
}

final class AnywherePlacementRuleEntity extends PlacementRuleEntity {
  const AnywherePlacementRuleEntity();

  @override
  bool operator ==(Object other) => other is AnywherePlacementRuleEntity;

  @override
  int get hashCode => (AnywherePlacementRuleEntity).hashCode;
}

final class NearRockPlacementRuleEntity extends PlacementRuleEntity {
  final double range;

  const NearRockPlacementRuleEntity({required this.range});

  @override
  bool operator ==(Object other) => other is NearRockPlacementRuleEntity && other.range == range;

  @override
  int get hashCode => Object.hash(NearRockPlacementRuleEntity, range);
}
