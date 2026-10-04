package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position

sealed interface Activity {
    data object Idle : Activity
    data class Walking(val destination: Position, val intent: Intent?) : Activity
    /** [elapsedMs] is the time since the last impact (axe hit, hammer blow...). */
    data class Working(val intent: Intent, val elapsedMs: Double) : Activity
}
