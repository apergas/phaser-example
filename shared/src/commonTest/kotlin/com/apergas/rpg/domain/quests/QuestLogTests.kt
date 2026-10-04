package com.apergas.rpg.domain.quests

import com.apergas.rpg.domain.entities.building.Blueprints
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.advanceFor
import com.apergas.rpg.domain.world.mock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class QuestLogTests {
    @Test
    fun testWhenGameStartsThenEveryQuestIsPendingAndTheFirstIsCurrent() {
        // given
        val world = World.mock()

        // when
        val status = QuestLog().status(world)

        // then
        assertEquals(
            listOf(
                QuestProgress(QuestId.PickUpAxe, progress = 0, target = 1, isCompleted = false, isCurrent = true),
                QuestProgress(QuestId.GatherWood, progress = 0, target = 15, isCompleted = false, isCurrent = false),
                QuestProgress(QuestId.BuildHouse, progress = 0, target = 1, isCompleted = false, isCurrent = false),
            ),
            status,
        )
    }

    @Test
    fun testWhenQuestIsFulfilledThenItIsReportedOnlyOnce() {
        // given
        val world = World.mock()
        val questLog = QuestLog()
        world.updatePlayer { it.withInventory(it.inventory.addTool(ToolKind.Axe)) }

        // when
        val first = questLog.update(world)
        val second = questLog.update(world)

        // then
        assertEquals(listOf(GameEvent.QuestCompleted(QuestId.PickUpAxe)), first)
        assertTrue(second.isEmpty())
    }

    @Test
    fun testWhenWoodIsSpentAfterCompletingThenWoodQuestStaysCompleted() {
        // given
        val world = World.mock()
        val questLog = QuestLog()
        world.updatePlayer { it.withInventory(it.inventory.addWood(16)) }
        questLog.update(world)

        // when
        world.updatePlayer { it.withInventory(it.inventory.spendWood(16)!!) }

        // then
        val woodQuest = questLog.status(world).first { it.id == QuestId.GatherWood }
        assertEquals(QuestProgress(QuestId.GatherWood, progress = 15, target = 15, isCompleted = true, isCurrent = false), woodQuest)
    }

    @Test
    fun testWhenProgressExceedsTargetThenItIsCapped() {
        // given
        val world = World.mock()
        world.updatePlayer { it.withInventory(it.inventory.addWood(40)) }

        // when
        val woodQuest = QuestLog().status(world).first { it.id == QuestId.GatherWood }

        // then
        assertEquals(15, woodQuest.progress)
    }

    @Test
    fun testWhenHouseIsOnlyPlacedThenBuildQuestIsNotCompleted() {
        // given
        val world = World.mock()
        val questLog = QuestLog()
        world.updatePlayer { it.withInventory(it.inventory.addWood(15)) }
        questLog.update(world)
        world.orderConstruction(Blueprints.house, Position(300.0, 100.0))

        // when
        val whilePlaced = questLog.update(world)
        world.advanceFor(10_000.0)
        val whenFinished = questLog.update(world)

        // then
        assertTrue(whilePlaced.isEmpty())
        assertEquals(listOf(GameEvent.QuestCompleted(QuestId.BuildHouse)), whenFinished)
    }
}
