# C4 · Lobos y oso — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C2 (ya en `feature/PROJECT-X-arena`, con C0, C1 y C3) |
| **Issue / milestone** | `phase:C4` · `stream:C` · milestone `C4 Beasts` (un issue por tarea: TC4.1 … TC4.3) |

**Goal:** Que la arena tenga animales entre los humanos: un lobo, una pareja de lobos, un oso y una manada de tres lobos, con arte LPC nuevo, y que cada animal ataque con un salto corto hacia su objetivo (mordisco o zarpazo) en lugar de con el hacha.

**Architecture:**
- **Arte:** dos hojas LPC nuevas en `asset-packs/lpc/sources/creatures/` (lobo y oso grizzly, vistos de lado). `build_assets.py` gana `ARENA_BEASTS` + `add_beasts()`, que recorta sus vistas que miran a la izquierda dentro del atlas `arena.{png,json}` (frames `wolf-*`, `bear-*`). `forest.*`, `ground.png` y `hero-*.png` no cambian.
- **Dominio:** `EnemyKind.wolf` / `bear` y `ArenaLevelId.wolf` / `wolfPair` / `bear` / `wolfPack` al final de sus enums; los cuatro niveles se insertan **en medio** de `ArenaLevels.all`. `ArenaRules.isUnlocked` también abre un nivel ya ganado, para que una partida no pierda niveles al insertar otros delante. El motor de combate no cambia.
- **Presentación:** `ArenaRenderConstants.leapSequence(EnemyKind?)` es el `switch` exhaustivo que decide quién salta: `null` (personas) sigue con la hoja `slash`; lobo y oso usan sus frames `attack-*` con su propia secuencia. `ArenaFrames.groundSpot` / `lift` calculan el salto (ida, mordisco, vuelta) hacia el objetivo, que `FighterRenderData` lleva ahora en `targetIndex`. `FighterComponent` mueve el sprite, la sombra y la barra con el salto, y los animales caen sobre su propio frame `down` en vez de girar 90°.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame, `easy_localization`; tests con `flutter_test`, `bloc_test`, `mockito`, `flame_test`. Arte con `asset-packs/lpc/build_assets.py` (Pillow).

**Precondición: C2 y C3 fusionadas en `feature/PROJECT-X-arena`** (commit `e182aae` o posterior). Este plan usa exactamente estas firmas. Antes de empezar, comprueba que no han cambiado:
- `enum EnemyKind { bandit, barbarian, barbarianChief }`; `enum ArenaLevelId { banditRookie, banditVeteran, banditTrio, barbarian, barbarianPair, barbarianChief }`;
- `ArenaLevels.all` (6 niveles) y `ArenaLevels.byId`; `ArenaLevelEntity.power` = suma de `CombatStatsEntity.power` (`attack * 3 + defense * 4 + health ~/ 2`);
- `extension ArenaRules on HeroEntity { bool isUnlocked(ArenaLevelEntity); bool hasCleared(ArenaLevelId); … }`;
- `Internationalize.arenaLevel({required ArenaLevelId id})`, `Internationalize.arenaEnemy({required EnemyKind kind})` (`switch` exhaustivos);
- `ArenaSpriteNames.enemy(EnemyKind)`, `fighter(EnemyKind?)`, `idle(String, int)`, `slash(String, int)`;
- `ArenaRenderConstants.fighterScale(EnemyKind?)`, `heroSpot` (190, 170), `enemySpots` (300, 170) / (340, 140) / (340, 200), `healthBarLift = 52`;
- `ArenaFrames.frameName(FighterRenderData, double)`, `ArenaFrames.spot(FightSide, int)`; `Easing.sineOut` / `sineInOut`; `PlayerFrames.workColumn` / `idleColumn`;
- `FighterRenderData(side, index, enemyKind, health, maxHealth, pose, swingProgress = 0)`; `FighterComponent(assets:, fighter:)` con `shadow`, `healthBar`, `frameName`, `show`, `hit`;
- `ArenaBloc._replayFighter` (construye cada `FighterRenderData` de la reproducción); `ArenaBlocMock.tickFor` con `frameMs = 16`;
- `build_assets.py` con `write_atlas`, `trim`, `cells`, `build_arena`;
- mocks `HeroEntityMock.mock` / `veteran` / `veteranWithSecondWind`, `FighterRenderDataMock`, `ArenaLevelItemDataMock`, `ArenaAssetsMock`.

Si algo ha cambiado, adapta los fragmentos de este plan y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- `flutter test` en verde (15 tests nuevos: 2 de TC4.1, 5 de TC4.2 y 8 de TC4.3), con los niveles nuevos, el flujo de una partida anterior a los animales, el BLoC con casos de uso reales (E11) y el componente del lobo con `testWithFlameGame`.
- La prueba manual de la sección *Prueba manual* en Chrome, el emulador Android y el simulador iOS, en horizontal.

**Cómo se ha comprobado este plan (2026-10-08):** en un worktree desechable sobre `feature/PROJECT-X-arena` (`e182aae`):
- se descargaron las dos hojas con los comandos de TC4.1 (los sha256 coinciden) y se aplicaron **todos** los fragmentos de las tres tareas;
- `python3 build_assets.py`: sólo cambian `arena.png` (1024 × 454, 40 frames: los 26 de C2 + 14 de los animales) y `arena.json`; `forest.*`, `ground.png` y `hero-*.png` salen idénticos byte a byte (`git status`). Se miró `arena.png`: lobos y oso miran a la izquierda, con los pies en la línea de suelo. Dos ejecuciones dan el mismo `arena.png` byte a byte;
- `dart run build_runner build --delete-conflicting-outputs`: sin cambios en `di.config.dart` ni en los `*.mocks.dart`;
- `flutter analyze` → `No issues found!`; `flutter test` → **567 tests** en verde (552 antes de la fase); `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart` → 40 en verde;
- también se comprobaron por separado los dos estados intermedios: **sólo TC4.1** (554 tests en verde) y **sólo TC4.2** (557 en verde), con `flutter analyze` limpio en los dos. La unión de las dos ramas con git no se ensayó (tocan trozos distintos de los mismos dos ficheros; ver *Reparto*);
- los fragmentos de este documento son esos ficheros, ya pasados por `dart format --line-length 120`.

## Decisiones del plan

Lo que este plan fija o añade sobre la ficha (todo lo demás de la ficha se mantiene):

1. **Arte encontrado (no hace falta el plan B del oso):**

   | Pieza | Fichero en `sources/creatures/` | Origen | Autor | Licencia |
   |---|---|---|---|---|
   | Lobo | `wolfsheet1.png` (640 × 384) | "[LPC] Wolf Animation" — <https://opengameart.org/content/lpc-wolf-animation> | Stephen "Redshrike" Challener (artista), William.Thompsonj (colaborador) | CC-BY 4.0, CC-BY 3.0, GPL 3.0, GPL 2.0, **OGA-BY 3.0** |
   | Oso | `bear-grizzly.png` (320 × 768), copiado de `bear, grizzly.png` dentro de `lpc_animals_2022_v1.1.zip` | "[LPC] bears, deer, lions and more" — <https://opengameart.org/content/lpc-bears-deer-lions-and-more> | tapatilorenzo | **CC-BY 4.0** (la página); el autor publica sus propios sprites (osos, ciervos, zorros, leones, ratones) como CC0 |

   - El lobo trae cinco animaciones (andar, correr, morder, aullar, morir) en 4 direcciones y 6 colores; se usa el marrón (`wolfsheet1.png`). Las vistas de lado ocupan la mitad derecha de la hoja (desde x = 320) en celdas de **64 × 32**; las que miran a la izquierda son las filas 6 (morir, 4 frames), 9 (andar, 5), 10 (correr, 5) y 11 (morder, 5).
   - El oso trae andar, atacar y morir en 4 direcciones, en celdas de **64 × 64**: andar a la izquierda es la fila 2 (5 frames), atacar a la izquierda la fila 6 (3 frames, el último es el zarpazo) y morir a la izquierda la fila 10 (4 frames).
   - **Licencia del oso (provisional):** CC-BY 4.0 no está en la lista de las *Global Constraints* del README (CC-BY-SA 3.0, GPL 3.0, OGA-BY 3.0), pero es compatible con un proyecto CC-BY-SA 3.0 (sólo pide atribución), el autor lo da además como CC0 y `CREDITS.md` ya incluye piezas CC-BY 4.0 (las herramientas). Se acepta y se apunta en la sección 5 del README; si no se acepta, se aplica el plan B de la ficha (lobo recoloreado marrón oscuro y ×1,5).
   - Se descargan con `curl` desde las URLs de OpenGameArt y se comprueba el sha256 (TC4.1, Step 2). Del zip sólo se copia el PNG del grizzly; no se ejecuta nada de lo descargado.
2. **Frames del atlas** (todos de celda completa, sin recortar, para que el pivote sea fijo; pivote x = 0,5 y pivote y = línea de suelo / alto de la celda, como `IDLE_PIVOT` de las personas):

   | Frame | Origen | Tamaño | Pivote y |
   |---|---|---|---|
   | `wolf-idle-{0,1}` | andar, columnas 0 y 1 | 64 × 32 | 1,0 |
   | `wolf-attack-{0..4}` | morder, columnas 0–4 (boca más abierta en la 2) | 64 × 32 | 1,0 |
   | `wolf-down` | morir, columna 3 (tumbado) | 64 × 32 | 1,0 |
   | `bear-idle-{0,1}` | andar, columnas 0 y 1 | 64 × 64 | 0,9688 (62/64) |
   | `bear-attack-{0..2}` | atacar, columnas 0–2 (zarpazo en la 2) | 64 × 64 | 0,9062 (58/64: en esta fila el oso está dibujado 4 px más arriba) |
   | `bear-down` | morir, columna 3 (tumbado) | 64 × 64 | 0,8906 (57/64) |

   - **Reposo = los dos primeros pasos de andar** (provisional): ninguna de las dos hojas trae una animación de reposo. A 2 fps se ve como un leve balanceo.
   - Las dos hojas ya miran a la izquierda en esas filas: no hay que voltear nada.
