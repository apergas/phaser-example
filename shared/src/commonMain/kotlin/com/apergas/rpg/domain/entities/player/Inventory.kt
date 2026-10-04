package com.apergas.rpg.domain.entities.player

/** What the player carries: stored wood and the tools it has picked up. */
data class Inventory(val wood: Int = 0, val tools: Set<ToolKind> = emptySet()) {
    fun addWood(amount: Int): Inventory {
        require(amount >= 0) { "Cannot add a negative amount of wood" }
        return copy(wood = wood + amount)
    }

    /** The inventory after paying [amount], or null when there is not enough wood. */
    fun spendWood(amount: Int): Inventory? = if (amount > wood) null else copy(wood = wood - amount)

    fun addTool(tool: ToolKind): Inventory = copy(tools = tools + tool)

    fun hasTool(tool: ToolKind): Boolean = tool in tools
}
