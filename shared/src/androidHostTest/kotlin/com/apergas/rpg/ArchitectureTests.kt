package com.apergas.rpg

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals

class ArchitectureTests {
    private val root = File("src/commonMain/kotlin/com/apergas/rpg")

    private fun importsUnder(folder: String): List<Pair<String, String>> =
        File(root, folder).walkTopDown().filter { it.extension == "kt" }.flatMap { file ->
            file.readLines().filter { it.startsWith("import ") }.map { file.relativeTo(root).path to it.removePrefix("import ").trim() }
        }.toList()

    private fun violations(folder: String, forbidden: Regex): List<String> =
        importsUnder(folder).filter { (_, import) -> forbidden.containsMatchIn(import) }.map { (file, import) -> "$file -> $import" }

    @Test
    fun testWhenCheckingDomainThenItImportsNothingFromDataPresentationOrPlatforms() {
        // given
        val forbidden = Regex("""^com\.apergas\.rpg\.(data|presentation|di)\.|^android\.|^platform\.|^kotlin\.js\.""")

        // when
        val found = violations("domain", forbidden)

        // then
        assertEquals(emptyList(), found)
    }

    @Test
    fun testWhenCheckingDataThenItNeverImportsPresentation() {
        // given
        val forbidden = Regex("""^com\.apergas\.rpg\.(presentation|di)\.""")

        // when
        val found = violations("data", forbidden)

        // then
        assertEquals(emptyList(), found)
    }

    @Test
    fun testWhenCheckingPresentationThenItNeverImportsData() {
        // given
        val forbidden = Regex("""^com\.apergas\.rpg\.data\.""")

        // when
        val found = violations("presentation", forbidden)

        // then
        assertEquals(emptyList(), found)
    }

    @Test
    fun testWhenCheckingEntitiesThenTheyAreImmutable() {
        // given
        val entityFiles = File(root, "domain/entities").walkTopDown().filter { it.extension == "kt" }

        // when
        val mutable = entityFiles.filter { file -> file.readLines().any { it.trimStart().startsWith("var ") || it.contains(" var ") } }
            .map { it.relativeTo(root).path }.toList()

        // then
        assertEquals(emptyList(), mutable)
    }
}
