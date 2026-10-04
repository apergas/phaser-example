package com.apergas.rpg.domain.entities.building

import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position

/** A building placed in the world. It blocks movement from the moment construction starts. */
data class Building(val id: String, val blueprint: Blueprint, val position: Position, val hitsDone: Int = 0) {
    val footprint: Obstacle get() = Obstacle(position, blueprint.footprintRadius)

    /** From 0 (just started) to 1 (complete). */
    val progress: Double get() = hitsDone.toDouble() / blueprint.hitsToBuild
    val isComplete: Boolean get() = hitsDone >= blueprint.hitsToBuild

    fun hammer(): Building = if (isComplete) this else copy(hitsDone = hitsDone + 1)

    companion object
}
