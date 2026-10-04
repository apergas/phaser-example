package com.apergas.rpg.android.presentation.forest.world

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.Facing
import com.apergas.rpg.presentation.forest.Placement
import com.apergas.rpg.presentation.forest.PlayerPose
import com.apergas.rpg.presentation.forest.PlayerRenderState
import com.apergas.rpg.presentation.forest.WorkTool
import kotlin.math.exp
import kotlin.math.min
import kotlin.math.sin

const val CAMERA_ZOOM = 2f
private const val HOUSE_FRONT_OFFSET = 24.0
private val FACING_ROWS = listOf(Facing.Up, Facing.Left, Facing.Down, Facing.Right)
private val CHOP_SEQUENCE = listOf(0, 0, 5, 5, 4, 4, 3, 1)
private val HAMMER_SEQUENCE = listOf(0, 0, 5, 5, 4, 4, 1)

/** Top-left world point shown on screen: the camera follows the player and stays inside the world. */
fun cameraOrigin(player: Position, scene: WorldSceneState, viewport: Size): Offset {
    val viewWidth = viewport.width / CAMERA_ZOOM
    val viewHeight = viewport.height / CAMERA_ZOOM
    fun axis(center: Double, world: Double, view: Float): Float =
        if (view >= world) ((world - view) / 2).toFloat()
        else (center - view / 2).coerceIn(0.0, world - view).toFloat()
    return Offset(axis(player.x, scene.width, viewWidth), axis(player.y, scene.height, viewHeight))
}

@Composable
fun WorldCanvas(
    scene: WorldSceneState,
    player: PlayerRenderState,
    placement: Placement?,
    assets: LpcAssets,
    frameNanos: Long,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        // Snapped to whole screen pixels, like Phaser's pixelArt rounding: a fractional offset leaves seams between tiles.
        val origin = cameraOrigin(player.position, scene, size).let { Offset(snap(it.x), snap(it.y)) }
        withTransform({
            scale(CAMERA_ZOOM, CAMERA_ZOOM, pivot = Offset.Zero)
            translate(-origin.x, -origin.y)
        }) {
            drawGround(scene, assets)
            val drawables = buildList<Pair<Double, DrawScope.() -> Unit>> {
                scene.decorations.values.forEach { decoration -> add(decoration.position.y to { drawFrame(assets, decoration.frame, decoration.position) }) }
                scene.stumps.values.forEach { base -> add(base.y - 1 to { drawFrame(assets, "stump", base) }) }
                scene.items.values.forEach { position -> add(position.y to { drawFrame(assets, "axe-pickup", Position(position.x, position.y - 8)) }) }
                scene.trees.values.forEach { tree -> add(tree.base.y to { drawTree(assets, tree, frameNanos) }) }
                scene.buildings.values.forEach { building ->
                    add(building.center.y + HOUSE_FRONT_OFFSET to { drawHouse(assets, building.center, 0.35f + 0.65f * building.progress.toFloat()) })
                }
                add(player.position.y to { drawPlayer(assets, player, frameNanos) })
            }
            drawables.sortedBy { it.first }.forEach { (_, draw) -> draw() }
            placement?.let { ghost ->
                val tint = if (ghost.isValid) Color(0xFFB8FFB8) else Color(0xFFFF8080)
                drawHouse(assets, ghost.position, 0.6f, ColorFilter.tint(tint, androidx.compose.ui.graphics.BlendMode.Modulate))
            }
        }
    }
}

private fun snap(world: Float): Float = kotlin.math.round(world * CAMERA_ZOOM) / CAMERA_ZOOM

private fun DrawScope.drawGround(scene: WorldSceneState, assets: LpcAssets) {
    val tile = 32
    var y = 0
    while (y < scene.height) {
        var x = 0
        while (x < scene.width) {
            drawImage(assets.ground, srcOffset = IntOffset.Zero, srcSize = IntSize(tile, tile), dstOffset = IntOffset(x, y), dstSize = IntSize(tile, tile), filterQuality = FilterQuality.None)
            x += tile
        }
        y += tile
    }
}