3. **El ataque de los animales** (en `ArenaRenderConstants` y `ArenaFrames`):
   - `leapSequence(EnemyKind?)` es el único `switch` exhaustivo nuevo por tipo de enemigo: `null` (héroe), bandido, bárbaro y jefe → `null` (siguen con `slash` y la secuencia `chop`); lobo → `wolfBiteSequence = [0, 1, 1, 2, 2, 3, 4, 0]`; oso → `bearSwipeSequence = [0, 1, 1, 2, 2, 2, 1, 0]`. El índice se elige con `swingProgress` igual que `PlayerFrames.workColumn`, así que al impactar (50 % del turno) se ve la boca más abierta del lobo (`attack-2`) y el zarpazo del oso (`attack-2`).
   - **Salto:** durante el primer 40 % del turno (`leapOutShare`) el animal avanza hacia el sitio de su objetivo con `Easing.sineOut` y se para a **30 px** (`leapGap`) de él; entre el 40 % y el 60 % (`leapBackShare`) se queda ahí (el impacto cae en el 50 %); del 60 % al final vuelve con `Easing.sineInOut`. En la ida y en la vuelta sube y baja un arco de **10 px** (`leapHeight`, un seno). Con el lobo en (300, 170) y el héroe en (190, 170) llega a x = 220.
   - El salto sale del sitio del atacante hacia el del objetivo (`ArenaFrames.spot(opposite(side), targetIndex)`), no en una dirección fija: así sirve igual para el héroe cuando, en el pulido (ARENA-FIXES §3), todos los luchadores se acerquen a golpear. Por eso `FighterRenderData` gana `targetIndex` (por defecto 0), que el BLoC rellena con `turn.targetIndex` en la pose `attack`.
   - La sombra se queda en el suelo bajo el animal (`groundSpot`), el sprite sube con el arco (`lift`) y la barra de vida acompaña al sprite. `priority` no cambia durante el salto (se queda la de su sitio).
   - En una esquiva, el animal salta y falla (la pose `attack` ya la da el BLoC); en el segundo aliento nadie salta.
4. **Caídos:** los animales se dibujan con su frame `down` (tumbados) al 80 % de opacidad y **sin girar** (`FighterComponent.tipsOver` es falso para ellos); las personas siguen girando 90°.
5. **Tamaños:**
   - `fighterScale` = 1 para lobo y oso (provisional). El oso de LPC ya es tan alto como una persona y más ancho (59 × 52 px), así que no se escala; la ficha sólo pedía ×1,5 para el plan B.
   - La sombra de los animales mide 44 × 7 (`beastShadowWidth`), porque son alargados; la de las personas sigue en 22 × 7.
   - La barra de vida sigue a 52 px de los pies y las gotas de sangre a 28 px (provisional): sobre el lomo del lobo (31 px de alto) la barra queda unos 20 px por encima. Se revisa en la prueba manual.
6. **Desbloqueo y partidas antiguas:** `ArenaRules.isUnlocked` devuelve `true` si el nivel ya está en `clearedLevels`; si no, mira el nivel anterior de la lista como hasta ahora. Una partida que ya había ganado `banditRookie` y `banditVeteran` sigue con los dos abiertos y ve abiertos `wolf` (detrás del novato) y `wolfPair` (detrás del veterano), pero no `bear`. Sin esta regla, `banditVeteran` (ganado) aparecería cerrado porque detrás tiene ahora el lobo.
7. **Catálogo** (los números de la ficha; C7 equilibra): `wolf` 5/1/22 (Poder 30, 15 de oro) tras `banditRookie`; `wolfPair` 2 × 5/1/22 (60, 25) y `bear` 9/3/40 (59, 35) tras `banditVeteran`; `wolfPack` 3 × 5/1/18 (84, 55) tras `barbarian`. Con estos números el héroe base gana al lobo con 2 de vida (comprobado con la semilla 3): la pelea es ajustada, como corresponde a un segundo nivel.
8. **Textos** (`es.json`): niveles "Lobo", "Pareja de lobos", "Oso", "Manada de lobos"; enemigos "Lobo", "Oso". La lista muestra "2 × Lobo" y "3 × Lobo" con `arenaEnemyCount`, como los grupos de bandidos.
9. **Arte provisional entre TC4.2 y TC4.3:** para que TC4.1 y TC4.2 vayan a la vez, TC4.2 añade los dos `EnemyKind` con `ArenaSpriteNames.enemy` apuntando a `'bandit'` (lobo) y `'barbarian'` (oso). Así compila y todos los tests del atlas pasan aunque la rama no tenga todavía el arte nuevo. TC4.3 los cambia a `'wolf'` y `'bear'`. No llega a la rama de integración: la PR de la fase lleva las tres tareas.
10. **Mocks y tests que cambian** porque el segundo nivel ya no es el bandido veterano:
    - `HeroEntityMock.veteran` (sólo ganó el novato) **no cambia**: ahora le toca el lobo. Los tests que peleaban contra `banditVeteran` con él pasan a `HeroEntityMock.wolfHunter` (novato y lobo ganados, `fightsFought: 3`: misma semilla, mismas peleas) y `wolfHunterAfterAnotherFight`.
    - `HeroEntityMock.veteranWithSecondWind` gana también `ArenaLevelId.wolf` en `clearedLevels` (sólo lo usa un test del BLoC que pelea contra el veterano; la semilla no cambia).
    - En `arena_bloc_test.dart` cambian los índices de la lista (`levels[1]` es ahora el lobo; el veterano es `levels[2]` y el trío `levels[5]`).
    - Los tests dorados de `combat_test.dart` y los mocks del primer nivel (`ArenaLevelEntityMock.banditRookie`, `FightResultEntityMock.victoryOverBandit`, `ArenaLevelStatusEntityMock.rookieForNewHero`) no cambian: el primer nivel sigue siendo el mismo.
11. **Grupos:** la pareja y la manada usan las posiciones de `ArenaRenderConstants.enemySpots` (provisional hasta C6). Los lobos de arriba y de abajo saltan en diagonal hacia el héroe.
12. **`CLAUDE.md`:** TC4.2 añade la regla de desbloqueo a la línea de `ArenaLevels`; TC4.3 describe el salto en *Rendering constants* y añade la receta **New enemy kind** (como la de recursos y edificios).

## Reparto

| Tarea | Qué | Depende de | Paralelizable |
|---|---|---|---|
| TC4.1 Arte de los animales | descarga en `sources/creatures/`, `build_assets.py`, `arena.{png,json}`, `CREDITS.md`, `ArenaSpriteNames.attack` / `down`, `ArenaAssetsMock` | C2 | **Sí, con TC4.2** |
| TC4.2 Niveles y textos | enums, `ArenaLevels`, `ArenaRules.isUnlocked`, `Internationalize`, `es.json`, casos nuevos de `ArenaSpriteNames.enemy` (provisionales) y `fighterScale`, tests de dominio y del BLoC, `CLAUDE.md` | C2 | **Sí, con TC4.1** |
| TC4.3 El salto de los animales | `leapSequence`, `ArenaFrames` (frames, salto), `FighterRenderData.targetIndex`, `ArenaBloc`, `FighterComponent`, nombres definitivos en `ArenaSpriteNames.enemy`, tests, `CLAUDE.md` | TC4.1, TC4.2 | No |

**Ficheros compartidos entre tareas paralelas (TC4.1 ∥ TC4.2):**
- `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`: TC4.2 añade dos casos dentro de `enemy()` (arriba) y TC4.1 añade `attack` y `down` al final de la clase. Son trozos separados por seis líneas: git debería unirlos sin conflicto.
- `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`: TC4.2 cambia una línea del primer test y TC4.1 añade un test al final. Tampoco deberían chocar.
- Si aun así hay conflicto, se quedan los dos cambios (son aditivos).

**Ficheros calientes compartidos con C5 (torre de magia, otra rama a la vez):** `asset-packs/lpc/build_assets.py` (C5 toca la sección del bosque; C4 la de la arena), `lib/core/assets/images/lpc/CREDITS.md` (las dos añaden una sección al final: se quedan las dos), `es.json` e `Internationalize` (bloques distintos: `arena.*` aquí), `test/core/assets/i18n/internationalize_test.dart`, `test/mocks/domain/entities/hero/hero_entity_mock.dart` (si las dos añaden mocks al final: se quedan todos) y `CLAUDE.md`. Atlas: C4 sólo regenera `arena.*` y C5 sólo `forest.*`; si al unir hay conflicto en un atlas, **nunca se resuelve a mano**: se vuelve a ejecutar `build_assets.py` con el script ya unido.

**Ramas (README, sección 3.0):**
- Rama de fase `feature/PROJECT-X-c4-beasts`, desde `feature/PROJECT-X-arena`. Su PR va a `feature/PROJECT-X-arena`.
- Cada tarea en su rama desde la de fase: `feature/PROJECT-X-c4-art`, `feature/PROJECT-X-c4-levels`, `feature/PROJECT-X-c4-leap`. TC4.1 y TC4.2, cada una en su propio worktree (`boost:using-git-worktrees`). Al terminar una tarea se une a la rama de fase con `git merge --no-ff` (sin PR por tarea, como en C1–C3).
- Commits `[PROJECT-X]: Imperative description`, sin atribución a IA; `CLAUDE.md` se añade al índice **en un comando aparte**.

---

### Task TC4.1: Arte de los animales

**Files:**
- Create (descargados):
  - `asset-packs/lpc/sources/creatures/wolfsheet1.png`
  - `asset-packs/lpc/sources/creatures/bear-grizzly.png`
- Create:
  - `asset-packs/lpc/sources/creatures/CREDITS-creatures.txt`
- Modify:
  - `asset-packs/lpc/build_assets.py`
  - `lib/core/assets/images/lpc/arena.png`, `lib/core/assets/images/lpc/arena.json` (generados)
  - `lib/core/assets/images/lpc/CREDITS.md`
  - `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_assets_test.dart`
  - `test/mocks/presentation/features/arena/game/arena_assets_mock.dart`

