package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class WorldMovementTests {
    @Test
    fun testWhenPathIsClearThenPlayerMoves() {
        // given
        val world = World.mock()
        world.movePlayerTo(Position(200.0, 100.0))

        // when
        world.advance(500.0)

        // then
        assertEquals(Position(150.0, 100.0), world.player.position)
    }

    @Test
    fun testWhenNextStepHitsATrunkThenPlayerStops() {
        // given
        val world = World.mock(trees = listOf(Tree.mock.copy(position = Position(130.0, 100.0))))
        world.movePlayerTo(Position(200.0, 100.0))

        // when
        world.advance(150.0)

        // then
        assertEquals(Position(100.0, 100.0), world.player.position)
        assertFalse(world.player.isMoving)
    }

    @Test
    fun testWhenDestinationIsOutsideTheWorldThenItIsClampedToTheEdge() {
        // given
        val world = World(width = 200.0, height = 100.0, player = Player.mock.copy(position = Position(50.0, 50.0)), trees = emptyList())
        world.movePlayerTo(Position(-50.0, 500.0))

        // when
        world.advanceFor(2000.0)

        // then
        assertEquals(Position(8.0, 92.0), world.player.position)
    }
}
