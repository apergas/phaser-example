package com.apergas.rpg.domain.entities.decoration

import com.apergas.rpg.domain.entities.geometry.Position

/** Ground decoration placed by the level. Purely visual: it never blocks movement. */
data class Decoration(val id: String, val kind: DecorationKind, val position: Position) {
    companion object
}
