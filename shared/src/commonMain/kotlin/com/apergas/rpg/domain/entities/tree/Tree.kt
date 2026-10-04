package com.apergas.rpg.domain.entities.tree

import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position

/** A choppable tree. Its trunk blocks movement until it is felled. */
data class Tree(
    val id: String,
    val kind: TreeKind,
    val position: Position,
    val trunkRadius: Double,
    /** Wood added to the inventory when the tree is felled. */
    val woodYield: Int,
    val hitsToFell: Int,
    val hitsTaken: Int = 0,
) {
    init {
        require(woodYield >= 0) { "Wood yield cannot be negative" }
        require(hitsToFell > 0) { "A tree needs at least one hit to fell" }
    }

    val footprint: Obstacle get() = Obstacle(position, trunkRadius)
    val hitsRemaining: Int get() = hitsToFell - hitsTaken
    val isFelled: Boolean get() = hitsRemaining == 0

    fun hit(): Tree = if (isFelled) this else copy(hitsTaken = hitsTaken + 1)

    companion object
}
