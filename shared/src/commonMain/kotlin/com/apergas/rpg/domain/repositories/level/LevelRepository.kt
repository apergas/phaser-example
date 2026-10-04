package com.apergas.rpg.domain.repositories.level

import com.apergas.rpg.domain.world.World

/** Provides the world a new game starts in. */
interface LevelRepository {
    fun load(): World
}
