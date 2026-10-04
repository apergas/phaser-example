package com.apergas.rpg.data.repositories.level

import com.apergas.rpg.data.datasources.local.level.LevelLocalDataSource
import com.apergas.rpg.domain.errors.ErrorHandler
import com.apergas.rpg.domain.repositories.level.LevelRepository
import com.apergas.rpg.domain.world.World

class LevelRepositoryImpl(
    private val localDataSource: LevelLocalDataSource,
    private val errorHandler: ErrorHandler,
) : LevelRepository {
    override fun load(): World = try {
        localDataSource.fetch().toDomain()
    } catch (error: Throwable) {
        throw errorHandler.handle(error)
    }
}
