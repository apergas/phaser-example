package com.apergas.rpg.domain.entities.geometry

/** Something solid on the ground. Only its circular footprint matters. */
data class Obstacle(val position: Position, val radius: Double) {
    init {
        require(radius > 0) { "Obstacle radius must be positive" }
    }

    fun blocks(position: Position, radius: Double): Boolean = this.position.distanceTo(position) < this.radius + radius
}
