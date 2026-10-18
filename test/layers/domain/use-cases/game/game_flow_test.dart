import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/quest_line.dart';
import 'package:farming/core/config/constants/enum/chop_result.dart';
import 'package:farming/core/config/constants/enum/deposit_result.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/game/construction_result_entity.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/chop_tree_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/deposit_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_stock_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_player_status_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/get_quests_use_case.dart';
import 'package:farming/layers/domain/use-cases/game/move_player_use_case.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/game/game_event_entity_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late MovePlayerUseCase movePlayer;
  late ChopTreeUseCase chopTree;
  late ConstructBuildingUseCase constructBuilding;
  late DepositUseCase deposit;
  late GetStockUseCase getStock;
  late AdvanceGameUseCase advanceGame;
  late GetPlayerStatusUseCase getPlayerStatus;
  late GetQuestsUseCase getQuests;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    movePlayer = MovePlayerUseCase(sessionRepository: sessionRepository);
    chopTree = ChopTreeUseCase(sessionRepository: sessionRepository);
    constructBuilding = ConstructBuildingUseCase(sessionRepository: sessionRepository);
    deposit = DepositUseCase(sessionRepository: sessionRepository);
    getStock = GetStockUseCase(sessionRepository: sessionRepository);
    advanceGame = AdvanceGameUseCase(sessionRepository: sessionRepository);
    getPlayerStatus = GetPlayerStatusUseCase(sessionRepository: sessionRepository);
    getQuests = GetQuestsUseCase(sessionRepository: sessionRepository);
  });

  List<GameEventEntity> advanceFor(double totalMs) {
    final events = <GameEventEntity>[];
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      events.addAll(advanceGame(deltaMs: 16));
      elapsed += 16;
    }
    return events;
  }

  test('testWhenPlayingTheWholeLoopThenTheWoodIsStoredTheHouseIsBuiltAndTheFirstQuestsAreCompleted', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.wholeLoop()));
    final chopTime = 2000 + Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell;
    const depositTime = 4000 + Rules.depositIntervalMs;
    const axeSpot = GameScenarioMock.wholeLoopAxeSpot;
    const site = GameScenarioMock.houseSite;

    // when
    final withoutAxe = chopTree(treeId: 'tree-1');
    movePlayer(x: axeSpot.x, y: axeSpot.y);
    advanceFor(500);
    final chopResults = ['tree-1', 'tree-2', 'tree-3'].map((treeId) {
      final result = chopTree(treeId: treeId);
      advanceFor(chopTime);
      final stored = deposit(buildingId: GameScenarioMock.wholeLoopCampId);
      advanceFor(depositTime);
      return (result, stored);
    }).toList();
    final carriedAfterChopping = getPlayerStatus().inventory.amount(Resource.wood);
    final woodAfterChopping = getStock().amount(Resource.wood);
    final construction = constructBuilding(blueprint: BlueprintId.house, x: site.x, y: site.y);
    final events = advanceFor(6000 + Rules.hammerIntervalMs * 8);

    // then
    expect(withoutAxe, ChopResult.noAxe);
    expect(chopResults, List.filled(3, (ChopResult.ok, DepositResult.ok)));
    expect((carriedAfterChopping, woodAfterChopping), (0, 18));
    expect(construction, isA<ConstructionStartedEntity>());
    expect(events, contains(GameEventEntityMock.buildingCompleted));
    expect(events, contains(GameEventEntityMock.buildHouseCompleted));
    expect(getStock().amount(Resource.wood), 3);
    expect(
      getQuests().where((quest) => quest.line == QuestLine.village && quest.isCompleted).map((quest) => quest.id),
      [QuestId.gatherWood, QuestId.buildHouse, QuestId.fellAnOak],
    );
  });
}
