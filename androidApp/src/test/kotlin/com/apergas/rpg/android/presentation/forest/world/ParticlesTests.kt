package com.apergas.rpg.android.presentation.forest.world

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.math.atan2
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ParticlesTests {
    private val trunkBase = Position(200.0, 300.0)

    @Test
    fun testWhenTreeIsHitFromTheLeftThenEightChipsFlyUpTowardsThePlayer() {
        // given
        val random = Random(1)

        // when
        val chips = ParticleBursts.woodChips(trunkBase, playerOnLeft = true, nowNanos = 0, random = random)

        // then
        assertEquals(8, chips.size)
        chips.forEach { chip ->
            assertEquals(Position(200.0, 290.0), chip.origin)
            assertTrue(chip.angleDegrees() in 200.0..290.0)
        }
    }

    @Test
    fun testWhenTimePassesThenAChipFallsWithGravityAndFadesOut() {
        // given
        val chip = ParticleBursts.woodChips(trunkBase, playerOnLeft = false, nowNanos = 0, random = Random(1)).first()

        // when
        val position = chip.position(nowNanos = 250_000_000)

        // then
        assertEquals(chip.origin.x + chip.velocityX * 0.25, position.x, 1e-9)
        assertEquals(chip.origin.y + chip.velocityY * 0.25 + 0.5 * 220 * 0.25 * 0.25, position.y, 1e-9)
        assertEquals(0.5, chip.alpha(nowNanos = 250_000_000), 1e-9)
        assertFalse(chip.isAlive(nowNanos = 500_000_000))
    }

    @Test
    fun testWhenBuildingIsHammeredThenSixDustPuffsRiseFromItsFront() {
        // given
        val center = Position(400.0, 400.0)

        // when
        val dust = ParticleBursts.dust(center, nowNanos = 0, random = Random(1))

        // then
        assertEquals(6, dust.size)
        dust.forEach { puff ->
            assertEquals(Position(400.0, 420.0), puff.origin)
            assertTrue(puff.velocityY <= 0.0)
            assertEquals(0.2, puff.scale(nowNanos = 450_000_000), 1e-9)
        }
    }

    private fun Particle.angleDegrees(): Double = (Math.toDegrees(atan2(velocityY, velocityX)) + 360) % 360
}
