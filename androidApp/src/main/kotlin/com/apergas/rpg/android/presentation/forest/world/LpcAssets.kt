package com.apergas.rpg.android.presentation.forest.world

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap

/** Every LPC texture the forest screen draws, loaded once from assets/lpc. */
class LpcAssets(context: Context) {
    private val assetManager: AssetManager = context.assets

    private fun bitmap(name: String): Bitmap =
        assetManager.open("lpc/$name").use { BitmapFactory.decodeStream(it) }

    val forestPixels: Bitmap = bitmap("forest.png")
    val forest: ImageBitmap = forestPixels.asImageBitmap()
    val frames: Map<String, AtlasFrame> =
        AtlasParser.parse(assetManager.open("lpc/forest.json").bufferedReader().use { it.readText() })
    val ground: ImageBitmap = bitmap("ground.png").asImageBitmap()
    val heroWalk: ImageBitmap = bitmap("hero-walk.png").asImageBitmap()
    val heroIdle: ImageBitmap = bitmap("hero-idle.png").asImageBitmap()
    val heroWalkAxe: ImageBitmap = bitmap("hero-walk-axe.png").asImageBitmap()
    val heroIdleAxe: ImageBitmap = bitmap("hero-idle-axe.png").asImageBitmap()
    val heroChop: ImageBitmap = bitmap("hero-chop.png").asImageBitmap()
    val heroHammer: ImageBitmap = bitmap("hero-hammer.png").asImageBitmap()

    /** Pixel-accurate hit test on an atlas frame, in frame-local coordinates. */
    fun isOpaque(frame: AtlasFrame, localX: Int, localY: Int): Boolean {
        if (localX !in 0 until frame.width || localY !in 0 until frame.height) return false
        return (forestPixels.getPixel(frame.x + localX, frame.y + localY) ushr 24) >= SOLID_ALPHA
    }

    private companion object {
        /** Same threshold as the web: the painted tree shadow is fainter. */
        const val SOLID_ALPHA = 200
    }
}
