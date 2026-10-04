package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.DecorationDto
import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto
import com.apergas.rpg.util.SeededRandom
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.hypot

private const val WIDTH = 1600.0
private const val HEIGHT = 1200.0
private const val TREE_COUNT = 70
private const val MIN_TREE_SPACING = 120.0
/** Canopies are tall and drawn above the trunk, so trees near the spawn would hide the player and the axe. */
private const val SPAWN_CLEARANCE = 200.0
private const val BORDER_MARGIN = 60.0
private const val MIN_WOOD = 5
private const val MAX_WOOD = 6
private const val TREE_SEED = 42L
/** Same seed and order the web view used to pick tree sprites, so the forest keeps its look. */
private const val TREE_KIND_SEED = 7L
/** Kinds in the order of TreeKind (domain); the generator indexes this list. */
private val TREE_KINDS = listOf(
    "slim", "round", "wide", "broad", "twisted", "branches", "leaning",
    "lumpy", "pine", "dome", "oak", "dense", "old", "big",
)
private const val DECORATION_SEED = 1337L
private const val DECORATION_ATTEMPTS = 107
private const val DECORATION_SPACING = 32.0
/** Repeated names weight the pick: mostly greenery, the odd rock or mushroom. */
private val DECORATION_KINDS = listOf("tall-grass", "tall-grass", "tall-grass", "leaves", "leaves", "mushrooms", "rock")
/** Area a tree covers on screen around its trunk base (canopy above, roots below), kept free of decoration. */
private const val TREE_HALF_WIDTH = 64.0
private const val TREE_HEIGHT = 170.0
private const val TREE_ROOTS = 20.0
/** Area around the spawn point kept free of decoration (same box the web used). */
private const val SPAWN_HALF_WIDTH = 48.0
private const val SPAWN_ABOVE = 96.0
private const val SPAWN_BELOW = 48.0
private val PLAYER_START = PointDto(WIDTH / 2, HEIGHT / 2)
/** Close to the spawn point, so it is the first thing the player finds. */
private val AXE = ItemDto(id = "axe", kind = "axe", x = WIDTH / 2 + 56, y = HEIGHT / 2 + 8)

/** A forest generated from fixed seeds: the same layout on every run and on every platform. */
class LevelLocalDataSourceImpl : LevelLocalDataSource {
    override fun fetch(): LevelDto {
        val trees = scatterTrees()
        return LevelDto(
            width = WIDTH,
            height = HEIGHT,
            playerStart = PLAYER_START,
            trees = trees,
            items = listOf(AXE),
            decorations = scatterDecorations(trees),
        )
    }

    /** Random but reproducible spots, trees kept apart from each other and away from the spawn. */
    private fun scatterTrees(): List<TreeDto> {
        val random = SeededRandom(TREE_SEED)
        val kinds = SeededRandom(TREE_KIND_SEED)
        val trees = mutableListOf<TreeDto>()
        val start = PLAYER_START

        var attempt = 0
        while (attempt < TREE_COUNT * 50 && trees.size < TREE_COUNT) {
            attempt++
            val x = BORDER_MARGIN + random.next() * (WIDTH - BORDER_MARGIN * 2)
            val y = BORDER_MARGIN + random.next() * (HEIGHT - BORDER_MARGIN * 2)
            val clearOfSpawn = hypot(x - start.x!!, y - start.y!!) >= SPAWN_CLEARANCE
            val apart = trees.all { hypot(x - it.x!!, y - it.y!!) >= MIN_TREE_SPACING }
            if (clearOfSpawn && apart) {
                val wood = MIN_WOOD + floor(random.next() * (MAX_WOOD - MIN_WOOD + 1)).toInt()
                val kind = TREE_KINDS[floor(kinds.next() * TREE_KINDS.size).toInt()]
                trees += TreeDto(id = "tree-${trees.size + 1}", kind = kind, x = x, y = y, wood = wood)
            }
        }
        return trees
    }

    /** Non-solid ground decoration, kept off the trees, the spawn point, the axe and each other. */
    private fun scatterDecorations(trees: List<TreeDto>): List<DecorationDto> {
        val random = SeededRandom(DECORATION_SEED)
        val decorations = mutableListOf<DecorationDto>()

        val spawnX = PLAYER_START.x!!
        val spawnY = PLAYER_START.y!!

        fun isFree(x: Double, y: Double): Boolean {
            val underTree = trees.any { tree ->
                val treeX = tree.x!!
                val treeY = tree.y!!
                abs(x - treeX) < TREE_HALF_WIDTH && y > treeY - TREE_HEIGHT && y < treeY + TREE_ROOTS
            }
            val onSpawn = abs(x - spawnX) < SPAWN_HALF_WIDTH && y > spawnY - SPAWN_ABOVE && y < spawnY + SPAWN_BELOW
            val onAxe = hypot(x - AXE.x!!, y - AXE.y!!) < DECORATION_SPACING
            val crowded = decorations.any { hypot(x - it.x!!, y - it.y!!) < DECORATION_SPACING }
            return !underTree && !onSpawn && !onAxe && !crowded
        }

        repeat(DECORATION_ATTEMPTS) {
            val kind = DECORATION_KINDS[floor(random.next() * DECORATION_KINDS.size).toInt()]
            for (placement in 0 until 20) {
                val x = random.next() * WIDTH
                val y = random.next() * HEIGHT
                if (isFree(x, y)) {
                    decorations += DecorationDto(id = "decoration-${decorations.size + 1}", kind = kind, x = x, y = y)
                    break
                }
            }
        }
        return decorations
    }
}
