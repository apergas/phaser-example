# F2 · Guardado de la partida — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **No está hecha en iOS**: allí también es una ficha (`$IOS/docs/plans/2026-10-12-village/F2-autosave.md`). Esta versión une la ficha Flutter anterior (almacenamiento con `shared_preferences`, que funciona en web) con las decisiones de iOS: va la última, tiene botón *Guardar* y guarda todo de una vez.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F2-autosave`, desde `feature/PROJECT-X-town` |
| **Depende de** | F8. Va **la última** de la aldea (decidido el 2026-10-17, como en iOS). |
| **Issue / milestone** | `phase:F2` · milestone `F2 Autosave` |
| **Referencia iOS** | ficha arriba y las secciones *Para F2* de los planes de C12, F3, F4, F5, F6, F7 y F8 de iOS |

## Objetivo

Que la partida sobreviva a cerrar la app o la pestaña: se guarda sola y también con un botón *Guardar*, y hay un botón *Nueva partida*. Al ir la última, el formato nace completo en la **versión 1** y ninguna fase anterior lo toca.

## Decisiones ya tomadas

**Dominio:**
- `GameSaveRepository` (`domain/repositories/save/`): `GameSessionEntity? load()`, `void save(GameSessionEntity session)` y `void clear()`. Síncrono (E3).
- `World` gana una *factory* de restauración con todo su estado; `WorldState` no sale de `domain/world/`:
  - los árboles que quedan, con sus golpes recibidos y en el orden de `World.trees` (los que rebrotaron van al final);
  - los tocones (F3), con `id`, `kind`, `position` y `elapsedMs`, en orden;
  - las rocas (F5), con `id`, `position` y `hitsTaken`, en orden; radio, piedra y golpes vuelven de `Rules`;
  - los objetos del suelo;
  - los edificios, con su progreso, incluidos el campamento, la cantera y el taller;
  - los contadores de ids;
  - las estadísticas (F4);
  - el almacén con oro y maná, y la carga (F6), que no puede pasar de `Rules.carryCapacity`;
  - el jugador: posición, herramientas y `toolLevels` (F8);
  - el héroe: arma, armadura, `skillLevels` (C12), niveles superados y `fightsFought`.
- `QuestLog` expone y restaura sus misiones completadas.
- Casos de uso: `SaveGameUseCase`, `NewGameUseCase`. `StartGameUseCase` carga primero el guardado y, si no hay, el nivel.

**Validar al cargar** (un dato fuera de rango es "partida inválida": se registra y se empieza de cero, nunca se rompe la app):
- cantidades ≥ 0;
- tiers del equipo dentro del catálogo;
- niveles de habilidad entre 1 y `maxLevel` (el `assert` de `HeroEntity` no tiene tope);
- `hitsTaken` de cada roca entre 0 y sus golpes;
- estadísticas ≥ 0;
- un nivel de herramienta sin mejora en el catálogo se recorta al máximo;
- una cantera guardada se queda aunque su roca ya esté rota (la regla de colocación no se vuelve a comprobar).

**Datos:**
- Dependencia nueva `shared_preferences` (Android, iOS y web), en su propio commit.
- `SharedPreferencesWithCache` se crea una vez al arrancar, en un módulo de DI con `@preResolve`: las lecturas son síncronas y las escrituras *fire-and-forget*. `configureDependencies` pasa a `await locator.init(...)`.
- En `data/datasources/save/`:
  - `local/dbo/`: `SaveDBO` (con `version`) y un DBO por pieza (árbol, tocón, roca, objeto, edificio, jugador, inventario, héroe, estadísticas), con campos anulables y `fromJson`/`toJson` a mano sobre `dart:convert`;
  - `source/game_save_local_datasource.dart` + `local/game_save_local_datasource_impl.dart` (`@LazySingleton`).
- Los enums se guardan por su `name` (el de Dart; iOS usará los mismos valores brutos).
- `data/repositories/save/`: `GameSaveRepositoryImpl` + un `*MapperDBO` por pieza. Nunca crea cantidades 0 en `InventoryEntity.resources` (se construye con `InventoryRules.add` o se filtran los ceros).
- `SaveDBO.currentVersion = 1`. Una versión desconocida o un JSON roto es "no hay partida", registrado con `AppExceptionHandler` / `Logger`.

