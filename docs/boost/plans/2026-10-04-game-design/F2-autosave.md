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
- Interfaz `GameSaveRepository` en `domain/repositories/save/`, con `GameSessionEntity? load()`, `void save(GameSessionEntity session)` y `void clear()`. Síncrona, como el resto (E3).
- `World` tiene que poder reconstruirse a partir de su estado: árboles que quedan y golpes recibidos, ítems, edificios con su progreso, contadores de ids de `WorldState`, y posición e inventario del jugador. Se añade un constructor o *factory* de restauración en `World`; `WorldState` no sale de `domain/world/`.
- Del `QuestLog` se expone y se restaura el conjunto de misiones completadas.
- Casos de uso nuevos: `SaveGameUseCase`, `NewGameUseCase`. `StartGameUseCase` carga la partida guardada y, si no hay, carga el nivel.

**Data:**
- Dependencia nueva `shared_preferences` (funciona igual en Android, iOS y web), en su propio commit.
- `SharedPreferencesWithCache` se crea una vez al arrancar, en un módulo de DI con `@preResolve`, para que las lecturas sean síncronas y los casos de uso sigan siendo síncronos. Las escrituras son *fire-and-forget*.
- En `data/datasources/save/`:
  - `local/dbo/`: `SaveDBO` y los DBOs que necesite (árbol, ítem, edificio, jugador), todos con campos anulables y `version`; se serializan a JSON con `dart:convert` y `fromJson`/`toJson` escritos a mano.
  - `source/game_save_local_datasource.dart` + `local/game_save_local_datasource_impl.dart` (`@LazySingleton`).
- En `data/repositories/save/`: `GameSaveRepositoryImpl` + `mappers/` con un `*MapperDBO` inyectado por pieza.
- `SaveDBO.currentVersion` vive en `data`. Si la versión es desconocida o el JSON no se puede leer, se trata como "no hay partida" y se registra con `AppExceptionHandler` / `Logger`.

**Excepciones de `CLAUDE.md` que cambian:** E5 (la sesión sigue en memoria, pero ahora hay un guardado con DBO), E6 (un repositorio lee y escribe un segundo datasource local) y E7 (aparece almacenamiento). Se actualizan en la misma fase.

**Cuándo se guarda** (lo decide `ForestBloc`, que llama a `SaveGameUseCase`):
- Cuando `AdvanceGameUseCase` devuelve un evento importante: `TreeFelledEventEntity`, `BuildingCompletedEventEntity`, `ItemPickedUpEventEntity` o `QuestCompletedEventEntity`.
- Cada `Rules.autosaveIntervalMs` (10 s) de juego, contados con los `deltaMs` de `ForestTicked`.
- Al pasar la app a segundo plano: `ForestPage` usa un `AppLifecycleListener` (`onPause` / `onHide`, que en la web corresponde a `visibilitychange`) y añade un evento nuevo `ForestPaused`.

**Arranque y nueva partida:**
- `ForestStarted` sigue arrancando la partida; ahora puede ser una restaurada.
- Nuevo evento `ForestNewGameRequested`: borra el guardado y vuelve a cargar el nivel.

**UI:**
- Botón "Nueva partida" en el HUD (`HudButton`), con una confirmación propia: un panel de la app (`HudPanel` o `CustomPopUp` a través de `NavigationService`), no un diálogo del sistema.
- Los textos van en `es.json`.

## Ficheros previstos

**Dominio:**
- `lib/layers/domain/repositories/save/game_save_repository.dart` (nuevo)
- `lib/layers/domain/world/world.dart` y `world_state.dart`: restaurar el estado.
- `lib/layers/domain/quests/quest_log.dart`
- `lib/layers/domain/use-cases/game/save_game_use_case.dart`, `new_game_use_case.dart` (nuevos) y `start_game_use_case.dart`
- `lib/layers/domain/rules/rules.dart`

**Datos:** `lib/layers/data/datasources/save/**` y `lib/layers/data/repositories/save/**` (nuevos).

**Core:** `lib/core/config/di/` (módulo con `@preResolve`, `di.config.dart` regenerado; `configureDependencies` en `di.dart` pasa a `await locator.init(...)`, porque con `@preResolve` el `init` generado devuelve un `Future`).

**Presentación:**
- `bloc/forest_bloc.dart`, `bloc/forest_event.dart`
- `forest_page.dart` (`AppLifecycleListener`)
- `widgets/hud_overlay.dart` y el panel de confirmación
- `Internationalize` y `es.json`

**Documentación:** `CLAUDE.md` (E5–E7, *Layout* de `data` y de `core`).

## Cómo probarlo

- Recoger el hacha, talar 2 árboles y dejar una casa a medias. Cerrar y volver a abrir (en la web, recargar la pestaña): todo sigue igual, incluidas las misiones completadas.
- Pulsar "Nueva partida" y confirmar: el bosque vuelve a su estado inicial.
- Tests:
  - ida y vuelta `GameSessionEntity` → `SaveDBO` → JSON → `SaveDBO` → `GameSessionEntity`;
  - versión desconocida y JSON corrupto;
  - el datasource con `SharedPreferences.setMockInitialValues`;
  - `ForestBloc`: guarda tras un evento importante, a los 10 s y con `ForestPaused`; `MockGameSaveRepository` generado con `@GenerateMocks`.
