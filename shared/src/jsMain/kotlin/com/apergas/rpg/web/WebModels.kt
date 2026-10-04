@file:OptIn(ExperimentalJsExport::class)

package com.apergas.rpg.web

@JsExport class WebPoint(val x: Double, val y: Double)

@JsExport class WebState(val player: WebPlayer, val hud: WebHud, val placement: WebPlacement?)

@JsExport class WebPlayer(
    val position: WebPoint,
    val facing: String,
    val pose: String,
    val withAxe: Boolean,
    val tool: String?,
    val swingProgress: Double,
)

@JsExport class WebHud(
    val wood: Int,
    val hasAxe: Boolean,
    val questBadge: String,
    val quests: Array<WebQuestItem>,
    val buildItems: Array<WebBuildItem>,
    val isBuildLocked: Boolean,
)

@JsExport class WebQuestItem(val title: String, val progressText: String, val status: String)

@JsExport class WebBuildItem(
    val blueprint: String,
    val name: String,
    val costText: String,
    val missingText: String?,
    val isEnabled: Boolean,
)

@JsExport class WebPlacement(val blueprint: String, val position: WebPoint, val isValid: Boolean)

@JsExport class WebWorld(
    val width: Double,
    val height: Double,
    val trees: Array<WebTree>,
    val items: Array<WebItem>,
    val decorations: Array<WebDecoration>,
    val buildings: Array<WebBuilding>,
)

@JsExport class WebTree(val id: String, val frame: String, val position: WebPoint)

@JsExport class WebDecoration(val id: String, val frame: String, val position: WebPoint)

@JsExport class WebItem(val id: String, val kind: String, val position: WebPoint)

@JsExport class WebBuilding(val id: String, val blueprint: String, val position: WebPoint, val progress: Double)

@JsExport class WebEffect(
    val kind: String,
    val id: String?,
    val fromX: Double,
    val progress: Double,
    val text: String?,
    val building: WebBuilding?,
)

@JsExport class WebLabels(val wood: String, val axe: String, val build: String, val quests: String)