**Excepciones de `CLAUDE.md` que cambian:** E5 (la sesión sigue en memoria, pero ahora hay un guardado con DBO), E6 (un repositorio lee y escribe un segundo datasource local) y E7 (aparece almacenamiento). Se actualizan en esta fase.

**Cuándo se guarda** (lo decide `ForestBloc`, con `SaveGameUseCase`):
- **Tras un evento importante:** talar, terminar un edificio, recoger un objeto, completar una misión, romper una roca, entregar, comprar equipo, mejora o habilidad, y al volver de la arena (la pelea ya está cobrada).
- Cada `Rules.autosaveIntervalMs = 10000` de juego, contados con los `deltaMs` de `ForestTicked`.
- Al pasar a segundo plano: `ForestPage` usa un `AppLifecycleListener` (`onPause`/`onHide`; en la web, `visibilitychange`) y añade el evento `ForestPaused`.

**Menú *Partida*** (el sexto botón; uno solo para no llenar la fila):
- `HudMenu.game`, al final del enum, con un SVG nuevo `save.svg`. Abre un panel con dos acciones:
  - ***Guardar*** (`ForestSaveRequested`): guarda en el momento y avisa "Partida guardada"; si falla, un pop-up de error a través de `NavigationService`.
  - ***Nueva partida*** (`ForestNewGameRequested`): pide confirmación **dentro del mismo panel** (no un diálogo del sistema), borra el guardado y vuelve a cargar el nivel.
- Se vuelven a medir los umbrales del HUD con seis botones.

**Escena al cargar:** los edificios terminados nacen sin barra (F6), los tocones y brotes sin crecer, y no se reproduce ningún efecto.

**Textos:**
- Botón y panel: `forest.hud.game` "Partida", `forest.game.save` "Guardar", `forest.game.saved` "Partida guardada", `forest.game.newGame` "Nueva partida".
- Confirmación: `forest.game.newGameConfirm` "Se perderá la partida actual. ¿Empezar de nuevo?", `forest.game.confirm` "Empezar", `forest.game.cancel` "Cancelar".

## Ficheros previstos

- **Dominio:** `repositories/save/game_save_repository.dart` (nuevo), `world/world.dart` y `world_state.dart` (restaurar), `quests/quest_log.dart`, `use-cases/game/save_game_use_case.dart` y `new_game_use_case.dart` (nuevos), `start_game_use_case.dart`, `rules/rules.dart`.
- **Datos:** `data/datasources/save/**` y `data/repositories/save/**` (nuevos).
- **Core:** `config/di/` (módulo con `@preResolve`, `di.dart`, `di.config.dart` regenerado), `forest/hud_menu.dart`, `es.json`, `internationalize.dart`, `images/icons/save.svg`.
- **Presentación:** `bloc/forest_bloc.dart`, `forest_event.dart`, `forest_page.dart` (`AppLifecycleListener`), `widgets/hud_overlay.dart`, el panel *Partida* (nuevo widget), `game/forest_scene_component.dart` (nada de efectos al cargar).
- **Docs:** `CLAUDE.md` (E5–E7 y el *Layout* de `data` y `core`).

## Cómo probarlo

- Jugar un rato con de todo: tocones, rocas a medias, almacén con oro y maná, carga, una obra a medias, mejoras, héroe con habilidades mejoradas y misiones. Cerrar y volver a abrir (en la web, recargar la pestaña): todo sigue igual.
- *Partida* ▸ *Guardar* avisa "Partida guardada". *Nueva partida* pide confirmación en el panel y empieza de cero.
- Tests:
  - ida y vuelta `GameSessionEntity` → `SaveDBO` → JSON → `SaveDBO` → `GameSessionEntity` con un mundo que tenga de todo;
  - versión desconocida, JSON roto y datos fuera de rango → `null` sin lanzar;
  - el datasource con `SharedPreferences.setMockInitialValues`;
  - `ForestBloc`:
    - guarda tras un evento importante, a los 10 s, con `ForestPaused` y con *Guardar* (y el pop-up si falla);
    - *Nueva partida* borra y recarga;
  - `MockGameSaveRepository` con `@GenerateMocks`.
