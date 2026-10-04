package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.geometry.Position

enum class PlayerActivity { Idle, Walking, Chopping, Constructing }

data class PlayerStatus(
    val position: Position,
    val activity: PlayerActivity,
    /** What the player is walking to or working on, if anything. */
    val target: Position?,
    /** Progress of the current swing, 0..1, while chopping or constructing. */
    val swingProgress: Double,
    val wood: Int,
    val hasAxe: Boolean,
)
