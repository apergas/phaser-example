package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull

class PlayerTests {
    @Test
    fun testWhenCreatedThenIsIdleWithoutNextPosition() {
        // given
        val player = Player.mock

        // when
        val next = player.nextPosition(1000.0)

        // then
        assertEquals(Activity.Idle, player.activity)
        assertNull(next)
    }

    @Test
    fun testWhenWalkingThenNextPositionAdvancesSpeedTimesSecondsWithoutMoving() {
        // given
        val player = Player.mock.copy(position = Position(0.0, 0.0)).walkTo(Position(1000.0, 0.0))

        // when
        val next = player.nextPosition(500.0)

        // then
        assertEquals(Position(50.0, 0.0), next)
        assertEquals(Position(0.0, 0.0), player.position)
    }

    @Test
    fun testWhenStoppingThenReturnsToIdle() {
        // given
        val walking = Player.mock.walkTo(Position(10.0, 0.0))

        // when
        val stopped = walking.stop()

        // then
        assertFalse(stopped.isMoving)
        assertEquals(Activity.Idle, stopped.activity)
    }

    @Test
    fun testWhenContinuingWorkThenTracksElapsedTime() {
        // given
        val working = Player.mock.startWork(Intent.Chop("tree-1"))

        // when
        val later = working.continueWork(300.0)

        // then
        assertEquals(Activity.Working(Intent.Chop("tree-1"), 300.0), later.activity)
    }

    @Test
    fun testWhenSpeedOrRadiusAreNotPositiveThenCreationFails() {
        // given
        val position = Position(0.0, 0.0)

        // when / then
        assertFailsWith<IllegalArgumentException> { Player(position, speed = 0.0, radius = 10.0) }
        assertFailsWith<IllegalArgumentException> { Player(position, speed = 100.0, radius = 0.0) }
    }
}
