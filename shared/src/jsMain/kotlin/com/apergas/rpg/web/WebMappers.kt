package com.apergas.rpg.web

import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.ForestState
import com.apergas.rpg.presentation.forest.PlayerPose
import com.apergas.rpg.presentation.forest.QuestItemStatus
import com.apergas.rpg.presentation.forest.SpriteNames
import com.apergas.rpg.presentation.forest.WorkTool

internal fun Position.toWeb() = WebPoint(x, y)

internal fun Building.toWeb() = WebBuilding(id, blueprint.id.name, position.toWeb(), progress)

internal fun WorldSnapshot.toWeb() = WebWorld(
    width = width,
    height = height,
    trees = trees.map { WebTree(it.id, SpriteNames.tree(it.kind), it.position.toWeb()) }.toTypedArray(),
    items = items.map { WebItem(it.id, it.kind.name.lowercase(), it.position.toWeb()) }.toTypedArray(),
    decorations = decorations.map { WebDecoration(it.id, SpriteNames.decoration(it.kind), it.position.toWeb()) }.toTypedArray(),
    buildings = buildings.map { it.toWeb() }.toTypedArray(),
)

internal fun ForestState.toWeb(): WebState {
    val pose = player.pose
    return WebState(
        player = WebPlayer(
            position = player.position.toWeb(),
            facing = player.facing.name.lowercase(),
            pose = when (pose) {
                is PlayerPose.Idle -> "idle"
                is PlayerPose.Walk -> "walk"
                is PlayerPose.Work -> "work"
            },
            withAxe = when (pose) {
                is PlayerPose.Idle -> pose.withAxe
                is PlayerPose.Walk -> pose.withAxe
                is PlayerPose.Work -> pose.tool == WorkTool.Axe
            },
            tool = (pose as? PlayerPose.Work)?.tool?.name?.lowercase(),
            swingProgress = (pose as? PlayerPose.Work)?.swingProgress ?: 0.0,
        ),
        hud = WebHud(
            wood = hud.wood,
            hasAxe = hud.hasAxe,
            questBadge = hud.questBadge,
            quests = hud.quests.map {
                WebQuestItem(it.title, it.progressText, when (it.status) {
                    QuestItemStatus.Done -> "done"
                    QuestItemStatus.Current -> "current"
                    QuestItemStatus.Pending -> "pending"
                })
            }.toTypedArray(),
            buildItems = hud.buildItems.map {
                WebBuildItem(it.blueprint.name, it.name, it.costText, it.missingText, it.isEnabled)
            }.toTypedArray(),
            isBuildLocked = hud.isBuildLocked,
        ),
        placement = placement?.let { WebPlacement(it.blueprint.name, it.position.toWeb(), it.isValid) },
    )
}

internal fun ForestEffect.toWeb(): WebEffect = when (this) {
    is ForestEffect.ItemPickedUp -> WebEffect("item-picked-up", itemId, 0.0, 0.0, null, null)
    is ForestEffect.TreeHit -> WebEffect("tree-hit", treeId, fromX, 0.0, null, null)
    is ForestEffect.TreeFelled -> WebEffect("tree-felled", treeId, fromX, 0.0, null, null)
    is ForestEffect.BuildingPlaced -> WebEffect("building-placed", building.id, 0.0, building.progress, null, building.toWeb())
    is ForestEffect.BuildingHammered -> WebEffect("building-hammered", buildingId, 0.0, progress, null, null)
    is ForestEffect.BuildingCompleted -> WebEffect("building-completed", buildingId, 0.0, 1.0, null, null)
    is ForestEffect.ShowMessage -> WebEffect("message", null, 0.0, 0.0, text, null)
}
