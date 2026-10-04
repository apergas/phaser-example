package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.geometry.Position

/** What the gameplay screen draws every frame. */
data class ForestState(
    val player: PlayerRenderState,
    val hud: HudState,
    /** A building being positioned with the pointer before it is ordered, if any. */
    val placement: Placement?,
)

data class PlayerRenderState(val position: Position, val facing: Facing, val pose: PlayerPose)

enum class Facing { Up, Left, Down, Right }

sealed interface PlayerPose {
    data class Idle(val withAxe: Boolean) : PlayerPose
    data class Walk(val withAxe: Boolean) : PlayerPose
    data class Work(val tool: WorkTool, val swingProgress: Double) : PlayerPose
}

enum class WorkTool { Axe, Hammer }

/** Display-ready HUD content: texts already formatted. */
data class HudState(
    val wood: Int,
    val hasAxe: Boolean,
    val questBadge: String,
    val quests: List<QuestItem>,
    val buildItems: List<BuildItem>,
    /** The build menu is locked while a building is being placed. */
    val isBuildLocked: Boolean,
)

data class QuestItem(val title: String, val progressText: String, val status: QuestItemStatus)

enum class QuestItemStatus { Done, Current, Pending }

data class BuildItem(
    val blueprint: BlueprintId,
    val name: String,
    val costText: String,
    val missingText: String?,
    val isEnabled: Boolean,
)

data class Placement(val blueprint: BlueprintId, val position: Position, val isValid: Boolean)

sealed interface ForestIntent {
    data class Tick(val deltaMs: Double) : ForestIntent
    /** [treeId] is the tree drawn under the pointer, if any: hit-testing sprites is the view's job. */
    data class MapClicked(val position: Position, val treeId: String?, val isSecondary: Boolean = false) : ForestIntent
    data class PointerMoved(val position: Position) : ForestIntent
    data class BuildRequested(val blueprint: BlueprintId) : ForestIntent
    data object PlacementCancelled : ForestIntent
}

/** One-off reactions the view plays once: animations, particles and messages. */
sealed interface ForestEffect {
    data class ItemPickedUp(val itemId: String) : ForestEffect
    data class TreeHit(val treeId: String, val fromX: Double) : ForestEffect
    data class TreeFelled(val treeId: String, val fromX: Double) : ForestEffect
    data class BuildingPlaced(val building: Building) : ForestEffect
    data class BuildingHammered(val buildingId: String, val progress: Double) : ForestEffect
    data class BuildingCompleted(val buildingId: String) : ForestEffect
    data class ShowMessage(val text: String) : ForestEffect
}