**Interfaces:**
- Consumes: `write_atlas`, `trim`, `build_arena` (`build_assets.py`); `ArenaSpriteNames.idle`; `RenderConstants.idleColumns`.
- Produces:
  ```dart
  // lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart
  static String attack(String fighter, int column);   // 'wolf-attack-4'
  static String down(String fighter);                 // 'bear-down'
  ```
  - frames en `arena.json`: `wolf-idle-{0,1}`, `wolf-attack-{0..4}`, `wolf-down`, `bear-idle-{0,1}`, `bear-attack-{0..2}`, `bear-down` (decisión 2);
  - `ArenaAssetsMock.create()` tiene también `<luchador>-attack-{0..4}` y `<luchador>-down` para cada luchador.

- [ ] **Step 1: Ramas**

```bash
git switch feature/PROJECT-X-arena && git pull
git switch -c feature/PROJECT-X-c4-beasts && git push -u origin feature/PROJECT-X-c4-beasts
git switch -c feature/PROJECT-X-c4-art
```

(TC4.2 a la vez, en otro worktree: `git worktree add ../phaser-example-c4-levels -b feature/PROJECT-X-c4-levels feature/PROJECT-X-c4-beasts`, y allí `flutter pub get`.)

- [ ] **Step 2: Descargar el arte y comprobarlo**

Desde la raíz del repositorio. El zip se abre en una carpeta temporal nueva y sólo se copia el PNG del oso:

```bash
mkdir -p asset-packs/lpc/sources/creatures
curl -sSfL -o asset-packs/lpc/sources/creatures/wolfsheet1.png https://opengameart.org/sites/default/files/wolfsheet1.png
tmp=$(mktemp -d)
curl -sSfL -o "$tmp/lpc_animals_2022_v1.1.zip" https://opengameart.org/sites/default/files/lpc_animals_2022_v1.1.zip
mkdir "$tmp/zip" && unzip -q "$tmp/lpc_animals_2022_v1.1.zip" -d "$tmp/zip"
cp "$tmp/zip/lpc animals 2022 v1.1/individual creature spritesheets/bear, grizzly.png" asset-packs/lpc/sources/creatures/bear-grizzly.png
shasum -a 256 "$tmp/lpc_animals_2022_v1.1.zip" asset-packs/lpc/sources/creatures/*.png
rm -r "$tmp"
```

Expected (los tres tienen que coincidir; si no, **para**: el autor ha cambiado el fichero y hay que volver a revisar los frames de la decisión 2):

```text
a4ea2c5b33061858e02a60dda34adb30bc8c4a334030bdcc7fafef32c810c002  …/lpc_animals_2022_v1.1.zip
a47c3d1516a0b53599c0f9636fbb5ce712156f7cf9e5758e609f9afe1d6109ae  asset-packs/lpc/sources/creatures/bear-grizzly.png
35037f84c065844cb974d7d692875115b4c6ebf34e242921991351f370e1fa4f  asset-packs/lpc/sources/creatures/wolfsheet1.png
```

`asset-packs/lpc/sources/creatures/CREDITS-creatures.txt` (como `terrain/Attribution.txt`, deja constancia del origen de cada hoja):

```text
Arena beasts (used by build_assets.py -> arena.png)
===================================================

wolfsheet1.png
  "[LPC] Wolf Animation" — Stephen "Redshrike" Challener (graphic artist), William.Thompsonj (contributor)
  https://opengameart.org/content/lpc-wolf-animation
  Download: https://opengameart.org/sites/default/files/wolfsheet1.png
  Licences: CC-BY 4.0, CC-BY 3.0, GPL 3.0, GPL 2.0, OGA-BY 3.0
  Attribution requested: "Attribute Stephen 'Redshrike' Challener as graphic artist and William.Thompsonj
  as contributor. If reasonable link back to this page or the OGA homepage."

bear-grizzly.png  (renamed from "lpc animals 2022 v1.1/individual creature spritesheets/bear, grizzly.png")
  "[LPC] bears, deer, lions and more" — tapatilorenzo (LPC Spring 2022 entry)
  https://opengameart.org/content/lpc-bears-deer-lions-and-more
  Download: https://opengameart.org/sites/default/files/lpc_animals_2022_v1.1.zip
  Licence: CC-BY 4.0. The author releases their own sprites (bears, deer, foxes, lions, mice) as CC0;
  attribution appreciated.
```

- [ ] **Step 3: Tests que fallan**

En `test/mocks/presentation/features/arena/game/arena_assets_mock.dart`, cada luchador gana sus frames de ataque y de caído (después de la línea de `slash`):

```dart
  static final List<String> frameNames = [
    ArenaSpriteNames.grass,
    ArenaSpriteNames.fence,
    for (final fighter in [ArenaSpriteNames.hero, ...EnemyKind.values.map(ArenaSpriteNames.enemy)]) ...[
      for (var column = 0; column < 2; column++) ArenaSpriteNames.idle(fighter, column),
      for (var column = 0; column < 6; column++) ArenaSpriteNames.slash(fighter, column),
      for (var column = 0; column < 5; column++) ArenaSpriteNames.attack(fighter, column),
      ArenaSpriteNames.down(fighter),
    ],
  ];
```

Al final de `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart` (dentro de `main`):

```dart
  test('testWhenReadingTheArenaAtlasThenTheWolfAndTheBearHaveTheirIdleAttackAndDownFrames', () {
    // given
    final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
    const beasts = [('wolf', 5), ('bear', 3)];

    // when
    final wanted = [
      for (final (beast, attackColumns) in beasts) ...[
        for (var column = 0; column < RenderConstants.idleColumns; column++) ArenaSpriteNames.idle(beast, column),
        for (var column = 0; column < attackColumns; column++) ArenaSpriteNames.attack(beast, column),
        ArenaSpriteNames.down(beast),
      ],
    ];

    // then
    expect(wanted.where((name) => !frames.contains(name)), isEmpty);
    expect((ArenaSpriteNames.attack('wolf', 4), ArenaSpriteNames.down('bear')), ('wolf-attack-4', 'bear-down'));
  });
```

Al final de `test/layers/presentation/features/arena/game/atlas/arena_assets_test.dart` (dentro de `main`):

```dart
  testWidgets('testWhenLoadingTheRealArtThenTheBeastsStandOnTheirPaws', (tester) async {
    // given
    final loader = ArenaAssetsLoader();

    // when
    final assets = (await tester.runAsync(loader.load))!;

    // then
    final wolf = assets.frame(ArenaSpriteNames.attack('wolf', 0));
    final bearIdle = assets.frame(ArenaSpriteNames.idle('bear', 0));
    final bearAttack = assets.frame(ArenaSpriteNames.attack('bear', 2));
    final bearDown = assets.frame(ArenaSpriteNames.down('bear'));
    expect((wolf.width, wolf.height, wolf.pivotY), (64, 32, 1.0));
    expect((bearIdle.width, bearIdle.height, bearIdle.pivotY), (64, 64, 0.9688));
    expect((bearAttack.pivotY, bearDown.pivotY), (0.9062, 0.8906));
  });
```

Run: `flutter test test/layers/presentation/features/arena/game/atlas`
Expected: FAIL de compilación (`The method 'attack' isn't defined for the type 'ArenaSpriteNames'`).

- [ ] **Step 4: Generar el atlas**

En `asset-packs/lpc/build_assets.py`:

1. En la cabecera, la entrada de `arena.png` queda así:

```text
  arena.png + arena.json           JSON-hash atlas for the arena: hero, bandit and barbarian idle (64px, axe in
                                   hand) and slash (128px) frames in their one facing (pivot = feet), the wolf
                                   and bear idle, attack and down frames facing left, the grass cell and a fence
                                   segment
```

2. Justo después de `SLASH_PIVOT = …`:

```python
# Beast -> (sheet in sources/creatures, origin of the side views, cell size, animations). The rows used already face
# left. Each animation is (row, columns, ground): one frame per column, and ground = the pixel row the paws stand on
# in that row (the pivot, like the feet of the people). A single column is named without an index ("wolf-down").
ARENA_BEASTS = {
    "wolf": (
        "wolfsheet1.png",
        (320, 0),
        (64, 32),
        {"idle": (9, [0, 1], 32), "attack": (11, [0, 1, 2, 3, 4], 32), "down": (6, [3], 32)},
    ),
    "bear": (
        "bear-grizzly.png",
        (0, 0),
        (64, 64),
        {"idle": (2, [0, 1], 62), "attack": (6, [0, 1, 2], 58), "down": (10, [3], 57)},
    ),
}
```

3. Entre `cells()` y `build_arena()`:

```python
def add_beasts(frames: dict, pivots: dict) -> None:
    for beast, (file_name, (origin_x, origin_y), (width, height), animations) in ARENA_BEASTS.items():
        sheet = Image.open(SOURCES / "creatures" / file_name).convert("RGBA")
        for animation, (row, columns, ground) in animations.items():
            for index, column in enumerate(columns):
                x, y = origin_x + column * width, origin_y + row * height
                name = f"{beast}-{animation}" if len(columns) == 1 else f"{beast}-{animation}-{index}"
                cell = sheet.crop((x, y, x + width, y + height))
                trim(cell, name)
                frames[name], pivots[name] = cell, {"x": 0.5, "y": round(ground / height, 4)}
```

(`trim` sólo se llama para que falle con un mensaje claro si una celda está vacía; el frame guarda la celda entera.)

4. En `build_arena()`, después del bucle de `ARENA_FIGHTERS` y antes de la hierba:

```python
        for column, image in enumerate(cells(slash, row, WORK_FRAME)):
            frames[f"{fighter}-slash-{column}"], pivots[f"{fighter}-slash-{column}"] = image, SLASH_PIVOT
    add_beasts(frames, pivots)
    column, row = ARENA_GRASS
```

