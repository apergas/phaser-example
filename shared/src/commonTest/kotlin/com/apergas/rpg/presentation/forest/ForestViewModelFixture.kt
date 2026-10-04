package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.repositories.level.LevelRepositoryMock
import com.apergas.rpg.domain.repositories.session.GameSessionRepositoryMock
import com.apergas.rpg.domain.usecases.game.GameUseCaseImpl
import com.apergas.rpg.domain.world.World
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch

/** A view model on the real use case, whose level is [world] (kept so tests can adjust it). */
fun forestViewModelFor(world: World): ForestViewModel {
    val levelRepository = LevelRepositoryMock().apply { makeWorld = { world } }
    return ForestViewModel(GameUseCaseImpl(levelRepository, GameSessionRepositoryMock()))
}

/**
 * Collects every effect while the test runs: pass `backgroundScope` and an `UnconfinedTestDispatcher`
 * so the collector is subscribed before the first intent and receives effects synchronously.
 */
fun ForestViewModel.collectEffects(scope: CoroutineScope, dispatcher: CoroutineDispatcher): List<ForestEffect> {
    val effects = mutableListOf<ForestEffect>()
    scope.launch(dispatcher) { uiEffect.toList(effects) }
    return effects
}

fun ForestViewModel.tickFor(totalMs: Double) {
    var elapsed = 0.0
    while (elapsed < totalMs) {
        onIntent(ForestIntent.Tick(16.0))
        elapsed += 16.0
    }
}
