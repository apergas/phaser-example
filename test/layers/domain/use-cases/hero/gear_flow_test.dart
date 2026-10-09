import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/buy_gear_result.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/buy_gear_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_gear_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/gear/gear_option_entity_mock.dart';
import '../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  test('testWhenTheForgeIsBuiltAndArenaGoldIsEarnedThenTheShortSwordRaisesAttackAndPower', () {
    // given
    final sessionRepository = MockGameSessionRepository();
    final world = GearScenarioMock.withoutWorkshops()..earn(Blueprints.forge.cost);
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    final construct = ConstructBuildingUseCase(sessionRepository: sessionRepository);
    final advance = AdvanceGameUseCase(sessionRepository: sessionRepository);
    final options = GetGearOptionsUseCase(sessionRepository: sessionRepository);
    final buy = BuyGearUseCase(sessionRepository: sessionRepository);
    final heroStatus = GetHeroStatusUseCase(sessionRepository: sessionRepository);
    final before = heroStatus();
    construct(blueprint: BlueprintId.forge, x: GearScenarioMock.forgeSite.x, y: GearScenarioMock.forgeSite.y);
    for (var elapsed = 0.0; elapsed < GearScenarioMock.buildMs; elapsed += 16) {
      advance(deltaMs: 16);
    }
    final ironSwordBefore = buy(id: GearId.ironSword);
    world.earn(FundsMock.shortSwordPrice);

    // when
    final result = buy(id: GearId.shortSword);

    // then
    final after = heroStatus();
    expect(ironSwordBefore, BuyGearResult.notNextTier);
    expect(result, BuyGearResult.ok);
    expect((before.stats.attackMin, after.stats.attackMax), (3, 8));
    expect((before.power, after.power), (31, 40));
    expect(options().first, GearOptionEntityMock.equipped(GearId.shortSword));
    expect(options()[1].state, GearOptionState.unaffordable);
  });
}