Generar y comprobar que el arte del bosque no cambia:

```bash
(cd asset-packs/lpc && python3 build_assets.py)
git status --short lib/core/assets/images/lpc
```

Expected: `Assets written to …` y sólo `M lib/core/assets/images/lpc/arena.json` y `M lib/core/assets/images/lpc/arena.png` (1024 × 454, 40 frames). Si aparece `forest.*`, `ground.png` o algún `hero-*.png`, el script está mal: se corrige el script, nunca la imagen.

Ábrelo en un visor: abajo, tras las personas, cinco frames del oso (dos de pie, tres del zarpazo), el oso tumbado, siete del lobo (dos de pie y cinco del mordisco), el lobo tumbado, y a la derecha la hierba y la valla. Todos miran a la izquierda.

- [ ] **Step 5: Créditos**

Al final de `lib/core/assets/images/lpc/CREDITS.md` (dentro de la sección *Arena*):

```markdown

### Wolf and bear (`wolf-*`, `bear-*` frames in `arena.png`)

Cut by `build_assets.py` from the side views that face left, without recolouring. Sources in
`asset-packs/lpc/sources/creatures/` (see `CREDITS-creatures.txt` there).

- Wolf: "[LPC] Wolf Animation" by Stephen "Redshrike" Challener (graphic artist) and
  William.Thompsonj (contributor), `wolfsheet1.png`. CC-BY 4.0 / CC-BY 3.0 / GPL 3.0 / GPL 2.0 /
  OGA-BY 3.0 — <https://opengameart.org/content/lpc-wolf-animation>.
- Bear: "[LPC] bears, deer, lions and more" by tapatilorenzo, `bear, grizzly.png` from
  `lpc_animals_2022_v1.1.zip`. CC-BY 4.0 (the author releases the bears as CC0) —
  <https://opengameart.org/content/lpc-bears-deer-lions-and-more>.
```

- [ ] **Step 6: Nombres de los frames nuevos**

En `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`, al final de la clase:

```dart
  static String slash(String fighter, int column) => '$fighter-slash-$column';

  static String attack(String fighter, int column) => '$fighter-attack-$column';

  static String down(String fighter) => '$fighter-down';
}
```

Run: `flutter test test/layers/presentation/features/arena/game/atlas test/core/assets/lpc_assets_test.dart`
Expected: PASS (7 tests en `atlas/`, 2 de ellos nuevos, y los de `lpc_assets_test.dart`).

- [ ] **Step 7: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/arena/game/atlas test/layers/presentation/features/arena/game/atlas test/mocks/presentation/features/arena/game/arena_assets_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida, `No issues found!` y todo en verde (554 tests si la rama todavía no tiene TC4.2).

- [ ] **Step 8: Commit y unión a la rama de fase**

```bash
git add asset-packs/lpc/sources/creatures asset-packs/lpc/build_assets.py lib/core/assets/images/lpc/arena.png lib/core/assets/images/lpc/arena.json lib/core/assets/images/lpc/CREDITS.md lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart test/layers/presentation/features/arena/game/atlas test/mocks/presentation/features/arena/game/arena_assets_mock.dart
git commit -m "[PROJECT-X]: Add the LPC wolf and bear to the arena atlas"
git switch feature/PROJECT-X-c4-beasts && git merge --no-ff feature/PROJECT-X-c4-art
```

---

### Task TC4.2: Niveles y textos

**Files:**
- Modify:
  - `lib/core/config/constants/enum/enemy_kind.dart`
  - `lib/core/config/constants/enum/arena_level_id.dart`
  - `lib/layers/domain/rules/arena_levels.dart`
  - `lib/layers/domain/world/extensions/arena_rules.dart`
  - `lib/core/assets/i18n/internationalize.dart`
  - `lib/core/assets/i18n/translations/es.json`
  - `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - `CLAUDE.md`
  - `test/layers/domain/rules/arena_levels_test.dart`
  - `test/layers/domain/world/extensions/arena_rules_test.dart`
  - `test/layers/domain/use-cases/arena/arena_flow_test.dart`
  - `test/layers/domain/use-cases/arena/start_fight_use_case_test.dart`
  - `test/core/assets/i18n/internationalize_test.dart`
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`
  - `test/mocks/domain/entities/hero/hero_entity_mock.dart`
  - `test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`
  - `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`

**Interfaces:**
- Consumes: `ArenaLevelEntity`, `EnemyEntity`, `CombatStatsEntity`, `Resource.gold`; `ArenaRules.hasCleared`.
- Produces:
  ```dart
  enum EnemyKind { bandit, barbarian, barbarianChief, wolf, bear }
  enum ArenaLevelId { banditRookie, banditVeteran, banditTrio, barbarian, barbarianPair, barbarianChief, wolf, wolfPair, bear, wolfPack }
  // ArenaLevels.all, en orden de juego:
  // banditRookie, wolf, banditVeteran, wolfPair, bear, banditTrio, barbarian, wolfPack, barbarianPair, barbarianChief
  bool isUnlocked(ArenaLevelEntity level);   // también true si el nivel ya está ganado
  // ArenaSpriteNames.enemy: wolf -> 'bandit', bear -> 'barbarian' (provisional, TC4.3 los cambia)
  // ArenaRenderConstants.fighterScale: wolf, bear -> 1
  ```
  - mocks: `HeroEntityMock.wolfHunter`, `wolfHunterAfterAnotherFight`, `beforeTheBeasts`; `ArenaLevelItemDataMock.wolfLocked` / `wolfOpen`; `FighterRenderDataMock.wolfIdle`.

- [ ] **Step 1: Rama**

En el worktree de TC4.2 (`../phaser-example-c4-levels`, rama `feature/PROJECT-X-c4-levels`) o, si va después de TC4.1:

```bash
git switch feature/PROJECT-X-c4-beasts && git switch -c feature/PROJECT-X-c4-levels
```

- [ ] **Step 2: Mocks**

`test/mocks/domain/entities/hero/hero_entity_mock.dart`: `veteranWithSecondWind` gana el lobo y, al final de la clase, tres mocks nuevos:

```dart
  static const HeroEntity veteranWithSecondWind = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    skills: {SkillId.secondWind},
  );

  static const HeroEntity wolfHunter = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    fightsFought: 3,
  );

  static const HeroEntity wolfHunterAfterAnotherFight = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    fightsFought: 4,
  );

  static const HeroEntity beforeTheBeasts = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.banditVeteran},
    fightsFought: 2,
  );
}
```

`test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`, antes de `chiefLocked`:

```dart
  static ArenaLevelItemData get wolfLocked => ArenaLevelItemData(
    id: ArenaLevelId.wolf,
    name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
    powerText: Internationalize.arenaPower(power: 30),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 15),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get wolfOpen => ArenaLevelItemData(
    id: ArenaLevelId.wolf,
    name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
    powerText: Internationalize.arenaPower(power: 30),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 15),
    status: ArenaLevelItemStatus.open,
  );
```

`test/mocks/presentation/features/arena/fighter_render_data_mock.dart`, después de `veteranBanditIdle`:

```dart
  static const FighterRenderData wolfIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 22,
    maxHealth: 22,
    pose: FighterPose.idle,
  );
```

- [ ] **Step 3: Tests que fallan**

`test/layers/domain/rules/arena_levels_test.dart`: import de `enemy_kind.dart` y dos tests antes de `testWhenFindingByIdThenItReturnsThatLevel`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
```

```dart
  test('testWhenListingLevelsThenTheBeastsSitBetweenTheHumans', () {
    // given
    final levels = ArenaLevels.all;

    // when
    final ids = levels.map((level) => level.id);

    // then
    expect(ids, [
      ArenaLevelId.banditRookie,
      ArenaLevelId.wolf,
      ArenaLevelId.banditVeteran,
      ArenaLevelId.wolfPair,
      ArenaLevelId.bear,
      ArenaLevelId.banditTrio,
      ArenaLevelId.barbarian,
      ArenaLevelId.wolfPack,
      ArenaLevelId.barbarianPair,
      ArenaLevelId.barbarianChief,
    ]);
  });

  test('testWhenFindingTheBeastLevelsThenTheirEnemiesPowerAndGoldMatchTheTable', () {
    // given
    const ids = [ArenaLevelId.wolf, ArenaLevelId.wolfPair, ArenaLevelId.bear, ArenaLevelId.wolfPack];

    // when
    final levels = ids.map(ArenaLevels.byId).toList();

    // then
    expect(levels.map((level) => level.enemies.map((enemy) => enemy.kind).toList()), [
      [EnemyKind.wolf],
      [EnemyKind.wolf, EnemyKind.wolf],
      [EnemyKind.bear],
      [EnemyKind.wolf, EnemyKind.wolf, EnemyKind.wolf],
    ]);
    expect(levels.map((level) => (level.power, level.reward[Resource.gold])), [(30, 15), (60, 25), (59, 35), (84, 55)]);
  });
```

`test/layers/domain/world/extensions/arena_rules_test.dart`, en el grupo `isUnlocked`, después de `testWhenTheHeroClearedTheFirstLevelThenTheSecondIsUnlockedButNotTheThird`:

```dart
    test('testWhenTheHeroClearedLevelsBeforeTheBeastsArrivedThenTheyStayOpenAndSoDoTheBeastsBehindThem', () {
      // given
      const hero = HeroEntityMock.beforeTheBeasts;

      // when
      final unlocked = ArenaLevels.all.where(hero.isUnlocked).map((level) => level.id);

      // then
      expect(unlocked, [
        ArenaLevelId.banditRookie,
        ArenaLevelId.wolf,
        ArenaLevelId.banditVeteran,
        ArenaLevelId.wolfPair,
      ]);
    });
