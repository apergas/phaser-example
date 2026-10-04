package com.apergas.rpg.domain.entities.item

import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind

/** A tool lying on the ground, waiting to be picked up. */
data class GroundItem(val id: String, val kind: ToolKind, val position: Position) {
    companion object
}
