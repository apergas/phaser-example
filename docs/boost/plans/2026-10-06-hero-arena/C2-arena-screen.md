# C2 · Pantalla de la arena — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C0 y C1 (los dos ya están en `feature/PROJECT-X-arena`) |
| **Issue / milestone** | `phase:C2` · `stream:C` · milestone `C2 Arena screen` (un issue por tarea: TC2.1 … TC2.5) |

**Goal:** Que se pueda entrar en la arena desde el bosque, elegir un nivel, pulsar **"Empezar pelea"** y ver la pelea animada: el héroe y los enemigos frente a frente, golpes con unas gotas de sangre, barras de vida y números de daño, con victoria o derrota y la recompensa al final. El bosque se queda en pausa mientras tanto.

**Architecture:**
- Feature nueva `lib/layers/presentation/features/arena/`, con la misma forma que `forest/` (E9 ampliada):
  - `bloc/`: `ArenaBloc` sobre los casos de uso reales de C1 (`GetArenaUseCase`, `StartFightUseCase`) y de C0 (`GetHeroStatusUseCase`, sólo para la vida del héroe antes de la primera pelea).
  - `models/`: `ArenaLevelItemData`, `FighterRenderData`, `FightReplayData` (decide qué turno ha llegado a partir del tiempo), `ArenaResultData` y `ArenaEffect` (`sealed`).
  - `game/`: `ArenaGame` (Flame, `dt` acotado a 100 ms) + `ArenaSceneComponent` + `ArenaStateListener`; componentes `ArenaGroundComponent`, `FighterComponent`, `HealthBarComponent`; atlas propio `arena.{png,json}` con `ArenaAssets`, `ArenaAssetsLoader` y `ArenaSpriteNames`.
  - `widgets/`: `ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel` (un fichero por clase).
  - `arena_page.dart`: `ArenaPage` + `_ArenaView`, con `GameWidget(autofocus: false)`.
- **La pelea ya está resuelta antes de verse:** `ArenaFightRequested` llama a `StartFightUseCase`, que cobra y desbloquea en el `World` en la misma llamada. La escena sólo reproduce el `FightLogEntity`.
- **Reutiliza lo del bosque** sin copiarlo: `AtlasFrame`, `LpcAtlas.parse`, `ShadowComponent`, `Easing`, `RenderDepth`, `PlayerFrames.workColumn` / `idleColumn`, `ParticleBurstComponent` y `ParticleBursts` (con la variante nueva `bloodDrops`), `HudButton` y `HudPanel`.
- **`FloatingTextComponent`** se crea en `features/forest/game/components/` con **el mismo nombre, ruta y código** que el plan de F1 (TF1.2, pasos 5 y 6), para que la fase que llegue segunda lo reutilice tal cual.
- **Pausa del bosque:** `NavigationService` expone un `RouteObserver<ModalRoute<void>>`, `ContainerApp` lo registra en su `MaterialApp` y `ForestPage` lo escucha con `RouteAware` (`pauseEngine` / `resumeEngine`).

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame + `flame_bloc`, `flutter_svg`, `easy_localization`; tests con `flutter_test`, `bloc_test`, `mockito`, `flame_test`. Arte con `asset-packs/lpc/build_assets.py` (Pillow).

**Precondición: C1 fusionada en `feature/PROJECT-X-arena`.** Este plan usa exactamente estas firmas de C0 y C1. Antes de empezar, comprueba que no han cambiado:
- `GetArenaUseCase.call() → ArenaEntity(heroPower, levels: List<ArenaLevelStatusEntity(level, isUnlocked, isCleared, nextReward)>)`;
- `StartFightUseCase.call({required ArenaLevelId levelId}) → FightResultEntity` (`FightPlayedEntity(log, advice)` o `FightLockedEntity`);
- `GetHeroStatusUseCase.call() → HeroStatusEntity(hero, stats, power)`;
- `FightLogEntity(levelId, heroStats, enemies, turns, outcome, reward)` con `isVictory`; `FightTurnEntity(round, actor, actorIndex, target, targetIndex, action, damage, targetHealthAfter)`;
- enums `EnemyKind { bandit, barbarian, barbarianChief }`, `ArenaLevelId` (6 valores), `FightSide`, `FightAction { hit, doubleStrike, dodge, secondWind }`, `FightAdvice`;
- mocks `FightLogEntityMock.victoryOverBandit()` / `allActions()`, `HeroEntityMock.mock` / `veteran` / `afterFirstVictory` / `veteranAfterAnotherFight`, `WorldMock.withHero`, `GameSessionEntityMock.playing`, `AppExceptionMock.noGameInProgress`.

Si algo ha cambiado, adapta los fragmentos de este plan y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- `flutter test` en verde (73 tests nuevos), con `arena_bloc_test.dart` (casos de uso reales, E11), `arena_page_test.dart`, los componentes con `testWithFlameGame` y el test de pausa de `forest_page_test.dart`.
- La prueba manual de la sección *Prueba manual* en Chrome, el emulador Android y el simulador iOS, en horizontal.

**Cómo se ha comprobado este plan:** todo el código y los tests de las cinco tareas se aplicaron sobre una copia de `feature/PROJECT-X-c1-combat-engine` (C0 + C1): `build_runner` sin cambios en `di.config.dart`, `flutter analyze` → `No issues found!`, `flutter test` → 491 tests en verde, y los tests en Chrome también. Los fragmentos de este documento son esos ficheros, ya pasados por `dart format --line-length 120`.

> **Coordinación C2 ↔ C3:** las dos fases añaden a `HudButton` el mismo parámetro opcional `final String? icon` (con `flutter_svg`, como primer hijo del `Row`). La que se fusione **primero** en `feature/PROJECT-X-arena` lo añade; la segunda se salta ese paso y usa el que ya existe (si la firma difiere, se queda la ya fusionada). Lo mismo con el fichero de tests del BLoC: C3 usa `forest_bloc_hero_test.dart` para no chocar con C2. La comprobación del ancho de la barra con cuatro botones (README, sección 3.2) la hace a ojo quien llegue segundo.

## Decisiones del plan

Lo que este plan fija o añade sobre la ficha (todo lo demás de la ficha se mantiene):

1. **Tiempos de la reproducción** (en `arena/game/render/arena_render_constants.dart`):
   - `leadInMs = 400`: pausa antes del primer golpe, para que se vea a los luchadores quietos;
   - `turnMs = 600`: cada turno dura lo mismo, sea golpe, esquiva o segundo aliento;
   - `impactShare = 0.5`: el golpe "llega" a mitad del turno, que coincide con el fotograma de impacto de la secuencia `chop` (`[0,0,5,5,4,4,3,1]`, el índice 4 cae en el 50 %);
   - una pelea de 9 turnos dura 400 + 9 × 600 = 5800 ms; la más larga posible (30 rondas, 3 enemigos) ronda los 70 s, y para eso está *Saltar*.
2. **`FightReplayData.turnIndex` es el último turno que ya ha impactado** (−1 si ninguno). La vida que se dibuja es la de después de ese turno. El efecto de cada turno se emite **al impactar**, no al empezar el golpe, para que el "−4" y la sangre salgan con el hacha. La pose de golpe usa otro dato, `swingingTurn` (el turno que se está animando) y su `swingProgress`.
3. **Poses:** `FighterPose { idle, attack, hurt, down }` (`core/config/constants/enum/arena/`).
   - `attack`: quien actúa en un `hit`, `doubleStrike` o `dodge` (en la esquiva, el enemigo golpea y falla);
   - `hurt`: el objetivo de un golpe con daño, desde el impacto hasta el final del turno (parpadea);
   - `down`: vida 0; se dibuja el primer fotograma `idle` tumbado (90°) y al 80 % de opacidad;
   - el `secondWind` no anima a nadie: sólo sale "+N" en verde sobre el héroe.
4. **`ArenaData` lleva más que lo de la ficha:** además de `levels`, `selected`, `heroPower` y `replay`, guarda `fighters` (lo que dibuja la escena), `result` (`ArenaResultData`, lo que enseña `ResultPanel`) y `effects`. Antes de pelear, `fighters` es la **vista previa** del nivel elegido (héroe con su vida máxima, de `GetHeroStatusUseCase`, y los enemigos del nivel).
5. **`FighterRenderData` usa `enemyKind: EnemyKind?`** en lugar de un `kind` propio: `null` es el héroe. Su clave en la escena es `'${side.name}-$index'` (`hero-0`, `enemy-0`…).
6. **Refresco de la lista:** el BLoC vuelve a llamar a `GetArenaUseCase` **cuando termina la reproducción** (o al saltarla), no al empezar la pelea, para no destapar "Ganado" antes de ver el final. El oro ya está en el `World` desde `ArenaFightRequested`.
7. **Selección inicial:** el primer nivel desbloqueado y no ganado; si están todos ganados, el último desbloqueado. Tras una pelea la selección no cambia (el jugador elige el siguiente nivel en la lista).
8. **Color del Poder del nivel** (`PowerTone`, en `enum/arena/`): verde si el Poder del nivel es menor o igual que el tuyo; ámbar hasta un 25 % más (`ArenaBloc.evenPowerRatio = 1.25`); rojo por encima. Con el héroe nuevo (Poder 31): `banditRookie` (19) verde, `banditVeteran` (41) rojo.
9. **Panel de resultado:** en victoria muestra "¡Victoria!" y "+N de oro" y **no tiene botón** (se cierra al elegir un nivel o pelear otra vez). En derrota muestra "Derrota", el consejo de `FightAdvice` y *Reintentar* (vuelve a lanzar `ArenaFightRequested` sobre el mismo nivel).
10. **Saltar:** `ArenaReplaySkipped` lleva la reproducción al final y emite **sólo** `FightEndedEffect` (ni números ni sangre en ráfaga); la escena pone las barras en su valor final al momento.
11. **Arte de la arena** (verificado generando `arena.{png,json}` con el script de este plan):
    - un único atlas `arena.png` (1024 × 388) con 26 frames sin recortar, para que el pivote sea fijo: `{hero,bandit,barbarian}-idle-{0,1}` (64 px, el hacha en la mano como `hero-idle-axe`, pivote `(0.5, 0.9688)`) y `{hero,bandit,barbarian}-slash-{0..5}` (128 px, hoja `slash` entre las capas del hacha, pivote `(0.5, 0.7344)`), más `arena-grass` (celda (1, 23) del `terrain_atlas`, la misma hierba del bosque) y `arena-fence` (64 × 32, un poste y dos travesaños de la caja `(480, 608, 544, 640)` del `terrain_atlas`, pivote abajo a la izquierda);
    - cada luchador sólo guarda **su fila**: el héroe mira a la derecha (fila 3 de LPC) y los enemigos a la izquierda (fila 1);
    - **héroe:** los mismos colores del bosque (camisa verde);
    - **bandido:** camisa granate, pantalón gris oscuro y pelo negro;
    - **bárbaro:** piel más oscura (rampa nueva `SKIN_RAMP` → `BARBARIAN_SKIN` en cuerpo y cabeza), camisa y pantalón marrones y pelo rojizo;
    - **todos golpean con el hacha:** no hay espadas en `sources/` (llegan con C3/C6); se apunta como desviación al cerrar la fase;
    - **`barbarianChief`:** usa los frames `barbarian-*` y se escala ×1,25 **al dibujarlo** (`ArenaRenderConstants.fighterScale`), no en el atlas, para no duplicar 8 frames que C6 va a sustituir.
    - `build_assets.py` gana `write_atlas` (lo comparten bosque y arena) y un parámetro `recolours` en `body_sheet`. **`forest.{png,json}`, `ground.png` y `hero-*.png` salen idénticos byte a byte** (comprobado con `git status`: sólo aparecen los dos ficheros nuevos).
12. **Escenario:** `stageWidth = 480`, `stageHeight = 270`, valla con la base en `y = 72`. La cámara mira al centro (240, 135) con un zoom que **cubre** la vista (`max(ancho / 480, alto / 270)`, entre 1 y 3): en un móvil de 844 × 390 es 1,76 y en 1280 × 720 es 2,67. Posiciones (pies): héroe (190, 170); enemigos (300, 170), (340, 140), (340, 200). La lista de niveles (280 px de ancho a la izquierda) no tapa a nadie en esos tamaños.
13. **Barra de vida:** 28 × 4, 52 px por encima de los pies (×1,25 para el jefe), verde por encima del 50 %, ámbar por encima del 25 %, roja debajo; baja con `Easing.sineOut` en 300 ms.
14. **Sangre:** `ParticleKind.bloodDrop` y `ParticleBursts.bloodDrops(impact:, attackerOnLeft:, random:)`: entre 4 y 6 gotas rojas de 2 × 2 (`0xFF9E1B1B`) que salen a 28 px de los pies del herido, en sentido contrario al atacante (280°–340° si ataca desde la izquierda, 200°–260° si ataca desde la derecha), con gravedad 260 y que desaparecen en 400 ms. Sólo con `HitEffect` de daño mayor que 0; nunca con esquiva ni segundo aliento, y nada se queda en el suelo.
15. **Números flotantes:** `FloatingTextComponent` de F1 (TF1.2) copiado **igual** en `features/forest/game/components/floating_text_component.dart`. La ficha hablaba de un `FloatingNumberComponent`; no se crea: la escena compone el texto (`Internationalize.arenaDamage` "−4" en `CustomColors.hudWarning`, `arenaHeal` "+12" en `CustomColors.success`, `arenaDodge` "¡Esquiva!" en el color por defecto) a 36 px por encima de los pies.
    - **Si F1 llega antes** a `feature/PROJECT-X-arena` (al traer `develop`): `grep -rn "class FloatingTextComponent" lib` antes de TC2.3; si existe, se salta su creación y se añaden sólo los dos tests de esta fase al fichero de test de F1.
    - **Si F1 llega después:** al traer `develop` habrá un conflicto *add/add* en el componente (idéntico: se queda cualquiera) y en su test (se dejan los cuatro tests, los dos de F1 y los dos de C2).
16. **Pausa del bosque con `RouteObserver` (verificado):**
    - `NavigationService` gana `RouteObserver<ModalRoute<void>> get routeObserver`; `NavifyImpl` lo crea una vez. Así el observador vive junto al `navigatorKey` y `ContainerApp` lo registra con `navigatorObservers`;
    - `ForestPage` está en una `MaterialPageRoute` (la pone `pushReplacement` desde `ContainerAppBloc`), así que `ModalRoute.of(context)` existe y `didPushNext` / `didPopNext` llegan al abrir y cerrar `ArenaPage`;
    - también pausa con los diálogos de error (`showErrorPopUp` abre una `DialogRoute`), lo que es correcto;
    - coste: los tests que registran `MockNavigationService` y montan `ForestPage` necesitan `when(navigationService.routeObserver).thenReturn(...)` (sólo `forest_page_test.dart`).
17. **Botón del HUD:** `HudButton` gana un `icon` opcional (SVG de 18 px antes del texto). *Arena* es el **tercer** botón (*Misiones*, *Construir*, *Arena*); la regla del cuarto botón del README (3.2) todavía no aplica. Pulsarlo cierra el menú abierto y lanza `ForestArenaRequested`; el BLoC cancela la colocación si había una y hace `push(const ArenaPage())`. Icono `arena.svg`: dos espadas cruzadas en el estilo de `axe.svg` (22 × 22, hoja `#C9CED6`, empuñadura `#8A5A2B`).
18. **Textos** (`es.json`): bloque `arena` completo y `forest.hud.arena` ("Arena"). Ver TC2.2 y TC2.5.
19. **Golden del panel de resultado:** no se hace. Los tests de widgets ya comprueban textos y botón, y los goldens del proyecto sólo cubren valores del bosque en Chrome.
20. **Sin `Esc`** en la arena: se vuelve con *Volver* o con la flecha del sistema en Android (la `MaterialPageRoute` ya la gestiona).

## Reparto

| Tarea | Qué | Depende de | Paralelizable |
|---|---|---|---|
| TC2.1 Arte y atlas de la arena | `build_assets.py`, `arena.{png,json}`, `CREDITS.md`, `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames`, regla de Flame en `architecture_test.dart` | C1 | **Sí, con TC2.2** |
| TC2.2 Modelos y `ArenaBloc` | enums `enum/arena/`, `models/`, `bloc/`, tiempos en `arena_render_constants.dart`, textos `arena.*` | C1 | **Sí, con TC2.1** |
| TC2.3 Escena Flame | `game/` (escena, componentes, juego), sangre, `FloatingTextComponent` | TC2.1, TC2.2 | **Sí, con TC2.4** |
| TC2.4 HUD de la arena | `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`) | TC2.2 | **Sí, con TC2.3** |
| TC2.5 Página, entrada desde el bosque y pausa | `arena_page.dart`, `NavigationService.routeObserver`, `ContainerApp`, `ForestBloc`, `HudOverlay`, `HudButton`, `ForestPage`, `CLAUDE.md` | TC2.1 … TC2.4 | No |

**Ficheros compartidos entre tareas paralelas:** ninguno.
- TC2.1 y TC2.2 no tocan los mismos ficheros. TC2.2 **crea** `arena_render_constants.dart` (sólo los tiempos) y TC2.3 le **añade** el resto (TC2.3 empieza cuando las dos están unidas).
- TC2.3 y TC2.4 tampoco: TC2.3 añade `ArenaDataMock`, `ArenaBlocFake`, `ArenaAssetsLoaderFake` y `FighterRenderDataMock.chiefIdle`; TC2.4 sólo lee los mocks de TC2.2.
- `es.json` e `Internationalize` los tocan TC2.2 (bloque `arena`) y TC2.5 (`forest.hud.arena`), que van en orden.

**Ramas (README, sección 3.0):**
- Rama de fase `feature/PROJECT-X-c2-arena-screen`, desde `feature/PROJECT-X-arena`. Su PR va a `feature/PROJECT-X-arena`.
- Cada tarea en su rama desde la de fase (`feature/PROJECT-X-c2-art`, `-c2-bloc`, `-c2-scene`, `-c2-hud`, `-c2-page`); las paralelas, cada una en su propio worktree (`boost:using-git-worktrees`). Al terminar una tarea se une a la rama de fase con `git merge --no-ff` (sin PR por tarea, como en C1).
- Commits `[PROJECT-X]: Imperative description`, sin atribución a IA; `CLAUDE.md` se añade al índice **en un comando aparte**.

---

### Task TC2.1: Arte y atlas de la arena

**Files:**
- Modify:
  - `asset-packs/lpc/build_assets.py`
  - `lib/core/assets/images/lpc/CREDITS.md`
  - `test/architecture_test.dart`
  - `test/core/assets/lpc_assets_test.dart`
- Create (generados):
  - `lib/core/assets/images/lpc/arena.png`
  - `lib/core/assets/images/lpc/arena.json`
- Create:
  - `lib/layers/presentation/features/arena/game/atlas/arena_assets.dart`
  - `lib/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart`
  - `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_assets_test.dart`
  - `test/mocks/presentation/features/arena/game/arena_assets_mock.dart`

`pubspec.yaml` no cambia: ya registra la carpeta `lib/core/assets/images/lpc/` entera.

**Interfaces:**
- Consumes: `AtlasFrame`, `LpcAtlas.parse`, `LpcAssetsLoader.prefix` (bosque); `EnemyKind`; `RenderConstants.idleColumns` / `workColumns`.
- Produces:
  ```dart
  // lib/layers/presentation/features/arena/game/atlas/arena_assets.dart
  class ArenaAssets {
    final Image atlas;
    final Map<String, AtlasFrame> frames;
    const ArenaAssets({required this.atlas, required this.frames});
    AtlasFrame frame(String name);   // ArgumentError si no existe
    Sprite sprite(String name);
  }

  // lib/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart
  class ArenaAssetsLoader {
    static const String prefix;      // = LpcAssetsLoader.prefix
    static const String atlasPath;   // 'lpc/arena.json'
    static const String imagePath;   // 'lpc/arena.png'
    ArenaAssetsLoader({AssetBundle? bundle});
    Future<ArenaAssets> load();
  }

  // lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart
  abstract final class ArenaSpriteNames {
    static const String hero;        // 'hero'
    static const String grass;       // 'arena-grass'
    static const String fence;       // 'arena-fence'
    static String enemy(EnemyKind kind);          // bandit | barbarian | barbarian (jefe)
    static String fighter(EnemyKind? kind);       // null = héroe
    static String idle(String fighter, int column);   // 'bandit-idle-1'
    static String slash(String fighter, int column);  // 'hero-slash-5'
  }

  // test/mocks/presentation/features/arena/game/arena_assets_mock.dart
  ArenaAssetsMock.create()   // atlas 8 × 8 blanco con todos los frames que pide la escena
  ```

- [x] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-arena && git pull
git switch -c feature/PROJECT-X-c2-arena-screen && git push -u origin feature/PROJECT-X-c2-arena-screen
git switch -c feature/PROJECT-X-c2-art
```

(Si TC2.2 se hace a la vez, en otro worktree: `git worktree add ../phaser-example-c2-bloc -b feature/PROJECT-X-c2-bloc feature/PROJECT-X-c2-arena-screen`.)

- [x] **Step 2: Tests que fallan**

`test/mocks/presentation/features/arena/game/arena_assets_mock.dart`:

```dart
import 'dart:ui';

import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';

abstract final class ArenaAssetsMock {
  static const int frameSize = 8;

  static final List<String> frameNames = [
    ArenaSpriteNames.grass,
    ArenaSpriteNames.fence,
    for (final fighter in [ArenaSpriteNames.hero, ...EnemyKind.values.map(ArenaSpriteNames.enemy)]) ...[
      for (var column = 0; column < 2; column++) ArenaSpriteNames.idle(fighter, column),
      for (var column = 0; column < 6; column++) ArenaSpriteNames.slash(fighter, column),
    ],
  ];

  static ArenaAssets create() {
    return ArenaAssets(
      atlas: _image(frameSize, frameSize),
      frames: {
        for (final name in frameNames)
          name: AtlasFrame(name: name, x: 0, y: 0, width: frameSize, height: frameSize, pivotX: 0.5, pivotY: 1),
      },
    );
  }

  static Image _image(int width, int height) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    return recorder.endRecording().toImageSync(width, height);
  }
}
```

`test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_constants.dart';

