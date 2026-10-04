package com.apergas.rpg.domain.entities.item

import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind

val GroundItem.Companion.mock: GroundItem
    get() = GroundItem(id = "axe-1", kind = ToolKind.Axe, position = Position(150.0, 100.0))
