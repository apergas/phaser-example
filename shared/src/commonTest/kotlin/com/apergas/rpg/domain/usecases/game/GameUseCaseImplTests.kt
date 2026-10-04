package com.apergas.rpg.domain.usecases.game

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.game.BuildOption
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.entities.game.PlayerActivity
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.item.mock
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.quests.QuestId
import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.repositories.level.LevelRepositoryMock
import com.apergas.rpg.domain.repositories.session.GameSessionRepositoryMock
import com.apergas.rpg.domain.rules.Rules
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertTrue

class GameUseCaseImplTests {
    private lateinit var levelRepository: LevelRepositoryMock
    private lateinit var sessionRepository: GameSessionRepositoryMock
    private lateinit var sut: GameUseCaseImpl

    @BeforeTest
    fun setUp() {
        levelRepository = LevelRepositoryMock()
        sessionRepository = GameSessionRepositoryMock()
        sut = GameUseCaseImpl(levelRepository, sessionRepository)
    }

    private fun playIn(world: World) {
        sessionRepository.session = GameSession(world, QuestLog())
    }

    private fun advanceFor(totalMs: Double): List<GameEvent> {
        val events = mutableListOf<GameEvent>()
        var elapsed = 0.0
        while (elapsed < totalMs) {
            events += sut.advance(16.0)
            elapsed += 16.0
        }
        return events
    }

    @Test
    fun testWhenStartGameThenSavesLevelWorldWithFreshQuests() {
        // given
        levelRepository.makeWorld = { World.mock(trees = listOf(Tree.mock)) }

        // when
        sut.startGame()

        // then
        assertTrue(levelRepository.loadCalled)
        assertTrue(sessionRepository.saveCalled)
        assertEquals(listOf("tree-1"), sut.worldSnapshot().trees.map { it.id })
        assertTrue(sut.quests().none { it.isCompleted })
    }

    @Test
    fun testWhenStartGameWithLevelErrorThenErrorPropagates() {
        // given
        levelRepository.error = AppError.LevelError.InvalidLevel("missing width")

        // when / then
        assertFailsWith<AppError.LevelError.InvalidLevel> { sut.startGame() }
        assertEquals(false, sessionRepository.saveCalled)
    }

    @Test
    fun testWhenNoGameInProgressThenQueriesFailWithGeneralError() {
        // given
        sessionRepository.session = null

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.playerStatus() }
    }

    @Test
    fun testWhenMovePlayerAndAdvanceThenPlayerReachesThePoint() {
        // given
        playIn(World.mock(player = Player.mock.copy(position = Position(50.0, 50.0))))

        // when
        sut.movePlayerTo(50.0, 150.0)
        sut.advance(1000.0)

        // then
        assertEquals(Position(50.0, 150.0), sut.playerStatus().position)
    }

    @Test
    fun testWhenPlayingTheWholeLoopThenHouseIsBuiltAndQuestsAreCompleted() {
        // given
        playIn(
            World.mock(
                items = listOf(GroundItem.mock.copy(position = Position(120.0, 100.0))),
                trees = listOf(
                    Tree.mock,
                    Tree.mock.copy(id = "tree-2", position = Position(200.0, 200.0)),
                    Tree.mock.copy(id = "tree-3", position = Position(100.0, 200.0)),
                ),
            ),
        )
        val chopTime = 2000 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE

        // when
        val withoutAxe = sut.chopTree("tree-1")
        sut.movePlayerTo(125.0, 100.0)
        advanceFor(500.0)
        val chopResults = listOf("tree-1", "tree-2", "tree-3").map { treeId ->
            sut.chopTree(treeId).also { advanceFor(chopTime) }
        }
        val woodAfterChopping = sut.playerStatus().wood
        val construction = sut.constructBuilding(BlueprintId.House, 400.0, 400.0)
        val events = advanceFor(6000 + Rules.HAMMER_INTERVAL_MS * 8)

        // then
        assertEquals(ChopResult.NoAxe, withoutAxe)
        assertEquals(listOf(ChopResult.Ok, ChopResult.Ok, ChopResult.Ok), chopResults)
        assertEquals(18, woodAfterChopping)
        assertIs<ConstructionResult.Started>(construction)
        assertContains(events, GameEvent.BuildingCompleted("building-1", BlueprintId.House))
        assertContains(events, GameEvent.QuestCompleted(QuestId.BuildHouse))
        assertEquals(3, sut.playerStatus().wood)
        assertTrue(sut.quests().all { it.isCompleted })
    }

    @Test
    fun testWhenPickingUpTheAxeThenQuestIsCompletedAndNextOneIsCurrent() {
        // given
        playIn(World.mock(items = listOf(GroundItem.mock.copy(position = Position(110.0, 100.0)))))

        // when
        sut.movePlayerTo(110.0, 100.0)
        val events = sut.advance(200.0)

        // then
        assertContains(events, GameEvent.QuestCompleted(QuestId.PickUpAxe))
        assertEquals(
            QuestProgress(QuestId.GatherWood, progress = 0, target = 15, isCompleted = false, isCurrent = true),
            sut.quests()[1],
        )
    }

    @Test
    fun testWhenChoppingHalfASwingThenStatusReportsChoppingProgressAndTarget() {
        // given
        val player = Player.mock.copy(inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        playIn(World.mock(player = player, trees = listOf(Tree.mock.copy(position = Position(120.0, 100.0)))))
        sut.chopTree("tree-1")

        // when
        sut.advance(Rules.CHOP_INTERVAL_MS / 2)
        val status = sut.playerStatus()

        // then
        assertEquals(PlayerActivity.Chopping, status.activity)
        assertEquals(0.5, status.swingProgress)
        assertEquals(Position(120.0, 100.0), status.target)
        assertTrue(status.hasAxe)
    }

    @Test
    fun testWhenWoodIsNotEnoughThenHouseIsNotAffordable() {
        // given
        playIn(World.mock(player = Player.mock.copy(inventory = Player.mock.inventory.addWood(10))))

        // when
        val options = sut.buildOptions()

        // then
        assertEquals(listOf(BuildOption(BlueprintId.House, woodCost = 15, isAffordable = false)), options)
    }

    @Test
    fun testWhenCheckingABlockedSiteThenCannotPlace() {
        // given
        playIn(World.mock(trees = listOf(Tree.mock.copy(position = Position(400.0, 400.0)))))

        // when
        val onTree = sut.canPlaceBuilding(BlueprintId.House, 410.0, 400.0)
        val onGrass = sut.canPlaceBuilding(BlueprintId.House, 600.0, 600.0)

        // then
        assertEquals(false, onTree)
        assertEquals(true, onGrass)
    }
}
