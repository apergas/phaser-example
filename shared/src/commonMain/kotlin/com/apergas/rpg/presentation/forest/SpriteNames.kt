package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.tree.TreeKind

/** Atlas frame names (forest.json) for what the level places. Shared so every app draws the same art. */
object SpriteNames {
    fun tree(kind: TreeKind): String = "tree-${kebab(kind.name)}"
    fun decoration(kind: DecorationKind): String = "decor-${kebab(kind.name)}"

    private fun kebab(name: String): String = name.replace(Regex("(?<!^)([A-Z])"), "-$1").lowercase()
}
