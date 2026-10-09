import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../../mocks/domain/world/funds_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/skill_item_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenTheGameStartsWithoutTheMageTowerThenEverySkillAsksForIt',
    build: () {
      // given
      return ForestBlocMock.make(SkillScenarioMock.withoutTower(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.hero.skills, SkillItemDataMock.withoutTower);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheTowerIsBuiltAndTheDoubleStrikeIsPaidForThenItCanBeLearned',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.hero, HeroPanelDataMock.readyToLearnDoubleStrike);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenLearningTheDoubleStrikeThenItIsKnownSparklesInBlueAndRaisesPower',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hero = bloc.state.data.hud!.hero;
      expect(effects, contains(ForestEffectMock.doubleStrikeLearned));
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(
          Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: SkillId.doubleStrike)),
        ),
      );
      expect((hero.attack, hero.power), (4, 34));
      expect(hero.skills, SkillItemDataMock.afterLearningDoubleStrike);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenLearningWithoutTheMageTowerThenSaysWhichBuildingIsMissing',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withoutTower(funds: FundsMock.doubleStrikePrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<SkillLearnedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(
          Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.mageTower)),
        ),
      );
      expect(bloc.state.data.hud!.hero.power, 31);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenLearningAKnownSkillThenSaysItIsAlreadyKnown',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice, hero: HeroEntityMock.withDoubleStrike),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageSkillAlreadyKnown),
      );
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenGoldIsShortThenSaysThereAreNotEnoughResources',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.tenGoldShortOfDoubleStrike),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<SkillLearnedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageNotEnoughResources),
      );
    },
  );
}