```

`test/layers/domain/use-cases/arena/arena_flow_test.dart`, antes de `testWhenANewHeroTriesTheLastLevelThenItIsLockedAndNothingChanges`:

```dart
  test('testWhenAGameFromBeforeTheBeastsGoesOnThenItKeepsItsLevelsAndCanFightTheWolfAndTheWolfPair', () {
    // given
    final session = playingWith(HeroEntityMock.beforeTheBeasts);

    // when
    final results = [
      startFight(levelId: ArenaLevelId.wolf),
      startFight(levelId: ArenaLevelId.banditVeteran),
      startFight(levelId: ArenaLevelId.wolfPair),
    ];

    // then
    expect(results, everyElement(isA<FightPlayedEntity>()));
    expect(
      session.world.hero.clearedLevels,
      containsAll([ArenaLevelId.banditRookie, ArenaLevelId.banditVeteran]),
    );
    final veteran = getArena().levels.firstWhere((status) => status.level.id == ArenaLevelId.banditVeteran);
    expect((veteran.isUnlocked, veteran.isCleared), (true, true));
  });
```

(El test de flujo que ya existe, `testWhenAFullyGearedHeroFightsEveryLevelInOrderThenItClearsTheWholeArena`, recorre ya los diez niveles sin tocarlo.)

`test/layers/domain/use-cases/arena/start_fight_use_case_test.dart`, en `testWhenTheHeroLosesThenNothingIsPaidAndAdviceIsGiven` (el veterano ya no está abierto para quien sólo ganó al novato):

```dart
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.wolfHunter));
```

```dart
    expect(session.world.hero, HeroEntityMock.wolfHunterAfterAnotherFight);
```

`test/core/assets/i18n/internationalize_test.dart`, en `testWhenNamingArenaLevelsEnemiesAndAdviceThenUsesTheSpanishTexts`:

```dart
    expect(levels, [
      'Bandido novato',
      'Bandido veterano',
      'Trío de bandidos',
      'Bárbaro',
      'Pareja de bárbaros',
      'Jefe bárbaro',
      'Lobo',
      'Pareja de lobos',
      'Oso',
      'Manada de lobos',
    ]);
    expect(enemies, ['Bandido', 'Bárbaro', 'Jefe bárbaro', 'Lobo', 'Oso']);
```

`test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`, en `testWhenNamingFightersThenTheChiefBorrowsTheBarbarianArt` (arte provisional, decisión 9):

```dart
    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian', 'bandit', 'barbarian']);
```

`test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`:
- `testWhenStartedThenListsEveryLevelOpensOnlyTheFirstAndSelectsIt`:

```dart
      expect(data.levels[0], ArenaLevelItemDataMock.rookieOpen);
      expect(data.levels[1], ArenaLevelItemDataMock.wolfLocked);
      expect(data.levels[2], ArenaLevelItemDataMock.veteranLocked);
      expect(data.levels[5], ArenaLevelItemDataMock.trioLocked);
      expect(data.levels.last, ArenaLevelItemDataMock.chiefLocked);
```

- `testWhenALevelPowerIsUpToAQuarterAboveTheHeroThenItsToneIsEven` (el veterano es ahora el tercero):

```dart
      expect(bloc.state.data.levels[2].tone, PowerTone.even);
```

- `testWhenSelectingAnOpenLevelThenItIsSelectedAndItsEnemiesWait`: el héroe es `HeroEntityMock.wolfHunter` y el veterano está en `levels[2]`:

```dart
      world = WorldMock.withHero(HeroEntityMock.wolfHunter);
```

```dart
      expect(bloc.state.data.levels[2], ArenaLevelItemDataMock.veteranOpen);
```

- un test nuevo justo después:

```dart
  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheRookieIsBeatenThenTheWolfIsSelectedAndWaitsAlone',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ArenaStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.wolf);
      expect(bloc.state.data.levels[1], ArenaLevelItemDataMock.wolfOpen);
      expect(bloc.state.data.levels[2].id, ArenaLevelId.banditVeteran);
      expect(bloc.state.data.fighters, [FighterRenderDataMock.heroIdle, FighterRenderDataMock.wolfIdle]);
    },
  );
```

- `testWhenTheReplayEndsThenEveryTurnPlayedOnceAndTheVictoryIsShown`:

```dart
      expect(data.levels[1], ArenaLevelItemDataMock.wolfOpen);
```

- `testWhenTheHeroLosesThenNoGoldIsPaidAndTheAdviceIsShown` y `testWhenRetryingAfterADefeatThenANewFightIsPlayed`: `world = WorldMock.withHero(HeroEntityMock.wolfHunter);` en lugar de `HeroEntityMock.veteran`.

Run: `flutter test test/layers/domain test/core/assets test/layers/presentation/features/arena`
Expected: FAIL de compilación (`There's no constant named 'wolf' in 'ArenaLevelId'`, `… 'wolf' in 'EnemyKind'`).

- [ ] **Step 4: Enums**

`lib/core/config/constants/enum/enemy_kind.dart`:

```dart
enum EnemyKind { bandit, barbarian, barbarianChief, wolf, bear }
```

`lib/core/config/constants/enum/arena_level_id.dart` (el formateador lo parte en líneas):

```dart
enum ArenaLevelId {
  banditRookie,
  banditVeteran,
  banditTrio,
  barbarian,
  barbarianPair,
  barbarianChief,
  wolf,
  wolfPair,
  bear,
  wolfPack,
}
```

Los `switch` exhaustivos dejan de compilar a propósito (aviso de C2): `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale`, `Internationalize.arenaLevel` e `Internationalize.arenaEnemy`. Se arreglan en los pasos siguientes, en el orden de declaración.

- [ ] **Step 5: Catálogo y desbloqueo**

`lib/layers/domain/rules/arena_levels.dart`: tres inserciones en `all`.
- Después del nivel `banditRookie`:

```dart
    ArenaLevelEntity(
      id: ArenaLevelId.wolf,
      enemies: [
        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 22)),
      ],
      reward: {Resource.gold: 15},
    ),
```

- Después del nivel `banditVeteran`:

```dart
    ArenaLevelEntity(
      id: ArenaLevelId.wolfPair,
      enemies: [
        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 22)),
        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 22)),
      ],
      reward: {Resource.gold: 25},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.bear,
      enemies: [
        EnemyEntity(kind: EnemyKind.bear, stats: CombatStatsEntity(attack: 9, defense: 3, health: 40)),
      ],
      reward: {Resource.gold: 35},
    ),
```

- Después del nivel `barbarian` (antes de `barbarianPair`):

```dart
    ArenaLevelEntity(
      id: ArenaLevelId.wolfPack,
      enemies: [
        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 18)),
        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 18)),
        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 18)),
      ],
      reward: {Resource.gold: 55},
    ),
```

`lib/layers/domain/world/extensions/arena_rules.dart`, primera línea de `isUnlocked` (decisión 6):

```dart
  bool isUnlocked(ArenaLevelEntity level) {
    if (hasCleared(level.id)) return true;
    final index = ArenaLevels.all.indexWhere((candidate) => candidate.id == level.id);
    if (index < 0) return false;
    return index == 0 || hasCleared(ArenaLevels.all[index - 1].id);
  }
```

- [ ] **Step 6: Textos**

`lib/core/assets/i18n/translations/es.json`, bloques `arena.level` y `arena.enemy`:

```json
    "level": {
      "banditRookie": "Bandido novato",
      "banditVeteran": "Bandido veterano",
      "banditTrio": "Trío de bandidos",
      "barbarian": "Bárbaro",
      "barbarianPair": "Pareja de bárbaros",
      "barbarianChief": "Jefe bárbaro",
      "wolf": "Lobo",
      "wolfPair": "Pareja de lobos",
      "bear": "Oso",
      "wolfPack": "Manada de lobos"
    },
    "enemy": {
      "bandit": "Bandido",
      "barbarian": "Bárbaro",
      "barbarianChief": "Jefe bárbaro",
      "wolf": "Lobo",
      "bear": "Oso"
    },
```

`lib/core/assets/i18n/internationalize.dart`:

```dart
  static String arenaLevel({required ArenaLevelId id}) => switch (id) {
    ArenaLevelId.banditRookie => '$_arena.level.banditRookie'.tr(),
    ArenaLevelId.banditVeteran => '$_arena.level.banditVeteran'.tr(),
    ArenaLevelId.banditTrio => '$_arena.level.banditTrio'.tr(),
    ArenaLevelId.barbarian => '$_arena.level.barbarian'.tr(),
    ArenaLevelId.barbarianPair => '$_arena.level.barbarianPair'.tr(),
    ArenaLevelId.barbarianChief => '$_arena.level.barbarianChief'.tr(),
    ArenaLevelId.wolf => '$_arena.level.wolf'.tr(),
    ArenaLevelId.wolfPair => '$_arena.level.wolfPair'.tr(),
    ArenaLevelId.bear => '$_arena.level.bear'.tr(),
    ArenaLevelId.wolfPack => '$_arena.level.wolfPack'.tr(),
  };
  static String arenaEnemy({required EnemyKind kind}) => switch (kind) {
    EnemyKind.bandit => '$_arena.enemy.bandit'.tr(),
    EnemyKind.barbarian => '$_arena.enemy.barbarian'.tr(),
    EnemyKind.barbarianChief => '$_arena.enemy.barbarianChief'.tr(),
    EnemyKind.wolf => '$_arena.enemy.wolf'.tr(),
    EnemyKind.bear => '$_arena.enemy.bear'.tr(),
  };
```

- [ ] **Step 7: Los dos `switch` de la escena**

`lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart` (arte provisional hasta TC4.3, decisión 9):

```dart
  static String enemy(EnemyKind kind) => switch (kind) {
    EnemyKind.bandit => 'bandit',
    EnemyKind.barbarian => 'barbarian',
    EnemyKind.barbarianChief => 'barbarian',
    EnemyKind.wolf => 'bandit',
    EnemyKind.bear => 'barbarian',
  };
```

`lib/layers/presentation/features/arena/game/render/arena_render_constants.dart` (decisión 5):

```dart
  static double fighterScale(EnemyKind? kind) => switch (kind) {
    null || EnemyKind.bandit || EnemyKind.barbarian => 1,
    EnemyKind.barbarianChief => chiefScale,
    EnemyKind.wolf || EnemyKind.bear => 1,
  };
```

