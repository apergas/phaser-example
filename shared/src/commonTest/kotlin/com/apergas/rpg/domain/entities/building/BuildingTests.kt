package com.apergas.rpg.domain.entities.building

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class BuildingTests {
    @Test
    fun testWhenHammeredThenProgressGrowsUntilComplete() {
        // given
        var building = Building(id = "building-1", blueprint = Blueprints.house, position = Position(0.0, 0.0))

        // when
        building = building.hammer()
        val afterOneHit = building.progress
        repeat(7) { building = building.hammer() }

        // then
        assertEquals(0.125, afterOneHit)
        assertTrue(building.isComplete)
    }
}
