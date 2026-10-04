package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree

fun World.Companion.mock(
    player: Player = Player.mock,
    trees: List<Tree> = emptyList(),
    items: List<GroundItem> = emptyList(),
): World = World(width = 1000.0, height = 1000.0, player = player, trees = trees, items = items)

/** Advances in 16 ms steps, like a 60 fps game loop, collecting every event. */
fun World.advanceFor(totalMs: Double): List<GameEvent> {
    val events = mutableListOf<GameEvent>()
    var elapsed = 0.0
    while (elapsed < totalMs) {
        events += advance(16.0)
        elapsed += 16.0
    }
    return events
}