Run: `flutter test test/layers/domain test/core/assets test/layers/presentation/features/arena`
Expected: PASS.

- [ ] **Step 8: `CLAUDE.md`**

En la línea de `rules/` (sección *Architecture*), el trozo de `ArenaLevels` queda así:

```markdown
`ArenaLevels`: the list order is the play order (a new level can go anywhere in the list, its `ArenaLevelId` always at the end of the enum; `ArenaRules.isUnlocked` also opens any level already cleared, so a game keeps its levels when new ones are inserted), and the combat constants of `Rules`)
```

- [ ] **Step 9: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum lib/core/assets/i18n/internationalize.dart lib/layers/domain/rules lib/layers/domain/world/extensions/arena_rules.dart lib/layers/presentation/features/arena test/layers/domain test/core/assets/i18n test/layers/presentation/features/arena test/mocks/domain/entities/hero test/mocks/presentation/features/arena
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

(No pases `dart format` sobre carpetas que contienen `*.mocks.dart`, como `test/mocks/domain/repositories` o `test/layers/data`: por eso se nombran las carpetas una a una.)

Expected: `git diff` sin salida, `No issues found!` y todo en verde (557 tests si la rama todavía no tiene TC4.1).

- [ ] **Step 10: Commit y unión a la rama de fase**

```bash
git add lib/core/config/constants/enum/enemy_kind.dart lib/core/config/constants/enum/arena_level_id.dart lib/layers/domain/rules/arena_levels.dart lib/layers/domain/world/extensions/arena_rules.dart lib/core/assets/i18n lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart lib/layers/presentation/features/arena/game/render/arena_render_constants.dart test/layers/domain test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/arena test/mocks/domain/entities/hero/hero_entity_mock.dart test/mocks/presentation/features/arena
git add CLAUDE.md
git commit -m "[PROJECT-X]: Insert the wolf and bear levels into the arena"
git switch feature/PROJECT-X-c4-beasts && git merge --no-ff feature/PROJECT-X-c4-levels
```

Con las dos tareas unidas, comprueba en la rama de fase que `flutter analyze` y `flutter test` siguen en verde (deberían ser 559 tests) antes de empezar TC4.3. Si se usó un worktree: `git worktree remove ../phaser-example-c4-levels`.

---

### Task TC4.3: El salto de los animales

**Files:**
- Modify:
  - `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_frames.dart`
  - `lib/layers/presentation/features/arena/models/fighter_render_data.dart`
  - `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
  - `lib/layers/presentation/features/arena/game/components/fighter_component.dart`
  - `CLAUDE.md`
  - `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_assets_test.dart`
  - `test/layers/presentation/features/arena/game/render/arena_frames_test.dart`
  - `test/layers/presentation/features/arena/game/components/fighter_component_test.dart`
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`
  - `test/mocks/domain/entities/hero/hero_entity_mock.dart`

**Interfaces:**
- Consumes: frames `wolf-*` / `bear-*` y `ArenaSpriteNames.attack` / `down` (TC4.1); `EnemyKind.wolf` / `bear`, `ArenaLevelId.wolfPack`, `FighterRenderDataMock.wolfIdle`, `HeroEntityMock.veteran` (TC4.2); `Easing.sineOut` / `sineInOut`.
- Produces:
  ```dart
  // ArenaRenderConstants
  static const List<int> wolfBiteSequence;    // [0, 1, 1, 2, 2, 3, 4, 0]
  static const List<int> bearSwipeSequence;   // [0, 1, 1, 2, 2, 2, 1, 0]
  static List<int>? leapSequence(EnemyKind? kind);   // null = golpea con el hacha
  static const double leapOutShare = 0.4, leapBackShare = 0.6, leapGap = 30, leapHeight = 10, beastShadowWidth = 44;

  // ArenaFrames
  static FightSide opposite(FightSide side);
  static bool isBeast(EnemyKind? kind);
  static int sequenceColumn(List<int> sequence, double progress);
  static bool isLeaping(FighterRenderData fighter);
  static double leapReach(double progress);   // 0 → 1 (ida), 1 (mordisco), 1 → 0 (vuelta)
  static double leapLift(double progress);    // arco de 0 a leapHeight en la ida y en la vuelta
  static PositionEntity groundSpot(FighterRenderData fighter);   // donde pisa (sombra)
  static double lift(FighterRenderData fighter);                 // cuánto sube el sprite

  // FighterRenderData
  final int targetIndex;   // = 0; el BLoC lo rellena en la pose attack

  // FighterComponent
  static double shadowWidthOf(EnemyKind? kind);
  bool get tipsOver;       // caído y persona: gira 90°; los animales no
  ```

- [ ] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-c4-beasts && git switch -c feature/PROJECT-X-c4-leap
```

- [ ] **Step 2: Mocks**

Al final de `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`:

```dart
  static FighterRenderData wolfLeaping(double swingProgress) => FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 19,
    maxHealth: 22,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
  );

  static FighterRenderData bearLeaping(double swingProgress) => FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bear,
    health: 40,
    maxHealth: 40,
    pose: FighterPose.attack,
    swingProgress: swingProgress,
  );

  static const FighterRenderData wolfDown = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.wolf,
    health: 0,
    maxHealth: 22,
    pose: FighterPose.down,
  );
}
```

Al final de `test/mocks/domain/entities/hero/hero_entity_mock.dart` (héroe con el mejor equipo que ya puede pelear contra la manada):

```dart
  static const HeroEntity packHunter = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    clearedLevels: {ArenaLevelId.barbarian},
  );
}
```

- [ ] **Step 3: Tests que fallan**

`test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`:
- import nuevo:

```dart
import 'package:rpg/layers/presentation/features/arena/game/render/arena_render_constants.dart';
```

- el primer test, con los nombres definitivos:

```dart
  test('testWhenNamingFightersThenTheChiefBorrowsTheBarbarianArtAndTheBeastsHaveTheirOwn', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final names = [ArenaSpriteNames.fighter(null), for (final kind in kinds) ArenaSpriteNames.fighter(kind)];

    // then
    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian', 'wolf', 'bear']);
    expect(ArenaSpriteNames.idle('bandit', 1), 'bandit-idle-1');
    expect(ArenaSpriteNames.slash('hero', 5), 'hero-slash-5');
  });
```

- `testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists` pide a cada tipo los frames que usa su ataque:

```dart
  test('testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists', () {
    // given
    final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
    const kinds = <EnemyKind?>[null, ...EnemyKind.values];

    // when
    final wanted = [
      ArenaSpriteNames.grass,
      ArenaSpriteNames.fence,
      for (final kind in kinds) ...[
        for (var column = 0; column < RenderConstants.idleColumns; column++)
          ArenaSpriteNames.idle(ArenaSpriteNames.fighter(kind), column),
        ...switch (ArenaRenderConstants.leapSequence(kind)) {
          null => [
            for (var column = 0; column < RenderConstants.workColumns; column++)
              ArenaSpriteNames.slash(ArenaSpriteNames.fighter(kind), column),
          ],
          final sequence => [
            for (final column in sequence.toSet()) ArenaSpriteNames.attack(ArenaSpriteNames.fighter(kind), column),
            ArenaSpriteNames.down(ArenaSpriteNames.fighter(kind)),
          ],
        },
      ],
    ];

    // then
    expect(wanted.where((name) => !frames.contains(name)), isEmpty);
  });
```

`test/layers/presentation/features/arena/game/atlas/arena_assets_test.dart`, en `testWhenAskingForAnUnknownFrameThenThrows` (`wolf-idle-0` ya existe en el mock):

```dart
    void lookUp() => assets.frame('dragon-idle-0');
```

`test/layers/presentation/features/arena/game/render/arena_frames_test.dart`: imports y cuatro tests al final.

```dart
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_frames.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_render_constants.dart';

import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';
```

```dart
  test('testWhenABeastAttacksThenTheAttackFrameFollowsItsSequenceWithTheWidestBiteOnImpact', () {
    // given
    final wolfStart = FighterRenderDataMock.wolfLeaping(0);
    final wolfImpact = FighterRenderDataMock.wolfLeaping(0.5);
    final bearImpact = FighterRenderDataMock.bearLeaping(0.5);

    // when
    final names = [
      ArenaFrames.frameName(wolfStart, 0),
      ArenaFrames.frameName(wolfImpact, 0),
      ArenaFrames.frameName(bearImpact, 0),
    ];

    // then
    expect(names, ['wolf-attack-0', 'wolf-attack-2', 'bear-attack-2']);
  });

  test('testWhenABeastIsDownThenItLiesOnItsOwnFrame', () {
    // given
    const down = FighterRenderDataMock.wolfDown;

    // when
    final name = ArenaFrames.frameName(down, 0.6);

    // then
    expect(name, 'wolf-down');
    expect((ArenaFrames.isBeast(EnemyKind.wolf), ArenaFrames.isBeast(EnemyKind.barbarian)), (true, false));
  });

  test('testWhenTheWolfLeapsThenItJumpsTowardsTheHeroStopsShortAndComesBack', () {
    // given
    final progresses = [0.0, 0.2, 0.5, 0.8, 0.999];

    // when
    final spots = [
      for (final progress in progresses) ArenaFrames.groundSpot(FighterRenderDataMock.wolfLeaping(progress)),
    ];
    final lifts = [for (final progress in progresses) ArenaFrames.lift(FighterRenderDataMock.wolfLeaping(progress))];

    // then
    expect(spots.map((spot) => spot.y), everyElement(170));
    expect(spots[0].x, 300);
    expect(spots[1].x, closeTo(300 - 80 * math.sqrt(0.5), 1e-9));
    expect(spots[2].x, 190 + ArenaRenderConstants.leapGap);
    expect(spots[3].x, closeTo(260, 1e-9));
    expect(spots[4].x, closeTo(300, 0.01));
    expect(lifts[0], 0);
    expect(lifts[1], closeTo(ArenaRenderConstants.leapHeight, 1e-9));
    expect(lifts[2], 0);
    expect(lifts[3], closeTo(ArenaRenderConstants.leapHeight, 1e-9));
  });

  test('testWhenAPersonSwingsThenItStaysOnItsSpot', () {
    // given
    final swinging = FighterRenderDataMock.heroSwinging(0.3);

    // when
    final spot = ArenaFrames.groundSpot(swinging);
    final lift = ArenaFrames.lift(swinging);

    // then
    expect((spot, lift), (const PositionEntity(x: 190, y: 170), 0.0));
  });