private fun DrawScope.drawFrame(assets: LpcAssets, name: String, anchor: Position, alpha: Float = 1f, colorFilter: ColorFilter? = null) {
    val frame = assets.frames.getValue(name)
    val left = (anchor.x - frame.width * frame.pivotX).toInt()
    val top = (anchor.y - frame.height * frame.pivotY).toInt()
    drawImage(
        assets.forest,
        srcOffset = IntOffset(frame.x, frame.y),
        srcSize = IntSize(frame.width, frame.height),
        dstOffset = IntOffset(left, top),
        dstSize = IntSize(frame.width, frame.height),
        alpha = alpha,
        colorFilter = colorFilter,
        filterQuality = FilterQuality.None,
    )
}

/** Shake for 140 ms after a hit; fall away from the player and fade out over 700 ms. */
private fun DrawScope.drawTree(assets: LpcAssets, tree: SceneTree, now: Long) {
    val awayFromPlayer = if (tree.fromX < tree.base.x) 1f else -1f
    val pivot = Offset(tree.base.x.toFloat(), tree.base.y.toFloat())
    val felledAt = tree.felledAtNanos
    if (felledAt != null) {
        val t = min(1f, (now - felledAt) / WorldSceneState.FALL_NANOS.toFloat())
        rotate(85f * awayFromPlayer * t * t, pivot) { drawFrame(assets, tree.frame, tree.base, alpha = 1f - t) }
        return
    }
    val hitAt = tree.hitAtNanos
    val shake = if (hitAt == null) 0f else {
        val t = (now - hitAt) / 1_000_000f
        if (t > 140f) 0f else 3f * awayFromPlayer * sin(t / 140f * Math.PI.toFloat()) * exp(-t / 200f)
    }
    rotate(shake, pivot) { drawFrame(assets, tree.frame, tree.base) }
}

private fun DrawScope.drawHouse(assets: LpcAssets, center: Position, alpha: Float, colorFilter: ColorFilter? = null) =
    drawFrame(assets, "house", Position(center.x, center.y + HOUSE_FRONT_OFFSET), alpha, colorFilter)

private fun DrawScope.drawPlayer(assets: LpcAssets, player: PlayerRenderState, now: Long) {
    val row = FACING_ROWS.indexOf(player.facing)
    val (sheet, cell, column, originY) = when (val pose = player.pose) {
        is PlayerPose.Work -> {
            val sequence = if (pose.tool == WorkTool.Axe) CHOP_SEQUENCE else HAMMER_SEQUENCE
            val step = min(sequence.size - 1, (pose.swingProgress * sequence.size).toInt())
            SheetFrame(if (pose.tool == WorkTool.Axe) assets.heroChop else assets.heroHammer, 128, sequence[step], 94f / 128)
        }
        is PlayerPose.Walk -> SheetFrame(if (pose.withAxe) assets.heroWalkAxe else assets.heroWalk, 64, 1 + ((now / 100_000_000L) % 8).toInt(), 62f / 64)
        is PlayerPose.Idle -> SheetFrame(if (pose.withAxe) assets.heroIdleAxe else assets.heroIdle, 64, ((now / 500_000_000L) % 2).toInt(), 62f / 64)
    }
    drawOval(Color(0x4D000000), topLeft = Offset(player.position.x.toFloat() - 11, player.position.y.toFloat() - 4.5f), size = Size(22f, 7f))
    drawImage(
        sheet,
        srcOffset = IntOffset(column * cell, row * cell),
        srcSize = IntSize(cell, cell),
        dstOffset = IntOffset((player.position.x - cell / 2).toInt(), (player.position.y - cell * originY).toInt()),
        dstSize = IntSize(cell, cell),
        filterQuality = FilterQuality.None,
    )
}

private data class SheetFrame(val sheet: ImageBitmap, val cell: Int, val column: Int, val originY: Float)
