package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.tree.Tree
import kotlin.math.max
import kotlin.math.min

/** The world's data, shared by the systems that implement its rules. Only `World` creates it. */
internal class WorldState(
    val width: Double,
    val height: Double,
    var player: Player,
    trees: List<Tree>,
    items: List<GroundItem>,
    /** Static and non-solid: no system changes it, it never takes part in collisions. */
    val decorations: List<Decoration>,
) {
    init {
        require(width > 0 && height > 0) { "World size must be positive" }
    }

    val trees: MutableMap<String, Tree> = trees.associateByTo(LinkedHashMap()) { it.id }
    val items: MutableMap<String, GroundItem> = items.associateByTo(LinkedHashMap()) { it.id }
    val buildings: MutableMap<String, Building> = LinkedHashMap()
    private val idCounters = mutableMapOf<String, Int>()

    /** Every footprint that blocks movement: standing trees and buildings (finished or not). */
    fun obstacles(): List<Obstacle> = trees.values.map { it.footprint } + buildings.values.map { it.footprint }

    fun isBlocked(position: Position, radius: Double): Boolean = obstacles().any { it.blocks(position, radius) }

    /** Keeps a footprint of [margin] radius inside the world. */
    fun clamp(position: Position, margin: Double): Position {
        fun clamp(value: Double, limit: Double) = min(max(value, margin), limit - margin)
        return Position(clamp(position.x, width), clamp(position.y, height))
    }

    fun isInside(position: Position, margin: Double): Boolean = clamp(position, margin) == position

    /** Sequential ids per prefix: `building-1`, `building-2`... */
    fun nextId(prefix: String): String {
        val next = (idCounters[prefix] ?: 0) + 1
        idCounters[prefix] = next
        return "$prefix-$next"
    }
}