void main() {
  test('testWhenNamingFightersThenTheChiefBorrowsTheBarbarianArt', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final names = [ArenaSpriteNames.fighter(null), for (final kind in kinds) ArenaSpriteNames.fighter(kind)];

    // then
    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian']);
    expect(ArenaSpriteNames.idle('bandit', 1), 'bandit-idle-1');
    expect(ArenaSpriteNames.slash('hero', 5), 'hero-slash-5');
  });

  test('testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists', () {
    // given
    final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
    final fighters = [ArenaSpriteNames.fighter(null), ...EnemyKind.values.map(ArenaSpriteNames.fighter)];

    // when
    final wanted = [
      ArenaSpriteNames.grass,
      ArenaSpriteNames.fence,
      for (final fighter in fighters) ...[
        for (var column = 0; column < RenderConstants.idleColumns; column++) ArenaSpriteNames.idle(fighter, column),
        for (var column = 0; column < RenderConstants.workColumns; column++) ArenaSpriteNames.slash(fighter, column),
      ],
    ];

    // then
    expect(wanted.where((name) => !frames.contains(name)), isEmpty);
  });
}
```

`test/layers/presentation/features/arena/game/atlas/arena_assets_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';

import '../../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('testWhenAskingForAnUnknownFrameThenThrows', () {
    // given
    final assets = ArenaAssetsMock.create();

    // when
    void lookUp() => assets.frame('wolf-idle-0');

    // then
    expect(lookUp, throwsArgumentError);
  });

  test('testWhenAskingForASpriteThenCutsTheFrameRectangle', () {
    // given
    final assets = ArenaAssetsMock.create();

    // when
    final sprite = assets.sprite(ArenaSpriteNames.fence);

    // then
    expect((sprite.srcSize.x, sprite.srcSize.y), (8, 8));
  });

  testWidgets('testWhenLoadingTheRealArtThenTheFeetPivotsAndTheFenceAreRead', (tester) async {
    // given
    final loader = ArenaAssetsLoader();

    // when
    final assets = (await tester.runAsync(loader.load))!;

    // then
    final idle = assets.frame(ArenaSpriteNames.idle(ArenaSpriteNames.hero, 0));
    final slash = assets.frame(ArenaSpriteNames.slash(ArenaSpriteNames.hero, 0));
    final fence = assets.frame(ArenaSpriteNames.fence);
    expect((idle.width, idle.height, idle.pivotY), (64, 64, 0.9688));
    expect((slash.width, slash.height, slash.pivotY), (128, 128, 0.7344));
    expect((fence.width, fence.height, fence.pivotX, fence.pivotY), (64, 32, 0.0, 1.0));
    expect(assets.atlas.width, 1024);
  });
}
```

En `test/core/assets/lpc_assets_test.dart`, al final de `_files`:

```dart
  'hero-hammer.png',
  'arena.png',
  'arena.json',
];
```

En `test/architecture_test.dart`:
- `_flameAllowedImporters` gana las dos rutas de la arena:

```dart
const List<String> _flameAllowedImporters = [
  'lib/layers/presentation/features/forest/game/',
  'lib/layers/presentation/features/forest/forest_page.dart',
  'lib/layers/presentation/features/arena/game/',
  'lib/layers/presentation/features/arena/arena_page.dart',
];
```

- el test de la regla se renombra a `testWhenCheckingLibThenFlameIsOnlyImportedByTheGamesAndTheirPages`;
- en `testWhenAWidgetOrBlocImportsFlameThenItIsReportedAndGameAndPageAreNot`, `sources` gana tres entradas y la lista esperada una:

```dart
        'lib/layers/presentation/features/arena/widgets/level_list.dart': "import 'package:flame/game.dart';\n",
        'lib/layers/presentation/features/arena/game/arena_game.dart': "import 'package:flame/game.dart';\n",
        'lib/layers/presentation/features/arena/arena_page.dart': "import 'package:flame/game.dart';\n",
```

```dart
        'lib/layers/presentation/features/arena/widgets/level_list.dart -> package:flame/game.dart',
```

Run: `flutter test test/layers/presentation/features/arena/game/atlas test/core/assets/lpc_assets_test.dart test/architecture_test.dart`
Expected: FAIL de compilación (`arena_assets.dart`, `arena_sprite_names.dart` no existen) y `lpc_assets_test.dart` falla al cargar `arena.png`.

- [x] **Step 3: Generar el atlas**

En `asset-packs/lpc/build_assets.py`:

1. En la cabecera, después de la línea de `ground.png`:

```text
  arena.png + arena.json           JSON-hash atlas for the arena: hero, bandit and barbarian idle (64px, axe in
                                   hand) and slash (128px) frames in their one facing (pivot = feet), the grass
                                   cell and a fence segment
```

2. `body_sheet` recibe los recoloreados (por defecto, los del héroe):

```python
def body_sheet(animation: str, recolours: dict = RECOLOURS) -> Image.Image:
    sheet = None
    for layer in CHARACTER_LAYERS:
        image = Image.open(SOURCES / "character" / f"{layer}__{animation}.png").convert("RGBA")
        if layer in recolours:
            image = recolour(image, *recolours[layer])
        sheet = image if sheet is None else Image.alpha_composite(sheet, image)
    return sheet
```

3. El final de `build_forest` se parte en dos: el atlas pasa a `write_atlas` y el suelo se queda en `build_forest`. Desde `frames["house"] = build_house()` hasta el final de la función queda así:

```python
    frames["house"] = build_house()
    pivots["house"] = {"x": 0.5, "y": 1}

    write_atlas("forest", frames, pivots)

    ground = Image.new("RGBA", (CELL * len(GROUND_TILES), CELL))
    for index, (column, row) in enumerate(GROUND_TILES):
        ground.alpha_composite(terrain.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL)), (index * CELL, 0))
    ground.save(OUT / "ground.png")


def write_atlas(atlas_name: str, frames: dict, pivots: dict) -> None:
    atlas, positions = pack(frames)
    atlas.save(OUT / f"{atlas_name}.png")
    data = {
        "frames": {
            name: {
                "frame": {"x": x, "y": y, "w": frames[name].width, "h": frames[name].height},
                "rotated": False,
                "trimmed": False,
                "spriteSourceSize": {"x": 0, "y": 0, "w": frames[name].width, "h": frames[name].height},
                "sourceSize": {"w": frames[name].width, "h": frames[name].height},
                "pivot": pivots[name],
            }
            for name, (x, y) in positions.items()
        },
        "meta": {"image": f"{atlas_name}.png", "size": {"w": atlas.width, "h": atlas.height}, "scale": "1"},
    }
    (OUT / f"{atlas_name}.json").write_text(json.dumps(data, indent=1))
```

4. Antes de `if __name__ == "__main__":`, la sección de la arena:

```python
# --- Arena atlas -----------------------------------------------------------------------------

# Skin ships in the human ramp, dark -> light; body and head share it.
SKIN_RAMP = [(153, 66, 60), (204, 134, 101), (228, 164, 124), (249, 213, 186), (250, 236, 231)]
BANDIT_RECOLOURS = {
    **RECOLOURS,
    "torso_clothes_longsleeve_longsleeve_male": (CLOTH_RAMP, [(48, 14, 16), (82, 22, 24), (112, 32, 30), (140, 46, 40), (168, 64, 54)]),
    "legs_pants_male": (CLOTH_RAMP, [(28, 22, 24), (44, 34, 36), (62, 48, 48), (82, 64, 62), (104, 82, 78)]),
    "hair_plain_adult": (HAIR_RAMP, [(20, 16, 16), (32, 26, 24), (46, 38, 34), (60, 50, 44), (76, 64, 56)]),
}
BARBARIAN_SKIN = [(78, 38, 30), (120, 72, 50), (146, 96, 66), (172, 122, 88), (196, 156, 126)]
BARBARIAN_RECOLOURS = {
    **RECOLOURS,
    "body_bodies_male": (SKIN_RAMP, BARBARIAN_SKIN),
    "head_heads_human_male": (SKIN_RAMP, BARBARIAN_SKIN),
    "torso_clothes_longsleeve_longsleeve_male": (CLOTH_RAMP, [(44, 28, 16), (74, 48, 26), (102, 68, 38), (130, 90, 52), (158, 114, 70)]),
    "legs_pants_male": (CLOTH_RAMP, [(36, 26, 18), (58, 42, 28), (80, 58, 38), (104, 76, 50), (128, 96, 64)]),
    "hair_plain_adult": (HAIR_RAMP, [(60, 20, 8), (92, 34, 12), (120, 50, 18), (148, 68, 26), (176, 90, 38)]),
}
# Fighter -> (recolours, LPC row): the hero faces right (row 3), the enemies face left (row 1).
ARENA_FIGHTERS = {
    "hero": (RECOLOURS, 3),
    "bandit": (BANDIT_RECOLOURS, 1),
    "barbarian": (BARBARIAN_RECOLOURS, 1),
}
ARENA_GRASS = (1, 23)  # (column, row) of terrain_atlas.png, the same grass as the forest ground
ARENA_FENCE_BOX = (480, 608, 544, 640)  # terrain_atlas.png: a post and a rail, 64x32, tiles horizontally
IDLE_PIVOT = {"x": 0.5, "y": round(62 / FRAME, 4)}
SLASH_PIVOT = {"x": 0.5, "y": round((32 + 62) / WORK_FRAME, 4)}


def cells(sheet: Image.Image, row: int, size: int) -> list:
    return [sheet.crop((column * size, row * size, (column + 1) * size, (row + 1) * size)) for column in range(sheet.width // size)]


def build_arena() -> None:
    terrain = Image.open(SOURCES / "terrain" / "terrain_atlas.png").convert("RGBA")
    frames, pivots = {}, {}
    for fighter, (recolours, row) in ARENA_FIGHTERS.items():
        idle = with_idle_axe(body_sheet("idle", recolours))
        slash = work_sheet(body_sheet("slash", recolours), "axe")
        for column, image in enumerate(cells(idle, row, FRAME)):
            frames[f"{fighter}-idle-{column}"], pivots[f"{fighter}-idle-{column}"] = image, IDLE_PIVOT
        for column, image in enumerate(cells(slash, row, WORK_FRAME)):
            frames[f"{fighter}-slash-{column}"], pivots[f"{fighter}-slash-{column}"] = image, SLASH_PIVOT
    column, row = ARENA_GRASS
    frames["arena-grass"] = terrain.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))
    pivots["arena-grass"] = {"x": 0, "y": 0}
    frames["arena-fence"] = trim(terrain.crop(ARENA_FENCE_BOX), "arena-fence")
    pivots["arena-fence"] = {"x": 0, "y": 1}
    write_atlas("arena", frames, pivots)
```

5. En `__main__`, después de `build_forest()`:

```python
    build_arena()
```

Generar y comprobar que el arte del bosque no cambia:

```bash
(cd asset-packs/lpc && python3 build_assets.py)
git status --short lib/core/assets/images/lpc
```

Expected: `Assets written to …` y sólo dos ficheros nuevos, `?? lib/core/assets/images/lpc/arena.json` y `?? lib/core/assets/images/lpc/arena.png` (1024 × 388, 26 frames). Si aparece modificado `forest.*`, `ground.png` o algún `hero-*.png`, el cambio de `write_atlas` / `body_sheet` está mal: se corrige el script, nunca se edita la imagen a mano.

Ábrelo en un visor: tres filas de luchadores (verde, granate, marrón con la piel oscura), los idle con el hacha en la mano, y a la derecha la hierba y la valla.

- [x] **Step 4: Créditos**

Al final de `lib/core/assets/images/lpc/CREDITS.md`:

```markdown
## Arena (`arena.png`)

Fighters composed by `build_assets.py` from the same character layers and axe as `hero-*.png`
(see *Character* above), each kept in one facing. The bandit and the barbarian are recolours of
those layers (clothes, hair and, for the barbarian, skin); the barbarian chief is the barbarian
drawn bigger. Same authors and licences as the character layers.

The grass (`arena-grass`) and the fence (`arena-fence`) come from the LPC Tile Atlas (see
*Ground and decor* above). CC-BY-SA 3.0 / GPL 3.0.
```

- [x] **Step 5: Implementar el atlas en Dart**

`lib/layers/presentation/features/arena/game/atlas/arena_assets.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../../../forest/game/atlas/atlas_frame.dart';

class ArenaAssets {
  final Image atlas;
  final Map<String, AtlasFrame> frames;

  const ArenaAssets({required this.atlas, required this.frames});

  AtlasFrame frame(String name) {
    final atlasFrame = frames[name];
    if (atlasFrame == null) throw ArgumentError.value(name, 'name', 'Unknown arena frame');
    return atlasFrame;
  }

  Sprite sprite(String name) {
    final atlasFrame = frame(name);
    return Sprite(
      atlas,
      srcPosition: Vector2(atlasFrame.x.toDouble(), atlasFrame.y.toDouble()),
      srcSize: Vector2(atlasFrame.width.toDouble(), atlasFrame.height.toDouble()),
    );
  }
}
```

`lib/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart`:

```dart
import 'package:flame/cache.dart';
import 'package:flutter/services.dart';

import '../../../forest/game/atlas/lpc_assets_loader.dart';
import '../../../forest/game/atlas/lpc_atlas.dart';
import 'arena_assets.dart';

class ArenaAssetsLoader {
  static const String prefix = LpcAssetsLoader.prefix;
  static const String atlasPath = 'lpc/arena.json';
  static const String imagePath = 'lpc/arena.png';

  final AssetBundle _bundle;

  ArenaAssetsLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<ArenaAssets> load() async {
    final images = Images(prefix: prefix, bundle: _bundle);
    final atlas = await images.load(imagePath);
    final atlasSource = await _bundle.loadString('$prefix$atlasPath');
    return ArenaAssets(atlas: atlas, frames: LpcAtlas.parse(atlasSource));
  }
}
```

`lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`:

```dart
import '../../../../../../core/config/constants/enum/enemy_kind.dart';

abstract final class ArenaSpriteNames {
  static const String hero = 'hero';
  static const String grass = 'arena-grass';
  static const String fence = 'arena-fence';

  static String enemy(EnemyKind kind) => switch (kind) {
    EnemyKind.bandit => 'bandit',
    EnemyKind.barbarian => 'barbarian',
    EnemyKind.barbarianChief => 'barbarian',
  };

  static String fighter(EnemyKind? kind) => kind == null ? hero : enemy(kind);

  static String idle(String fighter, int column) => '$fighter-idle-$column';

  static String slash(String fighter, int column) => '$fighter-slash-$column';
}
```

Run: `flutter test test/layers/presentation/features/arena/game/atlas test/core/assets/lpc_assets_test.dart test/architecture_test.dart`
Expected: PASS (5 tests de la arena, los de `lpc_assets_test.dart` y los 15 de arquitectura).

- [x] **Step 6: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/arena test/layers/presentation/features/arena test/mocks/presentation/features/arena test/architecture_test.dart test/core/assets/lpc_assets_test.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida, `No issues found!` y todo en verde.

- [x] **Step 7: Commit y unión a la rama de fase**

```bash
git add asset-packs/lpc/build_assets.py lib/core/assets/images/lpc/arena.png lib/core/assets/images/lpc/arena.json lib/core/assets/images/lpc/CREDITS.md lib/layers/presentation/features/arena/game/atlas test/layers/presentation/features/arena/game/atlas test/mocks/presentation/features/arena/game/arena_assets_mock.dart test/core/assets/lpc_assets_test.dart test/architecture_test.dart
git commit -m "[PROJECT-X]: Build the arena atlas with recoloured bandits and barbarians"
git switch feature/PROJECT-X-c2-arena-screen && git merge --no-ff feature/PROJECT-X-c2-art
```

---

### Task TC2.2: Modelos y `ArenaBloc`

**Files:**
- Create:
  - `lib/core/config/constants/enum/arena/power_tone.dart`
  - `lib/core/config/constants/enum/arena/arena_level_item_status.dart`
  - `lib/core/config/constants/enum/arena/fighter_pose.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart` (sólo los tiempos; TC2.3 lo amplía)
  - `lib/layers/presentation/features/arena/models/arena_level_item_data.dart`
  - `lib/layers/presentation/features/arena/models/fighter_render_data.dart`
  - `lib/layers/presentation/features/arena/models/fight_replay_data.dart`
  - `lib/layers/presentation/features/arena/models/arena_result_data.dart`
  - `lib/layers/presentation/features/arena/models/arena_effect.dart`
  - `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`, `arena_event.dart`, `arena_state.dart`
  - Tests: `test/layers/presentation/features/arena/models/fight_replay_data_test.dart`, `arena_effect_test.dart`, `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - Mocks en `test/mocks/presentation/features/arena/`: `arena_bloc_mock.dart`, `arena_level_item_data_mock.dart`, `fighter_render_data_mock.dart`, `fight_replay_data_mock.dart`, `arena_effect_mock.dart`, `arena_result_data_mock.dart`
- Modify:
  - `lib/core/assets/i18n/translations/es.json` y `lib/core/assets/i18n/internationalize.dart` (bloque `arena`)
  - `test/core/assets/i18n/internationalize_test.dart`
  - `test/mocks/domain/entities/hero/hero_entity_mock.dart` (dos héroes nuevos)

**Interfaces:**
- Consumes (C0/C1): `GetArenaUseCase`, `StartFightUseCase`, `GetHeroStatusUseCase`, `ArenaEntity`, `ArenaLevelStatusEntity`, `ArenaLevelEntity.power`, `FightResultEntity`, `FightLogEntity`, `FightTurnEntity`, `EnemyKind`, `ArenaLevelId`, `FightSide`, `FightAction`, `FightAdvice`, `Resource.gold`; `NavigationService.showErrorPopUp` / `showSnackbar` / `pop`.
- Produces:
  ```dart
  enum PowerTone { easy, even, hard }
  enum ArenaLevelItemStatus { locked, open, cleared }
  enum FighterPose { idle, attack, hurt, down }

  abstract final class ArenaRenderConstants {
    static const double leadInMs = 400;
    static const double turnMs = 600;
    static const double impactShare = 0.5;
  }

  class ArenaLevelItemData {   // id, name, enemiesText, powerText, tone, rewardText, status; bool get isPlayable
  class FighterRenderData {    // side, index, EnemyKind? enemyKind, health, maxHealth, pose, swingProgress; String get key
  class ArenaResultData {      // isVictory, title, detail
  class FightReplayData {
    static const int noTurn = -1;
    final FightLogEntity log; final double elapsedMs; final int turnIndex;
    factory FightReplayData.start(FightLogEntity log);
    double get durationMs; bool get isFinished; int? get swingingTurn; double get swingProgress;
    FightReplayData advanced(double deltaMs); FightReplayData skipped();
    int maxHealthOf(FightSide side, int index); int healthOf(FightSide side, int index);
    int healthBefore(int turn, FightSide side, int index);
  }
  sealed class ArenaEffect;  // HitEffect(side, index, damage), DodgeEffect(side, index),
                             // HealEffect(side, index, amount), FightEndedEffect(isVictory)

  class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
    static const double evenPowerRatio = 1.25;
    ArenaBloc({required GetArenaUseCase getArenaUseCase, required StartFightUseCase startFightUseCase,
               required GetHeroStatusUseCase getHeroStatusUseCase, required NavigationService navigationService});
  }
  // eventos: ArenaStarted, ArenaLevelSelected(levelId), ArenaFightRequested, ArenaReplayTicked(deltaMs),
  //          ArenaReplaySkipped, ArenaClosed
  // estados: ArenaInitial / ArenaInProgress / ArenaSuccess / ArenaFailure(exception), todos con ArenaData
  class ArenaData {  // levels, selected, heroPower, replay, fighters, result, effects;
                     // bool get isReplaying; bool get canFight; copyWith con ValueGetter en los nullables

  // Internationalize (bloque arena)
  arenaTitle, arenaHeroPower(power:), arenaPower(power:), arenaReward(amount:), arenaCleared, arenaLocked,
  arenaFight, arenaBack, arenaSkip, arenaRetry, arenaVictory, arenaDefeat, arenaDamage(amount:),
  arenaHeal(amount:), arenaDodge, arenaEnemyCount(count:, name:), arenaLevel(id:), arenaEnemy(kind:),
  arenaAdvice(advice:), arenaMessageLocked, arenaAccessibilityStage

  // mocks
  HeroEntityMock.dodgerAfterOneFight / .veteranWithSecondWind
  ArenaBlocMock.make(world, navigationService:, error:) / .tickFor / .collectEffects / .frameMs
  ArenaLevelItemDataMock.rookieOpen / .rookieCleared / .veteranLocked / .veteranOpen / .trioLocked / .chiefLocked
  FighterRenderDataMock.heroIdle / .rookieBanditIdle / .veteranBanditIdle / .rookieBanditHurt /
                        .rookieBanditDown / .heroAfterBeatingTheRookie / .heroSwinging(progress)
  FightReplayDataMock.victoryOverBanditStart() / .allActionsStart()
  ArenaEffectMock.banditHitForFour / .heroHitForTwo / .heroDodged / .heroHealedTwelve / .won / .lost /
                  .victoryOverBandit
  ArenaResultDataMock.victoryTenGold / .defeatNeedAttack
  ```

**Peleas reales que usan los tests** (motor de C1, comprobadas ejecutándolo):
- héroe nuevo (`HeroEntityMock.mock`, semilla 0) en `banditRookie`: es exactamente `FightLogEntityMock.victoryOverBandit()` (9 turnos, gana, +10 de oro);
- `HeroEntityMock.veteran` (semilla 3) en `banditVeteran`: derrota con `FightAdvice.needAttack`;
- `HeroEntityMock.dodgerAfterOneFight` (`dodge`, semilla 1) en `banditRookie`: el turno 3 es una esquiva del héroe;
- `HeroEntityMock.veteranWithSecondWind` (`secondWind`, semilla 0) en `banditVeteran`: el turno 10 es el segundo aliento (5 → 17, +12) y pierde.

Ninguno usa `ArenaLevelEntityMock.duel`, `wall` ni `brute` (ficha).