```

(Cuentas del tercer test: del lobo (300, 170) al héroe (190, 170) hay 110 px; se para a 30, así que recorre 80. Al 20 % del turno lleva `sineOut(0,5)` = √0,5 de la ida y está en lo alto del arco; al 50 % está en x = 220; al 80 % lleva medio regreso (`sineInOut(0,5)` = 0,5): x = 260, otra vez en lo alto.)

Al final de `test/layers/presentation/features/arena/game/components/fighter_component_test.dart`:

```dart
  testWithFlameGame('testWhenTheWolfLeapsThenItsShadowAndBarFollowAndItLandsBackOnItsSpot', (game) async {
    // given
    final wolf = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.wolfIdle);
    await game.ensureAdd(wolf);

    // when
    wolf.show(FighterRenderDataMock.wolfLeaping(0.5));
    final atTheHero = (wolf.position.clone(), wolf.shadow.position.clone(), wolf.healthBar.position.clone());
    wolf.show(FighterRenderDataMock.wolfLeaping(0.2));
    final inTheAir = wolf.position.y - wolf.shadow.position.y;
    wolf.show(FighterRenderDataMock.wolfIdle);

    // then
    expect(atTheHero, (Vector2(220, 170), Vector2(220, 170), Vector2(220, 118)));
    expect(inTheAir, closeTo(-10, 1e-9));
    expect((wolf.position, wolf.shadow.position), (Vector2(300, 170), Vector2(300, 170)));
    expect(wolf.shadow.size.x, 44);
    expect(wolf.frameName, startsWith('wolf-idle-'));
  });

  testWithFlameGame('testWhenTheWolfFallsThenItLiesOnItsOwnFrameInsteadOfTippingOver', (game) async {
    // given
    final wolf = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.wolfIdle);
    final bandit = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);
    await game.ensureAdd(wolf);
    await game.ensureAdd(bandit);

    // when
    wolf.show(FighterRenderDataMock.wolfDown);
    bandit.show(FighterRenderDataMock.rookieBanditDown);

    // then
    expect((wolf.frameName, wolf.tipsOver), ('wolf-down', false));
    expect((bandit.frameName, bandit.tipsOver), ('bandit-idle-0', true));
  });
```

`test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`, dos tests antes de `testWhenTheReplayEndsThenEveryTurnPlayedOnceAndTheVictoryIsShown`. Tiempos: `tickFor` avanza de 16 en 16 ms. En la pelea del héroe veterano contra el lobo (semilla 3) el segundo turno es el mordisco del lobo (empieza en 400 + 600 = 1000 ms); a 1248 ms lleva 248/600 del turno y el lobo tiene 19 de vida (el héroe ya le quitó 3). Con `packHunter` contra la manada (semilla 0), el turno 7 es el primer golpe del héroe al segundo lobo (el primero ya ha caído): empieza en 400 + 7 × 600 = 4600 ms y a 4848 ms el héroe está a mitad de golpe. Este segundo test es el que demuestra que el BLoC rellena `targetIndex` (en el primero vale 0, como por defecto).

```dart
  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheWolfStrikesThenItLeapsAtTheHero',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.veteran);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 1248);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.selected, ArenaLevelId.wolf);
      expect(bloc.state.data.fighters[1], FighterRenderDataMock.wolfLeaping(248 / 600));
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroStrikesTheSecondWolfOfThePackThenThatWolfIsItsTarget',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.packHunter);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.wolfPack))
        ..add(const ArenaFightRequested());
      ArenaBlocMock.tickFor(bloc, 4848);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hero = bloc.state.data.fighters.first;
      expect((hero.pose, hero.targetIndex), (FighterPose.attack, 1));
    },
  );
```

Run: `flutter test test/layers/presentation/features/arena`
Expected: FAIL de compilación (`The method 'leapSequence' isn't defined`, `The getter 'targetIndex' isn't defined`, `The getter 'tipsOver' isn't defined`…).

- [ ] **Step 4: Nombres definitivos y constantes del salto**

`lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`, los dos casos provisionales de TC4.2:

```dart
    EnemyKind.wolf => 'wolf',
    EnemyKind.bear => 'bear',
```

`lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`, justo después de `fighterScale`:

```dart
  static double fighterScale(EnemyKind? kind) => switch (kind) {
    null || EnemyKind.bandit || EnemyKind.barbarian => 1,
    EnemyKind.barbarianChief => chiefScale,
    EnemyKind.wolf || EnemyKind.bear => 1,
  };

  static const List<int> wolfBiteSequence = [0, 1, 1, 2, 2, 3, 4, 0];
  static const List<int> bearSwipeSequence = [0, 1, 1, 2, 2, 2, 1, 0];

  static List<int>? leapSequence(EnemyKind? kind) => switch (kind) {
    null || EnemyKind.bandit || EnemyKind.barbarian || EnemyKind.barbarianChief => null,
    EnemyKind.wolf => wolfBiteSequence,
    EnemyKind.bear => bearSwipeSequence,
  };

  static const double leapOutShare = 0.4;
  static const double leapBackShare = 0.6;
  static const double leapGap = 30;
  static const double leapHeight = 10;
  static const double beastShadowWidth = 44;
```

- [ ] **Step 5: El objetivo en `FighterRenderData` y en el BLoC**

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
  final int targetIndex;

  const FighterRenderData({
    required this.side,
    required this.index,
    required this.enemyKind,
    required this.health,
    required this.maxHealth,
    required this.pose,
    this.swingProgress = 0,
    this.targetIndex = 0,
  });

  static String keyOf(FightSide side, int index) => '${side.name}-$index';

  String get key => keyOf(side, index);

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
          other.swingProgress == swingProgress &&
          other.targetIndex == targetIndex;

  @override
  int get hashCode => Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress, targetIndex);
}
```

`lib/layers/presentation/features/arena/bloc/arena_bloc.dart`, al final de `_replayFighter`:

```dart
    return FighterRenderData(
      side: side,
      index: index,
      enemyKind: kind,
      health: health,
      maxHealth: replay.maxHealthOf(side, index),
      pose: pose,
      swingProgress: pose == FighterPose.attack ? progress : 0,
      targetIndex: pose == FighterPose.attack ? turn?.targetIndex ?? 0 : 0,
    );
```

- [ ] **Step 6: Frames y salto en `ArenaFrames`**

`lib/layers/presentation/features/arena/game/render/arena_frames.dart` completo:

```dart
import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../forest/game/render/easing.dart';
import '../../../forest/game/render/player_frames.dart';
import '../../models/fighter_render_data.dart';
import '../atlas/arena_sprite_names.dart';
import 'arena_render_constants.dart';

abstract final class ArenaFrames {
  static String frameName(FighterRenderData fighter, double animationSeconds) {
    final name = ArenaSpriteNames.fighter(fighter.enemyKind);
    final leap = ArenaRenderConstants.leapSequence(fighter.enemyKind);
    return switch (fighter.pose) {
      FighterPose.attack when leap != null => ArenaSpriteNames.attack(
        name,
        sequenceColumn(leap, fighter.swingProgress),
      ),
      FighterPose.attack => ArenaSpriteNames.slash(name, PlayerFrames.workColumn(WorkTool.axe, fighter.swingProgress)),
      FighterPose.idle || FighterPose.hurt => ArenaSpriteNames.idle(name, PlayerFrames.idleColumn(animationSeconds)),
      FighterPose.down when leap != null => ArenaSpriteNames.down(name),
      FighterPose.down => ArenaSpriteNames.idle(name, 0),
    };
  }

  static PositionEntity spot(FightSide side, int index) {
    return switch (side) {
      FightSide.hero => ArenaRenderConstants.heroSpot,
      FightSide.enemy => ArenaRenderConstants.enemySpots[index],
    };
  }

  static FightSide opposite(FightSide side) {
    return switch (side) {
      FightSide.hero => FightSide.enemy,
      FightSide.enemy => FightSide.hero,
    };
  }

  static bool isBeast(EnemyKind? kind) => ArenaRenderConstants.leapSequence(kind) != null;

  static int sequenceColumn(List<int> sequence, double progress) {
    final step = math.min(sequence.length - 1, (progress * sequence.length).floor());
    return sequence[math.max(0, step)];
  }

  static bool isLeaping(FighterRenderData fighter) => fighter.pose == FighterPose.attack && isBeast(fighter.enemyKind);

  static double leapReach(double progress) {
    const out = ArenaRenderConstants.leapOutShare;
    const back = ArenaRenderConstants.leapBackShare;
    if (progress <= 0) return 0;
    if (progress < out) return Easing.sineOut(progress / out);
    if (progress <= back) return 1;
    return 1 - Easing.sineInOut(math.min(1, (progress - back) / (1 - back)));
  }

  static double leapLift(double progress) {
    const out = ArenaRenderConstants.leapOutShare;
    const back = ArenaRenderConstants.leapBackShare;
    if (progress <= 0 || progress >= 1 || (progress >= out && progress <= back)) return 0;
    final hop = progress < out ? progress / out : (progress - back) / (1 - back);
    return ArenaRenderConstants.leapHeight * math.sin(math.pi * hop);
  }

