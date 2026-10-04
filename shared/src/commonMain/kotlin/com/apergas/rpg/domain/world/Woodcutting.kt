package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.rules.Rules

/** Felling trees with an axe: one hit per interval, wood added when the tree falls. */
internal object Woodcutting : Work<Intent.Chop> {
    override val intervalMs: Double = Rules.CHOP_INTERVAL_MS

    fun check(state: WorldState, treeId: String): ChopResult = when {
        treeId !in state.trees -> ChopResult.UnknownTree
        !state.player.inventory.hasTool(ToolKind.Axe) -> ChopResult.NoAxe
        else -> ChopResult.Ok
    }

    override fun target(state: WorldState, intent: Intent.Chop): Obstacle? = state.trees[intent.treeId]?.footprint

    /** Beside the trunk, a pixel in front so the player is drawn over it; near side first. */
    override fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position> {
        val (x, y) = target.position
        return listOf(Position(x + side * distance, y + 1), Position(x - side * distance, y + 1))
    }

    override fun impact(state: WorldState, intent: Intent.Chop, events: MutableList<GameEvent>): Boolean {
        val tree = state.trees[intent.treeId]?.hit() ?: return true
        events += GameEvent.TreeHit(tree.id, tree.hitsRemaining)
        if (!tree.isFelled) {
            state.trees[tree.id] = tree
            return false
        }
        state.trees.remove(tree.id)
        state.player = state.player.withInventory(state.player.inventory.addWood(tree.woodYield))
        events += GameEvent.TreeFelled(tree.id, tree.woodYield)
        return true
    }
}
