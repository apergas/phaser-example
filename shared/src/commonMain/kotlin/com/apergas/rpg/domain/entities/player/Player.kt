package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position

data class Player(
    val position: Position,
    /** World units per second. */
    val speed: Double,
    /** Radius of the footprint on the ground, used for collisions. */
    val radius: Double,
    val inventory: Inventory = Inventory(),
    val activity: Activity = Activity.Idle,
) {
    init {
        require(speed > 0) { "Player speed must be positive" }
        require(radius > 0) { "Player radius must be positive" }
    }

    val isMoving: Boolean get() = activity is Activity.Walking

    fun walkTo(destination: Position, intent: Intent? = null): Player =
        copy(activity = Activity.Walking(destination, intent))

    fun startWork(intent: Intent): Player = copy(activity = Activity.Working(intent, elapsedMs = 0.0))

    /** Keeps working on the current task; [elapsedMs] is the time since the last impact. */
    fun continueWork(elapsedMs: Double): Player {
        val working = activity as? Activity.Working ?: return this
        return copy(activity = working.copy(elapsedMs = elapsedMs))
    }

    fun stop(): Player = copy(activity = Activity.Idle)

    /** Where the player would be after [deltaMs], or null when not walking. */
    fun nextPosition(deltaMs: Double): Position? {
        val walking = activity as? Activity.Walking ?: return null
        return position.moveTowards(walking.destination, speed * deltaMs / 1000)
    }

    fun placeAt(position: Position): Player = copy(position = position)

    fun withInventory(inventory: Inventory): Player = copy(inventory = inventory)

    companion object
}
