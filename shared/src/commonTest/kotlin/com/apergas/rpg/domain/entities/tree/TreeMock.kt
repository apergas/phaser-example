package com.apergas.rpg.domain.entities.tree

import com.apergas.rpg.domain.entities.geometry.Position

val Tree.Companion.mock: Tree
    get() = Tree(id = "tree-1", kind = TreeKind.Oak, position = Position(200.0, 100.0), trunkRadius = 10.0, woodYield = 6, hitsToFell = 5)
