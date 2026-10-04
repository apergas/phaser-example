package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position

val Player.Companion.mock: Player
    get() = Player(position = Position(100.0, 100.0), speed = 100.0, radius = 8.0)
