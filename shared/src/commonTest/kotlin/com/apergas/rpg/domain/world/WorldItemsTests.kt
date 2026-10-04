package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.item.mock
import com.apergas.rpg.domain.entities.player.ToolKind
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertTrue

class WorldItemsTests {
    @Test
    fun testWhenPlayerWalksOverAToolThenPicksItUp() {
        // given
        val world = World.mock(items = listOf(GroundItem.mock))
        world.movePlayerTo(Position(160.0, 100.0))

        // when
        val events = world.advanceFor(1000.0)

        // then
        assertContains(events, GameEvent.ItemPickedUp("axe-1", ToolKind.Axe))
        assertTrue(world.player.inventory.hasTool(ToolKind.Axe))
        assertTrue(world.items.isEmpty())
    }
}
