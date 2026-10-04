package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.Blueprint
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.game.ConstructionRejection
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.rules.Rules

/** Paying for buildings, placing their sites and hammering them until they are finished. */
internal object Construction : Work<Intent.Construct> {
    override val intervalMs: Double = Rules.HAMMER_INTERVAL_MS

    fun canPlace(state: WorldState, blueprint: Blueprint, position: Position): Boolean {
        val radius = blueprint.footprintRadius
        val player = state.player
        val overlapsPlayer = position.distanceTo(player.position) < radius + player.radius
        val overlapsItem = state.items.values.any { position.distanceTo(it.position) < radius }
        return state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem
    }

    fun place(state: WorldState, blueprint: Blueprint, position: Position): ConstructionResult {
        val paid = state.player.inventory.spendWood(blueprint.woodCost)
            ?: return ConstructionResult.Rejected(ConstructionRejection.NotEnoughWood)
        if (!canPlace(state, blueprint, position)) return ConstructionResult.Rejected(ConstructionRejection.Blocked)

        state.player = state.player.withInventory(paid)
        val building = Building(state.nextId("building"), blueprint, position)
        state.buildings[building.id] = building
        return ConstructionResult.Started(building)
    }

    override fun target(state: WorldState, intent: Intent.Construct): Obstacle? =
        state.buildings[intent.buildingId]?.takeUnless { it.isComplete }?.footprint

    /** In front of the building (south), where the player stays in view. */
    override fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position> =
        listOf(Position(target.position.x, target.position.y + distance))

    override fun impact(state: WorldState, intent: Intent.Construct, events: MutableList<GameEvent>): Boolean {
        val building = state.buildings[intent.buildingId]?.hammer() ?: return true
        state.buildings[building.id] = building
        events += GameEvent.BuildingHammered(building.id, building.progress)
        if (!building.isComplete) return false
        events += GameEvent.BuildingCompleted(building.id, building.blueprint.id)
        return true
    }
}
