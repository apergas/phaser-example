package com.apergas.rpg.domain.entities.building

/** What it takes to construct a kind of building. */
data class Blueprint(
    val id: BlueprintId,
    val woodCost: Int,
    /** Hammer hits needed to finish it. */
    val hitsToBuild: Int,
    /** Radius of the circular footprint that blocks movement. */
    val footprintRadius: Double,
)

object Blueprints {
    val house = Blueprint(id = BlueprintId.House, woodCost = 15, hitsToBuild = 8, footprintRadius = 40.0)
    val all: List<Blueprint> = listOf(house)

    fun of(id: BlueprintId): Blueprint = all.first { it.id == id }
}
