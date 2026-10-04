package com.apergas.rpg.android.presentation.forest.world

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

enum class ParticleKind { WoodChip, Dust }

/** One particle with a closed-form trajectory: its state at any instant is computed, never stepped. */
data class Particle(
    val kind: ParticleKind,
    val origin: Position,
    val velocityX: Double,
    val velocityY: Double,
    val gravity: Double,
    val rotationDegrees: Double,
    val bornAtNanos: Long,
    val lifespanNanos: Long,
    val alphaStart: Double,
    val alphaEnd: Double,
    val scaleStart: Double,
    val scaleEnd: Double,
    /** Draw order: just in front of whatever emitted it. */
    val sortY: Double,
) {
    fun isAlive(nowNanos: Long): Boolean = nowNanos - bornAtNanos < lifespanNanos

    fun position(nowNanos: Long): Position {
        val seconds = (nowNanos - bornAtNanos) / 1e9
        return Position(
            origin.x + velocityX * seconds,
            origin.y + velocityY * seconds + 0.5 * gravity * seconds * seconds,
        )
    }

    fun alpha(nowNanos: Long): Double = alphaStart + (alphaEnd - alphaStart) * progress(nowNanos)

    fun scale(nowNanos: Long): Double = scaleStart + (scaleEnd - scaleStart) * progress(nowNanos)

    private fun progress(nowNanos: Long): Double = ((nowNanos - bornAtNanos).toDouble() / lifespanNanos).coerceIn(0.0, 1.0)
}

private const val CHIPS_PER_HIT = 8
private const val IMPACT_HEIGHT = 10.0
private const val DUST_PER_HAMMER = 6
/** The dust rises from the house's front wall, which is drawn 24 px below its footprint centre. */
private const val HOUSE_FRONT_OFFSET = 24.0
private const val DUST_LIFT = 4.0

/** The web's bursts (TreeView.hit, BuildingView.hammered) with the same Phaser emitter values: degrees, Y down. */
object ParticleBursts {
    fun woodChips(trunkBase: Position, playerOnLeft: Boolean, nowNanos: Long, random: Random): List<Particle> {
        val angles = if (playerOnLeft) 200.0..290.0 else 250.0..340.0
        return List(CHIPS_PER_HIT) {
            val speed = random.between(30.0..80.0)
            val angle = Math.toRadians(random.between(angles))
            Particle(
                kind = ParticleKind.WoodChip,
                origin = Position(trunkBase.x, trunkBase.y - IMPACT_HEIGHT),
                velocityX = speed * cos(angle),
                velocityY = speed * sin(angle),
                gravity = 220.0,
                rotationDegrees = random.between(0.0..360.0),
                bornAtNanos = nowNanos,
                lifespanNanos = 500_000_000,
                alphaStart = 1.0,
                alphaEnd = 0.0,
                scaleStart = 1.0,
                scaleEnd = 1.0,
                // Same depth as the web (trunk base + 1), which is where the chopping player stands: the sort is
                // stable and particles are added after the player, so the chips are drawn in front of them.
                sortY = trunkBase.y + 1,
            )
        }
    }

    fun dust(buildingCenter: Position, nowNanos: Long, random: Random): List<Particle> {
        val front = buildingCenter.y + HOUSE_FRONT_OFFSET
        return List(DUST_PER_HAMMER) {
            val speed = random.between(10.0..35.0)
            val angle = Math.toRadians(random.between(180.0..360.0))
            Particle(
                kind = ParticleKind.Dust,
                origin = Position(buildingCenter.x, front - DUST_LIFT),
                velocityX = speed * cos(angle),
                velocityY = speed * sin(angle),
                gravity = 0.0,
                rotationDegrees = 0.0,
                bornAtNanos = nowNanos,
                lifespanNanos = 450_000_000,
                alphaStart = 0.7,
                alphaEnd = 0.0,
                scaleStart = 0.8,
                scaleEnd = 0.2,
                sortY = front + 1,
            )
        }
    }

    private fun Random.between(range: ClosedFloatingPointRange<Double>): Double =
        range.start + nextDouble() * (range.endInclusive - range.start)
}
