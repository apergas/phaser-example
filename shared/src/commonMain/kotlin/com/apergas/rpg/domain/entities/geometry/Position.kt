package com.apergas.rpg.domain.entities.geometry

import kotlin.math.hypot

data class Position(val x: Double, val y: Double) {
    fun distanceTo(other: Position): Double = hypot(other.x - x, other.y - y)

    /** A position moved towards [target] by at most [maxStep], never overshooting it. */
    fun moveTowards(target: Position, maxStep: Double): Position {
        val distance = distanceTo(target)
        if (distance <= maxStep) return target
        val ratio = maxStep / distance
        return Position(x + (target.x - x) * ratio, y + (target.y - y) * ratio)
    }

    /**
     * The point at exactly [distance] from this position in the direction of [towards].
     * When both coincide there is no direction, so the point is placed below (south).
     */
    fun pointAtDistance(distance: Double, towards: Position): Position {
        val length = distanceTo(towards)
        if (length == 0.0) return Position(x, y + distance)
        val ratio = distance / length
        return Position(x + (towards.x - x) * ratio, y + (towards.y - y) * ratio)
    }

    companion object
}