- [x] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-c2-arena-screen && git switch -c feature/PROJECT-X-c2-bloc
```

(O en su worktree, si va a la vez que TC2.1.)

- [x] **Step 2: Textos, primero el test**

En `test/core/assets/i18n/internationalize_test.dart`, imports nuevos

```dart
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
```

y, al final de `main`:

```dart
  test('testWhenFormattingArenaNumbersThenUsesTheSpanishTexts', () {
    // given
    const amount = 10;

    // when
    final reward = Internationalize.arenaReward(amount: amount);
    final power = Internationalize.arenaPower(power: 19);
    final heroPower = Internationalize.arenaHeroPower(power: 31);
    final damage = Internationalize.arenaDamage(amount: 4);
    final heal = Internationalize.arenaHeal(amount: 12);
    final group = Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit));

    // then
    expect(reward, '+10 de oro');
    expect(power, 'Poder 19');
    expect(heroPower, 'Tu Poder: 31');
    expect(damage, '−4');
    expect(heal, '+12');
    expect(group, '3 × Bandido');
  });

  test('testWhenNamingArenaLevelsEnemiesAndAdviceThenUsesTheSpanishTexts', () {
    // given
    // when
    final levels = ArenaLevelId.values.map((id) => Internationalize.arenaLevel(id: id)).toList();
    final enemies = EnemyKind.values.map((kind) => Internationalize.arenaEnemy(kind: kind)).toList();
    final advice = FightAdvice.values.map((advice) => Internationalize.arenaAdvice(advice: advice)).toList();

    // then
    expect(levels, [
      'Bandido novato',
      'Bandido veterano',
      'Trío de bandidos',
      'Bárbaro',
      'Pareja de bárbaros',
      'Jefe bárbaro',
    ]);
    expect(enemies, ['Bandido', 'Bárbaro', 'Jefe bárbaro']);
    expect(advice, [
      '¡Casi lo tienes! Vuelve a intentarlo.',
      'Te falta Ataque: visita la Herrería.',
      'Te falta Defensa: visita la Armería.',
    ]);
    expect((Internationalize.arenaFight, Internationalize.arenaVictory), ('Empezar pelea', '¡Victoria!'));
  });
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: FAIL de compilación (`arenaReward` no existe).

En `es.json`, un bloque nuevo al final (después de `forest`):

```json
  "arena": {
    "title": "Arena",
    "heroPower": "Tu Poder: {power}",
    "power": "Poder {power}",
    "reward": "+{amount} de oro",
    "cleared": "Ganado",
    "locked": "Cerrado",
    "fight": "Empezar pelea",
    "back": "Volver",
    "skip": "Saltar",
    "retry": "Reintentar",
    "victory": "¡Victoria!",
    "defeat": "Derrota",
    "damage": "−{amount}",
    "heal": "+{amount}",
    "dodge": "¡Esquiva!",
    "enemyCount": "{count} × {name}",
    "level": {
      "banditRookie": "Bandido novato",
      "banditVeteran": "Bandido veterano",
      "banditTrio": "Trío de bandidos",
      "barbarian": "Bárbaro",
      "barbarianPair": "Pareja de bárbaros",
      "barbarianChief": "Jefe bárbaro"
    },
    "enemy": {
      "bandit": "Bandido",
      "barbarian": "Bárbaro",
      "barbarianChief": "Jefe bárbaro"
    },
    "advice": {
      "almostThere": "¡Casi lo tienes! Vuelve a intentarlo.",
      "needAttack": "Te falta Ataque: visita la Herrería.",
      "needDefense": "Te falta Defensa: visita la Armería."
    },
    "message": {
      "locked": "Ese nivel todavía está cerrado."
    },
    "accessibility": {
      "stage": "Arena: el héroe frente a sus rivales"
    }
  }
```

En `internationalize.dart`, los imports de `arena_level_id.dart`, `enemy_kind.dart` y `fight_advice.dart`, y al final de la clase:

```dart
  static const String _arena = 'arena';
  static String get arenaTitle => '$_arena.title'.tr();
  static String arenaHeroPower({required int power}) => '$_arena.heroPower'.tr(namedArgs: {'power': '$power'});
  static String arenaPower({required int power}) => '$_arena.power'.tr(namedArgs: {'power': '$power'});
  static String arenaReward({required int amount}) => '$_arena.reward'.tr(namedArgs: {'amount': '$amount'});
  static String get arenaCleared => '$_arena.cleared'.tr();
  static String get arenaLocked => '$_arena.locked'.tr();
  static String get arenaFight => '$_arena.fight'.tr();
  static String get arenaBack => '$_arena.back'.tr();
  static String get arenaSkip => '$_arena.skip'.tr();
  static String get arenaRetry => '$_arena.retry'.tr();
  static String get arenaVictory => '$_arena.victory'.tr();
  static String get arenaDefeat => '$_arena.defeat'.tr();
  static String arenaDamage({required int amount}) => '$_arena.damage'.tr(namedArgs: {'amount': '$amount'});
  static String arenaHeal({required int amount}) => '$_arena.heal'.tr(namedArgs: {'amount': '$amount'});
  static String get arenaDodge => '$_arena.dodge'.tr();
  static String arenaEnemyCount({required int count, required String name}) =>
      '$_arena.enemyCount'.tr(namedArgs: {'count': '$count', 'name': name});
  static String arenaLevel({required ArenaLevelId id}) => switch (id) {
    ArenaLevelId.banditRookie => '$_arena.level.banditRookie'.tr(),
    ArenaLevelId.banditVeteran => '$_arena.level.banditVeteran'.tr(),
    ArenaLevelId.banditTrio => '$_arena.level.banditTrio'.tr(),
    ArenaLevelId.barbarian => '$_arena.level.barbarian'.tr(),
    ArenaLevelId.barbarianPair => '$_arena.level.barbarianPair'.tr(),
    ArenaLevelId.barbarianChief => '$_arena.level.barbarianChief'.tr(),
  };
  static String arenaEnemy({required EnemyKind kind}) => switch (kind) {
    EnemyKind.bandit => '$_arena.enemy.bandit'.tr(),
    EnemyKind.barbarian => '$_arena.enemy.barbarian'.tr(),
    EnemyKind.barbarianChief => '$_arena.enemy.barbarianChief'.tr(),
  };
  static String arenaAdvice({required FightAdvice advice}) => switch (advice) {
    FightAdvice.almostThere => '$_arena.advice.almostThere'.tr(),
    FightAdvice.needAttack => '$_arena.advice.needAttack'.tr(),
    FightAdvice.needDefense => '$_arena.advice.needDefense'.tr(),
  };
  static String get arenaMessageLocked => '$_arena.message.locked'.tr();
  static String get arenaAccessibilityStage => '$_arena.accessibility.stage'.tr();
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: PASS.

- [x] **Step 3: Enums y tiempos**

```dart
// lib/core/config/constants/enum/arena/power_tone.dart
enum PowerTone { easy, even, hard }

// lib/core/config/constants/enum/arena/arena_level_item_status.dart
enum ArenaLevelItemStatus { locked, open, cleared }

// lib/core/config/constants/enum/arena/fighter_pose.dart
enum FighterPose { idle, attack, hurt, down }
```

`lib/layers/presentation/features/arena/game/render/arena_render_constants.dart` (TC2.3 añade el resto):

```dart
abstract final class ArenaRenderConstants {
  static const double leadInMs = 400;
  static const double turnMs = 600;
  static const double impactShare = 0.5;
}
```

- [x] **Step 4: `FightReplayData`, primero el test**

`test/mocks/presentation/features/arena/fight_replay_data_mock.dart`:

```dart
import 'package:rpg/layers/presentation/features/arena/models/fight_replay_data.dart';

import '../../../domain/entities/combat/fight_log_entity_mock.dart';

abstract final class FightReplayDataMock {
  static FightReplayData victoryOverBanditStart() => FightReplayData.start(FightLogEntityMock.victoryOverBandit());

  static FightReplayData allActionsStart() => FightReplayData.start(FightLogEntityMock.allActions());
}
```

`test/layers/presentation/features/arena/models/fight_replay_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';

import '../../../../../mocks/presentation/features/arena/fight_replay_data_mock.dart';

void main() {
  test('testWhenTheReplayStartsThenNothingHasLandedAndEveryoneHasFullHealth', () {
    // given
    // when
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // then
    expect((replay.turnIndex, replay.swingingTurn, replay.isFinished), (-1, null, false));
    expect(replay.durationMs, 400 + 9 * 600);
    expect(replay.healthOf(FightSide.hero, 0), 30);
    expect(replay.healthOf(FightSide.enemy, 0), 20);
  });

  test('testWhenTheFirstSwingIsHalfwayThenTheFirstBlowLands', () {
    // given
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // when
    final halfway = replay.advanced(699);
    final landed = replay.advanced(700);

    // then
    expect((halfway.turnIndex, halfway.swingingTurn), (-1, 0));
    expect(halfway.healthOf(FightSide.enemy, 0), 20);
    expect((landed.turnIndex, landed.swingingTurn, landed.swingProgress), (0, 0, 0.5));
    expect(landed.healthOf(FightSide.enemy, 0), 16);
  });

  test('testWhenAdvancedPastTheEndThenStopsThereWithEveryTurnPlayed', () {
    // given
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // when
    final ended = replay.advanced(100000);

    // then
    expect((ended.elapsedMs, ended.turnIndex, ended.swingingTurn, ended.isFinished), (5800, 8, null, true));
    expect(ended.healthOf(FightSide.hero, 0), 22);
    expect(ended.healthOf(FightSide.enemy, 0), 0);
  });

  test('testWhenSkippedThenItIsTheSameAsAdvancingToTheEnd', () {
    // given
    final replay = FightReplayDataMock.victoryOverBanditStart();

    // when
    final skipped = replay.skipped();

    // then
    expect(skipped, replay.advanced(replay.durationMs));
  });

  test('testWhenASecondWindIsReplayedThenTheHealthBeforeItIsTheLastBlowTaken', () {
    // given
    final replay = FightReplayDataMock.allActionsStart();

    // when
    final afterHeal = replay.advanced(400 + 4 * 600 + 300);

    // then
    expect(afterHeal.turnIndex, 4);
    expect(afterHeal.healthBefore(4, FightSide.hero, 0), 8);
    expect(afterHeal.healthOf(FightSide.hero, 0), 20);
  });
}
```

Run: `flutter test test/layers/presentation/features/arena/models`
Expected: FAIL de compilación (`fight_replay_data.dart` no existe).

`lib/layers/presentation/features/arena/models/fight_replay_data.dart`:

```dart
import 'dart:math' as math;

import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../domain/entities/combat/fight_log_entity.dart';
import '../game/render/arena_render_constants.dart';

class FightReplayData {
  static const int noTurn = -1;

  final FightLogEntity log;
  final double elapsedMs;
  final int turnIndex;

  const FightReplayData({required this.log, required this.elapsedMs, required this.turnIndex});

  factory FightReplayData.start(FightLogEntity log) => FightReplayData(log: log, elapsedMs: 0, turnIndex: noTurn);

  double get durationMs => ArenaRenderConstants.leadInMs + log.turns.length * ArenaRenderConstants.turnMs;

  bool get isFinished => elapsedMs >= durationMs;

  int? get swingingTurn {
    final sinceFirstTurn = elapsedMs - ArenaRenderConstants.leadInMs;
    if (isFinished || sinceFirstTurn < 0) return null;
    return sinceFirstTurn ~/ ArenaRenderConstants.turnMs;
  }

  double get swingProgress {
    final sinceFirstTurn = elapsedMs - ArenaRenderConstants.leadInMs;
    if (isFinished || sinceFirstTurn < 0) return 0;
    return (sinceFirstTurn % ArenaRenderConstants.turnMs) / ArenaRenderConstants.turnMs;
  }

  FightReplayData advanced(double deltaMs) {
    final elapsed = math.min(durationMs, elapsedMs + deltaMs);
    return FightReplayData(log: log, elapsedMs: elapsed, turnIndex: _lastImpactAt(elapsed));
  }

  FightReplayData skipped() => advanced(durationMs);

  int maxHealthOf(FightSide side, int index) {
    return switch (side) {
      FightSide.hero => log.heroStats.health,
      FightSide.enemy => log.enemies[index].stats.health,
    };
  }

  int healthOf(FightSide side, int index) => healthBefore(turnIndex + 1, side, index);

  int healthBefore(int turn, FightSide side, int index) {
    var health = maxHealthOf(side, index);
    for (final played in log.turns.take(turn)) {
      if (played.target == side && played.targetIndex == index) health = played.targetHealthAfter;
    }
    return health;
  }

  int _lastImpactAt(double elapsedMs) {
    final firstImpactMs =
        ArenaRenderConstants.leadInMs + ArenaRenderConstants.impactShare * ArenaRenderConstants.turnMs;
    if (elapsedMs < firstImpactMs) return noTurn;
    return math.min(log.turns.length - 1, (elapsedMs - firstImpactMs) ~/ ArenaRenderConstants.turnMs);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FightReplayData && other.log == log && other.elapsedMs == elapsedMs && other.turnIndex == turnIndex;

  @override
  int get hashCode => Object.hash(log, elapsedMs, turnIndex);
}
```

Run: `flutter test test/layers/presentation/features/arena/models`
Expected: PASS (5 tests).

- [x] **Step 5: Los demás modelos y sus mocks**

`lib/layers/presentation/features/arena/models/arena_level_item_data.dart`:

```dart
import '../../../../../core/config/constants/enum/arena/arena_level_item_status.dart';
import '../../../../../core/config/constants/enum/arena/power_tone.dart';
import '../../../../../core/config/constants/enum/arena_level_id.dart';

class ArenaLevelItemData {
  final ArenaLevelId id;
  final String name;
  final String enemiesText;
  final String powerText;
  final PowerTone tone;
  final String rewardText;
  final ArenaLevelItemStatus status;

  const ArenaLevelItemData({
    required this.id,
    required this.name,
    required this.enemiesText,
    required this.powerText,
    required this.tone,
    required this.rewardText,
    required this.status,
  });

  bool get isPlayable => status != ArenaLevelItemStatus.locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArenaLevelItemData &&
          other.id == id &&
          other.name == name &&
          other.enemiesText == enemiesText &&
          other.powerText == powerText &&
          other.tone == tone &&
          other.rewardText == rewardText &&
          other.status == status;

  @override
  int get hashCode => Object.hash(id, name, enemiesText, powerText, tone, rewardText, status);
}
```

`lib/layers/presentation/features/arena/models/fighter_render_data.dart`:

```dart
import '../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';

class FighterRenderData {
  final FightSide side;
  final int index;
  final EnemyKind? enemyKind;
  final int health;
  final int maxHealth;
  final FighterPose pose;
  final double swingProgress;

  const FighterRenderData({
    required this.side,
    required this.index,
    required this.enemyKind,
    required this.health,
    required this.maxHealth,
    required this.pose,
    this.swingProgress = 0,
  });

  String get key => '${side.name}-$index';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FighterRenderData &&
          other.side == side &&
          other.index == index &&
          other.enemyKind == enemyKind &&
          other.health == health &&
          other.maxHealth == maxHealth &&
          other.pose == pose &&
          other.swingProgress == swingProgress;

  @override
  int get hashCode => Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress);
}
```

`lib/layers/presentation/features/arena/models/arena_result_data.dart`:

```dart
class ArenaResultData {
  final bool isVictory;
  final String title;
  final String detail;

  const ArenaResultData({required this.isVictory, required this.title, required this.detail});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArenaResultData && other.isVictory == isVictory && other.title == title && other.detail == detail;

  @override
  int get hashCode => Object.hash(isVictory, title, detail);
}
```

`lib/layers/presentation/features/arena/models/arena_effect.dart`:

```dart
import '../../../../../core/config/constants/enum/fight_side.dart';

sealed class ArenaEffect {
  const ArenaEffect();
}

final class HitEffect extends ArenaEffect {
  final FightSide side;
  final int index;
  final int damage;

  const HitEffect({required this.side, required this.index, required this.damage});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HitEffect && other.side == side && other.index == index && other.damage == damage;

  @override
  int get hashCode => Object.hash(HitEffect, side, index, damage);
}

final class DodgeEffect extends ArenaEffect {
  final FightSide side;
  final int index;

  const DodgeEffect({required this.side, required this.index});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DodgeEffect && other.side == side && other.index == index;

  @override
  int get hashCode => Object.hash(DodgeEffect, side, index);
}

final class HealEffect extends ArenaEffect {
  final FightSide side;
  final int index;
  final int amount;

  const HealEffect({required this.side, required this.index, required this.amount});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealEffect && other.side == side && other.index == index && other.amount == amount;

  @override
  int get hashCode => Object.hash(HealEffect, side, index, amount);
}

final class FightEndedEffect extends ArenaEffect {
  final bool isVictory;

  const FightEndedEffect({required this.isVictory});

  @override
  bool operator ==(Object other) => identical(this, other) || other is FightEndedEffect && other.isVictory == isVictory;

  @override
  int get hashCode => Object.hash(FightEndedEffect, isVictory);
}
```

Mocks (`test/mocks/presentation/features/arena/`). `arena_effect_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

abstract final class ArenaEffectMock {
  static const HitEffect banditHitForFour = HitEffect(side: FightSide.enemy, index: 0, damage: 4);

  static const HitEffect heroHitForTwo = HitEffect(side: FightSide.hero, index: 0, damage: 2);

  static const DodgeEffect heroDodged = DodgeEffect(side: FightSide.hero, index: 0);

  static const HealEffect heroHealedTwelve = HealEffect(side: FightSide.hero, index: 0, amount: 12);

  static const FightEndedEffect won = FightEndedEffect(isVictory: true);

  static const FightEndedEffect lost = FightEndedEffect(isVictory: false);

  static const List<ArenaEffect> victoryOverBandit = [
    banditHitForFour,
    heroHitForTwo,
    banditHitForFour,
    heroHitForTwo,
    banditHitForFour,
    heroHitForTwo,
    banditHitForFour,
    heroHitForTwo,
    banditHitForFour,
    won,
  ];
}
```

`arena_level_item_data_mock.dart` (Poderes 19, 41, 78 y 173 de `ArenaLevels`):

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/arena/arena_level_item_status.dart';
import 'package:rpg/core/config/constants/enum/arena/power_tone.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_level_item_data.dart';

abstract final class ArenaLevelItemDataMock {
  static ArenaLevelItemData get rookieOpen => ArenaLevelItemData(
    id: ArenaLevelId.banditRookie,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditRookie),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 19),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 10),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get rookieCleared => ArenaLevelItemData(
    id: ArenaLevelId.banditRookie,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditRookie),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 19),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 3),
    status: ArenaLevelItemStatus.cleared,
  );

  static ArenaLevelItemData get veteranLocked => ArenaLevelItemData(
    id: ArenaLevelId.banditVeteran,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 41),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 20),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get veteranOpen => ArenaLevelItemData(
    id: ArenaLevelId.banditVeteran,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 41),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 20),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get trioLocked => ArenaLevelItemData(
    id: ArenaLevelId.banditTrio,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditTrio),
    enemiesText: Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit)),
    powerText: Internationalize.arenaPower(power: 78),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 40),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get chiefLocked => ArenaLevelItemData(
    id: ArenaLevelId.barbarianChief,
    name: Internationalize.arenaLevel(id: ArenaLevelId.barbarianChief),
    enemiesText: [
      Internationalize.arenaEnemy(kind: EnemyKind.barbarianChief),
      Internationalize.arenaEnemyCount(count: 2, name: Internationalize.arenaEnemy(kind: EnemyKind.barbarian)),
    ].join(', '),
    powerText: Internationalize.arenaPower(power: 173),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 100),
    status: ArenaLevelItemStatus.locked,
  );
}
```

`fighter_render_data_mock.dart` (sin `chiefIdle`, que añade TC2.3):

```dart
import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/presentation/features/arena/models/fighter_render_data.dart';

abstract final class FighterRenderDataMock {
  static const FighterRenderData heroIdle = FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.idle,
  );

  static const FighterRenderData rookieBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 20,
    maxHealth: 20,
    pose: FighterPose.idle,
  );

  static const FighterRenderData veteranBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.idle,
  );

  static const FighterRenderData rookieBanditHurt = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 16,
    maxHealth: 20,
    pose: FighterPose.hurt,
  );

  static const FighterRenderData rookieBanditDown = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 0,
    maxHealth: 20,
    pose: FighterPose.down,
  );

  static const FighterRenderData heroAfterBeatingTheRookie = FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 22,
    maxHealth: 30,
    pose: FighterPose.idle,
  );

  static FighterRenderData heroSwinging(double swingProgress) => FighterRenderData(
    side: FightSide.hero,
    index: 0,
    enemyKind: null,
    health: 30,
    maxHealth: 30,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
  );
}
```

`arena_result_data_mock.dart`:

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_result_data.dart';

abstract final class ArenaResultDataMock {
  static ArenaResultData get victoryTenGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaVictory,
    detail: Internationalize.arenaReward(amount: 10),
  );

  static ArenaResultData get defeatNeedAttack => ArenaResultData(
    isVictory: false,
    title: Internationalize.arenaDefeat,
    detail: Internationalize.arenaAdvice(advice: FightAdvice.needAttack),
  );
}
```

En `test/mocks/domain/entities/hero/hero_entity_mock.dart`, al final de la clase:

```dart
  static const HeroEntity dodgerAfterOneFight = HeroEntity(skills: {SkillId.dodge}, fightsFought: 1);

  static const HeroEntity veteranWithSecondWind = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie},
    skills: {SkillId.secondWind},
  );
```

`test/layers/presentation/features/arena/models/arena_effect_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

import '../../../../../mocks/presentation/features/arena/arena_effect_mock.dart';

void main() {
  test('testWhenComparingEffectsThenTheyAreEqualByValue', () {
    // given
    const effects = ArenaEffectMock.victoryOverBandit;

    // when
    final hits = effects.whereType<HitEffect>().toSet();

    // then
    expect(hits, {ArenaEffectMock.banditHitForFour, ArenaEffectMock.heroHitForTwo});
    expect(ArenaEffectMock.won, isNot(ArenaEffectMock.lost));
    expect(ArenaEffectMock.heroDodged.side, FightSide.hero);
    expect(ArenaEffectMock.heroHealedTwelve.hashCode, ArenaEffectMock.heroHealedTwelve.hashCode);
  });
}
```

Run: `flutter test test/layers/presentation/features/arena/models`
Expected: PASS (6 tests).

- [x] **Step 6: Tests del BLoC que fallan**

`test/mocks/presentation/features/arena/arena_bloc_mock.dart` (casos de uso reales sobre `MockGameSessionRepository`, E11):

```dart
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

import '../../../core/services/navigation_service_mocks.mocks.dart';
import '../../../domain/entities/game/game_session_entity_mock.dart';
import '../../../domain/repositories/repository_mocks.mocks.dart';

abstract final class ArenaBlocMock {
  static const double frameMs = 16;

