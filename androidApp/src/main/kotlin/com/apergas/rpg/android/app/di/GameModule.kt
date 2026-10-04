package com.apergas.rpg.android.app.di

import com.apergas.rpg.di.GameContainer
import com.apergas.rpg.domain.usecases.game.GameUseCase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object GameModule {
    @Provides
    @Singleton
    fun provideGameUseCase(): GameUseCase = GameContainer.makeGameUseCase()
}
