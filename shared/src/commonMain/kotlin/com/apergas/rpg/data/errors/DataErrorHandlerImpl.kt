package com.apergas.rpg.data.errors

import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.errors.ErrorHandler

/** Controlled errors pass through; anything else becomes a general error. */
class DataErrorHandlerImpl : ErrorHandler {
    override fun handle(error: Throwable): AppError = error as? AppError ?: AppError.GeneralError(error)
}