  static ArenaBloc make(World world, {required MockNavigationService navigationService, Exception? error}) {
    final sessionRepository = MockGameSessionRepository();
    final session = GameSessionEntityMock.playing(world);
    when(sessionRepository.current()).thenAnswer((_) {
      if (error != null) throw error;
      return session;
    });
    return ArenaBloc(
      getArenaUseCase: GetArenaUseCase(sessionRepository: sessionRepository),
      startFightUseCase: StartFightUseCase(sessionRepository: sessionRepository),
      getHeroStatusUseCase: GetHeroStatusUseCase(sessionRepository: sessionRepository),
      navigationService: navigationService,
    );
  }

  static void tickFor(ArenaBloc bloc, double totalMs) {
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      bloc.add(const ArenaReplayTicked(deltaMs: frameMs));
      elapsed += frameMs;
    }
  }

  static List<ArenaEffect> collectEffects(ArenaBloc bloc) {
    final effects = <ArenaEffect>[];
    bloc.stream.listen((state) => effects.addAll(state.data.effects));
    return effects;
  }
}
```

`test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/world/world_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_bloc_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_effect_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late World world;
  late List<ArenaEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    world = WorldMock.withHero(HeroEntityMock.mock);
    effects = [];
  });

  blocTest<ArenaBloc, ArenaState>(
    'testWhenStartedThenListsEveryLevelOpensOnlyTheFirstAndSelectsIt',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(bloc.state, isA<ArenaSuccess>());
      expect(data.heroPower, 31);
      expect(data.levels.map((level) => level.id), ArenaLevels.all.map((level) => level.id));
      expect(data.levels[0], ArenaLevelItemDataMock.rookieOpen);
      expect(data.levels[1], ArenaLevelItemDataMock.veteranLocked);
      expect(data.levels[2], ArenaLevelItemDataMock.trioLocked);
      expect(data.levels.last, ArenaLevelItemDataMock.chiefLocked);
      expect(data.selected, ArenaLevelId.banditRookie);
      expect(data.fighters, [FighterRenderDataMock.heroIdle, FighterRenderDataMock.rookieBanditIdle]);
      expect(data.canFight, isTrue);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenThereIsNoGameThenFailsAndShowsTheError',
    build: () {
      // given
      return ArenaBlocMock.make(
        world,
        navigationService: navigationService,
        error: AppExceptionMock.noGameInProgress,
      );
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state, isA<ArenaFailure>());
      verify(
        navigationService.showErrorPopUp(
          title: AppExceptionMock.noGameInProgress.title,
          message: AppExceptionMock.noGameInProgress.message,
          buttonTitle: anyNamed('buttonTitle'),
        ),
      ).called(1);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenSelectingAnOpenLevelThenItIsSelectedAndItsEnemiesWait',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.banditVeteran);
      expect(bloc.state.data.levels[1], ArenaLevelItemDataMock.veteranOpen);
      expect(bloc.state.data.fighters, [FighterRenderDataMock.heroIdle, FighterRenderDataMock.veteranBanditIdle]);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenSelectingALockedLevelThenTheSelectionDoesNotChange',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditTrio));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.banditRookie);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenAFightIsRequestedThenItIsAlreadyPaidAndTheReplayStarts',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(world.funds.amount(Resource.gold), 10);
      expect(world.hero, HeroEntityMock.afterFirstVictory);
      expect((data.replay!.elapsedMs, data.replay!.turnIndex), (0, -1));
      expect(data.isReplaying, isTrue);
      expect(data.canFight, isFalse);
      expect(data.result, isNull);
      expect(data.levels[0], ArenaLevelItemDataMock.rookieOpen);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheFirstBlowLandsThenTheHeroSwingsAndTheBanditIsHurt',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 720);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final fighters = bloc.state.data.fighters;
      expect(fighters[0].pose, FighterPose.attack);
      expect(fighters[0].swingProgress, closeTo(320 / 600, 1e-9));
      expect(fighters[1], FighterRenderDataMock.rookieBanditHurt);
      expect(effects, [ArenaEffectMock.banditHitForFour]);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheReplayEndsThenEveryTurnPlayedOnceAndTheVictoryIsShown',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 6000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(effects, ArenaEffectMock.victoryOverBandit);
      expect(data.replay!.isFinished, isTrue);
      expect(data.result, ArenaResultDataMock.victoryTenGold);
      expect(data.fighters, [FighterRenderDataMock.heroAfterBeatingTheRookie, FighterRenderDataMock.rookieBanditDown]);
      expect(data.levels[0], ArenaLevelItemDataMock.rookieCleared);
      expect(data.levels[1], ArenaLevelItemDataMock.veteranOpen);
      expect(data.canFight, isTrue);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheReplayIsSkippedThenOnlyTheEndIsPlayedAndTheResultIsShown',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects, [ArenaEffectMock.won]);
      expect(bloc.state.data.replay!.isFinished, isTrue);
      expect(bloc.state.data.result, ArenaResultDataMock.victoryTenGold);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheReplayIsRunningThenSelectingAndFightingAreIgnored',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditRookie))
        ..add(const ArenaFightRequested())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.banditRookie);
      expect(world.hero, HeroEntityMock.veteranAfterAnotherFight);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroLosesThenNoGoldIsPaidAndTheAdviceIsShown',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(world.funds.amount(Resource.gold), 0);
      expect(effects, [ArenaEffectMock.lost]);
      expect(bloc.state.data.result, ArenaResultDataMock.defeatNeedAttack);
      expect(bloc.state.data.fighters.first.pose, FighterPose.down);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenRetryingAfterADefeatThenANewFightIsPlayed',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped())
        ..add(const ArenaFightRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(world.hero.fightsFought, 5);
      expect(bloc.state.data.isReplaying, isTrue);
      expect(bloc.state.data.result, isNull);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroDodgesThenTheDodgeIsPlayed',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.dodgerAfterOneFight);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 7000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects[3], ArenaEffectMock.heroDodged);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroGetsASecondWindThenTheHealIsPlayedWithTheHealthGained',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteranWithSecondWind);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 12000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects[10], ArenaEffectMock.heroHealedTwelve);
      expect(effects.last, ArenaEffectMock.lost);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenClosedThenGoesBackToTheForest',
    build: () {
      // given
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaClosed());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      verify(navigationService.pop()).called(1);
    },
  );
}
```

Run: `flutter test test/layers/presentation/features/arena/bloc`
Expected: FAIL de compilación (`arena_bloc.dart` no existe).

- [x] **Step 7: Implementar el BLoC**

`lib/layers/presentation/features/arena/bloc/arena_event.dart`:

```dart
part of 'arena_bloc.dart';

sealed class ArenaEvent {
  const ArenaEvent();
}

final class ArenaStarted extends ArenaEvent {
  const ArenaStarted();
}

final class ArenaLevelSelected extends ArenaEvent {
  final ArenaLevelId levelId;

  const ArenaLevelSelected({required this.levelId});
}

final class ArenaFightRequested extends ArenaEvent {
  const ArenaFightRequested();
}

final class ArenaReplayTicked extends ArenaEvent {
  final double deltaMs;

  const ArenaReplayTicked({required this.deltaMs});
}

final class ArenaReplaySkipped extends ArenaEvent {
  const ArenaReplaySkipped();
}

final class ArenaClosed extends ArenaEvent {
  const ArenaClosed();
}
```

`lib/layers/presentation/features/arena/bloc/arena_state.dart`:

```dart
part of 'arena_bloc.dart';

class ArenaData {
  final List<ArenaLevelItemData> levels;
  final ArenaLevelId? selected;
  final int heroPower;
  final FightReplayData? replay;
  final List<FighterRenderData> fighters;
  final ArenaResultData? result;
  final List<ArenaEffect> effects;

  const ArenaData({
    this.levels = const [],
    this.selected,
    this.heroPower = 0,
    this.replay,
    this.fighters = const [],
    this.result,
    this.effects = const [],
  });

  bool get isReplaying => replay?.isFinished == false;

  bool get canFight => !isReplaying && levels.any((level) => level.id == selected && level.isPlayable);

  ArenaData copyWith({
    List<ArenaLevelItemData>? levels,
    ValueGetter<ArenaLevelId?>? selected,
    int? heroPower,
    ValueGetter<FightReplayData?>? replay,
    List<FighterRenderData>? fighters,
    ValueGetter<ArenaResultData?>? result,
    List<ArenaEffect>? effects,
  }) {
    return ArenaData(
      levels: levels ?? this.levels,
      selected: selected != null ? selected() : this.selected,
      heroPower: heroPower ?? this.heroPower,
      replay: replay != null ? replay() : this.replay,
      fighters: fighters ?? this.fighters,
      result: result != null ? result() : this.result,
      effects: effects ?? this.effects,
    );
  }
}

sealed class ArenaState {
  final ArenaData data;

  const ArenaState({required this.data});
}

final class ArenaInitial extends ArenaState {
  const ArenaInitial() : super(data: const ArenaData());
}

final class ArenaInProgress extends ArenaState {
  const ArenaInProgress({required super.data});
}

final class ArenaSuccess extends ArenaState {
  const ArenaSuccess({required super.data});
}

final class ArenaFailure extends ArenaState {
  final CustomException exception;

  const ArenaFailure({required super.data, required this.exception});
}
```

`lib/layers/presentation/features/arena/bloc/arena_bloc.dart`:

```dart
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/arena/arena_level_item_status.dart';
import '../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../core/config/constants/enum/arena/power_tone.dart';
import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../core/config/constants/enum/fight_action.dart';
import '../../../../../core/config/constants/enum/fight_advice.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../core/config/constants/enum/resource.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../../core/services/navigation/source/navigation_service.dart';
import '../../../../domain/entities/combat/arena_entity.dart';
import '../../../../domain/entities/combat/arena_level_entity.dart';
import '../../../../domain/entities/combat/arena_level_status_entity.dart';
import '../../../../domain/entities/combat/fight_result_entity.dart';
import '../../../../domain/use-cases/arena/get_arena_use_case.dart';
import '../../../../domain/use-cases/arena/start_fight_use_case.dart';
import '../../../../domain/use-cases/hero/get_hero_status_use_case.dart';
import '../game/render/arena_render_constants.dart';
import '../models/arena_effect.dart';
import '../models/arena_level_item_data.dart';
import '../models/arena_result_data.dart';
import '../models/fight_replay_data.dart';
import '../models/fighter_render_data.dart';

part 'arena_event.dart';
part 'arena_state.dart';

class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
  static const double evenPowerRatio = 1.25;

  final GetArenaUseCase _getArenaUseCase;
  final StartFightUseCase _startFightUseCase;
  final GetHeroStatusUseCase _getHeroStatusUseCase;
  final NavigationService _navigationService;

  ArenaEntity? _arena;
  FightAdvice? _advice;

  ArenaBloc({
    required this._getArenaUseCase,
    required this._startFightUseCase,
    required this._getHeroStatusUseCase,
    required this._navigationService,
  }) : super(const ArenaInitial()) {
    on<ArenaEvent>((event, emit) async {
      await switch (event) {
        ArenaStarted() => _onStarted(event, emit),
        ArenaLevelSelected() => _onLevelSelected(event, emit),
        ArenaFightRequested() => _onFightRequested(event, emit),
        ArenaReplayTicked() => _onReplayTicked(event, emit),
        ArenaReplaySkipped() => _onReplaySkipped(event, emit),
        ArenaClosed() => _onClosed(event, emit),
      };
    });
  }

  Future<void> _onStarted(ArenaStarted event, Emitter<ArenaState> emit) async {
    emit(ArenaInProgress(data: state.data));

    try {
      final arena = _getArenaUseCase();
      _arena = arena;
      _advice = null;
      final selected = _defaultSelection(arena);
      emit(
        ArenaSuccess(
          data: _withArena(const ArenaData(), arena).copyWith(
            selected: () => selected,
            fighters: _previewFighters(arena, selected),
          ),
        ),
      );
    } on AppException catch (exception) {
      _navigationService.showErrorPopUp(
        title: exception.title,
        message: exception.message,
        buttonTitle: Internationalize.commonAccept,
      );
      emit(ArenaFailure(data: state.data, exception: exception));
    }
  }

  Future<void> _onLevelSelected(ArenaLevelSelected event, Emitter<ArenaState> emit) async {
    final arena = _arena;
    if (state is! ArenaSuccess || arena == null || state.data.isReplaying) return;
    final level = state.data.levels.firstWhereOrNull((level) => level.id == event.levelId);
    if (level == null || !level.isPlayable) return;
    emit(
      ArenaSuccess(
        data: state.data.copyWith(
          selected: () => event.levelId,
          replay: () => null,
          result: () => null,
          fighters: _previewFighters(arena, event.levelId),
          effects: const [],
        ),
      ),
    );
  }

  Future<void> _onFightRequested(ArenaFightRequested event, Emitter<ArenaState> emit) async {
    final selected = state.data.selected;
    if (state is! ArenaSuccess || selected == null || !state.data.canFight) return;
    switch (_startFightUseCase(levelId: selected)) {
      case FightPlayedEntity(:final log, :final advice):
        _advice = advice;
        final replay = FightReplayData.start(log);
        emit(
          ArenaSuccess(
            data: state.data.copyWith(
              replay: () => replay,
              result: () => null,
              fighters: _replayFighters(replay),
              effects: const [],
            ),
          ),
        );
      case FightLockedEntity():
        _navigationService.showSnackbar(message: Internationalize.arenaMessageLocked);
    }
  }

  Future<void> _onReplayTicked(ArenaReplayTicked event, Emitter<ArenaState> emit) async {
    final replay = state.data.replay;
    if (state is! ArenaSuccess || replay == null || replay.isFinished) return;
    _emitReplay(replay, replay.advanced(event.deltaMs), emit);
  }

  Future<void> _onReplaySkipped(ArenaReplaySkipped event, Emitter<ArenaState> emit) async {
    final replay = state.data.replay;
    if (state is! ArenaSuccess || replay == null || replay.isFinished) return;
    _emitReplay(replay, replay.skipped(), emit, playTurns: false);
  }

  Future<void> _onClosed(ArenaClosed event, Emitter<ArenaState> emit) async {
    _navigationService.pop();
  }

  void _emitReplay(
    FightReplayData previous,
    FightReplayData next,
    Emitter<ArenaState> emit, {
    bool playTurns = true,
  }) {
    final effects = <ArenaEffect>[
      if (playTurns)
        for (var turn = previous.turnIndex + 1; turn <= next.turnIndex; turn++) _effectFor(next, turn),
      if (next.isFinished) FightEndedEffect(isVictory: next.log.isVictory),
    ];
    var data = state.data.copyWith(replay: () => next, fighters: _replayFighters(next), effects: effects);
    if (next.isFinished) {
      final arena = _getArenaUseCase();
      _arena = arena;
      data = _withArena(data, arena).copyWith(result: () => _result(next));
    }
    emit(ArenaSuccess(data: data));
  }

  ArenaEffect _effectFor(FightReplayData replay, int turnIndex) {
    final turn = replay.log.turns[turnIndex];
    return switch (turn.action) {
      FightAction.hit || FightAction.doubleStrike => HitEffect(
        side: turn.target,
        index: turn.targetIndex,
        damage: turn.damage,
      ),
      FightAction.dodge => DodgeEffect(side: turn.target, index: turn.targetIndex),
      FightAction.secondWind => HealEffect(
        side: turn.target,
        index: turn.targetIndex,
        amount: turn.targetHealthAfter - replay.healthBefore(turnIndex, turn.target, turn.targetIndex),
      ),
    };
  }

  ArenaResultData _result(FightReplayData replay) {
    final log = replay.log;
    if (log.isVictory) {
      return ArenaResultData(
        isVictory: true,
        title: Internationalize.arenaVictory,
        detail: Internationalize.arenaReward(amount: log.reward[Resource.gold] ?? 0),
      );
    }
    final advice = _advice;
    return ArenaResultData(
      isVictory: false,
      title: Internationalize.arenaDefeat,
      detail: advice == null ? '' : Internationalize.arenaAdvice(advice: advice),
    );
  }

  ArenaData _withArena(ArenaData data, ArenaEntity arena) {
    return data.copyWith(
      heroPower: arena.heroPower,
      levels: [for (final status in arena.levels) _levelItem(status, heroPower: arena.heroPower)],
    );
  }

  ArenaLevelId? _defaultSelection(ArenaEntity arena) {
    final open = arena.levels.where((status) => status.isUnlocked);
    return (open.firstWhereOrNull((status) => !status.isCleared) ?? open.lastOrNull)?.level.id;
  }

  ArenaLevelItemData _levelItem(ArenaLevelStatusEntity status, {required int heroPower}) {
    final level = status.level;
    return ArenaLevelItemData(
      id: level.id,
      name: Internationalize.arenaLevel(id: level.id),
      enemiesText: _enemiesText(level),
      powerText: Internationalize.arenaPower(power: level.power),
      tone: _tone(levelPower: level.power, heroPower: heroPower),
      rewardText: Internationalize.arenaReward(amount: status.nextReward[Resource.gold] ?? 0),
      status: switch (status) {
        ArenaLevelStatusEntity(isCleared: true) => ArenaLevelItemStatus.cleared,
        ArenaLevelStatusEntity(isUnlocked: true) => ArenaLevelItemStatus.open,
        _ => ArenaLevelItemStatus.locked,
      },
    );
  }

  String _enemiesText(ArenaLevelEntity level) {
    final counts = <String, int>{};
    for (final enemy in level.enemies) {
      final name = Internationalize.arenaEnemy(kind: enemy.kind);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries
        .map(
          (entry) =>
              entry.value == 1 ? entry.key : Internationalize.arenaEnemyCount(count: entry.value, name: entry.key),
        )
        .join(', ');
  }

  PowerTone _tone({required int levelPower, required int heroPower}) {
    if (levelPower <= heroPower) return PowerTone.easy;
    if (levelPower <= heroPower * evenPowerRatio) return PowerTone.even;
    return PowerTone.hard;
  }

  List<FighterRenderData> _previewFighters(ArenaEntity arena, ArenaLevelId? selected) {
    final heroHealth = _getHeroStatusUseCase().stats.health;
    final level = arena.levels.firstWhereOrNull((status) => status.level.id == selected)?.level;
    return [
      FighterRenderData(
        side: FightSide.hero,
        index: 0,
        enemyKind: null,
        health: heroHealth,
        maxHealth: heroHealth,
        pose: FighterPose.idle,
      ),
      if (level != null)
        for (final (index, enemy) in level.enemies.indexed)
          FighterRenderData(
            side: FightSide.enemy,
            index: index,
            enemyKind: enemy.kind,
            health: enemy.stats.health,
            maxHealth: enemy.stats.health,
            pose: FighterPose.idle,
          ),
    ];
  }

  List<FighterRenderData> _replayFighters(FightReplayData replay) {
    final log = replay.log;
    return [
      _replayFighter(replay, FightSide.hero, 0, null),
      for (final (index, enemy) in log.enemies.indexed) _replayFighter(replay, FightSide.enemy, index, enemy.kind),
    ];
  }

  FighterRenderData _replayFighter(FightReplayData replay, FightSide side, int index, EnemyKind? kind) {
    final health = replay.healthOf(side, index);
    final swinging = replay.swingingTurn;
    final turn = swinging == null ? null : replay.log.turns[swinging];
    final progress = replay.swingProgress;
    final isActor = turn != null && turn.actor == side && turn.actorIndex == index;
    final isTarget = turn != null && turn.target == side && turn.targetIndex == index;
    final pose = switch (turn?.action) {
      _ when health == 0 => FighterPose.down,
      FightAction.hit || FightAction.doubleStrike || FightAction.dodge when isActor => FighterPose.attack,
      FightAction.hit || FightAction.doubleStrike
          when isTarget && turn.damage > 0 && progress >= ArenaRenderConstants.impactShare =>
        FighterPose.hurt,
      _ => FighterPose.idle,
    };
    return FighterRenderData(
      side: side,
      index: index,
      enemyKind: kind,
      health: health,
      maxHealth: replay.maxHealthOf(side, index),
      pose: pose,
      swingProgress: pose == FighterPose.attack ? progress : 0,
    );
  }
}
```

Notas:
- los manejadores son síncronos por dentro, como en `ForestBloc`: los `ArenaReplayTicked` se procesan en orden;
- `_onReplayTicked` y `_onReplaySkipped` no hacen nada si no hay reproducción o ya terminó, así que los ticks que lleguen tarde no emiten estados;
- `_emitReplay` emite los efectos de todos los turnos que han impactado desde el estado anterior (un tick largo puede cubrir dos) y, al terminar, `FightEndedEffect`, la lista refrescada y el resultado.

Run: `flutter test test/layers/presentation/features/arena`
Expected: PASS (14 tests del BLoC y 6 de modelos).

- [x] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/arena lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/arena test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/arena test/mocks/presentation/features/arena test/mocks/domain/entities/hero/hero_entity_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida (el BLoC no lleva `@Injectable()`), `No issues found!` y todo en verde.

- [x] **Step 9: Commit y unión a la rama de fase**

```bash
git add lib/core/config/constants/enum/arena lib/core/assets/i18n lib/layers/presentation/features/arena/models lib/layers/presentation/features/arena/bloc lib/layers/presentation/features/arena/game/render/arena_render_constants.dart test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/arena/models test/layers/presentation/features/arena/bloc test/mocks/presentation/features/arena test/mocks/domain/entities/hero/hero_entity_mock.dart
git commit -m "[PROJECT-X]: Replay arena fights turn by turn in the arena bloc"
git switch feature/PROJECT-X-c2-arena-screen && git merge --no-ff feature/PROJECT-X-c2-bloc
```

Si TC2.1 y TC2.2 se unieron por separado, después de la segunda unión: `flutter analyze && flutter test`.

---

### Task TC2.3: Escena Flame de la arena

**Files:**
- Modify:
  - `lib/core/config/constants/enum/forest/particle_kind.dart`
  - `lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`
  - `lib/layers/presentation/features/forest/game/particles/particle_burst_component.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - `test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`
  - `test/mocks/presentation/features/arena/fighter_render_data_mock.dart` (`chiefIdle`)
- Create:
  - `lib/layers/presentation/features/forest/game/components/floating_text_component.dart` (el de F1)
  - `lib/layers/presentation/features/arena/game/render/arena_framing.dart`, `arena_frames.dart`
  - `lib/layers/presentation/features/arena/game/components/arena_ground_component.dart`, `health_bar_component.dart`, `fighter_component.dart`
  - `lib/layers/presentation/features/arena/game/arena_scene_component.dart`, `arena_state_listener.dart`, `arena_game.dart`
  - Tests (en `test/layers/presentation/features/`): `forest/game/components/floating_text_component_test.dart`, `arena/game/render/arena_framing_test.dart`, `arena/game/render/arena_frames_test.dart`, `arena/game/components/health_bar_component_test.dart`, `arena/game/components/fighter_component_test.dart`, `arena/game/arena_scene_component_test.dart`, `arena/game/arena_game_test.dart`
  - Mocks: `test/mocks/presentation/features/arena/arena_data_mock.dart`, `arena_bloc_fake.dart`, `game/arena_assets_loader_fake.dart`

