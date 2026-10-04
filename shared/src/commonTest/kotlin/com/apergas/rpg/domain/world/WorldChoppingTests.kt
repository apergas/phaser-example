package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.rules.Rules
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class WorldChoppingTests {
    private fun worldWithAxeAndTree(): World {
        val player = Player.mock.copy(inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        return World.mock(player = player, trees = listOf(Tree.mock))
    }

    @Test
    fun testWhenChoppingWithoutAxeThenReturnsNoAxeAndStaysPut() {
        // given
        val world = World.mock(trees = listOf(Tree.mock))

        // when
        val result = world.orderChop("tree-1")

        // then
        assertEquals(ChopResult.NoAxe, result)
        assertFalse(world.player.isMoving)
    }

    @Test
    fun testWhenChoppingUnknownTreeThenReturnsUnknownTree() {
        // given
        val world = worldWithAxeAndTree()

        // when
        val result = world.orderChop("nope")

        // then
        assertEquals(ChopResult.UnknownTree, result)
    }

    @Test
    fun testWhenChoppingThenWalksToTheNearSideAndStartsWorking() {
        // given
        val world = worldWithAxeAndTree()

        // when
        val result = world.orderChop("tree-1")
        world.advanceFor(1500.0)

        // then
        assertEquals(ChopResult.Ok, result)
        assertEquals(Intent.Chop("tree-1"), (world.player.activity as Activity.Working).intent)
        assertEquals(Position(180.0, 101.0), world.player.position)
    }

    @Test
    fun testWhenNearSideIsBlockedThenChopsFromTheOtherSide() {
        // given
        val player = Player.mock.copy(position = Position(100.0, 300.0), inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        val world = World.mock(player = player, trees = listOf(Tree.mock, Tree.mock.copy(id = "neighbour", position = Position(165.0, 100.0))))
        world.orderChop("tree-1")

        // when
        world.advanceFor(4000.0)

        // then
        assertIs<Activity.Working>(world.player.activity)
        assertTrue(world.player.position.x > 200.0)
    }

    @Test
    fun testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded() {
        // given
        val world = worldWithAxeAndTree()
        world.orderChop("tree-1")
        world.advanceFor(1500.0)

        // when
        val events = world.advanceFor(Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE + 100)

        // then
        assertEquals(5, events.count { it is GameEvent.TreeHit })
        assertContains(events, GameEvent.TreeFelled("tree-1", 6))
        assertEquals(6, world.player.inventory.wood)
        assertTrue(world.trees.isEmpty())
        assertEquals(Activity.Idle, world.player.activity)
    }

    @Test
    fun testWhenAnotherTreeStandsInTheWayThenReportsPlayerBlocked() {
        // given
        val player = Player.mock.copy(inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        val world = World.mock(
            player = player,
            trees = listOf(Tree.mock.copy(position = Position(300.0, 100.0)), Tree.mock.copy(id = "in-the-way", position = Position(180.0, 100.0))),
        )
        world.orderChop("tree-1")

        // when
        val events = world.advanceFor(3000.0)

        // then
        assertContains(events, GameEvent.PlayerBlocked)
        assertEquals(Activity.Idle, world.player.activity)
    }

    @Test
    fun testWhenTreeIsFelledThenPathIsFree() {
        // given
        val world = worldWithAxeAndTree()
        world.orderChop("tree-1")
        world.advanceFor(1500 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE + 100)

        // when
        world.movePlayerTo(Position(300.0, 100.0))
        world.advanceFor(3000.0)

        // then
        assertEquals(Position(300.0, 100.0), world.player.position)
    }
}
