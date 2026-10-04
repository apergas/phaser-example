package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.rules.Rules

/** Picks up every item the player is standing on. */
internal fun pickUpItems(state: WorldState, events: MutableList<GameEvent>) {
    for (item in state.items.values.toList()) {
        if (item.position.distanceTo(state.player.position) > Rules.PICK_UP_RANGE) continue
        state.items.remove(item.id)
        state.player = state.player.withInventory(state.player.inventory.addTool(item.kind))
        events += GameEvent.ItemPickedUp(item.id, item.kind)
    }
}
