package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.LevelDto

class LevelLocalDataSourceMock : LevelLocalDataSource {
    var error: Throwable? = null
    var levelDto: LevelDto = LevelDto.mock
    var fetchCalled = false

    override fun fetch(): LevelDto {
        fetchCalled = true
        error?.let { throw it }
        return levelDto
    }
}
