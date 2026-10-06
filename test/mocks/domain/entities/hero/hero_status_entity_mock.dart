import 'package:rpg/layers/domain/entities/hero/hero_status_entity.dart';

import 'combat_stats_entity_mock.dart';
import 'hero_entity_mock.dart';

abstract final class HeroStatusEntityMock {
  static const HeroStatusEntity base = HeroStatusEntity(
    hero: HeroEntityMock.mock,
    stats: CombatStatsEntityMock.heroBase,
    power: 31,
  );

  static const HeroStatusEntity withTwoSkills = HeroStatusEntity(
    hero: HeroEntityMock.withTwoSkills,
    stats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
    power: 64,
  );
}
