package com.apergas.rpg.di

import com.apergas.rpg.data.datasources.local.level.LevelLocalDataSourceImpl
import com.apergas.rpg.data.datasources.local.session.GameSessionLocalDataSourceImpl
import com.apergas.rpg.data.errors.DataErrorHandlerImpl
import com.apergas.rpg.data.repositories.level.LevelRepositoryImpl
import com.apergas.rpg.data.repositories.session.GameSessionRepositoryImpl
import com.apergas.rpg.domain.repositories.session.GameSessionRepository
import com.apergas.rpg.domain.usecases.game.GameUseCase
import com.apergas.rpg.domain.usecases.game.GameUseCaseImpl
import com.apergas.rpg.presentation.forest.ForestViewModel

/**
 * Builds the dependency graph from the bottom up (DataSource -> Repository -> UseCase), like the
 * iOS `Container`. The only place in `shared` that knows concrete implementations. The session
 * repository is a single instance: every use case works on the same game.
 */
object GameContainer {
    private val errorHandler = DataErrorHandlerImpl()
    private val sessionRepository: GameSessionRepository by lazy {
        GameSessionRepositoryImpl(GameSessionLocalDataSourceImpl(), errorHandler)
    }

    fun makeGameUseCase(): GameUseCase = GameUseCaseImpl(
        levelRepository = LevelRepositoryImpl(LevelLocalDataSourceImpl(), errorHandler),
        sessionRepository = sessionRepository,
    )

    fun makeForestViewModel(): ForestViewModel = ForestViewModel(makeGameUseCase())
}
