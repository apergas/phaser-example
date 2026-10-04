package com.apergas.rpg.data.repositories.level

import com.apergas.rpg.data.datasources.local.level.dto.DecorationDto
import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.TreeKind
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.rules.Rules
import com.apergas.rpg.domain.world.World

internal fun LevelDto.toDomain(): World = World(
    width = width ?: throw AppError.LevelError.InvalidLevel("missing width"),
    height = height ?: throw AppError.LevelError.InvalidLevel("missing height"),
    player = Player(
        position = playerStart?.toDomain() ?: throw AppError.LevelError.InvalidLevel("missing player start"),
        speed = Rules.PLAYER_SPEED,
        radius = Rules.PLAYER_RADIUS,
    ),
    trees = trees.orEmpty().mapIndexed { index, tree -> tree.toDomain(index) },
    items = items.orEmpty().map { it.toDomain() },
    decorations = decorations.orEmpty().mapIndexed { index, decoration -> decoration.toDomain(index) },
)

/** "tall-grass" -> TallGrass: level data uses lower-case kebab names. */
private fun <T : Enum<T>> List<T>.byKebabName(name: String?): T? =
    firstOrNull { entry -> entry.name.replace(Regex("(?<!^)([A-Z])"), "-$1").lowercase() == name }

internal fun PointDto.toDomain(): Position = Position(x ?: 0.0, y ?: 0.0)

internal fun TreeDto.toDomain(index: Int): Tree {
    val treeId = id ?: "tree-${index + 1}"
    return Tree(
        id = treeId,
        kind = TreeKind.entries.byKebabName(kind) ?: throw AppError.LevelError.UnknownTreeKind(treeId, kind.orEmpty()),
        position = Position(x ?: 0.0, y ?: 0.0),
        trunkRadius = Rules.TREE_TRUNK_RADIUS,
        woodYield = wood ?: 0,
        hitsToFell = Rules.HITS_TO_FELL_TREE,
    )
}

internal fun DecorationDto.toDomain(index: Int): Decoration {
    val decorationId = id ?: "decoration-${index + 1}"
    return Decoration(
        id = decorationId,
        kind = DecorationKind.entries.byKebabName(kind)
            ?: throw AppError.LevelError.UnknownDecorationKind(decorationId, kind.orEmpty()),
        position = Position(x ?: 0.0, y ?: 0.0),
    )
}

internal fun ItemDto.toDomain(): GroundItem {
    val itemId = id.orEmpty()
    val tool = ToolKind.entries.firstOrNull { it.name.equals(kind, ignoreCase = true) }
        ?: throw AppError.LevelError.UnknownItemKind(itemId, kind.orEmpty())
    return GroundItem(id = itemId, kind = tool, position = Position(x ?: 0.0, y ?: 0.0))
}
