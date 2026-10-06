# C2 · Pantalla de la arena — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C0. C1 hace falta para jugar de verdad, pero **no para empezar**: hasta que llegue, la escena se desarrolla y se prueba con `FightLogEntityMock`. |
| **Issue / milestone** | `phase:C2` · `stream:C` · milestone `C2 Arena screen` |

## Objetivo

Que se pueda entrar en la arena desde el bosque, elegir un nivel, pulsar **"Empezar pelea"** y ver la pelea animada: el héroe y los enemigos frente a frente, golpes, barras de vida y números de daño, con victoria o derrota y la recompensa al final.

## Decisiones ya tomadas

**Navegación:**
- Botón *Arena* en `HudOverlay` (un `HudButton` más, con su icono SVG `arena.svg`).
- Al pulsarlo, `ForestBloc` llama a `NavigationService.push(const ArenaPage())`. La página se crea con `BlocProvider.create` desde `locator`, como `ForestPage`. Volver es `NavigationService.pop()` (botón *Volver* y la flecha del sistema en Android).
- **El bosque se pausa** mientras la arena está encima:
  - `ForestPage` registra un `RouteAware` (con un `RouteObserver` en el `MaterialApp` de `ContainerApp`) y llama a `game.pauseEngine()` en `didPushNext` y a `resumeEngine()` en `didPopNext`;
  - así el jugador no sigue talando ni se pierden ticks;
  - si `ForestTicked` no llega con el motor parado, se comprueba en un test de página.

**Feature** `lib/layers/presentation/features/arena/`, con la misma forma que `forest/` (excepción E9 ampliada):
- `bloc/`: `ArenaBloc` (un solo `on<ArenaEvent>` con `await switch`).
  - Eventos: `ArenaStarted`, `ArenaLevelSelected(levelId)`, `ArenaFightRequested`, `ArenaReplayTicked(deltaMs)`, `ArenaReplaySkipped`, `ArenaClosed`.
  - Estados: `ArenaInitial` / `ArenaInProgress` / `ArenaSuccess` / `ArenaFailure` con `ArenaData`.
- `models/`:
  - `ArenaData(levels: List<ArenaLevelItemData>, selected, heroPower, replay: FightReplayData?)`;
  - `FightReplayData(log, elapsedMs, turnIndex)`, que decide en qué turno va la animación a partir del tiempo (`Rules` no: constantes de presentación en `arena/game/render/arena_render_constants.dart`, ≈ 600 ms por turno);
  - `FighterRenderData(side, index, kind, health, maxHealth, pose)`;
  - `ArenaEffect` `sealed` (`HitEffect`, `DodgeEffect`, `HealEffect`, `FightEndedEffect`), que se reproduce una vez por estado emitido, como `ForestEffect`.
- `game/`: `ArenaGame` (Flame) + `ArenaSceneComponent` + `ArenaStateListener`, con la misma regla de `dt` acotado a 100 ms que `ForestGame`.
  - Componentes: fondo (hierba y valla del `terrain_atlas`), `FighterComponent` (pose idle / golpe / recibe / cae), `HealthBarComponent` y `FloatingNumberComponent` (puede reutilizar el `FloatingTextComponent` de F1 si ya está; si no, se crea aquí y F1 lo reutiliza).
- `widgets/`: `ArenaHud` con `LevelList` + `LevelTile` (nombre, Poder del nivel frente al tuyo con color verde / ámbar / rojo, recompensa, candado o "Ganado"), `FightButton` (*Empezar pelea*), `ResultPanel` (victoria con el oro ganado; derrota con el consejo de `FightPlayedEntity.advice`, por ejemplo "Te falta Ataque: visita la Herrería", y *Reintentar*). Un fichero por clase.
- `arena_page.dart`: `ArenaPage` + `_ArenaView`, con su `GameWidget(autofocus: false)`.

**API de C1 que usa la pantalla:**
- `GetArenaUseCase` devuelve, para cada nivel, su Poder, si está desbloqueado o ganado y la próxima recompensa, además de `heroPower`.
- `StartFightUseCase` devuelve `FightPlayedEntity(log, advice)` o `FightLockedEntity`. El `log` trae `heroStats` y `enemies` (para la vida máxima de las barras), los turnos y la recompensa cobrada.
- Tras cada pelea, el BLoC vuelve a llamar a `GetArenaUseCase` para refrescar la lista.
- En los tests del BLoC no se usan los mocks `ArenaLevelEntityMock.duel`, `wall` ni `brute` como niveles del catálogo: tienen ids reales (`banditVeteran`, `barbarian`) y se confundirían con ellos.