**Interfaces:**
- Consumes: TC2.1 (`ArenaAssets`, `ArenaAssetsLoader`, `ArenaSpriteNames`, `ArenaAssetsMock`), TC2.2 (`ArenaBloc`, `ArenaData`, `ArenaEffect`, `FighterRenderData`, `FighterPose`, `ArenaRenderConstants` de tiempos, mocks); del bosque `ShadowComponent`, `Easing`, `RenderDepth`, `RenderConstants.maxFrameSeconds`, `PlayerFrames.workColumn` / `idleColumn`, `PositionEntityVector.toVector2`, `UpdateProbeComponentFake`.
- Produces:
  ```dart
  enum ParticleKind { woodChip, dust, bloodDrop }
  // ParticleBursts
  static List<Particle> bloodDrops({required PositionEntity impact, required bool attackerOnLeft, required math.Random random});

  // la API exacta de F1 (TF1.2)
  class FloatingTextComponent extends TextComponent<TextPaint> {
    static const Color defaultColor;  static const double startLift, rise, lifetimeMs;
    FloatingTextComponent({required String text, required PositionEntity at, Color color = defaultColor});
    double get alpha;
  }

  // ArenaRenderConstants (además de los tiempos)
  stageWidth, stageHeight, fenceY, minZoom, maxZoom, backgroundColor, heroSpot, enemySpots, chiefScale,
  fighterScale(EnemyKind?), impactHeight, floatingTextHeight, hurtBlinkMs, blinkPeriodMs, fallenAlpha,
  healthBarWidth, healthBarHeight, healthBarLift, healthBarEaseMs, healthBarWarning, healthBarDanger

  abstract final class ArenaFraming { static const Offset center; static double zoom(Size view); }
  abstract final class ArenaFrames {
    static String frameName(FighterRenderData fighter, double animationSeconds);
    static PositionEntity spot(FightSide side, int index);
  }
  class HealthBarComponent extends PositionComponent {   // show(health:, maxHealth:), snap(),
                                                         // targetFraction, displayedFraction, fillColor
  class FighterComponent extends PositionComponent {     // shadow, healthBar, fighter, frameName, isBlinkedOut,
                                                         // impactPoint, headPoint, show(data), hit()
  class ArenaGroundComponent extends PositionComponent;
  class ArenaSceneComponent extends Component {          // fighters (Map por clave), show(ArenaData)
  class ArenaStateListener extends Component with FlameBlocListenable<ArenaBloc, ArenaState>;
  class ArenaGame extends FlameGame {
    ArenaGame({required ArenaBloc bloc, ArenaAssetsLoader? assetsLoader, math.Random? random});
    ArenaSceneComponent? get scene; bool get isReady;
  }

  // mocks
  FighterRenderDataMock.chiefIdle
  ArenaDataMock.preview / .heroAlone / .replaying / .banditHit / .heroDodged / .won
  ArenaBlocFake(initialState) (events, push)
  ArenaAssetsLoaderFake(assets) (loadCalled)
  ```

> **Antes de empezar:** `grep -rn "class FloatingTextComponent" lib`. Si ya existe (F1 llegó a `feature/PROJECT-X-arena` al traer `develop`), en el Step 3 no se crea: se comprueba que su constructor es `({required String text, required PositionEntity at, Color color})` y se añaden los dos tests de este plan al fichero de test de F1, renombrando el primero si coincide.

- [x] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-c2-arena-screen && git switch -c feature/PROJECT-X-c2-scene
```

(TC2.4 puede ir a la vez en otro worktree.)

- [x] **Step 2: Gotas de sangre, primero el test**

Al final de `main` en `test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`:

```dart
  test('testWhenTheHeroHitsAnEnemyThenAFewDropsOfBloodFlyAwayFromHim', () {
    // given
    const impact = ParticleMock.trunkBase;

    // when
    final drops = ParticleBursts.bloodDrops(impact: impact, attackerOnLeft: true, random: ParticleMock.seededOne);

    // then
    expect(drops.length, inInclusiveRange(4, 6));
    for (final drop in drops) {
      expect(drop.kind, ParticleKind.bloodDrop);
      expect(drop.origin, impact);
      expect(_angleDegrees(drop.velocityX, drop.velocityY), inInclusiveRange(280, 340));
      expect(drop.gravity, 260);
      expect(drop.lifespanSeconds, 0.4);
      expect(drop.alpha(0.4), 0);
    }
  });

  test('testWhenAnEnemyHitsTheHeroThenTheBloodFliesTheOtherWay', () {
    // given
    const impact = ParticleMock.trunkBase;

    // when
    final drops = ParticleBursts.bloodDrops(impact: impact, attackerOnLeft: false, random: ParticleMock.seededOne);

    // then
    for (final drop in drops) {
      expect(_angleDegrees(drop.velocityX, drop.velocityY), inInclusiveRange(200, 260));
    }
  });
```

Run: `flutter test test/layers/presentation/features/forest/game/particles`
Expected: FAIL de compilación (`bloodDrops` y `ParticleKind.bloodDrop` no existen).

`lib/core/config/constants/enum/forest/particle_kind.dart`:

```dart
enum ParticleKind { woodChip, dust, bloodDrop }
```

En `particle_bursts.dart`, después de `sortYOffset`:

```dart
  static const int bloodDropsMin = 4;
  static const int bloodDropsMax = 6;
  static const double bloodAngleAwayFromLeftMin = 280;
  static const double bloodAngleAwayFromLeftMax = 340;
  static const double bloodAngleAwayFromRightMin = 200;
  static const double bloodAngleAwayFromRightMax = 260;
  static const double bloodSpeedMin = 25;
  static const double bloodSpeedMax = 60;
  static const double bloodGravity = 260;
  static const double bloodLifespanSeconds = 0.4;
  static const double bloodAlphaStart = 1;
  static const double bloodAlphaEnd = 0;
  static const double bloodScale = 1;
```

y antes de `chipsSortY`:

```dart
  static List<Particle> bloodDrops({
    required PositionEntity impact,
    required bool attackerOnLeft,
    required math.Random random,
  }) {
    final minAngle = attackerOnLeft ? bloodAngleAwayFromLeftMin : bloodAngleAwayFromRightMin;
    final maxAngle = attackerOnLeft ? bloodAngleAwayFromLeftMax : bloodAngleAwayFromRightMax;
    final count = bloodDropsMin + random.nextInt(bloodDropsMax - bloodDropsMin + 1);
    return List.generate(count, (_) {
      final speed = _between(random, bloodSpeedMin, bloodSpeedMax);
      final angle = _between(random, minAngle, maxAngle) * math.pi / 180;
      return Particle(
        kind: ParticleKind.bloodDrop,
        origin: impact,
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: bloodGravity,
        rotationDegrees: 0,
        lifespanSeconds: bloodLifespanSeconds,
        alphaStart: bloodAlphaStart,
        alphaEnd: bloodAlphaEnd,
        scaleStart: bloodScale,
        scaleEnd: bloodScale,
      );
    });
  }
```

En `particle_burst_component.dart`, dos constantes después de `chipHighlight`

```dart
  static const Color bloodColor = Color(0xFF9E1B1B);
  static const Rect bloodDrop = Rect.fromLTWH(-1, -1, 2, 2);
```

y un caso más en el `switch` de `render`, después del de `ParticleKind.dust`:

```dart
        case ParticleKind.bloodDrop:
          _paint.color = bloodColor.withValues(alpha: alpha);
          canvas.drawRect(bloodDrop.shift(Offset(at.x, at.y)), _paint);
```

Run: `flutter test test/layers/presentation/features/forest/game/particles`
Expected: PASS.

- [x] **Step 3: `FloatingTextComponent` (el de F1), primero el test**

`test/layers/presentation/features/forest/game/components/floating_text_component_test.dart` (los mismos dos tests que F1, con un texto de la arena):

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/floating_text_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWithFlameGame('testWhenAddedThenShowsTheTextAboveThePointOverEverything', (game) async {
    // given
    final floating = FloatingTextComponent(
      text: Internationalize.arenaDamage(amount: 8),
      at: const PositionEntity(x: 100, y: 120),
    );

    // when
    await game.ensureAdd(floating);

    // then
    expect(floating.text, Internationalize.arenaDamage(amount: 8));
    expect(floating.position, Vector2(100, 100));
    expect(floating.anchor, Anchor.bottomCenter);
    expect(floating.priority, RenderDepth.overlay);
    expect(floating.alpha, 1);
  });

  testWithFlameGame('testWhenTimePassesThenRisesFadesAndRemovesItself', (game) async {
    // given
    final floating = FloatingTextComponent(
      text: Internationalize.arenaDamage(amount: 4),
      at: const PositionEntity(x: 100, y: 120),
    );
    await game.ensureAdd(floating);

    // when
    game.update(0.45);
    final halfwayY = floating.position.y;
    final halfwayAlpha = floating.alpha;
    game.update(0.225);
    final fadingAlpha = floating.alpha;
    game.update(0.3);
    await game.ready();

    // then
    expect(halfwayY, closeTo(87.27, 0.01));
    expect(halfwayAlpha, closeTo(1, 0.001));
    expect(fadingAlpha, closeTo(0.5, 0.001));
    expect(floating.isMounted, isFalse);
  });
}
```

Run: `flutter test test/layers/presentation/features/forest/game/components/floating_text_component_test.dart`
Expected: FAIL de compilación (`floating_text_component.dart` no existe).

`lib/layers/presentation/features/forest/game/components/floating_text_component.dart` (copia literal de TF1.2, Step 6):

```dart
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../theme/colors/custom_colors.dart';
import '../render/easing.dart';
import '../render/render_depth.dart';

class FloatingTextComponent extends TextComponent<TextPaint> {
  static const Color defaultColor = CustomColors.hudAccent;
  static const Color outlineColor = CustomColors.black;
  static const double fontSize = 9;
  static const double startLift = 20;
  static const double rise = 18;
  static const double lifetimeMs = 900;
  static const double fadeStart = 0.5;

  final Color color;
  final double _startY;
  double _elapsedMs = 0;

  FloatingTextComponent({required String text, required PositionEntity at, this.color = defaultColor})
    : _startY = at.y - startLift,
      super(
        text: text,
        textRenderer: TextPaint(style: _style(color, 1)),
        position: Vector2(at.x, at.y - startLift),
        anchor: Anchor.bottomCenter,
        priority: RenderDepth.overlay,
      );

  double get alpha {
    final progress = _progress;
    if (progress <= fadeStart) return 1;
    return 1 - (progress - fadeStart) / (1 - fadeStart);
  }

  double get _progress => math.min(1.0, _elapsedMs / lifetimeMs);

  static TextStyle _style(Color color, double alpha) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color.withValues(alpha: alpha),
    shadows: [
      Shadow(
        color: outlineColor.withValues(alpha: alpha),
        offset: const Offset(0.5, 0.5),
      ),
    ],
  );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedMs += dt * 1000;
    position.y = _startY - rise * Easing.sineOut(_progress);
    textRenderer = TextPaint(style: _style(color, alpha));
    if (_progress >= 1) removeFromParent();
  }
}
```

Run: el mismo comando. Expected: PASS (2 tests).

- [x] **Step 4: Constantes, encuadre y frames, primero el test**

`test/layers/presentation/features/arena/game/render/arena_framing_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_framing.dart';

void main() {
  test('testWhenFramingTheStageThenTheGrassCoversTheWholeView', () {
    // given
    const phone = Size(844, 390);
    const desktop = Size(1280, 720);

    // when
    final phoneZoom = ArenaFraming.zoom(phone);
    final desktopZoom = ArenaFraming.zoom(desktop);

    // then
    expect(phoneZoom, closeTo(844 / 480, 1e-9));
    expect(desktopZoom, closeTo(1280 / 480, 1e-9));
    expect(ArenaFraming.center, const Offset(240, 135));
  });

  test('testWhenTheViewIsTinyOrHugeThenTheZoomIsClamped', () {
    // given
    const tiny = Size(200, 100);
    const huge = Size(3840, 2160);

    // when
    final tinyZoom = ArenaFraming.zoom(tiny);
    final hugeZoom = ArenaFraming.zoom(huge);

    // then
    expect((tinyZoom, hugeZoom), (1, 3));
  });
}
```

En `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`, al final de la clase:

```dart
  static const FighterRenderData chiefIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.barbarianChief,
    health: 70,
    maxHealth: 70,
    pose: FighterPose.idle,
  );
```

`test/layers/presentation/features/arena/game/render/arena_frames_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_frames.dart';

import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';

void main() {
  test('testWhenAFighterSwingsThenTheSlashFrameFollowsTheChopSequence', () {
    // given
    final start = FighterRenderDataMock.heroSwinging(0);
    final impact = FighterRenderDataMock.heroSwinging(0.5);

    // when
    final startName = ArenaFrames.frameName(start, 0);
    final impactName = ArenaFrames.frameName(impact, 0);

    // then
    expect(startName, 'hero-slash-0');
    expect(impactName, 'hero-slash-4');
  });

  test('testWhenAFighterIsIdleHurtOrDownThenTheIdleFramesAreUsed', () {
    // given
    const idle = FighterRenderDataMock.rookieBanditIdle;
    const hurt = FighterRenderDataMock.rookieBanditHurt;
    const down = FighterRenderDataMock.rookieBanditDown;

    // when
    final names = [ArenaFrames.frameName(idle, 0.6), ArenaFrames.frameName(hurt, 0), ArenaFrames.frameName(down, 0.6)];

    // then
    expect(names, ['bandit-idle-1', 'bandit-idle-0', 'bandit-idle-0']);
    expect(ArenaFrames.frameName(FighterRenderDataMock.chiefIdle, 0), 'barbarian-idle-0');
  });

  test('testWhenPlacingFightersThenTheHeroFacesTheEnemiesFromTheLeft', () {
    // given
    // when
    final hero = ArenaFrames.spot(FightSide.hero, 0);
    final enemies = [for (var index = 0; index < 3; index++) ArenaFrames.spot(FightSide.enemy, index)];

    // then
    expect(hero, const PositionEntity(x: 190, y: 170));
    expect(enemies, const [
      PositionEntity(x: 300, y: 170),
      PositionEntity(x: 340, y: 140),
      PositionEntity(x: 340, y: 200),
    ]);
  });
}
```

Run: `flutter test test/layers/presentation/features/arena/game/render`
Expected: FAIL de compilación.

`lib/layers/presentation/features/arena/game/render/arena_render_constants.dart` completo:

```dart
import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';

abstract final class ArenaRenderConstants {
  static const double leadInMs = 400;
  static const double turnMs = 600;
  static const double impactShare = 0.5;

  static const double stageWidth = 480;
  static const double stageHeight = 270;
  static const double fenceY = 72;
  static const double minZoom = 1;
  static const double maxZoom = 3;
  static const int backgroundColor = 0xFF0E150E;

  static const PositionEntity heroSpot = PositionEntity(x: 190, y: 170);
  static const List<PositionEntity> enemySpots = [
    PositionEntity(x: 300, y: 170),
    PositionEntity(x: 340, y: 140),
    PositionEntity(x: 340, y: 200),
  ];
  static const double chiefScale = 1.25;

  static double fighterScale(EnemyKind? kind) => switch (kind) {
    null || EnemyKind.bandit || EnemyKind.barbarian => 1,
    EnemyKind.barbarianChief => chiefScale,
  };

  static const double impactHeight = 28;
  static const double floatingTextHeight = 36;
  static const double hurtBlinkMs = 300;
  static const double blinkPeriodMs = 80;
  static const double fallenAlpha = 0.8;

  static const double healthBarWidth = 28;
  static const double healthBarHeight = 4;
  static const double healthBarLift = 52;
  static const double healthBarEaseMs = 300;
  static const double healthBarWarning = 0.5;
  static const double healthBarDanger = 0.25;
}
```

`lib/layers/presentation/features/arena/game/render/arena_framing.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'arena_render_constants.dart';

abstract final class ArenaFraming {
  static const Offset center = Offset(ArenaRenderConstants.stageWidth / 2, ArenaRenderConstants.stageHeight / 2);

  static double zoom(Size view) {
    final cover = math.max(
      view.width / ArenaRenderConstants.stageWidth,
      view.height / ArenaRenderConstants.stageHeight,
    );
    return cover.clamp(ArenaRenderConstants.minZoom, ArenaRenderConstants.maxZoom).toDouble();
  }
}
```

`lib/layers/presentation/features/arena/game/render/arena_frames.dart`:

```dart
import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../forest/game/render/player_frames.dart';
import '../../models/fighter_render_data.dart';
import '../atlas/arena_sprite_names.dart';
import 'arena_render_constants.dart';

abstract final class ArenaFrames {
  static String frameName(FighterRenderData fighter, double animationSeconds) {
    final name = ArenaSpriteNames.fighter(fighter.enemyKind);
    return switch (fighter.pose) {
      FighterPose.attack => ArenaSpriteNames.slash(name, PlayerFrames.workColumn(WorkTool.axe, fighter.swingProgress)),
      FighterPose.idle || FighterPose.hurt => ArenaSpriteNames.idle(name, PlayerFrames.idleColumn(animationSeconds)),
      FighterPose.down => ArenaSpriteNames.idle(name, 0),
    };
  }

  static PositionEntity spot(FightSide side, int index) {
    return switch (side) {
      FightSide.hero => ArenaRenderConstants.heroSpot,
      FightSide.enemy => ArenaRenderConstants.enemySpots[index],
    };
  }
}
```

Run: `flutter test test/layers/presentation/features/arena/game/render`
Expected: PASS (5 tests).

- [x] **Step 5: Barra de vida y luchador, primero el test**

`test/layers/presentation/features/arena/game/components/health_bar_component_test.dart` (`0.7071` = `sineOut(0,5)`: a mitad de la animación la barra ha bajado el 70,7 % del camino):

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/components/health_bar_component.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

void main() {
  testWithFlameGame('testWhenHealthDropsThenTheBarEasesDownToTheNewValue', (game) async {
    // given
    final bar = HealthBarComponent(position: Vector2(100, 100));
    await game.ensureAdd(bar);

    // when
    bar.show(health: 10, maxHealth: 20);
    final atStart = bar.displayedFraction;
    game.update(0.15);
    final halfway = bar.displayedFraction;
    game.update(0.2);

    // then
    expect(atStart, 1);
    expect(halfway, closeTo(1 - 0.5 * 0.7071, 0.001));
    expect(bar.displayedFraction, 0.5);
    expect(bar.fillColor, CustomColors.warning);
  });

  testWithFlameGame('testWhenSnappedThenTheBarJumpsToTheTargetAndTurnsRedWhenLow', (game) async {
    // given
    final bar = HealthBarComponent(position: Vector2(100, 100));
    await game.ensureAdd(bar);
    bar.show(health: 2, maxHealth: 20);

    // when
    bar.snap();

    // then
    expect(bar.displayedFraction, closeTo(0.1, 1e-9));
    expect(bar.fillColor, CustomColors.error);
  });
}
```

`test/layers/presentation/features/arena/game/components/fighter_component_test.dart` (barra a 300, 170 − 52 = 118; la del jefe a 170 − 52 × 1,25 = 105; el parpadeo apaga el sprite en los tramos impares de 80 ms desde el golpe):

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/components/fighter_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';
import '../../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenCreatedThenStandsOnItsSpotWithAFullBar', (game) async {
    // given
    final fighter = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);

    // when
    await game.ensureAdd(fighter);

    // then
    expect(fighter.position, Vector2(300, 170));
    expect(fighter.priority, RenderDepth.bySortY(170));
    expect(fighter.healthBar.position, Vector2(300, 118));
    expect(fighter.healthBar.displayedFraction, 1);
    expect(fighter.frameName, 'bandit-idle-0');
  });

  testWithFlameGame('testWhenTheChiefIsShownThenItIsTheBarbarianBigger', (game) async {
    // given
    final chief = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.chiefIdle);

    // when
    await game.ensureAdd(chief);

    // then
    expect(chief.scale, Vector2.all(1.25));
    expect(chief.frameName, 'barbarian-idle-0');
    expect(chief.healthBar.position, Vector2(300, 105));
  });

  testWithFlameGame('testWhenHitThenBlinksForAMomentAndTheBarFollowsTheHealth', (game) async {
    // given
    final fighter = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);
    await game.ensureAdd(fighter);

    // when
    fighter
      ..show(FighterRenderDataMock.rookieBanditHurt)
      ..hit();
    game.update(0.1);
    final blinking = fighter.isBlinkedOut;
    game.update(0.25);

    // then
    expect(blinking, isTrue);
    expect(fighter.isBlinkedOut, isFalse);
    expect(fighter.healthBar.targetFraction, 0.8);
  });
}
```

Run: `flutter test test/layers/presentation/features/arena/game/components`
Expected: FAIL de compilación.

`lib/layers/presentation/features/arena/game/components/health_bar_component.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../theme/colors/custom_colors.dart';
import '../../../forest/game/render/easing.dart';
import '../../../forest/game/render/render_depth.dart';
import '../render/arena_render_constants.dart';

class HealthBarComponent extends PositionComponent {
  static const Color trackColor = Color(0xCC1C1610);

  final Paint _trackPaint = Paint()..color = trackColor;
  final Paint _fillPaint = Paint();
  double _from = 1;
  double _target = 1;
  double _elapsedMs = ArenaRenderConstants.healthBarEaseMs;

  HealthBarComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(ArenaRenderConstants.healthBarWidth, ArenaRenderConstants.healthBarHeight),
        anchor: Anchor.bottomCenter,
        priority: RenderDepth.overlay - 1,
      );

  double get targetFraction => _target;

  double get displayedFraction {
    final progress = math.min(1.0, _elapsedMs / ArenaRenderConstants.healthBarEaseMs);
    return _from + (_target - _from) * Easing.sineOut(progress);
  }

  Color get fillColor {
    final fraction = displayedFraction;
    if (fraction > ArenaRenderConstants.healthBarWarning) return CustomColors.success;
    if (fraction > ArenaRenderConstants.healthBarDanger) return CustomColors.warning;
    return CustomColors.error;
  }

  void show({required int health, required int maxHealth}) {
    final target = maxHealth <= 0 ? 0.0 : (health / maxHealth).clamp(0, 1).toDouble();
    if (target == _target) return;
    _from = displayedFraction;
    _target = target;
    _elapsedMs = 0;
  }

  void snap() {
    _from = _target;
    _elapsedMs = ArenaRenderConstants.healthBarEaseMs;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedMs += dt * 1000;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _trackPaint);
    _fillPaint.color = fillColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x * displayedFraction, size.y), _fillPaint);
  }
}
```

