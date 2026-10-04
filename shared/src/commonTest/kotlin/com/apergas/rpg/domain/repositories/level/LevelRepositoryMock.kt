package com.apergas.rpg.domain.repositories.level

import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock

class LevelRepositoryMock : LevelRepository {
    var error: Throwable? = null
    /** A fresh world on every load, like a real level source. */
    var makeWorld: () -> World = { World.mock() }
    var loadCalled = false

    override fun load(): World {
        loadCalled = true
        error?.let { throw it }
        return makeWorld()
    }
}