**Reproducción:**
- `ArenaFightRequested` llama a `StartFightUseCase`: el resultado ya está aplicado en el `World`.
- Después, `ArenaReplayTicked` avanza `FightReplayData`. Cada turno nuevo emite su efecto, y la escena anima:
  - golpe con la hoja `slash` (secuencia `chop` de `RenderConstants`);
  - parpadeo del que recibe y **unas gotas de sangre** que saltan del impacto y caen: `ParticleKind.bloodDrop` y `ParticleBursts.bloodDrops(...)`, variante de `woodChips` con 4–6 partículas rojas pequeñas que desaparecen en ≈ 400 ms. Sólo con `hit` y `doubleStrike` que hacen daño; nunca con `dodge` ni `secondWind`, y sin charcos ni manchas que se queden en el suelo;
  - "−N" flotando;
  - la barra de vida baja con *easing*.
- *Saltar* (`ArenaReplaySkipped`) va directamente al último turno.
- Mientras se reproduce, la lista y el botón están desactivados.

**Arte** (atlas propio `arena.{png,json}`, generado por `build_assets.py`):
- **Héroe:** las hojas `slash` e `idle` que ya existen, mirando a la derecha.
- **Bandido y bárbaro:** las mismas capas, mirando a la izquierda, con `recolour()` en ropa y pelo (bandido: ropa roja oscura; bárbaro: piel más oscura y ropa marrón). C6 cambia el bárbaro por arte propio.
- **`barbarianChief`:** el bárbaro escalado ×1,25 hasta C6.
- **Escenario:** hierba y valla del `terrain_atlas`.
- `SpriteNames` de la arena en `arena/game/atlas/arena_sprite_names.dart`. `EnemyKind` → frame, con un `switch` exhaustivo.

**Arquitectura:**
- `test/architecture_test.dart`: `_flameAllowedImporters` gana `features/arena/game/` y `features/arena/arena_page.dart`.
- `CLAUDE.md` documenta la nueva feature y amplía E9.

**Textos** (`es.json`, bloque `arena`):
- título, *Empezar pelea*, *Volver*, *Saltar*, *Reintentar*, "¡Victoria!", "Derrota", "+{amount} de oro", "Poder {power}";
- el nombre de cada `ArenaLevelId` y de cada `EnemyKind`;
- un texto por cada `FightAdvice`.

## Ficheros previstos

**Presentación:**
- `features/arena/**` (nuevo)
- `features/forest/bloc/forest_bloc.dart` y `forest_event.dart` (`ForestArenaRequested`)
- `features/forest/widgets/hud_overlay.dart`, `features/forest/forest_page.dart` (pausa)
- `app/container_app.dart` (`RouteObserver`)
- `theme/images/custom_icons.dart`
- `core/config/constants/enum/forest/hud_menu.dart` si el botón abre un menú

**Core:** `Internationalize`, `es.json`, `lib/core/assets/images/icons/arena.svg`.

**Arte:** `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/arena.{png,json}`, `pubspec.yaml` (registrar el atlas si los assets se listan uno a uno).

**Tests:**
- `test/architecture_test.dart`;
- `arena_bloc_test.dart` (casos de uso reales sobre `MockGameSessionRepository`, E11);
- `arena_page_test.dart`;
- componentes con `testWithFlameGame`;
- golden opcional del panel de resultado.

## Cómo probarlo

- Desde el bosque, *Arena*: aparece la lista; sólo el primer nivel está abierto.
- *Empezar pelea*: se ve la pelea (golpes con unas gotas de sangre, números, barras) y "¡Victoria! +10 de oro".
- Al volver al bosque, el HUD muestra 10 de oro y el héroe está donde estaba (el bosque estuvo en pausa).
- El segundo nivel ya está abierto.
- Un nivel muy alto: derrota con un consejo, *Reintentar*, y el oro no cambia.
- *Saltar* muestra el resultado al momento.
- Funciona en Chrome, en el emulador Android y en el simulador iOS, en horizontal.
