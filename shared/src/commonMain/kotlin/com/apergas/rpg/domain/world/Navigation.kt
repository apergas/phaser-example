package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.rules.Rules

/** Extra distance, beyond touching footprints, from which the player can still work on a target. */
private const val REACH_TOLERANCE = 6.0

/** Walking, collisions and getting into position to work on a target. */
internal class Navigation(private val state: WorldState) {
    fun walkTo(destination: Position) {
        state.player = state.player.walkTo(state.clamp(destination, state.player.radius))
    }

    /** Walks up to the intent's target, or starts working right away if it is already within reach. */
    fun goWorkOn(intent: Intent) {
        if (isWithinReach(intent)) return startWork(intent)
        state.player = state.player.walkTo(workSpot(intent), intent)
    }

    fun step(deltaMs: Double, activity: Activity.Walking, events: MutableList<GameEvent>) {
        val player = state.player
        val next = player.nextPosition(deltaMs) ?: return
        val intent = activity.intent

        if (state.isBlocked(next, player.radius)) {
            if (intent != null && isWithinReach(intent)) return startWork(intent)
            if (intent != null) events += GameEvent.PlayerBlocked
            state.player = player.stop()
            return
        }

        state.player = player.placeAt(next)
        if (next != activity.destination) return
        if (intent != null) startWork(intent) else state.player = state.player.stop()
    }

    private fun startWork(intent: Intent) {
        state.player = if (workFor(intent).target(state) != null) state.player.startWork(intent) else state.player.stop()
    }

    private fun isWithinReach(intent: Intent): Boolean {
        val target = workFor(intent).target(state) ?: return false
        val reach = target.radius + state.player.radius + Rules.WORK_GAP + REACH_TOLERANCE
        return state.player.position.distanceTo(target.position) <= reach
    }

    /** The work's preferred spots first; the closest point on the player's side when those are blocked. */
    private fun workSpot(intent: Intent): Position {
        val player = state.player
        val work = workFor(intent)
        val target = work.target(state) ?: return player.position
        val distance = target.radius + player.radius + Rules.WORK_GAP
        val side = if (player.position.x < target.position.x) -1 else 1
        val isFree = { spot: Position -> state.isInside(spot, player.radius) && !state.isBlocked(spot, player.radius) }

        return work.preferredSpots(target, distance, side).firstOrNull(isFree)
            ?: state.clamp(target.position.pointAtDistance(distance, player.position), player.radius)
    }
}
