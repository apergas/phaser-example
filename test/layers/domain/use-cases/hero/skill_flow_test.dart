import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/learn_skill_result.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_skill_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/learn_skill_use_case.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';
import '../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  test('testWhenTheMageTowerIsBuiltAndArenaGoldIsEarnedThenTheDoubleStrikeRaisesPowerByTenPercent', () {
    // given
    final sessionRepository = MockGameSessionRepository();
    final world = SkillScenarioMock.withoutTower()..earn(Blueprints.mageTower.cost);
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    final construct = ConstructBuildingUseCase(sessionRepository: sessionRepository);
    final advance = AdvanceGameUseCase(sessionRepository: sessionRepository);
    final options = GetSkillOptionsUseCase(sessionRepository: sessionRepository);
    final learn = LearnSkillUseCase(sessionRepository: sessionRepository);
    final heroStatus = GetHeroStatusUseCase(sessionRepository: sessionRepository);
    final before = heroStatus();
    final beforeTheTower = learn(id: SkillId.doubleStrike);
    construct(blueprint: BlueprintId.mageTower, x: SkillScenarioMock.towerSite.x, y: SkillScenarioMock.towerSite.y);
    for (var elapsed = 0.0; elapsed < SkillScenarioMock.buildMs; elapsed += 16) {
      advance(deltaMs: 16);
    }
    world.earn(FundsMock.doubleStrikePrice);

    // when
    final result = learn(id: SkillId.doubleStrike);

    // then
    final after = heroStatus();
    expect(beforeTheTower, LearnSkillResult.missingBuilding);
    expect(result, LearnSkillResult.ok);
    expect((before.power, after.power), (31, 34));
    expect(after.stats, before.stats);
    expect(options(), SkillOptionEntityMock.afterLearningDoubleStrike);
  });
}
