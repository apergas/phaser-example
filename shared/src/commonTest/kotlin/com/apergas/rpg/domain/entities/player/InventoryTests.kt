package com.apergas.rpg.domain.entities.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class InventoryTests {
    @Test
    fun testWhenSpendingAffordableWoodThenReturnsInventoryWithTheRest() {
        // given
        val inventory = Inventory().addWood(6)

        // when
        val afterSpending = inventory.spendWood(4)

        // then
        assertEquals(2, afterSpending?.wood)
    }

    @Test
    fun testWhenSpendingMoreWoodThanStoredThenReturnsNull() {
        // given
        val inventory = Inventory().addWood(3)

        // when
        val afterSpending = inventory.spendWood(5)

        // then
        assertNull(afterSpending)
        assertEquals(3, inventory.wood)
    }

    @Test
    fun testWhenAddingToolThenInventoryHasIt() {
        // given
        val inventory = Inventory()

        // when
        val withAxe = inventory.addTool(ToolKind.Axe)

        // then
        assertFalse(inventory.hasTool(ToolKind.Axe))
        assertTrue(withAxe.hasTool(ToolKind.Axe))
    }
}
