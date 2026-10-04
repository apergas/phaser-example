package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.tree.Tree

/** Everything placed in the world at a given moment, to draw it from scratch. */
data class WorldSnapshot(
    val width: Double,
    val height: Double,
    val trees: List<Tree>,
    val items: List<GroundItem>,
    val decorations: List<Decoration>,
    val buildings: List<Building>,
)
