package com.apergas.rpg.android.presentation.forest.world

import androidx.compose.runtime.mutableStateMapOf
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.SpriteNames

data class SceneTree(val id: String, val base: Position, val frame: String, val hitAtNanos: Long? = null, val fromX: Double = 0.0, val felledAtNanos: Long? = null)
data class SceneBuilding(val id: String, val center: Position, val progress: Double, val completedAtNanos: Long? = null)
data class SceneDecoration(val id: String, val position: Position, val frame: String)

/**
 * What is drawn in the world beyond the player: built from the initial snapshot and kept up to date
 * by the view model's effects, exactly like the web scene.
 */
class WorldSceneState(snapshot: WorldSnapshot) {
    val width = snapshot.width
    val height = snapshot.height
    val trees = mutableStateMapOf<String, SceneTree>()
    val items = mutableStateMapOf<String, Position>()
    val buildings = mutableStateMapOf<String, SceneBuilding>()
    val stumps = mutableStateMapOf<String, Position>()
    val decorations = mutableStateMapOf<String, SceneDecoration>()

    init {
        // What to draw and where comes from the level (shared): no art decisions are made here.
        snapshot.trees.forEach { tree -> trees[tree.id] = SceneTree(tree.id, tree.position, SpriteNames.tree(tree.kind)) }
        snapshot.decorations.forEach { decoration ->
            decorations[decoration.id] = SceneDecoration(decoration.id, decoration.position, SpriteNames.decoration(decoration.kind))
        }
        snapshot.items.forEach { items[it.id] = it.position }
        snapshot.buildings.forEach { buildings[it.id] = it.toScene() }
    }

    fun play(effect: ForestEffect, nowNanos: Long) {
        when (effect) {
            is ForestEffect.ItemPickedUp -> items.remove(effect.itemId)
            is ForestEffect.TreeHit -> trees.computeIfPresent(effect.treeId) { _, tree -> tree.copy(hitAtNanos = nowNanos, fromX = effect.fromX) }
            is ForestEffect.TreeFelled -> trees[effect.treeId]?.let { tree ->
                trees[tree.id] = tree.copy(felledAtNanos = nowNanos, fromX = effect.fromX)
                stumps[tree.id] = tree.base
            }
            is ForestEffect.BuildingPlaced -> {
                buildings[effect.building.id] = effect.building.toScene()
                val radius = effect.building.blueprint.footprintRadius + 24
                stumps.filterValues { base -> base.distanceTo(effect.building.position) < radius }.keys.forEach(stumps::remove)
                decorations.filterValues { it.position.distanceTo(effect.building.position) < radius }.keys.forEach(decorations::remove)
            }
            is ForestEffect.BuildingHammered -> buildings.computeIfPresent(effect.buildingId) { _, b -> b.copy(progress = effect.progress) }
            is ForestEffect.BuildingCompleted -> buildings.computeIfPresent(effect.buildingId) { _, b -> b.copy(progress = 1.0, completedAtNanos = nowNanos) }
            is ForestEffect.ShowMessage -> Unit
        }
    }

    /** Removes trees whose fall animation has finished. */
    fun prune(nowNanos: Long) {
        trees.values.filter { it.felledAtNanos != null && nowNanos - it.felledAtNanos > FALL_NANOS }.forEach { trees.remove(it.id) }
    }

    /** The tree drawn on top at this world point, pixel-accurate, or null. */
    fun treeAt(point: Position, assets: LpcAssets): String? =
        trees.values.filter { it.felledAtNanos == null }.sortedByDescending { it.base.y }.firstOrNull { tree ->
            val frame = assets.frames.getValue(tree.frame)
            val left = tree.base.x - frame.width * frame.pivotX
            val top = tree.base.y - frame.height * frame.pivotY
            assets.isOpaque(frame, (point.x - left).toInt(), (point.y - top).toInt())
        }?.id

    private fun Building.toScene() = SceneBuilding(id, position, progress)

    companion object {
        const val FALL_NANOS = 700_000_000L
    }
}