`lib/layers/presentation/features/arena/game/components/fighter_component.dart` (se dibuja con el pivote del frame; caído, girado 90° hacia atrás y al 80 %):

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../forest/game/components/shadow_component.dart';
import '../../../forest/game/render/position_conversion.dart';
import '../../../forest/game/render/render_depth.dart';
import '../../models/fighter_render_data.dart';
import '../atlas/arena_assets.dart';
import '../render/arena_frames.dart';
import '../render/arena_render_constants.dart';
import 'health_bar_component.dart';

class FighterComponent extends PositionComponent {
  static const double shadowWidth = 22;
  static const double shadowHeight = 7;

  final ArenaAssets _assets;
  final ShadowComponent shadow;
  final HealthBarComponent healthBar;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  FighterRenderData _fighter;
  double _animationSeconds = 0;
  double _blinkMs = 0;

  FighterComponent({required this._assets, required FighterRenderData fighter})
    : _fighter = fighter,
      shadow = ShadowComponent(
        center: ArenaFrames.spot(fighter.side, fighter.index).toVector2(),
        size: Vector2(shadowWidth, shadowHeight) * ArenaRenderConstants.fighterScale(fighter.enemyKind),
      ),
      healthBar = HealthBarComponent(
        position: ArenaFrames.spot(fighter.side, fighter.index).toVector2()
          ..y -= ArenaRenderConstants.healthBarLift * ArenaRenderConstants.fighterScale(fighter.enemyKind),
      ),
      super(
        position: ArenaFrames.spot(fighter.side, fighter.index).toVector2(),
        scale: Vector2.all(ArenaRenderConstants.fighterScale(fighter.enemyKind)),
        priority: RenderDepth.bySortY(ArenaFrames.spot(fighter.side, fighter.index).y),
      ) {
    healthBar
      ..show(health: fighter.health, maxHealth: fighter.maxHealth)
      ..snap();
  }

  FighterRenderData get fighter => _fighter;

  String get frameName => ArenaFrames.frameName(_fighter, _animationSeconds);

  bool get isBlinkedOut =>
      _blinkMs > 0 && ((ArenaRenderConstants.hurtBlinkMs - _blinkMs) ~/ ArenaRenderConstants.blinkPeriodMs).isOdd;

  PositionEntity get impactPoint => PositionEntity(
    x: position.x,
    y: position.y - ArenaRenderConstants.impactHeight * scale.y,
  );

  PositionEntity get headPoint => PositionEntity(
    x: position.x,
    y: position.y - ArenaRenderConstants.floatingTextHeight * scale.y,
  );

  void show(FighterRenderData fighter) {
    _fighter = fighter;
    healthBar.show(health: fighter.health, maxHealth: fighter.maxHealth);
  }

  void hit() {
    _blinkMs = ArenaRenderConstants.hurtBlinkMs;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationSeconds += dt;
    _blinkMs = math.max(0, _blinkMs - dt * 1000);
  }

  @override
  void render(Canvas canvas) {
    if (isBlinkedOut) return;
    final frame = _assets.frame(frameName);
    final sprite = _assets.sprite(frameName);
    final isDown = _fighter.pose == FighterPose.down;
    _paint.color = Color.fromRGBO(255, 255, 255, isDown ? ArenaRenderConstants.fallenAlpha : 1);
    canvas.save();
    if (isDown) canvas.rotate((_fighter.side == FightSide.hero ? -1 : 1) * math.pi / 2);
    sprite.render(
      canvas,
      position: Vector2(-frame.width * frame.pivotX, -frame.height * frame.pivotY),
      overridePaint: _paint,
    );
    canvas.restore();
  }
}
```

Run: `flutter test test/layers/presentation/features/arena/game/components`
Expected: PASS (5 tests).

- [x] **Step 6: Escena y juego, primero el test**

`test/mocks/presentation/features/arena/arena_data_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';

import 'arena_effect_mock.dart';
import 'arena_level_item_data_mock.dart';
import 'arena_result_data_mock.dart';
import 'fight_replay_data_mock.dart';
import 'fighter_render_data_mock.dart';

abstract final class ArenaDataMock {
  static ArenaData get preview => ArenaData(
    levels: [ArenaLevelItemDataMock.rookieOpen, ArenaLevelItemDataMock.veteranLocked],
    selected: ArenaLevelId.banditRookie,
    heroPower: 31,
    fighters: const [FighterRenderDataMock.heroIdle, FighterRenderDataMock.rookieBanditIdle],
  );

  static ArenaData get heroAlone => preview.copyWith(fighters: const [FighterRenderDataMock.heroIdle]);

  static ArenaData get replaying => preview.copyWith(replay: FightReplayDataMock.victoryOverBanditStart);

  static ArenaData get banditHit => replaying.copyWith(
    fighters: const [FighterRenderDataMock.heroIdle, FighterRenderDataMock.rookieBanditHurt],
    effects: const [ArenaEffectMock.banditHitForFour],
  );

  static ArenaData get heroDodged => replaying.copyWith(effects: const [ArenaEffectMock.heroDodged]);

  static ArenaData get won => preview.copyWith(
    replay: () => FightReplayDataMock.victoryOverBanditStart().skipped(),
    fighters: const [FighterRenderDataMock.heroAfterBeatingTheRookie, FighterRenderDataMock.rookieBanditDown],
    result: () => ArenaResultDataMock.victoryTenGold,
    effects: const [ArenaEffectMock.won],
  );
}
```

`test/mocks/presentation/features/arena/arena_bloc_fake.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';

class ArenaBlocFake extends Bloc<ArenaEvent, ArenaState> implements ArenaBloc {
  final List<ArenaEvent> events = [];

  ArenaBlocFake(super.initialState) {
    on<ArenaEvent>((event, emit) => events.add(event));
  }

  void push(ArenaState state) => emit(state);
}
```

`test/mocks/presentation/features/arena/game/arena_assets_loader_fake.dart`:

```dart
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart';

class ArenaAssetsLoaderFake implements ArenaAssetsLoader {
  ArenaAssetsLoaderFake(this.assets);

  final ArenaAssets assets;
  bool loadCalled = false;

  @override
  Future<ArenaAssets> load() async {
    loadCalled = true;
    return assets;
  }
}
```

`test/layers/presentation/features/arena/game/arena_scene_component_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/game/arena_scene_component.dart';
import 'package:rpg/layers/presentation/features/arena/game/components/arena_ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/floating_text_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

Future<ArenaSceneComponent> _mountedScene(FlameGame game) async {
  final scene = ArenaSceneComponent(assets: ArenaAssetsMock.create(), random: math.Random(1));
  await game.ensureAdd(scene);
  scene.show(ArenaDataMock.preview);
  await game.ready();
  return scene;
}

void main() {
  setUpAll(loadSpanishTranslations);

  testWithFlameGame('testWhenShowingTheFirstStateThenBuildsTheStageAndTheFighters', (game) async {
    // given
    final scene = ArenaSceneComponent(assets: ArenaAssetsMock.create(), random: math.Random(1));
    await game.ensureAdd(scene);

    // when
    scene.show(ArenaDataMock.preview);
    await game.ready();

    // then
    expect(scene.children.whereType<ArenaGroundComponent>(), hasLength(1));
    expect(scene.fighters.keys, ['hero-0', 'enemy-0']);
  });

  testWithFlameGame('testWhenTheLevelChangesThenFightersThatLeftAreRemoved', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.heroAlone);
    await game.ready();

    // then
    expect(scene.fighters.keys, ['hero-0']);
  });

  testWithFlameGame('testWhenABlowLandsThenTheDamageFloatsAndBloodSplashes', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.banditHit);
    await game.ready();

    // then
    final texts = scene.children.whereType<FloatingTextComponent>().map((text) => text.text);
    expect(texts, [Internationalize.arenaDamage(amount: 4)]);
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
    expect(scene.fighters['enemy-0']!.healthBar.targetFraction, 0.8);
    expect(scene.fighters['enemy-0']!.isBlinkedOut, isFalse);
  });

  testWithFlameGame('testWhenTheHeroDodgesThenTheDodgeFloatsWithoutBlood', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.heroDodged);
    await game.ready();

    // then
    final texts = scene.children.whereType<FloatingTextComponent>().map((text) => text.text);
    expect(texts, [Internationalize.arenaDodge]);
    expect(scene.children.whereType<ParticleBurstComponent>(), isEmpty);
  });

  testWithFlameGame('testWhenTheFightEndsThenTheBarsJumpToTheFinalHealth', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.won);
    await game.ready();

    // then
    expect(scene.fighters['enemy-0']!.healthBar.displayedFraction, 0);
    expect(scene.fighters['hero-0']!.healthBar.displayedFraction, closeTo(22 / 30, 1e-9));
  });
}
```

`test/layers/presentation/features/arena/game/arena_game_test.dart` (`containsAllInOrder`: `game.ready()` puede lanzar antes un `update(0)`):

```dart
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/game/arena_game.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_bloc_fake.dart';
import '../../../../../mocks/presentation/features/arena/arena_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/game/arena_assets_loader_fake.dart';
import '../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/update_probe_component_fake.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ArenaBlocFake bloc;
  late ArenaAssetsLoaderFake loader;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    bloc = ArenaBlocFake(ArenaSuccess(data: ArenaDataMock.preview));
    loader = ArenaAssetsLoaderFake(ArenaAssetsMock.create());
  });

  testWithGame<ArenaGame>(
    'testWhenLoadedThenBuildsTheSceneFromTheBlocState',
    () => ArenaGame(bloc: bloc, assetsLoader: loader),
    (
      game,
    ) async {
      // given
      await game.ready();

      // when
      final scene = game.scene;

      // then
      expect(loader.loadCalled, isTrue);
      expect(game.isReady, isTrue);
      expect(scene!.fighters.keys, ['hero-0', 'enemy-0']);
    },
  );

  testWithGame<ArenaGame>(
    'testWhenNothingIsReplayingThenDoesNotTick',
    () => ArenaGame(bloc: bloc, assetsLoader: loader),
    (
      game,
    ) async {
      // given
      await game.ready();

      // when
      game.update(0.016);
      await _settle();

      // then
      expect(bloc.events.whereType<ArenaReplayTicked>(), isEmpty);
    },
  );

  testWithGame<ArenaGame>(
    'testWhenReplayingThenTicksWithTheFrameTimeCappedLikeTheForest',
    () => ArenaGame(
      bloc: bloc = ArenaBlocFake(ArenaSuccess(data: ArenaDataMock.replaying)),
      assetsLoader: loader,
    ),
    (game) async {
      // given
      await game.ready();
      final probe = UpdateProbeComponentFake();
      await game.world.add(probe);
      await game.ready();

      // when
      game.update(0.016);
      game.update(0.5);
      await _settle();

      // then
      final ticks = bloc.events.whereType<ArenaReplayTicked>().map((event) => event.deltaMs);
      expect(ticks, containsAllInOrder([closeTo(16, 1e-9), closeTo(100, 1e-9)]));
      expect(probe.updates, [closeTo(0.016, 1e-9), closeTo(0.1, 1e-9)]);
    },
  );
}
```

Run: `flutter test test/layers/presentation/features/arena/game`
Expected: FAIL de compilación.

`lib/layers/presentation/features/arena/game/components/arena_ground_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../forest/game/render/render_depth.dart';
import '../atlas/arena_assets.dart';
import '../atlas/arena_sprite_names.dart';
import '../render/arena_render_constants.dart';

class ArenaGroundComponent extends PositionComponent {
  final Sprite _grass;
  final Sprite _fence;
  final Vector2 _grassSize;
  final Vector2 _fenceSize;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  ArenaGroundComponent({required ArenaAssets assets})
    : _grass = assets.sprite(ArenaSpriteNames.grass),
      _fence = assets.sprite(ArenaSpriteNames.fence),
      _grassSize = assets.sprite(ArenaSpriteNames.grass).srcSize,
      _fenceSize = assets.sprite(ArenaSpriteNames.fence).srcSize,
      super(
        size: Vector2(ArenaRenderConstants.stageWidth, ArenaRenderConstants.stageHeight),
        priority: RenderDepth.ground,
      );

  int get fencePosts => (ArenaRenderConstants.stageWidth / _fenceSize.x).ceil();

  @override
  void render(Canvas canvas) {
    for (var y = 0.0; y < size.y; y += _grassSize.y) {
      for (var x = 0.0; x < size.x; x += _grassSize.x) {
        _grass.render(canvas, position: Vector2(x, y), overridePaint: _paint);
      }
    }
    for (var post = 0; post < fencePosts; post++) {
      _fence.render(
        canvas,
        position: Vector2(post * _fenceSize.x, ArenaRenderConstants.fenceY - _fenceSize.y),
        overridePaint: _paint,
      );
    }
  }
}
```

`lib/layers/presentation/features/arena/game/arena_scene_component.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../forest/game/components/floating_text_component.dart';
import '../../forest/game/particles/particle_burst_component.dart';
import '../../forest/game/particles/particle_bursts.dart';
import '../bloc/arena_bloc.dart';
import '../models/arena_effect.dart';
import '../models/fighter_render_data.dart';
import 'atlas/arena_assets.dart';
import 'components/arena_ground_component.dart';
import 'components/fighter_component.dart';

class ArenaSceneComponent extends Component {
  final ArenaAssets _assets;
  final math.Random _random;
  final Map<String, FighterComponent> _fighters = {};
  bool _isBuilt = false;

  ArenaSceneComponent({required this._assets, math.Random? random}) : _random = random ?? math.Random();

  Map<String, FighterComponent> get fighters => Map.unmodifiable(_fighters);

  void show(ArenaData data) {
    if (!_isBuilt) {
      _isBuilt = true;
      add(ArenaGroundComponent(assets: _assets));
    }
    _reconcile(data.fighters);
    for (final effect in data.effects) {
      _play(effect);
    }
  }

  void _reconcile(List<FighterRenderData> fighters) {
    final keys = {for (final fighter in fighters) fighter.key};
    for (final key in _fighters.keys.where((key) => !keys.contains(key)).toList()) {
      final removed = _fighters.remove(key)!;
      removed.shadow.removeFromParent();
      removed.healthBar.removeFromParent();
      removed.removeFromParent();
    }
    for (final fighter in fighters) {
      final current = _fighters[fighter.key];
      if (current != null && current.fighter.enemyKind == fighter.enemyKind) {
        current.show(fighter);
        continue;
      }
      if (current != null) {
        current.shadow.removeFromParent();
        current.healthBar.removeFromParent();
        current.removeFromParent();
      }
      final created = FighterComponent(assets: _assets, fighter: fighter);
      _fighters[fighter.key] = created;
      add(created.shadow);
      add(created.healthBar);
      add(created);
    }
  }

  void _play(ArenaEffect effect) {
    switch (effect) {
      case HitEffect(:final side, :final index, :final damage):
        _onHit(side, index, damage);
      case DodgeEffect(:final side, :final index):
        _float(side, index, Internationalize.arenaDodge, FloatingTextComponent.defaultColor);
      case HealEffect(:final side, :final index, :final amount):
        _float(side, index, Internationalize.arenaHeal(amount: amount), CustomColors.success);
      case FightEndedEffect():
        for (final fighter in _fighters.values) {
          fighter.healthBar.snap();
        }
    }
  }

  void _onHit(FightSide side, int index, int damage) {
    final fighter = _fighters['${side.name}-$index'];
    if (fighter == null) return;
    _float(side, index, Internationalize.arenaDamage(amount: damage), CustomColors.hudWarning);
    if (damage <= 0) return;
    fighter.hit();
    final impact = fighter.impactPoint;
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.bloodDrops(
          impact: impact,
          attackerOnLeft: side == FightSide.enemy,
          random: _random,
        ),
        sortY: fighter.position.y,
      ),
    );
  }

  void _float(FightSide side, int index, String text, Color color) {
    final fighter = _fighters['${side.name}-$index'];
    if (fighter == null) return;
    add(FloatingTextComponent(text: text, at: fighter.headPoint, color: color));
  }
}
```

`lib/layers/presentation/features/arena/game/arena_state_listener.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/arena_bloc.dart';
import 'arena_scene_component.dart';

class ArenaStateListener extends Component with FlameBlocListenable<ArenaBloc, ArenaState> {
  final ArenaSceneComponent _scene;

  ArenaStateListener({required this._scene});

  @override
  void onInitialState(ArenaState state) {
    _scene.show(state.data);
  }

  @override
  void onNewState(ArenaState state) {
    _scene.show(state.data);
  }
}
```

`lib/layers/presentation/features/arena/game/arena_game.dart` (el `dt` se acota una vez y ese valor va al tick y a los componentes, como en `ForestGame`; sólo se envía `ArenaReplayTicked` mientras hay reproducción):

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../../forest/game/render/render_constants.dart';
import '../bloc/arena_bloc.dart';
import 'arena_scene_component.dart';
import 'arena_state_listener.dart';
import 'atlas/arena_assets_loader.dart';
import 'render/arena_framing.dart';
import 'render/arena_render_constants.dart';

class ArenaGame extends FlameGame {
  final ArenaBloc _bloc;
  final ArenaAssetsLoader _assetsLoader;
  final math.Random? _random;
  ArenaSceneComponent? _scene;

  ArenaGame({required this._bloc, ArenaAssetsLoader? assetsLoader, this._random})
    : _assetsLoader = assetsLoader ?? ArenaAssetsLoader();

  ArenaSceneComponent? get scene => _scene;

  bool get isReady => _scene != null;

  @override
  Color backgroundColor() => const Color(ArenaRenderConstants.backgroundColor);

  @override
  Future<void> onLoad() async {
    final assets = await _assetsLoader.load();
    final scene = ArenaSceneComponent(assets: assets, random: _random);
    await world.add(
      FlameBlocProvider<ArenaBloc, ArenaState>.value(
        value: _bloc,
        children: [
          scene,
          ArenaStateListener(scene: scene),
        ],
      ),
    );
    _scene = scene;
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(ArenaFraming.center.dx, ArenaFraming.center.dy);
  }

  @override
  void update(double dt) {
    final frameSeconds = math.min(dt, RenderConstants.maxFrameSeconds);
    camera.viewfinder.zoom = ArenaFraming.zoom(Size(size.x, size.y));
    final state = _bloc.state;
    if (isReady && state is ArenaSuccess && state.data.isReplaying) {
      _bloc.add(ArenaReplayTicked(deltaMs: frameSeconds * 1000));
    }
    super.update(frameSeconds);
  }
}
```

Run: `flutter test test/layers/presentation/features/arena test/layers/presentation/features/forest/game test/architecture_test.dart`
Expected: PASS.

- [x] **Step 7: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/forest/particle_kind.dart lib/layers/presentation/features/forest/game lib/layers/presentation/features/arena/game test/layers/presentation/features/forest/game test/layers/presentation/features/arena/game test/mocks/presentation/features/arena
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di test/mocks/core test/mocks/domain
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida, `No issues found!` y todo en verde.

- [x] **Step 8: Commit y unión a la rama de fase**

```bash
git add lib/core/config/constants/enum/forest/particle_kind.dart lib/layers/presentation/features/forest/game/particles lib/layers/presentation/features/forest/game/components/floating_text_component.dart lib/layers/presentation/features/arena/game test/layers/presentation/features/forest/game test/layers/presentation/features/arena/game test/mocks/presentation/features/arena
git commit -m "[PROJECT-X]: Draw the arena fight with health bars, damage numbers and blood drops"
git switch feature/PROJECT-X-c2-arena-screen && git merge --no-ff feature/PROJECT-X-c2-scene
```

---

### Task TC2.4: HUD de la arena

**Files:**
- Create:
  - `lib/layers/presentation/features/arena/widgets/level_tile.dart`, `level_list.dart`, `fight_button.dart`, `result_panel.dart`, `arena_hud.dart`
  - `test/layers/presentation/features/arena/widgets/level_tile_test.dart`, `level_list_test.dart`, `fight_button_test.dart`, `result_panel_test.dart`, `arena_hud_test.dart`

**Interfaces:**
- Consumes (TC2.2): `ArenaLevelItemData`, `ArenaResultData`, `PowerTone`, `ArenaLevelItemStatus`, `ArenaLevelItemDataMock`, `ArenaResultDataMock`, textos `arena*`; del bosque `HudButton`, `HudPanel`; `CustomColors`, `CustomTextStyles`.
- Produces:
  ```dart
  class LevelTile extends StatelessWidget {
    const LevelTile({required ArenaLevelItemData level, required bool isSelected, required bool isEnabled, required VoidCallback onTap});
    static Color toneColor(PowerTone tone);   // success / warning / error
  }
  class LevelList extends StatelessWidget {    // maxWidth 280, con scroll
    const LevelList({required List<ArenaLevelItemData> levels, required ArenaLevelId? selected, required bool isEnabled, required ValueChanged<ArenaLevelId> onSelected});
  }
  class FightButton extends StatelessWidget {  // "Empezar pelea", o "Saltar" mientras se reproduce
    const FightButton({required bool isReplaying, required bool canFight, required VoidCallback onFight, required VoidCallback onSkip});
  }
  class ResultPanel extends StatelessWidget {
    const ResultPanel({required ArenaResultData result, required VoidCallback onRetry});
  }
  class ArenaHud extends StatelessWidget {
    const ArenaHud({required List<ArenaLevelItemData> levels, required ArenaLevelId? selected, required int heroPower,
      required bool isReplaying, required bool canFight, required ArenaResultData? result,
      required ValueChanged<ArenaLevelId> onLevelSelected, required VoidCallback onFight,
      required VoidCallback onSkip, required VoidCallback onBack});
  }
  ```

Distribución: arriba a la izquierda *Volver* y un panel con "Arena" y "Tu Poder: N"; debajo, la lista de niveles (hasta el borde inferior, con scroll); abajo a la derecha el botón de pelea; arriba a la derecha el panel de resultado cuando la reproducción ha terminado.

