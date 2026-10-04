package com.apergas.rpg.domain.entities.geometry

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue

class PositionTests {
    @Test
    fun testWhenMeasuringDistanceThenReturnsEuclideanDistance() {
        // given
        val origin = Position(0.0, 0.0)

        // when
        val distance = origin.distanceTo(Position(3.0, 4.0))

        // then
        assertEquals(5.0, distance)
    }

    @Test
    fun testWhenMovingTowardsTargetThenAdvancesByStep() {
        // given
        val origin = Position(0.0, 0.0)

        // when
        val moved = origin.moveTowards(Position(10.0, 0.0), 4.0)

        // then
        assertEquals(Position(4.0, 0.0), moved)
    }

    @Test
    fun testWhenStepWouldOvershootThenSnapsToTarget() {
        // given
        val target = Position(10.0, 0.0)

        // when
        val moved = Position(8.0, 0.0).moveTowards(target, 5.0)

        // then
        assertSame(target, moved)
    }

    @Test
    fun testWhenAskingPointAtDistanceThenFollowsDirection() {
        // given
        val origin = Position(0.0, 0.0)

        // when
        val point = origin.pointAtDistance(5.0, Position(30.0, 40.0))

        // then
        assertEquals(Position(3.0, 4.0), point)
    }

    @Test
    fun testWhenBothPositionsCoincideThenPointIsBelow() {
        // given
        val position = Position(1.0, 1.0)

        // when
        val point = position.pointAtDistance(5.0, Position(1.0, 1.0))

        // then
        assertEquals(Position(1.0, 6.0), point)
    }

    @Test
    fun testWhenFootprintsOverlapThenObstacleBlocks() {
        // given
        val obstacle = Obstacle(Position(30.0, 0.0), 10.0)

        // when
        val blocksNear = obstacle.blocks(Position(15.0, 0.0), 8.0)
        val blocksFar = obstacle.blocks(Position(0.0, 0.0), 8.0)

        // then
        assertTrue(blocksNear)
        assertFalse(blocksFar)
    }
}
