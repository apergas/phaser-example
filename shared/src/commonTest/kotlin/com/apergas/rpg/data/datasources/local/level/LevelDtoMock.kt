package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.DecorationDto
import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto

val LevelDto.Companion.mock: LevelDto
    get() = LevelDto(
        width = 400.0,
        height = 300.0,
        playerStart = PointDto(200.0, 150.0),
        trees = listOf(TreeDto(id = "tree-a", kind = "oak", x = 50.0, y = 60.0, wood = 5)),
        items = listOf(ItemDto(id = "axe", kind = "axe", x = 220.0, y = 150.0)),
        decorations = listOf(DecorationDto(id = "decoration-a", kind = "tall-grass", x = 300.0, y = 200.0)),
    )

val LevelDto.Companion.mockWithUnknownItem: LevelDto
    get() = mock.copy(items = listOf(ItemDto(id = "mystery", kind = "laser", x = 0.0, y = 0.0)))

val LevelDto.Companion.mockWithoutSize: LevelDto
    get() = mock.copy(width = null)

val LevelDto.Companion.mockWithUnknownTreeKind: LevelDto
    get() = mock.copy(trees = listOf(TreeDto(id = "tree-x", kind = "palm", x = 0.0, y = 0.0, wood = 5)))