- [x] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-c2-arena-screen && git switch -c feature/PROJECT-X-c2-hud
```

- [x] **Step 2: Tests que fallan**

`test/layers/presentation/features/arena/widgets/level_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_tile.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenAnOpenLevelIsShownThenNamePowerInItsToneAndRewardAreListed', (tester) async {
    // given
    var taps = 0;
    final level = ArenaLevelItemDataMock.rookieOpen;

    // when
    await tester.pumpHud(
      Center(
        child: LevelTile(level: level, isSelected: true, isEnabled: true, onTap: () => taps++),
      ),
    );
    await tester.tap(find.text(level.name));

    // then
    expect(find.text(level.enemiesText), findsOneWidget);
    expect(find.text(level.rewardText), findsOneWidget);
    expect(tester.widget<Text>(find.text(level.powerText)).style!.color, CustomColors.success);
    expect(taps, 1);
  });

  testWidgets('testWhenALevelIsLockedThenItShowsTheLockAndCannotBeTapped', (tester) async {
    // given
    var taps = 0;
    final level = ArenaLevelItemDataMock.veteranLocked;

    // when
    await tester.pumpHud(
      Center(
        child: LevelTile(level: level, isSelected: false, isEnabled: true, onTap: () => taps++),
      ),
    );
    await tester.tap(find.text(level.name));

    // then
    expect(tester.widget<Icon>(find.byIcon(Icons.lock)).semanticLabel, Internationalize.arenaLocked);
    expect(tester.widget<Text>(find.text(level.powerText)).style!.color, CustomColors.error);
    expect(taps, 0);
  });

  testWidgets('testWhenALevelIsClearedThenItSaysSo', (tester) async {
    // given
    final level = ArenaLevelItemDataMock.rookieCleared;

    // when
    await tester.pumpHud(
      Center(
        child: LevelTile(level: level, isSelected: false, isEnabled: true, onTap: () {}),
      ),
    );

    // then
    expect(find.text(Internationalize.arenaCleared), findsOneWidget);
  });
}
```

`test/layers/presentation/features/arena/widgets/level_list_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_list.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenATileIsTappedThenItsLevelIsSelected', (tester) async {
    // given
    final selected = <ArenaLevelId>[];
    final levels = [ArenaLevelItemDataMock.rookieCleared, ArenaLevelItemDataMock.veteranOpen];
    await tester.pumpHud(
      LevelList(levels: levels, selected: ArenaLevelId.banditRookie, isEnabled: true, onSelected: selected.add),
    );

    // when
    await tester.tap(find.text(levels[1].name));

    // then
    expect(selected, [ArenaLevelId.banditVeteran]);
    expect(tester.widgetList<LevelTile>(find.byType(LevelTile)).map((tile) => tile.isSelected), [true, false]);
  });

  testWidgets('testWhenTheListIsDisabledThenTapsAreIgnored', (tester) async {
    // given
    final selected = <ArenaLevelId>[];
    final levels = [ArenaLevelItemDataMock.rookieCleared, ArenaLevelItemDataMock.veteranOpen];
    await tester.pumpHud(
      LevelList(levels: levels, selected: ArenaLevelId.banditRookie, isEnabled: false, onSelected: selected.add),
    );

    // when
    await tester.tap(find.text(levels[1].name));

    // then
    expect(selected, isEmpty);
  });
}
```

`test/layers/presentation/features/arena/widgets/fight_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/fight_button.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenAFightCanStartThenTappingStartsIt', (tester) async {
    // given
    var fights = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: false, canFight: true, onFight: () => fights++, onSkip: () {}),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaFight));

    // then
    expect(fights, 1);
  });

  testWidgets('testWhenNoFightCanStartThenTheButtonIsDimmed', (tester) async {
    // given
    var fights = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: false, canFight: false, onFight: () => fights++, onSkip: () {}),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaFight));

    // then
    expect(fights, 0);
  });

  testWidgets('testWhenTheFightIsReplayingThenTheButtonSkipsIt', (tester) async {
    // given
    var skips = 0;
    await tester.pumpHud(
      Center(
        child: FightButton(isReplaying: true, canFight: false, onFight: () {}, onSkip: () => skips++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaSkip));

    // then
    expect(skips, 1);
    expect(find.text(Internationalize.arenaFight), findsNothing);
  });
}
```

`test/layers/presentation/features/arena/widgets/result_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/result_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheHeroWonThenTheGoldIsShownWithoutRetry', (tester) async {
    // given
    final result = ArenaResultDataMock.victoryTenGold;

    // when
    await tester.pumpHud(
      Center(
        child: ResultPanel(result: result, onRetry: () {}),
      ),
    );

    // then
    expect(find.text(Internationalize.arenaVictory), findsOneWidget);
    expect(find.text(Internationalize.arenaReward(amount: 10)), findsOneWidget);
    expect(find.text(Internationalize.arenaRetry), findsNothing);
  });

  testWidgets('testWhenTheHeroLostThenTheAdviceAndRetryAreShown', (tester) async {
    // given
    var retries = 0;
    final result = ArenaResultDataMock.defeatNeedAttack;
    await tester.pumpHud(
      Center(
        child: ResultPanel(result: result, onRetry: () => retries++),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.arenaRetry));

    // then
    expect(find.text(Internationalize.arenaDefeat), findsOneWidget);
    expect(find.text(result.detail), findsOneWidget);
    expect(retries, 1);
  });
}
```

`test/layers/presentation/features/arena/widgets/arena_hud_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_result_data.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/arena_hud.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/result_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  Future<List<String>> pumpHud(WidgetTester tester, {required bool isReplaying, ArenaResultData? result}) async {
    final calls = <String>[];
    await tester.pumpHud(
      ArenaHud(
        levels: [ArenaLevelItemDataMock.rookieOpen, ArenaLevelItemDataMock.veteranLocked],
        selected: ArenaLevelId.banditRookie,
        heroPower: 31,
        isReplaying: isReplaying,
        canFight: !isReplaying,
        result: result,
        onLevelSelected: (id) => calls.add(id.name),
        onFight: () => calls.add('fight'),
        onSkip: () => calls.add('skip'),
        onBack: () => calls.add('back'),
      ),
    );
    return calls;
  }

  testWidgets('testWhenShownThenTheHeroPowerTheLevelsAndTheFightButtonAreThere', (tester) async {
    // given
    final calls = await pumpHud(tester, isReplaying: false);

    // when
    await tester.tap(find.text(Internationalize.arenaFight));
    await tester.tap(find.text(Internationalize.arenaBack));

    // then
    expect(find.text(Internationalize.arenaHeroPower(power: 31)), findsOneWidget);
    expect(find.text(ArenaLevelItemDataMock.rookieOpen.name), findsOneWidget);
    expect(calls, ['fight', 'back']);
  });

  testWidgets('testWhenTheFightEndedThenTheResultIsShown', (tester) async {
    // given
    // when
    await pumpHud(tester, isReplaying: false, result: ArenaResultDataMock.victoryTenGold);

    // then
    expect(find.byType(ResultPanel), findsOneWidget);
  });

  testWidgets('testWhenReplayingThenTheResultIsHiddenAndTheLevelsIgnoreTaps', (tester) async {
    // given
    final calls = await pumpHud(tester, isReplaying: true, result: ArenaResultDataMock.victoryTenGold);

    // when
    await tester.tap(find.text(ArenaLevelItemDataMock.rookieOpen.name));
    await tester.tap(find.text(Internationalize.arenaSkip));

    // then
    expect(find.byType(ResultPanel), findsNothing);
    expect(calls, ['skip']);
  });
}
```

Run: `flutter test test/layers/presentation/features/arena/widgets`
Expected: FAIL de compilación.

- [x] **Step 3: Implementar los widgets**

`lib/layers/presentation/features/arena/widgets/level_tile.dart` (el Poder y la recompensa van en un `Wrap`: con la fuente de los tests, un `Row` se desborda en 280 px):

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/arena/arena_level_item_status.dart';
import '../../../../../core/config/constants/enum/arena/power_tone.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../../forest/widgets/hud_panel.dart';
import '../models/arena_level_item_data.dart';

class LevelTile extends StatelessWidget {
  final ArenaLevelItemData level;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const LevelTile({
    super.key,
    required this.level,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  static Color toneColor(PowerTone tone) => switch (tone) {
    PowerTone.easy => CustomColors.success,
    PowerTone.even => CustomColors.warning,
    PowerTone.hard => CustomColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && level.isPlayable;
    return Opacity(
      opacity: level.isPlayable ? 1 : 0.5,
      child: HudPanel(
        isHighlighted: isSelected,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: canTap ? onTap : null,
            borderRadius: BorderRadius.circular(6),
            hoverColor: CustomColors.hudAccentSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(child: _texts()),
                  _status(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(level.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
        Text(level.enemiesText, style: CustomTextStyles.system12w600.copyWith(color: CustomColors.hudMuted)),
        Wrap(
          spacing: 8,
          children: [
            Text(level.powerText, style: CustomTextStyles.system12w600.copyWith(color: toneColor(level.tone))),
            Text(level.rewardText, style: CustomTextStyles.system12w600.copyWith(color: CustomColors.hudAccent)),
          ],
        ),
      ],
    );
  }

  Widget _status() {
    return switch (level.status) {
      ArenaLevelItemStatus.locked => Icon(
        Icons.lock,
        size: 18,
        color: CustomColors.hudMuted,
        semanticLabel: Internationalize.arenaLocked,
      ),
      ArenaLevelItemStatus.open => const SizedBox.shrink(),
      ArenaLevelItemStatus.cleared => Text(
        Internationalize.arenaCleared,
        style: CustomTextStyles.system12w600.copyWith(color: CustomColors.success),
      ),
    };
  }
}
```

`lib/layers/presentation/features/arena/widgets/level_list.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../models/arena_level_item_data.dart';
import 'level_tile.dart';

class LevelList extends StatelessWidget {
  static const double maxWidth = 280;

  final List<ArenaLevelItemData> levels;
  final ArenaLevelId? selected;
  final bool isEnabled;
  final ValueChanged<ArenaLevelId> onSelected;

  const LevelList({
    super.key,
    required this.levels,
    required this.selected,
    required this.isEnabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final level in levels)
              LevelTile(
                level: level,
                isSelected: level.id == selected,
                isEnabled: isEnabled,
                onTap: () => onSelected(level.id),
              ),
          ],
        ),
      ),
    );
  }
}
```

`lib/layers/presentation/features/arena/widgets/fight_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../forest/widgets/hud_button.dart';

class FightButton extends StatelessWidget {
  final bool isReplaying;
  final bool canFight;
  final VoidCallback onFight;
  final VoidCallback onSkip;

  const FightButton({
    super.key,
    required this.isReplaying,
    required this.canFight,
    required this.onFight,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (isReplaying) return HudButton(label: Internationalize.arenaSkip, onPressed: onSkip);
    return HudButton(label: Internationalize.arenaFight, isActive: canFight, onPressed: canFight ? onFight : null);
  }
}
```

`lib/layers/presentation/features/arena/widgets/result_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../../forest/widgets/hud_button.dart';
import '../../forest/widgets/hud_panel.dart';
import '../models/arena_result_data.dart';

class ResultPanel extends StatelessWidget {
  static const double maxWidth = 280;

  final ArenaResultData result;
  final VoidCallback onRetry;

  const ResultPanel({super.key, required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: HudPanel(
        isHighlighted: result.isVictory,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              result.title,
              textAlign: TextAlign.center,
              style: CustomTextStyles.system18w600.copyWith(
                color: result.isVictory ? CustomColors.hudAccent : CustomColors.hudWarning,
              ),
            ),
            if (result.detail.isNotEmpty)
              Text(
                result.detail,
                textAlign: TextAlign.center,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
            if (!result.isVictory) HudButton(label: Internationalize.arenaRetry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
```

`lib/layers/presentation/features/arena/widgets/arena_hud.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../../forest/widgets/hud_button.dart';
import '../../forest/widgets/hud_panel.dart';
import '../models/arena_level_item_data.dart';
import '../models/arena_result_data.dart';
import 'fight_button.dart';
import 'level_list.dart';
import 'result_panel.dart';

class ArenaHud extends StatelessWidget {
  static const double _margin = 12;
  static const double _listTop = 64;

  final List<ArenaLevelItemData> levels;
  final ArenaLevelId? selected;
  final int heroPower;
  final bool isReplaying;
  final bool canFight;
  final ArenaResultData? result;
  final ValueChanged<ArenaLevelId> onLevelSelected;
  final VoidCallback onFight;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const ArenaHud({
    super.key,
    required this.levels,
    required this.selected,
    required this.heroPower,
    required this.isReplaying,
    required this.canFight,
    required this.result,
    required this.onLevelSelected,
    required this.onFight,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final shownResult = result;
    return Stack(
      children: [
        Positioned(top: _margin, left: _margin, child: _header()),
        Positioned(
          top: _listTop,
          left: _margin,
          bottom: _margin,
          child: LevelList(levels: levels, selected: selected, isEnabled: !isReplaying, onSelected: onLevelSelected),
        ),
        Positioned(
          right: _margin,
          bottom: _margin,
          child: FightButton(isReplaying: isReplaying, canFight: canFight, onFight: onFight, onSkip: onSkip),
        ),
        if (shownResult != null && !isReplaying)
          Positioned(
            top: _margin,
            right: _margin,
            child: ResultPanel(result: shownResult, onRetry: onFight),
          ),
      ],
    );
  }

  Widget _header() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        HudButton(label: Internationalize.arenaBack, onPressed: onBack),
        HudPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                Internationalize.arenaTitle,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudAccent),
              ),
              Text(
                Internationalize.arenaHeroPower(power: heroPower),
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

Run: `flutter test test/layers/presentation/features/arena/widgets`
Expected: PASS (13 tests).

- [x] **Step 4: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/arena/widgets test/layers/presentation/features/arena/widgets
flutter analyze
flutter test
```

Expected: `No issues found!` y todo en verde. (No cambia nada de DI ni de mocks generados.)

- [x] **Step 5: Commit y unión a la rama de fase**

```bash
git add lib/layers/presentation/features/arena/widgets test/layers/presentation/features/arena/widgets
git commit -m "[PROJECT-X]: List arena levels with their power, reward and fight result"
git switch feature/PROJECT-X-c2-arena-screen && git merge --no-ff feature/PROJECT-X-c2-hud
flutter analyze && flutter test
```

---

### Task TC2.5: Página de la arena, entrada desde el bosque y pausa

**Files:**
- Create:
  - `lib/layers/presentation/features/arena/arena_page.dart`
  - `lib/core/assets/images/icons/arena.svg`
  - `test/layers/presentation/features/arena/arena_page_test.dart`
  - `test/mocks/core/services/route_aware_fake.dart`
- Modify:
  - `lib/core/services/navigation/source/navigation_service.dart`, `lib/core/services/navigation/navify/navify_impl.dart`
  - `test/mocks/core/services/navigation_service_mocks.mocks.dart` (regenerado)
  - `lib/layers/presentation/app/container_app.dart`
  - `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart` (`forest.hud.arena`)
  - `lib/layers/presentation/theme/images/custom_icons.dart`
  - `lib/layers/presentation/features/forest/widgets/hud_button.dart`, `hud_overlay.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_event.dart`, `forest_bloc.dart`
  - `lib/layers/presentation/features/forest/forest_page.dart`
  - Tests: `test/core/services/navigation/navify/navify_impl_test.dart`, `test/layers/presentation/theme/images/custom_icons_test.dart`, `test/layers/presentation/features/forest/widgets/hud_button_test.dart`, `hud_overlay_test.dart`, `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`, `test/layers/presentation/features/forest/forest_page_test.dart`
  - `CLAUDE.md`

`core/config/constants/enum/forest/hud_menu.dart` no cambia: *Arena* no abre un menú.

**Interfaces:**
- Consumes: todo lo de TC2.1–TC2.4; `StartGameUseCase` (para tener partida en el test de página).
- Produces:
  ```dart
  // NavigationService / NavifyImpl
  RouteObserver<ModalRoute<void>> get routeObserver;

  // ArenaPage
  class ArenaPage extends StatelessWidget { const ArenaPage({super.key}); }

  // bosque
  final class ForestArenaRequested extends ForestEvent { const ForestArenaRequested(); }
  HudButton({required String label, String? badge, String? icon, VoidCallback? onPressed, bool isActive = false})
  HudOverlay({required HudData hud, required ValueChanged<BlueprintId> onBuildSelected, required VoidCallback onArenaPressed})
  CustomIcons.arena          // 'lib/core/assets/images/icons/arena.svg'
  Internationalize.forestArena   // "Arena"

  // test
  RouteAwareFake (calls: ['didPushNext', 'didPopNext'])
  ```

- [x] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-c2-arena-screen && git switch -c feature/PROJECT-X-c2-page
```

- [x] **Step 2: `RouteObserver` en `NavigationService`, primero el test**

`test/mocks/core/services/route_aware_fake.dart`:

```dart
import 'package:flutter/widgets.dart';

class RouteAwareFake with RouteAware {
  final List<String> calls = [];

  @override
  void didPushNext() => calls.add('didPushNext');

  @override
  void didPopNext() => calls.add('didPopNext');
}
```

En `test/core/services/navigation/navify/navify_impl_test.dart`, el import `'../../../../mocks/core/services/route_aware_fake.dart'` y, al final de `main`:

```dart
  testWidgets('testWhenAPageIsPushedOverAnotherThenTheRouteObserverTellsTheOneBelow', (tester) async {
    // given
    final below = RouteAwareFake();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navify.navigatorKey,
        navigatorObservers: [navify.routeObserver],
        home: const Scaffold(),
      ),
    );
    navify.routeObserver.subscribe(below, ModalRoute.of(tester.element(find.byType(Scaffold)))!);

    // when
    navify.push(const Scaffold());
    await tester.pumpAndSettle();
    navify.pop();
    await tester.pumpAndSettle();

    // then
    expect(below.calls, ['didPushNext', 'didPopNext']);
  });
```

Run: `flutter test test/core/services/navigation/navify/navify_impl_test.dart`
Expected: FAIL de compilación (`routeObserver` no existe).

En `navigation_service.dart`, después de `navigatorKey`:

```dart
  RouteObserver<ModalRoute<void>> get routeObserver;
```

En `navify_impl.dart`, después de `navigatorKey`:

```dart
  @override
  final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
```

En `container_app.dart`, en el `MaterialApp`, después de `navigatorKey`:

```dart
        navigatorObservers: [locator<NavigationService>().routeObserver],
```

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/services test/layers/presentation/app
```

Expected: PASS; `navigation_service_mocks.mocks.dart` sólo gana el getter `routeObserver` y su clase falsa `_FakeRouteObserver_1` (si no se le da un `when`, devuelve ese falso y `subscribe` falla: por eso el Step 6 lo stubea).

- [x] **Step 3: Botón *Arena* en el HUD, primero los tests**

En `test/layers/presentation/theme/images/custom_icons_test.dart`, al final de `main`:

```dart
  test('testWhenResolvingTheArenaIconThenTheSvgFileExists', () {
    // given
    const path = CustomIcons.arena;

    // when
    final exists = File(path).existsSync();

    // then
    expect(exists, isTrue);
  });
```

En `test/layers/presentation/features/forest/widgets/hud_button_test.dart`, imports de `package:flutter_svg/flutter_svg.dart` y de `custom_icons.dart`, y al final de `main`:

```dart
  testWidgets('testWhenAnIconIsGivenThenItIsShownBeforeTheLabel', (tester) async {
    // given
    final button = HudButton(label: Internationalize.forestArena, icon: CustomIcons.arena, onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    final icon = tester.getTopLeft(find.byType(SvgPicture));
    final label = tester.getTopLeft(find.text(Internationalize.forestArena));
    expect(icon.dx, lessThan(label.dx));
  });
```

En `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`, `pumpOverlay` acepta el callback nuevo:

```dart
  Future<List<BlueprintId>> pumpOverlay(WidgetTester tester, HudData hud, {VoidCallback? onArenaPressed}) async {
    final selected = <BlueprintId>[];
    await tester.pumpHud(HudOverlay(hud: hud, onBuildSelected: selected.add, onArenaPressed: onArenaPressed ?? () {}));
    return selected;
  }
```

y al final de `main`:

```dart
  testWidgets('testWhenArenaIsTappedThenTheOpenMenuClosesAndTheArenaIsRequested', (tester) async {
    // given
    var arenaTaps = 0;
    await pumpOverlay(tester, HudDataMock.gathering, onArenaPressed: () => arenaTaps++);
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestArena));
    await tester.pump();

    // then
    expect(arenaTaps, 1);
    expect(find.byType(QuestPanel), findsNothing);
  });
```

Run: `flutter test test/layers/presentation/theme test/layers/presentation/features/forest/widgets`
Expected: FAIL de compilación (`CustomIcons.arena`, `icon`, `onArenaPressed`, `forestArena` no existen).

Implementación:
- `es.json`: en `forest.hud`, después de `"missing"`, `"arena": "Arena"`.
- `internationalize.dart`, después de `forestQuests`:

```dart
  static String get forestArena => '$_forest.hud.arena'.tr();
```

- `lib/core/assets/images/icons/arena.svg` (dos espadas cruzadas, mismos colores que `axe.svg`):

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
  <path d="M3 3L15 15" stroke="#C9CED6" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M19 3L7 15" stroke="#C9CED6" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M13 17L17 13M5 13L9 17" stroke="#8A5A2B" stroke-width="2.4" stroke-linecap="round"/>
  <path d="M16.5 16.5L19.5 19.5M5.5 16.5L2.5 19.5" stroke="#8A5A2B" stroke-width="2.6" stroke-linecap="round"/>
</svg>
```

- `custom_icons.dart`, después de `axe`:

```dart
  static const String arena = '$_path/arena.svg';
```

- `hud_button.dart`: import de `package:flutter_svg/flutter_svg.dart`, campo `final String? icon;`, constructor `const HudButton({super.key, required this.label, this.badge, this.icon, this.onPressed, this.isActive = false});`, `final iconPath = icon;` junto a `badgeText`, y como primer hijo del `Row`:

```dart
                  if (iconPath != null) SvgPicture.asset(iconPath, width: 18, height: 18, excludeFromSemantics: true),
```

- `hud_overlay.dart`: import de `../../../theme/images/custom_icons.dart`, campo `final VoidCallback onArenaPressed;` (requerido en el constructor), el tercer botón al final de `_buttonRow`

```dart
        HudButton(label: Internationalize.forestArena, icon: CustomIcons.arena, onPressed: _onArenaPressed),
