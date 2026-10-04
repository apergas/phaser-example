package com.apergas.rpg.domain.entities.player

/** Work the player is asked to do on a target: walk up to it, then work until it is done. */
sealed interface Intent {
    data class Chop(val treeId: String) : Intent
    data class Construct(val buildingId: String) : Intent
}
