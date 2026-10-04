package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.Blueprint
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.tree.Tree

/**
 * Aggregate root: the only entry point that changes the world. It owns the state and delegates each
 * rule to a system (navigation, woodcutting, construction, pick-up). Everything it hands out is an
 * immutable entity snapshot.
 */
class World(
    width: Double,
    height: Double,
    player: Player,
    trees: List<Tree>,
    items: List<GroundItem> = emptyList(),
    decorations: List<Decoration> = emptyList(),
) {
    private val state = WorldState(width, height, player, trees, items, decorations)
    private val navigation = Navigation(state)

    val width: Double get() = state.width
    val height: Double get() = state.height
    val player: Player get() = state.player
    val trees: List<Tree> get() = state.trees.values.toList()
    val items: List<GroundItem> get() = state.items.values.toList()
    val decorations: List<Decoration> get() = state.decorations
    val buildings: List<Building> get() = state.buildings.values.toList()
    val obstacles: List<Obstacle> get() = state.obstacles()

    /** Progress of the current impact cycle, 0..1, or 0 when not working. */
    val workProgress: Double
        get() {
            val working = player.activity as? Activity.Working ?: return 0.0
            return working.elapsedMs / workFor(working.intent).intervalMs
        }

    /** Where the player is heading or what it is working on, if anything. */
    val playerTarget: Position?
        get() = when (val activity = player.activity) {
            is Activity.Walking -> activity.destination
            is Activity.Working -> workFor(activity.intent).target(state)?.position
            Activity.Idle -> null
        }

    fun movePlayerTo(destination: Position) = navigation.walkTo(destination)

    /** Sends the player to chop a tree. Requires an axe. */
    fun orderChop(treeId: String): ChopResult {
        val result = Woodcutting.check(state, treeId)
        if (result == ChopResult.Ok) navigation.goWorkOn(Intent.Chop(treeId))
        return result
    }

    /** Pays for a building, places its site and sends the player to construct it. */
    fun orderConstruction(blueprint: Blueprint, position: Position): ConstructionResult {
        val result = Construction.place(state, blueprint, position)
        if (result is ConstructionResult.Started) navigation.goWorkOn(Intent.Construct(result.building.id))
        return result
    }

    fun canPlace(blueprint: Blueprint, position: Position): Boolean = Construction.canPlace(state, blueprint, position)

    fun advance(deltaMs: Double): List<GameEvent> {
        val events = mutableListOf<GameEvent>()
        when (val activity = player.activity) {
            is Activity.Walking -> navigation.step(deltaMs, activity, events)
            is Activity.Working -> work(deltaMs, activity, events)
            Activity.Idle -> Unit
        }
        pickUpItems(state, events)
        return events
    }

    /** Test seam: prepares a player state without going through the game rules. */
    internal fun updatePlayer(transform: (Player) -> Player) {
        state.player = transform(state.player)
    }

    /** Generic work loop: one impact per interval until the work reports it is finished. */
    private fun work(deltaMs: Double, activity: Activity.Working, events: MutableList<GameEvent>) {
        val work = workFor(activity.intent)
        if (work.target(state) == null) {
            state.player = state.player.stop()
            return
        }
        val elapsed = activity.elapsedMs + deltaMs
        if (elapsed < work.intervalMs) {
            state.player = state.player.continueWork(elapsed)
            return
        }
        state.player = state.player.continueWork(elapsed - work.intervalMs)
        if (work.impact(state, events)) state.player = state.player.stop()
    }

    companion object
}
