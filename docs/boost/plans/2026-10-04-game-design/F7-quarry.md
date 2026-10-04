# F7 · Cantera — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F5 (piedra) y F6 (entregas) |
| **Issue / milestone** | `phase:F7` · milestone `F7 Quarry` |

## Objetivo

Añadir la primera **regla de colocación** propia de un edificio, y un edificio cuya función depende del terreno.

## Decisiones ya tomadas

**Cantera** (`BlueprintId.Quarry`):
- Cuesta 25 de madera.
- **Sólo se puede colocar** a menos de `Rules.QUARRY_ROCK_RANGE` (≈ 120 u) de una roca que no esté rota.

**Reglas de colocación:**
- `Blueprint` gana `placementRule: PlacementRule`, una `sealed interface` con dos casos: `Anywhere` y `NearRock(range)`.
- `Construction.canPlace` evalúa la regla.
- El motivo del rechazo se expone como `ConstructionRejection.NeedsNearbyRock`.
- `Placement` gana `invalidReason`, para explicar el porqué mientras se coloca (`ForestLabels.Placement.needsRock`).

**Funciones:**
- Es punto de entrega de **piedra**. Los almacenes de F6 aceptan todo; la cantera, sólo piedra.
- Picar a menos de `QUARRY_BOOST_RANGE` de una cantera terminada es un 30 % más rápido. Para ello, `Mining.intervalMs` pasa a depender del estado.

**Arte:** frame `quarry`, montado en `build_assets.py` con rocas de `terrain_atlas` y un tejadillo o una valla, todo con piezas existentes.

## Ficheros previstos

- **Dominio:** `Blueprint.kt`, `PlacementRule.kt` (nuevo), `Construction.kt`, `Mining.kt`, `Depositing.kt`, `Rules.kt`.
- **Contrato y presentación:** `ConstructionResult.kt`, `ForestContract.kt` (`Placement.invalidReason`), `ForestViewModel.kt`, `ForestLabels.kt`.
- **Web y arte:** `jsMain/web/*`, `build_assets.py`.
- **Apps:** el motivo se muestra como texto en la barra de colocación (táctil) y en el mensaje (web).

## Cómo probarlo

- Elegir "Cantera": la previsualización sale roja lejos de una roca, con el motivo, y verde cerca de una.
- Una vez construida, se puede entregar piedra en ella.
- Picar cerca de la cantera es visiblemente más rápido. Se puede medir el tiempo entre golpes.
