import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/quest_line.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../../mocks/domain/world/funds_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';
import '../../../../../mocks/presentation/features/forest/gear_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenTheGameStartsThenTheHeroPanelShowsBaseStatsAndWhatEachWorkshopNeeds',
    build: () {
      // given
      return ForestBlocMock.make(GearScenarioMock.withoutWorkshops(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.hero, HeroPanelDataMock.newHero);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheForgeIsBuiltAndTheSwordIsPaidForThenItCanBeBought',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
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
      expect(bloc.state.data.hud!.hero, HeroPanelDataMock.readyToBuySword);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenFundsAreShortThenTheSwordSaysWhatIsMissing',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword),
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
      expect(bloc.state.data.hud!.hero.rows.first.next, GearItemDataMock.shortSwordFiveGoldShort);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenBuyingTheShortSwordThenEquipsItSparklesAndAnnouncesIt',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.shortSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hero = bloc.state.data.hud!.hero;
      expect(effects, contains(ForestEffectMock.shortSwordPurchased));
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageGearPurchased(name: Internationalize.forestGear(id: GearId.shortSword))),
      );
      expect((hero.attack, hero.power), (Internationalize.forestHeroAttackRange(min: 6, max: 8), 40));
      expect(hero.rows.first.equipped, GearItemDataMock.shortSwordEquipped);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenBuyingArmorWithoutTheArmoryThenExplainsWhichBuildingIsMissing',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.leatherArmor));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<GearPurchasedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(
          Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.armory)),
        ),
      );
      expect(bloc.state.data.hud!.hero.attack, Internationalize.forestHeroAttackRange(min: 3, max: 5));
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenSkippingATierThenSaysThePreviousPieceComesFirst',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.ironSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<GearPurchasedEffect>(), isEmpty);
      expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageGearNotNextTier));
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenBuyingTheSwordWithShortFundsThenSaysThereAreNotEnoughResources',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.shortSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<GearPurchasedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageNotEnoughResources),
      );
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheHeroHasBeatenTheChiefThenTheHeroPanelShowsTheChampionBadge',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withoutWorkshops(hero: HeroEntityMock.champion),
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
      expect(bloc.state.data.hud!.hero.isChampion, isTrue);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheLastHeroQuestIsCompletedThenShowsTheHeroLineFinalMessage',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withAllWorkshops(hero: HeroEntityMock.championWithEveryQuestDone),
        navigationService: navigationService,
      );
    },
    act: (bloc) async {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
      await ForestBlocMock.processEvents();
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(
        ForestBlocMock.shownMessages(navigationService).last,
        Internationalize.forestMessageQuestLineCompleted(line: QuestLine.hero),
      );
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenAHeroQuestIsCompletedWhileOthersAreStillPendingThenShowsTheQuestMessage',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForgeAndArmory(hero: HeroEntityMock.champion),
        navigationService: navigationService,
      );
    },
    act: (bloc) async {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
      await ForestBlocMock.processEvents();
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(
        ForestBlocMock.shownMessages(navigationService).last,
        Internationalize.forestMessageQuestCompleted(
          title: Internationalize.forestQuestTitle(id: QuestId.becomeChampion),
        ),
      );
    },
  );
}
