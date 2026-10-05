import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
import '../../../../../mocks/presentation/features/forest/build_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';
import '../../../../../mocks/presentation/features/forest/placement_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/player_pose_mock.dart';
import '../../../../../mocks/presentation/features/forest/quest_item_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenFirstTickThenGreetsAndShowsTheQuestList',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
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
      expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageWelcome));
      expect(hud.questBadge, '0/3');
      expect(hud.quests[0], QuestItemDataMock.pickUpAxeCurrent);
      expect(hud.quests[1], QuestItemDataMock.gatherWoodPending);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenClickingEmptyGroundThenWalksThereFacingIt',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast));
      ForestBlocMock.tickFor(bloc, 1000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.player!.position, ForestScenarioMock.groundEast);
      expect(bloc.state.data.player!.facing, Facing.right);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenClickingATreeWithoutAxeThenExplainsWhy',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.treeEast(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.eastTreeCanopy, treeId: 'tree-1'));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageNeedAxe));
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenPickingUpTheAxeThenPlaysEffectAnnouncesAndHoldsIt',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.axeNextToPlayer(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.axeSpot));
      ForestBlocMock.tickFor(bloc, 300);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects, contains(ForestEffectMock.axePickedUp));
      expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessagePickedUpAxe));
      expect(bloc.state.data.hud!.hasAxe, isTrue);
      expect(bloc.state.data.player!.pose, PlayerPoseMock.idle);
    },
  );

  group('testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall', () {
    late Facing facing;
    late PlayerPose pose;

    blocTest<ForestBloc, ForestState>(
      'testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall',
      build: () {
        // given
        return ForestBlocMock.make(ForestScenarioMock.axeInHandWithTree(), navigationService: navigationService);
      },
      act: (bloc) async {
        // when
        effects = ForestBlocMock.collectEffects(bloc);
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.treeCanopy, treeId: 'tree-1'));
        ForestBlocMock.tickFor(bloc, 1500);
        await ForestBlocMock.processEvents();
        facing = bloc.state.data.player!.facing;
        pose = bloc.state.data.player!.pose;
        ForestBlocMock.tickFor(bloc, Rules.chopIntervalMs * Rules.hitsToFellTree);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(facing, Facing.right);
        expect(pose, isA<WorkPose>());
        expect((pose as WorkPose).tool, WorkTool.axe);
        expect(effects.whereType<TreeHitEffect>().length, 5);
        expect(effects, contains(ForestEffectMock.treeFelled));
        expect(bloc.state.data.hud!.wood, 6);
      },
    );
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenWoodIsNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.tenWood(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs))
        ..add(const ForestBuildRequested(blueprint: BlueprintId.house));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.buildItems, [BuildItemDataMock.makeUnaffordable(missingWood: 5)]);
      expect(bloc.state.data.placement, isNull);
      expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageNotEnoughWood));
    },
  );

  group('testWhenPlacingThenPreviewsValidityIgnoresBlockedSitesAndPlacesOnAFreeOne', () {
    late PlacementData? preview;
    late bool isLockedWhilePlacing;
    late PlacementData? stillPlacing;

    blocTest<ForestBloc, ForestState>(
      'testWhenPlacingThenPreviewsValidityIgnoresBlockedSitesAndPlacesOnAFreeOne',
      build: () {
        // given
        return ForestBlocMock.make(ForestScenarioMock.fifteenWoodWithFarTree(), navigationService: navigationService);
      },
      act: (bloc) async {
        // when
        effects = ForestBlocMock.collectEffects(bloc);
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestPointerMoved(position: ForestScenarioMock.siteNextToFarTree));
        await ForestBlocMock.processEvents();
        preview = bloc.state.data.placement;
        isLockedWhilePlacing = bloc.state.data.hud!.isBuildLocked;
        bloc.add(const ForestMapClicked(position: ForestScenarioMock.siteNextToFarTree));
        await ForestBlocMock.processEvents();
        stillPlacing = bloc.state.data.placement;
        bloc.add(const ForestMapClicked(position: ForestScenarioMock.freeSite));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(preview, PlacementDataMock.blockedNextToFarTree);
        expect(isLockedWhilePlacing, isTrue);
        expect(stillPlacing, isNotNull);
        expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageBlockedSite));
        final placed = effects.whereType<BuildingPlacedEffect>().single;
        expect(placed.building.id, 'building-1');
        expect(placed.building.position, ForestScenarioMock.freeSite);
        expect(bloc.state.data.placement, isNull);
      },
    );
  });

  group('testWhenSecondaryClickWhilePlacingThenCancelsWithoutBuilding', () {
    late World world;

    blocTest<ForestBloc, ForestState>(
      'testWhenSecondaryClickWhilePlacingThenCancelsWithoutBuilding',
      build: () {
        // given
        world = ForestScenarioMock.fifteenWood();
        return ForestBlocMock.make(world, navigationService: navigationService);
      },
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestMapClicked(position: ForestScenarioMock.farSite, isSecondary: true));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.placement, isNull);
        expect(world.buildings, isEmpty);
        expect(bloc.state.data.hud!.isBuildLocked, isFalse);
      },
    );
  });

  group('testWhenCancellingThePlacementThenClosesItWithoutBuilding', () {
    late World world;

    blocTest<ForestBloc, ForestState>(
      'testWhenCancellingThePlacementThenClosesItWithoutBuilding',
      build: () {
        // given
        world = ForestScenarioMock.fifteenWood();
        return ForestBlocMock.make(world, navigationService: navigationService);
      },
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestPlacementCancelled());
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.placement, isNull);
        expect(world.buildings, isEmpty);
        expect(bloc.state.data.hud!.isBuildLocked, isFalse);
        expect(
          ForestBlocMock.shownMessages(navigationService),
          contains(
            Internationalize.forestMessagePlacing(name: Internationalize.forestBlueprint(id: BlueprintId.house)),
          ),
        );
      },
    );
  });

  group('testWhenTheLastQuestIsCompletedThenShowsTheFinalMessage', () {
    late String badgeBefore;

    blocTest<ForestBloc, ForestState>(
      'testWhenTheLastQuestIsCompletedThenShowsTheFinalMessage',
      build: () {
        // given
        return ForestBlocMock.make(ForestScenarioMock.axeAndFifteenWood(), navigationService: navigationService);
      },
      act: (bloc) async {
        // when
        effects = ForestBlocMock.collectEffects(bloc);
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
        await ForestBlocMock.processEvents();
        badgeBefore = bloc.state.data.hud!.questBadge;
        bloc
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestMapClicked(position: ForestScenarioMock.houseSiteEast));
        ForestBlocMock.tickFor(bloc, 6000 + Rules.hammerIntervalMs * 8);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(badgeBefore, '2/3');
        expect(effects, contains(ForestEffectMock.buildingCompleted));
        expect(bloc.state.data.hud!.questBadge, '3/3');
        expect(ForestBlocMock.shownMessages(navigationService).last, Internationalize.forestMessageAllQuestsCompleted);
      },
    );
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenEventsArriveInOrderThenTheLastClickWins',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast));
      ForestBlocMock.tickFor(bloc, 320);
      bloc.add(const ForestMapClicked(position: ForestScenarioMock.playerStart));
      ForestBlocMock.tickFor(bloc, 1000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.player!.position, ForestScenarioMock.playerStart);
      expect(bloc.state.data.player!.facing, Facing.left);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenEachEventEmitsThenOnlyCarriesItsOwnEffects',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.axeNextToPlayer(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs))
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
    },
    wait: Duration.zero,
    expect: () => [
      isA<ForestInProgress>(),
      isA<ForestSuccess>(),
      isA<ForestSuccess>().having((state) => state.data.effects, 'effects', [ForestEffectMock.axePickedUp]),
      isA<ForestSuccess>().having((state) => state.data.effects, 'effects', isEmpty),
    ],
  );
}
