@file:OptIn(ExperimentalJsExport::class)

package com.apergas.rpg.web

import com.apergas.rpg.di.GameContainer
import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.ForestIntent
import com.apergas.rpg.presentation.forest.ForestLabels
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * The shared ForestViewModel, exposed to the web with plain JS types. The Phaser scene calls it every
 * frame: `tick`, then `takeEffects` to play animations, then `state` to draw.
 */
@JsExport
class ForestWebController {
    private val viewModel = GameContainer.makeForestViewModel()
    private val pendingEffects = mutableListOf<ForestEffect>()

    init {
        // Unconfined: effects are collected synchronously, in the same call that emits them.
        CoroutineScope(Dispatchers.Unconfined).launch { viewModel.uiEffect.collect { pendingEffects += it } }
    }

    fun tick(deltaMs: Double) = viewModel.onIntent(ForestIntent.Tick(deltaMs))

    fun mapClicked(x: Double, y: Double, treeId: String?, isSecondary: Boolean) =
        viewModel.onIntent(ForestIntent.MapClicked(Position(x, y), treeId, isSecondary))

    fun pointerMoved(x: Double, y: Double) = viewModel.onIntent(ForestIntent.PointerMoved(Position(x, y)))

    fun requestBuild(blueprint: String) = viewModel.onIntent(ForestIntent.BuildRequested(BlueprintId.valueOf(blueprint)))

    fun cancelPlacement() = viewModel.onIntent(ForestIntent.PlacementCancelled)

    fun state(): WebState = viewModel.uiState.value.toWeb()

    fun world(): WebWorld = viewModel.worldSnapshot().toWeb()

    /** Effects emitted since the previous call, oldest first. */
    fun takeEffects(): Array<WebEffect> {
        val effects = pendingEffects.map { it.toWeb() }.toTypedArray()
        pendingEffects.clear()
        return effects
    }

    fun labels(): WebLabels = WebLabels(ForestLabels.WOOD, ForestLabels.AXE, ForestLabels.BUILD, ForestLabels.QUESTS)
}