```

y el método, antes de `_onBuildSelected`:

```dart
  void _onArenaPressed() {
    setState(() => _openMenu = null);
    widget.onArenaPressed();
  }
```

`forest_page.dart` todavía no compila (falta `onArenaPressed`): se arregla en el Step 5.

Run: `flutter test test/layers/presentation/theme test/layers/presentation/features/forest/widgets`
Expected: PASS.

- [x] **Step 4: `ArenaPage`, primero el test**

`test/layers/presentation/features/arena/arena_page_test.dart` (DI real con `LevelRepository` y `NavigationService` simulados, como `forest_page_test.dart`; la partida se crea con `StartGameUseCase`; la reproducción completa se empuja con pasos de 100 ms porque `pumpUntil` avanza 50 ms por vuelta y se pasaría de los 10 s):

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';
import 'package:rpg/layers/presentation/features/arena/arena_page.dart';
import 'package:rpg/layers/presentation/features/arena/game/arena_game.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/level_list.dart';
import 'package:rpg/layers/presentation/features/arena/widgets/result_panel.dart';

import '../../../../helpers/pump_until.dart';
import '../../../../helpers/spanish_translations.dart';
import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
import '../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
import '../../../../mocks/presentation/features/forest/game/asset_bundle_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLevelRepository levelRepository;
  late MockNavigationService navigationService;

  setUpAll(loadSpanishTranslations);

  setUp(() async {
    rootBundle.clear();
    await configureDependencies(environment: DiEnvironment.dev);
    levelRepository = MockLevelRepository();
    navigationService = MockNavigationService();
    locator.allowReassignment = true;
    locator.registerFactory<LevelRepository>(() => levelRepository);
    locator.registerSingleton<NavigationService>(navigationService);
    when(levelRepository.load()).thenReturn(ForestScenarioMock.empty());
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<ArenaGame> pumpArena(WidgetTester tester) async {
    locator.get<StartGameUseCase>()();
    await tester.pumpWidget(const MaterialApp(home: ArenaPage()));
    await pumpUntil(tester, () => find.byType(LevelList).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ArenaGame>>(find.byType(GameWidget<ArenaGame>)).game!;
    await pumpUntil(tester, () => game.isReady);
    return game;
  }

  testWidgets('testWhenOpenedThenTheStageTheLevelsAndTheFightButtonAreShown', (tester) async {
    // given
    // when
    final game = await pumpArena(tester);

    // then
    expect(game.scene!.fighters.keys, ['hero-0', 'enemy-0']);
    expect(find.text(ArenaLevelItemDataMock.rookieOpen.name), findsOneWidget);
    expect(find.text(Internationalize.arenaFight), findsOneWidget);
    expect(find.bySemanticsLabel(Internationalize.arenaAccessibilityStage), findsOneWidget);
  });

  testWidgets('testWhenAFightIsSkippedThenTheVictoryAndTheGoldAreShown', (tester) async {
    // given
    await pumpArena(tester);
    await tester.tap(find.text(Internationalize.arenaFight));
    await pumpUntil(tester, () => find.text(Internationalize.arenaSkip).evaluate().isNotEmpty);

    // when
    await tester.tap(find.text(Internationalize.arenaSkip));
    await pumpUntil(tester, () => find.byType(ResultPanel).evaluate().isNotEmpty);

    // then
    expect(find.text(Internationalize.arenaVictory), findsOneWidget);
    expect(find.text(Internationalize.arenaReward(amount: 10)), findsOneWidget);
    expect(find.text(Internationalize.arenaCleared), findsOneWidget);
  });

  testWidgets('testWhenTheReplayRunsThenTheGameTicksItToTheEnd', (tester) async {
    // given
    await pumpArena(tester);

    // when
    await tester.tap(find.text(Internationalize.arenaFight));
    for (var frame = 0; frame < 70 && find.byType(ResultPanel).evaluate().isEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // then
    expect(find.text(Internationalize.arenaVictory), findsOneWidget);
    expect(find.text(Internationalize.arenaFight), findsOneWidget);
  });

  testWidgets('testWhenThereIsNoGameThenTheErrorAndBackAreShown', (tester) async {
    // given
    await tester.pumpWidget(const MaterialApp(home: ArenaPage()));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.arenaBack));

    // then
    expect(find.text(Internationalize.errorNoGameInProgressMessage), findsOneWidget);
    verify(navigationService.pop()).called(1);
  });

  testWidgets('testWhenTheArtCannotBeLoadedThenTheErrorRetryAndBackAreShown', (tester) async {
    // given
    final bundle = AssetBundleFake(failingKey: ArenaAssetsLoader.prefix + ArenaAssetsLoader.atlasPath);
    locator.get<StartGameUseCase>()();

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(bundle: bundle, child: const ArenaPage()),
      ),
    );
    await pumpUntil(tester, () => find.text(Internationalize.errorGenericMessage).evaluate().isNotEmpty);

    // then
    expect(bundle.failedLoads, greaterThan(0));
    expect(find.text(Internationalize.arenaRetry), findsOneWidget);
    expect(find.text(Internationalize.arenaBack), findsWidgets);
  });
}
```

Run: `flutter test test/layers/presentation/features/arena/arena_page_test.dart`
Expected: FAIL de compilación (`arena_page.dart` no existe).

`lib/layers/presentation/features/arena/arena_page.dart` (el HUD se reconstruye sólo cuando cambia el registro que selecciona, no en cada tick; el error de "no hay partida" ofrece *Volver*, y el de arte además *Reintentar*):

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/i18n/internationalize.dart';
import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/di/locator.dart';
import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../../domain/use-cases/arena/get_arena_use_case.dart';
import '../../../domain/use-cases/arena/start_fight_use_case.dart';
import '../../../domain/use-cases/hero/get_hero_status_use_case.dart';
import '../../theme/colors/custom_colors.dart';
import '../../theme/styles/custom_text_styles.dart';
import '../forest/widgets/hud_button.dart';
import '../forest/widgets/hud_panel.dart';
import 'bloc/arena_bloc.dart';
import 'game/arena_game.dart';
import 'game/atlas/arena_assets_loader.dart';
import 'models/arena_level_item_data.dart';
import 'models/arena_result_data.dart';
import 'widgets/arena_hud.dart';

class ArenaPage extends StatelessWidget {
  const ArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ArenaBloc>(
      create: (_) => ArenaBloc(
        getArenaUseCase: locator.get<GetArenaUseCase>(),
        startFightUseCase: locator.get<StartFightUseCase>(),
        getHeroStatusUseCase: locator.get<GetHeroStatusUseCase>(),
        navigationService: locator.get<NavigationService>(),
      )..add(const ArenaStarted()),
      child: const _ArenaView(),
    );
  }
}

typedef _HudView = ({
  List<ArenaLevelItemData> levels,
  ArenaLevelId? selected,
  int heroPower,
  bool isReplaying,
  bool canFight,
  ArenaResultData? result,
});

class _ArenaView extends StatefulWidget {
  const _ArenaView();

  @override
  State<_ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<_ArenaView> {
  ArenaBloc get bloc => context.read<ArenaBloc>();

  late ArenaGame _game = _createGame();

  ArenaGame _createGame() => ArenaGame(
    bloc: bloc,
    assetsLoader: ArenaAssetsLoader(bundle: DefaultAssetBundle.of(context)),
  );

  void _restartGame() {
    setState(() => _game = _createGame());
    bloc.add(const ArenaStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.black,
      body: BlocBuilder<ArenaBloc, ArenaState>(
        buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
        builder: (context, state) => _bodyByState(state),
      ),
    );
  }

  Widget _bodyByState(ArenaState state) {
    return switch (state) {
      ArenaInitial() => _loadingBody(),
      ArenaInProgress() => _loadingBody(),
      ArenaSuccess() => _arenaBody(),
      ArenaFailure() => _errorBody(state),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator(color: CustomColors.hudAccent));
  }

  Widget _arenaBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          container: true,
          label: Internationalize.arenaAccessibilityStage,
          child: GameWidget<ArenaGame>(
            game: _game,
            autofocus: false,
            errorBuilder: (context, error) => _gameErrorBody(),
          ),
        ),
        SafeArea(child: _hud()),
      ],
    );
  }

  Widget _hud() {
    return BlocSelector<ArenaBloc, ArenaState, _HudView>(
      selector: (state) => (
        levels: state.data.levels,
        selected: state.data.selected,
        heroPower: state.data.heroPower,
        isReplaying: state.data.isReplaying,
        canFight: state.data.canFight,
        result: state.data.result,
      ),
      builder: (context, view) => ArenaHud(
        levels: view.levels,
        selected: view.selected,
        heroPower: view.heroPower,
        isReplaying: view.isReplaying,
        canFight: view.canFight,
        result: view.result,
        onLevelSelected: (levelId) => bloc.add(ArenaLevelSelected(levelId: levelId)),
        onFight: () => bloc.add(const ArenaFightRequested()),
        onSkip: () => bloc.add(const ArenaReplaySkipped()),
        onBack: () => bloc.add(const ArenaClosed()),
      ),
    );
  }

  Widget _errorBody(ArenaFailure state) {
    return _errorPanel(title: state.exception.title, message: state.exception.message, onRetry: null);
  }

  Widget _gameErrorBody() {
    const exception = GenericException();
    return _errorPanel(title: exception.title, message: exception.message, onRetry: _restartGame);
  }

  Widget _errorPanel({required String title, required String message, required VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HudPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: CustomTextStyles.system18w600.copyWith(color: CustomColors.hudAccent),
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (onRetry != null) HudButton(label: Internationalize.arenaRetry, onPressed: onRetry),
                  HudButton(label: Internationalize.arenaBack, onPressed: () => bloc.add(const ArenaClosed())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Run: `flutter test test/layers/presentation/features/arena/arena_page_test.dart`
Expected: PASS (5 tests).

- [x] **Step 5: Entrar desde el bosque, primero el test**

En `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`, imports de `package:mockito/mockito.dart` y de `arena_page.dart`, y al final de `main` (el `push` de `MockNavigationService` necesita su `when`: devuelve un `Future` y mockito no lo inventa):

```dart
  blocTest<ForestBloc, ForestState>(
    'testWhenTheArenaIsRequestedThenItOpensAndCancelsThePlacement',
    build: () {
      // given
      when(navigationService.push(any)).thenReturn(null);
      return ForestBlocMock.make(ForestScenarioMock.fifteenWood(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
        ..add(const ForestArenaRequested());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      verify(navigationService.push(argThat(isA<ArenaPage>()))).called(1);
      expect(bloc.state.data.placement, isNull);
    },
  );
```

Run: `flutter test test/layers/presentation/features/forest/bloc`
Expected: FAIL de compilación (`ForestArenaRequested` no existe).

`forest_event.dart`, al final:

```dart
final class ForestArenaRequested extends ForestEvent {
  const ForestArenaRequested();
}
```

`forest_bloc.dart`: import de `../../arena/arena_page.dart`, el caso `ForestArenaRequested() => _onArenaRequested(event, emit),` al final del `switch` y el manejador después de `_onPlacementCancelled`:

```dart
  Future<void> _onArenaRequested(ForestArenaRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _placement = null;
    _navigationService.push(const ArenaPage());
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }
```

`forest_page.dart`, en `_hudOverlay`:

```dart
      onArenaPressed: () => bloc.add(const ForestArenaRequested()),
```

Run: `flutter test test/layers/presentation/features/forest/bloc test/layers/presentation/features/forest/widgets`
Expected: PASS.

- [x] **Step 6: Pausar el bosque, primero el test**

En `test/layers/presentation/features/forest/forest_page_test.dart`:
- variable `late RouteObserver<ModalRoute<void>> routeObserver;` junto a `navigationService`;
- en `setUp`, después de crear `navigationService`:

```dart
    routeObserver = RouteObserver<ModalRoute<void>>();
    when(navigationService.routeObserver).thenReturn(routeObserver);
```

- al final de `main` (con `pumpAndSettle` no vale: el bucle de Flame pide fotogramas sin parar):

```dart
  testWidgets('testWhenAPageIsPushedOverTheForestThenTheGamePausesAndResumesOnReturn', (tester) async {
    // given
    when(levelRepository.load()).thenReturn(ForestScenarioMock.fifteenWood());
    await tester.pumpWidget(MaterialApp(navigatorObservers: [routeObserver], home: const ForestPage()));
    await pumpUntil(tester, () => find.byType(HudOverlay).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<ForestGame>>(find.byType(GameWidget<ForestGame>)).game!;
    await pumpUntil(tester, () => game.world.isReady);
    final bloc = tester.element(find.byType(HudOverlay)).read<ForestBloc>();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    // when
    navigator.push(MaterialPageRoute<void>(builder: (_) => const SizedBox()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final stateWhilePaused = bloc.state;
    await tester.pump(const Duration(milliseconds: 100));
    final pausedAfterFrames = game.paused;
    final ticksWhilePaused = !identical(bloc.state, stateWhilePaused);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // then
    expect(pausedAfterFrames, isTrue);
    expect(ticksWhilePaused, isFalse);
    expect(game.paused, isFalse);
  });
```

Run: `flutter test test/layers/presentation/features/forest/forest_page_test.dart`
Expected: FAIL en el test nuevo (`Expected: true, Actual: <false>`: el juego no se pausa).

En `forest_page.dart`:
- `class _ForestViewState extends State<_ForestView> with RouteAware {`
- campo, después de `_game`:

```dart
  final RouteObserver<ModalRoute<void>> _routeObserver = locator<NavigationService>().routeObserver;
```

- antes de `dispose`, y `dispose` desuscribe:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) _routeObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _game.pauseEngine();

  @override
  void didPopNext() => _game.resumeEngine();

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
    super.dispose();
  }
```

Run: `flutter test test/layers/presentation/features/forest test/layers/presentation/app`
Expected: PASS.

- [x] **Step 7: Documentar en `CLAUDE.md`**

- *Layout* → `lib/core/`:
  - `assets/`: `images/lpc/` also holds the arena atlas `arena.{png,json}`; `images/icons/` gains `arena.svg`;
  - `config/constants/enum/`: "screen-only ones in `enum/forest/` and `enum/arena/`";
  - `services/navigation/`: "`NavigationService` + `NavifyImpl`: navigation, snackbars, error pop-ups and the `routeObserver` that `ContainerApp` registers and pages listen to with `RouteAware`".
- *Architecture* → reglas de `architecture_test.dart`: "Flame stays in `forest/game/`, `arena/game/` and the two pages".
- *Architecture* → `lib/layers/presentation/`:
  - `features/forest/bloc/`: añadir el evento `ForestArenaRequested` (opens the arena with `NavigationService.push(const ArenaPage())` and cancels placement);
  - `features/forest/game/`: `components/` gains `FloatingTextComponent` (shared with the arena; same API as F1's plan); `particles/` gains blood drops (`ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`);
  - `features/forest/widgets/`: `HudButton` takes an optional SVG `icon`; `HudOverlay` has a third button, *Arena*;
  - página del bosque: "`_ForestViewState` is `RouteAware` on `NavigationService.routeObserver`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops";
  - línea nueva `features/arena/`: "the arena screen, same shape as `forest/`: `ArenaBloc` (events `ArenaStarted`, `ArenaLevelSelected`, `ArenaFightRequested`, `ArenaReplayTicked`, `ArenaReplaySkipped`, `ArenaClosed`; `ArenaData` with the level list, the selection, `FightReplayData`, `FighterRenderData`s, `ArenaResultData` and sealed `ArenaEffect`s); the fight is already resolved and paid by `StartFightUseCase`, the bloc only replays the `FightLogEntity` (one turn every 600 ms, each turn's effect when its blow lands) and refreshes the list with `GetArenaUseCase` when the replay ends; `game/` (`ArenaGame` with the same capped `dt`, `ArenaSceneComponent`, `ArenaStateListener`, `FighterComponent`, `HealthBarComponent`, `ArenaGroundComponent`, atlas `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames` over `arena.json`); `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`); `arena_page.dart` (`ArenaPage` + `_ArenaView`, `GameWidget(autofocus: false)`)".
- E9: "`features/forest/` and `features/arena/` add `models/` and `game/` (Flame) next to `bloc/`, `widgets/` and the page; Flame stays confined to `game/` and the pages."
- *Key cross-cutting conventions* → *Rendering constants*: añadir "Arena: `arena/game/render/arena_render_constants.dart` (400 ms lead-in, 600 ms per turn, impact at half the turn; 480×270 stage framed with a cover zoom between 1 and 3; hero facing right, enemies facing left; the barbarian chief is the barbarian drawn ×1.25 until C6)."

- [x] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/services/navigation lib/core/assets/i18n/internationalize.dart lib/layers/presentation test/core/services test/mocks/core/services/route_aware_fake.dart test/layers/presentation
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di
git diff --stat -- test/mocks/core/services/navigation_service_mocks.mocks.dart
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected:
- `dart format` no toca ningún fichero generado: en esas rutas no hay `*.mocks.dart` (por eso de `test/mocks` sólo se pasa `route_aware_fake.dart`, y no se pasa `test/layers/data`);
- `di.config.dart` sin cambios; el `.mocks.dart` de navegación sólo con el getter nuevo;
- `No issues found!` y todo en verde (unos 490 tests; 73 nuevos en esta fase).

- [x] **Step 9: Commit y unión a la rama de fase**

```bash
git add lib/core/services/navigation test/mocks/core/services lib/layers/presentation/app/container_app.dart lib/core/assets/i18n lib/core/assets/images/icons/arena.svg lib/layers/presentation/theme/images/custom_icons.dart lib/layers/presentation/features/forest lib/layers/presentation/features/arena/arena_page.dart test/core/services test/layers/presentation/theme test/layers/presentation/features/forest test/layers/presentation/features/arena/arena_page_test.dart
git commit -m "[PROJECT-X]: Open the arena from the forest HUD and pause the forest meanwhile"
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the arena screen in the project guide"
git switch feature/PROJECT-X-c2-arena-screen && git merge --no-ff feature/PROJECT-X-c2-page
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida.

---

## Prueba manual

En las tres plataformas, en horizontal. La partida es nueva (sin guardado hasta F2).

**Chrome** (`flutter run -d chrome`):
1. El HUD del bosque tiene tres botones: *Misiones*, *Construir* y *Arena* (con las espadas cruzadas). Abre *Construir*, elige la casa y, con la colocación abierta, pulsa *Arena*: la colocación se cancela y se abre la arena.
2. En la arena: hierba, valla al fondo, el héroe (camisa verde) a la izquierda y un bandido (granate, pelo negro) a la derecha, cada uno con su barra llena. Arriba, *Volver* y "Arena · Tu Poder: 31".
3. La lista: "Bandido novato" con "Poder 19" en verde y "+10 de oro", seleccionado; los demás con candado y su Poder en rojo; al pulsar uno cerrado no pasa nada.
4. *Empezar pelea*: el botón pasa a *Saltar* y la lista se atenúa. Cada golpe: el atacante balancea el hacha, al impactar sale "−N" naranja, unas gotas rojas que caen y desaparecen (nada queda en la hierba), el herido parpadea y su barra baja suavemente.
5. Al caer el bandido queda tumbado; aparece "¡Victoria!" con "+10 de oro". "Bandido novato" muestra "Ganado" y "+3 de oro"; "Bandido veterano" ya no tiene candado.
6. *Volver*: el héroe está donde estaba, el HUD muestra 10 de oro y el bosque sigue (nada se movió mientras estaba la arena: deja al héroe andando hacia un punto lejano antes de entrar y comprueba que no ha avanzado al volver).
7. Vuelve a la arena, elige "Bandido veterano" y pelea: el héroe base pierde (C1, decisión 1). "Derrota", "Te falta Ataque: visita la Herrería." y *Reintentar*. El oro sigue en 10 al volver al bosque.
8. *Reintentar* y, en cuanto empiece, *Saltar*: el resultado sale al momento, con las barras ya en su valor final y sin números ni sangre.
9. Redimensiona la ventana (estrecha y ancha): la hierba siempre cubre el fondo y los luchadores no quedan debajo de la lista.

**Android** (`flutter run -d emulator-5554`): lo mismo; además, la flecha del sistema en la arena vuelve al bosque (y el bosque se reanuda). Con un móvil de 640 px de ancho en horizontal, los tres botones del HUD caben (si no, la fila se encoge con `FittedBox`, como hoy).

**iOS** (`flutter run -d "iPhone 17"`): lo mismo; la lista no se mete bajo la isla dinámica (`SafeArea`).

## Al cerrar C2

- Marca los checkboxes de las cinco tareas y abre la PR de `feature/PROJECT-X-c2-arena-screen` a `feature/PROJECT-X-arena` (`/cerrar-tarea`), con la prueba manual hecha en las tres plataformas.
- Apunta en la sección 5 del README (C2):
  - todos los luchadores golpean con el hacha (no hay espadas en `sources/`); el jefe es el bárbaro ×1,25 dibujado, no en el atlas;
  - `ArenaData` lleva `fighters`, `result` y `effects`, y el BLoC usa también `GetHeroStatusUseCase`;
  - no hay `FloatingNumberComponent`: se usa `FloatingTextComponent` (API de F1);
  - `NavigationService` tiene `routeObserver`;
  - el panel de victoria no tiene botón.
- Avisa a quien lleve:
  - **C3:** `HudButton` ya acepta `icon`; *Héroe* sería el cuarto botón del HUD: aplica la regla de la sección 3.2 del README (probar en 640 px y, si no cabe, agrupar *Arena* y *Héroe*). El consejo de derrota ya manda a la Herrería y a la Armería.
  - **C4:** al añadir `EnemyKind.wolf` / `bear`, los `switch` exhaustivos de `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale` e `Internationalize.arenaEnemy` dejan de compilar a propósito; añade sus frames al atlas de la arena con `write_atlas` y sus nombres en `es.json`. Los niveles nuevos salen solos en la lista.
  - **C6:** sustituye los frames `barbarian-*` (y crea `barbarian-chief-*`, quitando el ×1,25 de `fighterScale`); las posiciones de 3 enemigos ya existen en `ArenaRenderConstants.enemySpots`.
  - **C7:** los textos de `FightAdvice` están en `arena.advice`; si cambia el catálogo, el BLoC no tiene números propios salvo `evenPowerRatio` y los Poderes de `ArenaLevelItemDataMock`.
  - **F1:** `FloatingTextComponent` ya existe en la rama de la arena (decisión 15).
