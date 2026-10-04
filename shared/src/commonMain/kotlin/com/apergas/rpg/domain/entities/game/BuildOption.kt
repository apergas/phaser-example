package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.BlueprintId

data class BuildOption(val blueprint: BlueprintId, val woodCost: Int, val isAffordable: Boolean)
