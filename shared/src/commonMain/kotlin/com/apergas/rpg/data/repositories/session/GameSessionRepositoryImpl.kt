package com.apergas.rpg.data.repositories.session

import com.apergas.rpg.data.datasources.local.session.GameSessionLocalDataSource
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.errors.ErrorHandler
import com.apergas.rpg.domain.repositories.session.GameSessionRepository

class GameSessionRepositoryImpl(
    private val localDataSource: GameSessionLocalDataSource,
    private val errorHandler: ErrorHandler,
) : GameSessionRepository {
    override fun current(): GameSession = try {
        localDataSource.get() ?: throw AppError.GeneralError(IllegalStateException("No game in progress: call startGame() first"))
    } catch (error: Throwable) {
        throw errorHandler.handle(error)
    }

    override fun save(session: GameSession) = try {
        localDataSource.set(session)
    } catch (error: Throwable) {
        throw errorHandler.handle(error)
    }
}
