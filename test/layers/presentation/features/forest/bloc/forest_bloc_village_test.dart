import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/core/config/constants/enum/forest/work_tool.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/world/world.dart';
import 'package:farming/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:farming/layers/presentation/features/forest/models/forest_effect.dart';
import 'package:farming/layers/presentation/features/forest/models/placement_data.dart';
import 'package:farming/layers/presentation/features/forest/models/player_pose.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/game/upgrade_scenario_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
import '../../../../../mocks/presentation/features/forest/hud_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/quest_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/tool_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/upgrade_item_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;
  late World world;
  late List<String> shown;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
    shown = [];
    when(navigationService.showSnackbar(message: anyNamed('message'))).thenAnswer((invocation) {
      shown.add(invocation.namedArguments[#message] as String);
    });
  });

  ForestBloc make(World scenario, {bool isTouchInput = false}) {
    world = scenario;
    return ForestBlocMock.make(world, navigationService: navigationService, isTouchInput: isTouchInput);
  }

  List<String> messages() => shown;

  group('regrowth', () {
    blocTest<ForestBloc, ForestState>(
      'testWhenAStumpSproutsThenItsEffectIsPlayedWithoutAMessage',
      build: () => make(ForestScenarioMock.stumpAboutToSprout()),
      act: (bloc) {
        // given
        effects = ForestBlocMock.collectEffects(bloc);
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(effects, [ForestEffectMock.stumpSprouted]);
        expect(messages(), [Internationalize.forestMessageWelcome]);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenATreeRegrowsThenItsEffectIsPlayedWithoutAMessage',
      build: () => make(ForestScenarioMock.stumpAboutToRegrow()),
      act: (bloc) {
        // given
        effects = ForestBlocMock.collectEffects(bloc);
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: 100));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(effects, [ForestEffectMock.treeRegrown]);
        expect(messages(), contains(Internationalize.forestMessageWelcome));
        expect(messages().where((message) => message != Internationalize.forestMessageWelcome), [
          Internationalize.forestMessageQuestCompleted(
            title: Internationalize.forestQuestTitle(id: QuestItemDataMock.seeATreeRegrowId),
          ),
        ]);
        expect(bloc.state.data.world!.trees.last.id, 'tree-1');
      },
    );
  });

  group('quests', () {
    blocTest<ForestBloc, ForestState>(
      'testWhenTheFirstTwoVillageQuestsAreDoneThenTheyFoldAndTheNextOnesShow',
      build: () => make(ForestScenarioMock.fifteenWoodAndAHouse()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        final hud = bloc.state.data.hud!;
        expect(hud.questBadge, '2/19');
        expect(hud.quests, QuestItemDataMock.afterTheFirstTwoVillageQuests);
      },
    );
  });

  group('stone', () {
    blocTest<ForestBloc, ForestState>(
      'testWhenClickingARockWithoutAPickaxeThenExplainsWhy',
      build: () => make(ForestScenarioMock.rockWithoutPickaxe()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.rockSpot, rockId: 'rock-1'));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(messages(), contains(Internationalize.forestMessageNeedPickaxe));
        expect(world.player.activity, isA<IdleActivityEntity>());
      },
    );

    late PlayerPose pose;

    blocTest<ForestBloc, ForestState>(
      'testWhenMiningARockThenSwingsThePickaxeHitsAndBreaksItForEightStone',
      build: () => make(ForestScenarioMock.pickaxeAndRock()),
      act: (bloc) async {
        // given
        effects = ForestBlocMock.collectEffects(bloc);
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.rockSpot, rockId: 'rock-1'));
        ForestBlocMock.tickFor(bloc, 2500);
        await ForestBlocMock.processEvents();
        pose = bloc.state.data.player!.pose;
        ForestBlocMock.tickFor(bloc, 6500);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect((pose as WorkPose).tool, WorkTool.pickaxe);
        expect(effects.whereType<RockHitEffect>(), hasLength(8));
        expect(effects.whereType<RockHitEffect>().first, ForestEffectMock.rockHitFromTheStart);
        expect(effects, contains(ForestEffectMock.rockBroken));
        expect(messages(), contains(Internationalize.forestMessageStoneGained(amount: 8)));
        expect(bloc.state.data.world!.rocks, isEmpty);
        expect(bloc.state.data.hud!.stock, HudDataMock.stockWith(stone: 8));
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenARockAndATreeAreBothTappedThenTheRockWins',
      build: () => make(ForestScenarioMock.rockInFrontOfATree()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.rockSpot, rockId: 'rock-1', treeId: 'tree-1'));
        ForestBlocMock.tickFor(bloc, 2500);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect((bloc.state.data.player!.pose as WorkPose).tool, WorkTool.pickaxe);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTheHudIsBuiltThenItListsTheFourResourcesAndBothTools',
      build: () => make(ForestScenarioMock.pickaxeAndRock()),
      act: (bloc) {
        // when
        bloc.add(const ForestStarted());
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        final hud = bloc.state.data.hud!;
        expect(hud.stock.map((item) => item.resource), Resource.values);
        expect(hud.stock, hasLength(4));
        expect(hud.tools, HudDataMock.tools(isPickaxeOwned: true));
      },
    );
  });

  group('buildings', () {
    blocTest<ForestBloc, ForestState>(
      'testWhenAFinishedBuildingAndARockAreBothTappedThenTheRockIsMined',
      build: () => make(ForestScenarioMock.campAndARock()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(
            const ForestMapClicked(
              position: ForestScenarioMock.rockSpot,
              rockId: 'rock-1',
              buildingId: ForestScenarioMock.campId,
            ),
          );
        ForestBlocMock.tickFor(bloc, 2500);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect((bloc.state.data.player!.pose as WorkPose).tool, WorkTool.pickaxe);
        expect(messages(), [Internationalize.forestMessageWelcome]);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenAnUnfinishedBuildingAndARockAreBothTappedThenTheBuildingWins',
      build: () => make(ForestScenarioMock.houseSiteAndARock()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.rockSpot, rockId: 'rock-1', buildingId: 'house'));
        ForestBlocMock.tickFor(bloc, 4000);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(world.rocks.single.hitsTaken, 0);
        expect(world.buildings.single.hitsDone, greaterThan(0));
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTappingTheCampThenThePlayerJustWalksThereSilently',
      build: () => make(ForestScenarioMock.atTheCamp()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast, buildingId: ForestScenarioMock.campId));
        ForestBlocMock.tickFor(bloc, 1000);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.player!.position, ForestScenarioMock.groundEast);
        expect(messages(), [Internationalize.forestMessageWelcome]);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTappingAHouseSiteThenTheWorkIsResumed',
      build: () => make(ForestScenarioMock.nextToAHouseSite()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.rockSpot, buildingId: 'house'));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        final activity = world.player.activity;
        expect(activity, isA<WalkingActivityEntity>());
        expect((activity as WalkingActivityEntity).intent, isNotNull);
        expect(messages(), isEmpty);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTappingAFinishedHouseThenThePlayerJustWalksThere',
      build: () => make(ForestScenarioMock.nextToAFinishedHouse()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast, buildingId: 'house'));
        ForestBlocMock.tickFor(bloc, 1000);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.player!.position, ForestScenarioMock.groundEast);
        expect(world.player.activity, isA<IdleActivityEntity>());
      },
    );
  });

  group('quarry placement', () {
    late PlacementData? opened;
    late PlacementData? far;
    late PlacementData? near;

    blocTest<ForestBloc, ForestState>(
      'testWhenPlacingTheQuarryThenTheReasonFollowsTheRockAndATapFarAwayWarnsAndKeepsPlacing',
      build: () => make(ForestScenarioMock.quarryPriceAndARock()),
      act: (bloc) async {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.quarry));
        await ForestBlocMock.processEvents();
        opened = bloc.state.data.placement;
        bloc.add(const ForestPointerMoved(position: ForestScenarioMock.farFromTheRock));
        await ForestBlocMock.processEvents();
        far = bloc.state.data.placement;
        bloc.add(const ForestPointerMoved(position: ForestScenarioMock.nearTheRock));
        await ForestBlocMock.processEvents();
        near = bloc.state.data.placement;
        bloc.add(const ForestMapClicked(position: ForestScenarioMock.farFromTheRock));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(opened!.invalidReason, ConstructionRejection.needsNearbyRock);
        expect(far!.invalidReason, ConstructionRejection.needsNearbyRock);
        expect(near!.invalidReason, isNull);
        expect(
          messages(),
          contains(Internationalize.forestPlacementRejection(rejection: ConstructionRejection.needsNearbyRock)),
        );
        expect(bloc.state.data.placement, isNotNull);
        expect(world.buildings, isEmpty);
      },
    );
  });

  group('workshop', () {
    blocTest<ForestBloc, ForestState>(
      'testWhenBuyingTheIronAxeThenItIsAnnouncedPlayedAndShownInTheBar',
      build: () => make(ForestScenarioMock.workshopWith(UpgradeScenarioMock.ironAxePrice)),
      act: (bloc) {
        // given
        effects = ForestBlocMock.collectEffects(bloc);
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestUpgradeRequested(upgrade: UpgradeId.ironAxe));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        final hud = bloc.state.data.hud!;
        expect(effects, [ForestEffectMock.ironAxePurchased]);
        expect(
          messages(),
          contains(
            Internationalize.forestMessageUpgradePurchased(
              name: Internationalize.forestUpgradeName(id: UpgradeId.ironAxe),
            ),
          ),
        );
        expect(hud.tools.first, ToolItemDataMock.ironAxe);
        expect(hud.upgradeItems, UpgradeItemDataMock.axeOwnedAndPickaxeShort);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTheUpgradeFailsThenEachReasonIsAnnouncedAndNothingIsPlayed',
      build: () => make(ForestScenarioMock.workshopWith(UpgradeScenarioMock.fiveStoneShortOfTheIronAxe)),
      act: (bloc) {
        // given
        effects = ForestBlocMock.collectEffects(bloc);
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestUpgradeRequested(upgrade: UpgradeId.ironAxe));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(effects, isEmpty);
        expect(messages(), [Internationalize.forestMessageNotEnoughResources]);
        expect(bloc.state.data.hud!.upgradeItems, UpgradeItemDataMock.fiveStoneShortOfTheAxe);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenThereIsNoWorkshopOrTheUpgradeIsOwnedThenSaysSo',
      build: () => make(ForestScenarioMock.ironAxeWithoutWorkshop()),
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestUpgradeRequested(upgrade: UpgradeId.ironPickaxe))
          ..add(const ForestUpgradeRequested(upgrade: UpgradeId.ironAxe));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(messages(), [Internationalize.forestUpgradeNeedsWorkshop, Internationalize.forestMessageUpgradeOwned]);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTheWorkshopIsMissingThenTheUpgradeItemsSayWhy',
      build: () => make(ForestScenarioMock.empty()),
      act: (bloc) {
        // when
        bloc.add(const ForestStarted());
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.hud!.upgradeItems, UpgradeItemDataMock.withoutWorkshop);
      },
    );

    blocTest<ForestBloc, ForestState>(
      'testWhenTheStockPaysForTheAxeThenItsItemCanBeBought',
      build: () => make(ForestScenarioMock.workshopWith(UpgradeScenarioMock.axeAndAlmostThePickaxe)),
      act: (bloc) {
        // when
        bloc.add(const ForestStarted());
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.hud!.upgradeItems, UpgradeItemDataMock.axeAffordable);
        expect(world.player.inventory.toolLevels[ToolKind.axe], isNull);
      },
    );
  });
}
