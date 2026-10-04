package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.LevelDto

interface LevelLocalDataSource {
    fun fetch(): LevelDto
}
