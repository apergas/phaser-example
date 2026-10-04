package com.apergas.rpg.domain.rules

/** Tuning values for the gathering and building loop. Times in milliseconds, distances in world units. */
object Rules {
    const val HITS_TO_FELL_TREE = 5
    const val CHOP_INTERVAL_MS = 750.0
    const val HAMMER_INTERVAL_MS = 650.0
    /** Gap left between the player's footprint and the target's when walking up to work on it. */
    const val WORK_GAP = 2.0
    /** The player picks up items within this distance of its feet. */
    const val PICK_UP_RANGE = 14.0
    const val PLAYER_SPEED = 110.0
    const val PLAYER_RADIUS = 8.0
    const val TREE_TRUNK_RADIUS = 12.0
}