  static PositionEntity groundSpot(FighterRenderData fighter) {
    final home = spot(fighter.side, fighter.index);
    if (!isLeaping(fighter)) return home;
    final target = spot(opposite(fighter.side), fighter.targetIndex);
    final dx = target.x - home.x;
    final dy = target.y - home.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= ArenaRenderConstants.leapGap) return home;
    final travel = (distance - ArenaRenderConstants.leapGap) / distance * leapReach(fighter.swingProgress);
    return PositionEntity(x: home.x + dx * travel, y: home.y + dy * travel);
  }

  static double lift(FighterRenderData fighter) => isLeaping(fighter) ? leapLift(fighter.swingProgress) : 0;
}
```

(No se usa `distanceTo` de `domain/world/extensions/`: fuera de `domain/world/` no se importan sus internos, `architecture_test.dart`.)

- [ ] **Step 7: `FighterComponent` sigue el salto**

`lib/layers/presentation/features/arena/game/components/fighter_component.dart` completo:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/enemy_kind.dart';
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
        size:
            Vector2(shadowWidthOf(fighter.enemyKind), shadowHeight) *
            ArenaRenderConstants.fighterScale(fighter.enemyKind),
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
    _place();
  }

  static double shadowWidthOf(EnemyKind? kind) =>
      ArenaFrames.isBeast(kind) ? ArenaRenderConstants.beastShadowWidth : shadowWidth;

  FighterRenderData get fighter => _fighter;

  String get frameName => ArenaFrames.frameName(_fighter, _animationSeconds);

  bool get tipsOver => _fighter.pose == FighterPose.down && !ArenaFrames.isBeast(_fighter.enemyKind);

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
    _place();
  }

  void hit() {
    _blinkMs = ArenaRenderConstants.hurtBlinkMs;
  }

  void _place() {
    final ground = ArenaFrames.groundSpot(_fighter);
    final lift = ArenaFrames.lift(_fighter);
    shadow.position.setValues(ground.x, ground.y);
    position.setValues(ground.x, ground.y - lift);
    healthBar.position.setValues(ground.x, ground.y - lift - ArenaRenderConstants.healthBarLift * scale.y);
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
    if (tipsOver) canvas.rotate((_fighter.side == FightSide.hero ? -1 : 1) * math.pi / 2);
    sprite.render(
      canvas,
      position: Vector2(-frame.width * frame.pivotX, -frame.height * frame.pivotY),
      overridePaint: _paint,
    );
    canvas.restore();
  }
}
```

`ArenaSceneComponent` no cambia: ya llama a `show` en cada estado, y el BLoC emite uno por fotograma durante la reproducción.

Run: `flutter test test/layers/presentation/features/arena`
Expected: PASS (todos los de la arena; 8 nuevos en esta tarea).

- [ ] **Step 8: `CLAUDE.md`**

En *Key cross-cutting conventions*, al final de la línea **Rendering constants**, la frase de la arena queda así, y justo debajo va la receta nueva:

```markdown
hero facing right, enemies facing left; the barbarian chief is the barbarian drawn ×1.25 until C6; wolves and bears (`ArenaRenderConstants.leapSequence`, an exhaustive `switch` on `EnemyKind`) bite or swipe with their own `attack-*` frames while `ArenaFrames.groundSpot` / `lift` make them leap at their target (`FighterRenderData.targetIndex`) during the first 40 % of the turn, stopping 30 px short, and back after 60 %, and they lie on their own `down` frame instead of tipping over).
- **New enemy kind:** the `EnemyKind` value (appended at the end) + its cases in `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale` and `leapSequence`, `Internationalize.arenaEnemy` and `es.json`, and its frames in `arena.png` (`build_assets.py`, credited in `CREDITS.md`); `arena_sprite_names_test.dart` and `internationalize_test.dart` fail if any piece is missing.
```

- [ ] **Step 9: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/arena test/layers/presentation/features/arena test/mocks/presentation/features/arena test/mocks/domain/entities/hero
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida, `No issues found!`, **567 tests** en verde y los 40 de Chrome en verde.

- [ ] **Step 10: Commit y unión a la rama de fase**

```bash
git add lib/layers/presentation/features/arena test/layers/presentation/features/arena test/mocks/presentation/features/arena/fighter_render_data_mock.dart test/mocks/domain/entities/hero/hero_entity_mock.dart
git add CLAUDE.md
git commit -m "[PROJECT-X]: Make the arena beasts leap at their target"
git switch feature/PROJECT-X-c4-beasts && git merge --no-ff feature/PROJECT-X-c4-leap
```

---

## Prueba manual

En las tres plataformas, en horizontal. La partida es nueva (sin guardado hasta F2).

**Chrome** (`flutter run -d chrome`):
1. En la arena, la lista tiene diez niveles en este orden: Bandido novato, **Lobo**, Bandido veterano, **Pareja de lobos**, **Oso**, Trío de bandidos, Bárbaro, **Manada de lobos**, Pareja de bárbaros, Jefe bárbaro. "Lobo" dice "Poder 30" (verde) y "+15 de oro", con candado.
2. Gana al bandido novato: el lobo pierde el candado y la selección no cambia (sigue en el novato). Elige "Lobo": a la derecha aparece un lobo marrón mirando al héroe, con su sombra alargada y su barra.
3. *Empezar pelea*: en cada turno del lobo, salta hacia el héroe (un pequeño arco), abre la boca al llegar, salen "−N" y la sangre sobre el héroe, y vuelve de otro salto a su sitio. El héroe sigue golpeando con el hacha desde el suyo. Al caer, el lobo queda tumbado de lado (no girado) y semitransparente.
4. Con el héroe base la pelea contra el lobo es ajustada (puede ganar o perder por poco según la semilla). Si pierde, *Reintentar*.
5. Con oro de sobra (o equipo comprado en la Herrería y la Armería), avanza hasta la pareja de lobos y el oso: los dos lobos de la pareja saltan cada uno desde su sitio (el de arriba en diagonal); el oso da un zarpazo y cae tumbado sobre su frame.
6. En la manada (tras el bárbaro), los tres lobos quedan bien colocados: ninguno tapa la barra de otro ni queda debajo de la lista de niveles. Apunta si la barra de vida de los lobos se ve demasiado alta sobre su lomo (decisión 5).
7. *Saltar* en mitad de un salto: el lobo vuelve a su sitio al momento.
8. Redimensiona la ventana: los saltos no se salen de la hierba.

**Android** (`flutter run -d emulator-5554`): lo mismo; en un móvil de 844 × 390, la manada y el panel de derrota no se tapan (ARENA-FIXES §6).

**iOS** (`flutter run -d "iPhone 17"`): lo mismo.

## Al cerrar C4

- Marca los checkboxes de las tres tareas. **Este plan no hace push ni abre PR**: la PR de `feature/PROJECT-X-c4-beasts` a `feature/PROJECT-X-arena` la abre `/cerrar-tarea` cuando la prueba manual de las tres plataformas esté hecha. Tras la unión, la batería de cierre en la rama de integración (README 3.0).
- Apunta en la sección 5 del README de la arena (C4):
  - arte: lobo de "[LPC] Wolf Animation" (Redshrike, William.Thompsonj; OGA-BY 3.0 y otras) y oso grizzly de "[LPC] bears, deer, lions and more" (tapatilorenzo; **CC-BY 4.0**, CC0 por el autor): no hizo falta el plan B del oso. Si se acepta CC-BY 4.0, añádelo a la lista de licencias de las *Global Constraints*;
  - reposo de los animales = dos pasos de andar; oso sin escalar; sombra de 44 px; barra de vida a la misma altura que en las personas;
  - `ArenaRules.isUnlocked` abre también los niveles ya ganados;
  - `FighterRenderData` lleva `targetIndex`;
  - si TC4.1 y TC4.2 se hicieron a la vez (ramas y uniones), como en C1–C3, y si hubo conflictos.
- Revisa con el usuario las decisiones provisionales (licencia del oso, reposo, tamaños y altura de la barra) y apunta en ARENA-FIXES las que queden para el pulido.
- Avisa a quien lleve:
  - **C6:** las posiciones de grupo (`enemySpots`) también las usan la pareja y la manada de lobos; si cambian, los lobos de arriba y abajo saltan en otra diagonal (los tests usan sólo el lobo 0). Para el jefe y los bárbaros nuevos, sigue la receta **New enemy kind** de `CLAUDE.md`.
  - **C7:** los niveles nuevos son el 2, 4, 5 y 8 de la lista. Si cambian los números de `wolf`, revisa `ArenaLevelItemDataMock.wolfLocked` / `wolfOpen` (Poder 30, 15 de oro), `FighterRenderDataMock.wolfIdle` / `wolfLeaping` (vida 22 / 19) y los tiempos de `testWhenTheWolfStrikesThenItLeapsAtTheHero` y `testWhenTheHeroStrikesTheSecondWolfOfThePackThenThatWolfIsItsTarget` (dependen del orden de los turnos).
  - **Pulido (ARENA-FIXES §3):** `ArenaFrames.groundSpot` / `lift` y `FighterRenderData.targetIndex` ya llevan a un luchador hasta su objetivo; para que las personas también se acerquen basta con que `isLeaping` (o una variante) acepte la pose `attack` de cualquiera y con elegir sus frames de andar.
  - **C5 (a la vez):** ficheros calientes compartidos en *Reparto*; los atlas nunca se resuelven a mano.
- Si alguna firma de *Interfaces* cambió al implementar, actualízala aquí **y** en las fichas de C6 y C7, y apúntalo en la sección 5 del README.

## Preguntas abiertas (decisiones provisionales)

1. **Licencia del oso:** CC-BY 4.0 (CC0 según el autor) no está en la lista de las *Global Constraints*. ¿Se acepta (y se amplía la lista) o se usa el plan B (lobo recoloreado ×1,5)?
2. **Reposo de los animales:** los dos primeros pasos de andar a 2 fps. ¿Se prefiere un único frame quieto?
3. **Tamaño del oso:** sin escalar (ya es tan alto como el héroe y más ancho). ¿Más grande (×1,25 como el jefe)?
4. **Barra de vida y sangre de los animales:** a la misma altura que en las personas (52 y 28 px); sobre el lobo la barra queda alta. ¿Se ajusta por tipo en el pulido?
