# F2 · Guardado automático — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | B |
| **Depende de** | F0 |
| **Issue / milestone** | `phase:F2` · milestone `F2 Autosave` |

## Objetivo

Que la partida sobreviva a cerrar la app o la pestaña, y que se pueda empezar de cero. Es un requisito de todo lo que viene después: una aldea que se pierde al cerrar no tiene sentido.

## Decisiones ya tomadas

**Dominio:**
- Interfaz `GameSaveRepository`, en `domain/repositories/save/`, con `load(): GameSession?`, `save(session: GameSession)` y `clear()`.
- `World` tiene que poder reconstruirse a partir de su estado: árboles que quedan y golpes recibidos, ítems, edificios con su progreso, y posición e inventario del jugador.
- Del `QuestLog` se expone y se restaura `completed`.

**Data:**
- En `data/datasources/local/save/`:
  - `SaveDto`: `@Serializable`, todos los campos anulables, con `version: Int`.
  - `SaveMappers.kt`, junto al repositorio.
- `SAVE_VERSION` vive en `data`.
- Si la versión es desconocida, se trata como "no hay partida" y se registra con `ErrorHandler`.

**Almacenamiento por plataforma:**
- Interfaz `KeyValueStorage { get(key): String?; set(key, value); remove(key) }`.
- **Cada app inyecta su implementación** en `GameContainer`. No se usa `expect/actual`, para no tocar `commonMain` con APIs de plataforma.
  - Web: `localStorage`. `ForestWebController` recibe un objeto que lo implementa.
  - Android: `SharedPreferences`, que no añade dependencias. Si se prefiere DataStore, la versión va en `libs.versions.toml` y hay que comprobar que es compatible con SDK 36.
  - iOS: `UserDefaults`.

**Cuándo se guarda:**
- En el `advance` del caso de uso, cuando hay un evento importante: `TreeFelled`, `BuildingCompleted`, `ItemPickedUp` o `QuestCompleted`.
- Cada 10 s de juego.
- Al pasar la app a segundo plano: `onStop` en Android, `scenePhase` en iOS y `visibilitychange` en la web. Para ello se añade un `ForestIntent.Paused`.

**Arranque:**
- `startGame()` carga la partida guardada; si no hay, carga el nivel.
- Se añade `newGame()`.

**UI:**
- Botón "Nueva partida" en el HUD, con una confirmación propia (un panel de la app, no `alert`/`confirm`).
- Los textos van en `ForestLabels`.

## Ficheros previstos

**`shared`:**
- `shared/.../domain/repositories/save/GameSaveRepository.kt` (nuevo)
- `shared/.../domain/world/World.kt` y `WorldState.kt`: restaurar el estado.
- `shared/.../domain/quests/QuestLog.kt`
- `shared/.../domain/usecases/game/GameUseCase(Impl).kt`
- `shared/.../data/datasources/local/save/*` y `data/repositories/save/*` (nuevos)
- `shared/.../di/GameContainer.kt`
- `ForestContract.kt`, `ForestViewModel.kt` y `ForestLabels.kt`
- `ForestWebController.kt`

**Apps:**
- Web: `main.ts` y `Hud.ts`.
- Android: `ForestScreen.kt`, `HudOverlay.kt` y `GameModule.kt`.
- iOS: `ForestView.swift`, `HudView.swift` y `ForestBuilder.swift`.

## Cómo probarlo

- Recoger el hacha, talar 2 árboles y dejar una casa a medias. Cerrar y volver a abrir (en la web, recargar): todo sigue igual, incluidas las misiones completadas.
- Pulsar "Nueva partida" y confirmar: el bosque vuelve a su estado inicial.
- Tests:
  - ida y vuelta `GameSession` → `SaveDto` → `GameSession`;
  - versión desconocida;
  - `KeyValueStorageMock` con `error` y los flags `getCalled`/`setCalled`.
