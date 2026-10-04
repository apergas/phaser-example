package com.apergas.rpg.domain.errors

/** Base of every controlled error; nothing else reaches the presentation layer. */
sealed class AppError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class GeneralError(cause: Throwable? = null) : AppError("Something went wrong", cause)

    sealed class LevelError(message: String) : AppError(message) {
        class UnknownItemKind(val itemId: String, val kind: String) :
            LevelError("Level item \"$itemId\" has an unknown kind: \"$kind\"")

        class UnknownTreeKind(val treeId: String, val kind: String) :
            LevelError("Level tree \"$treeId\" has an unknown kind: \"$kind\"")

        class UnknownDecorationKind(val decorationId: String, val kind: String) :
            LevelError("Level decoration \"$decorationId\" has an unknown kind: \"$kind\"")

        class InvalidLevel(reason: String) : LevelError("Invalid level: $reason")
    }
}
