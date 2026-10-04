package com.apergas.rpg.domain.errors

fun interface ErrorHandler {
    fun handle(error: Throwable): AppError
}
