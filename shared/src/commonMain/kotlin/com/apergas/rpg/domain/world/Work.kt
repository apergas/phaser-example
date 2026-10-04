package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Intent

/**
 * A kind of work done on a target one impact at a time. Adding a mechanic = a new `Intent`
 * variant + a `Work` + one branch in [workFor]; the compiler flags the missing branch.
 */
internal interface Work<I : Intent> {
    val intervalMs: Double
    fun target(state: WorldState, intent: I): Obstacle?
    /** Spots to stand on, best first, [distance] from the target; [side] is -1 from the left, 1 from the right. */
    fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position>
    /** Applies one impact. Returns true when the work is finished. */
    fun impact(state: WorldState, intent: I, events: MutableList<GameEvent>): Boolean
}

/** A work bound to its intent, so callers do not deal with the generic type. */
internal class BoundWork<I : Intent>(private val work: Work<I>, private val intent: I) {
    val intervalMs: Double get() = work.intervalMs
    fun target(state: WorldState): Obstacle? = work.target(state, intent)
    fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position> =
        work.preferredSpots(target, distance, side)
    fun impact(state: WorldState, events: MutableList<GameEvent>): Boolean = work.impact(state, intent, events)
}

internal fun workFor(intent: Intent): BoundWork<*> = when (intent) {
    is Intent.Chop -> BoundWork(Woodcutting, intent)
    is Intent.Construct -> BoundWork(Construction, intent)
}
