package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.building.Blueprints
import com.apergas.rpg.domain.entities.game.ConstructionRejection
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.rules.Rules
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class WorldConstructionTests {
    private val house = Blueprints.house

    private fun worldWithWood(wood: Int): World =
        World.mock(player = Player.mock.copy(inventory = Player.mock.inventory.addWood(wood)))

    @Test
    fun testWhenConstructingWithoutEnoughWoodThenIsRejected() {
        // given
        val world = World.mock()

        // when
        val result = world.orderConstruction(house, Position(400.0, 400.0))

        // then
        assertEquals(ConstructionResult.Rejected(ConstructionRejection.NotEnoughWood), result)
        assertTrue(world.buildings.isEmpty())
    }

    @Test
    fun testWhenSiteOverlapsTreePlayerOrEdgeThenIsBlockedWithoutCharging() {
        // given
        val world = World.mock(
            player = Player.mock.copy(inventory = Player.mock.inventory.addWood(15)),
            trees = listOf(Tree.mock.copy(position = Position(400.0, 400.0))),
        )
        val blocked = ConstructionResult.Rejected(ConstructionRejection.Blocked)

        // when
        val overTree = world.orderConstruction(house, Position(420.0, 400.0))
        val overPlayer = world.orderConstruction(house, Position(110.0, 100.0))
        val overEdge = world.orderConstruction(house, Position(10.0, 500.0))

        // then
        assertEquals(blocked, overTree)
        assertEquals(blocked, overPlayer)
        assertEquals(blocked, overEdge)
        assertEquals(15, world.player.inventory.wood)
    }

    @Test
    fun testWhenConstructingThenChargesWoodPlacesSiteAndWalksThere() {
        // given
        val world = worldWithWood(17)

        // when
        val result = world.orderConstruction(house, Position(300.0, 100.0))

        // then
        assertIs<ConstructionResult.Started>(result)
        assertEquals(2, world.player.inventory.wood)
        assertEquals(1, world.buildings.size)
        assertTrue(world.player.isMoving)
    }

    @Test
    fun testWhenReachingTheSiteThenBuildsFromTheFront() {
        // given
        val world = worldWithWood(17)
        world.orderConstruction(house, Position(300.0, 100.0))

        // when
        world.advanceFor(3000.0)

        // then
        assertEquals(Intent.Construct("building-1"), (world.player.activity as Activity.Working).intent)
        assertEquals(Position(300.0, 150.0), world.player.position)
    }

    @Test
    fun testWhenHammeringLongEnoughThenBuildingIsCompleted() {
        // given
        val world = worldWithWood(17)
        world.orderConstruction(house, Position(300.0, 100.0))

        // when
        val events = world.advanceFor(3000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild)

        // then
        assertEquals(8, events.count { it is GameEvent.BuildingHammered })
        assertContains(events, GameEvent.BuildingCompleted("building-1", BlueprintId.House))
        assertTrue(world.buildings.single().isComplete)
        assertEquals(Activity.Idle, world.player.activity)
    }

    @Test
    fun testWhenBuildingIsCompleteThenItBlocksMovement() {
        // given
        val world = worldWithWood(17)
        world.orderConstruction(house, Position(300.0, 100.0))
        world.advanceFor(3000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild)
        for (waypoint in listOf(Position(200.0, 200.0), Position(200.0, 100.0))) {
            world.movePlayerTo(waypoint)
            world.advanceFor(3000.0)
        }

        // when
        world.movePlayerTo(Position(500.0, 100.0))
        world.advanceFor(5000.0)

        // then
        assertTrue(world.player.position.x < 260.0)
    }
}
