import 'package:farming/layers/domain/entities/building/placement_rule_entity.dart';

abstract final class PlacementRuleEntityMock {
  static const AnywherePlacementRuleEntity anywhere = AnywherePlacementRuleEntity();

  static const NearRockPlacementRuleEntity nearRock = NearRockPlacementRuleEntity(range: 120);

  static const NearRockPlacementRuleEntity nearRockCopy = NearRockPlacementRuleEntity(range: 120);

  static const NearRockPlacementRuleEntity veryNearRock = NearRockPlacementRuleEntity(range: 60);
}
