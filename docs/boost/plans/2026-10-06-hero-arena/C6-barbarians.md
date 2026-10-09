# C6 · Bárbaros y jefe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C4 (ya en `feature/PROJECT-X-arena`, con C0–C3 y C5) |
| **Issue / milestone** | `phase:C6` · `stream:C` · milestone `C6 Barbarians` (un issue por tarea: TC6.1 … TC6.4) |

**Goal:** Cerrar la arena con un final que se note: bárbaros con aspecto propio (armadura de cuero, barba y casco), un jefe distinto y más grande, un anillo bajo el enemigo al que apunta el héroe y, al ganar al jefe por primera vez, el título de *Campeón de la arena* con confeti y una insignia en el panel *Héroe*.

**Architecture:**
- **Arte:** seis capas nuevas del *Universal LPC Spritesheet Character Generator* en `asset-packs/lpc/sources/barbarians/` (pantalón corto, armadura de cuero, brazales, barba larga, casco bárbaro y casco vikingo; sólo `idle` y `slash`). `build_assets.py` compone cada luchador de la arena con su propia lista de capas (`ARENA_FIGHTERS` gana `layers`); el bárbaro y el jefe (`barbarian-chief-*`) salen de capas reales en vez de recolorear al bandido. El arma sigue siendo el hacha de siempre. Sólo cambia `arena.{png,json}`.
- **Dominio:** `FightPlayedEntity.isFirstChampionship` (por defecto `false`) lo calcula `StartFightUseCase` cuando el héroe gana `ArenaLevels.championship` (el jefe bárbaro) sin haberlo ganado antes. `ArenaRules.isChampion` dice si el héroe ya lo ha ganado y `HeroStatusEntity.isChampion` lo lleva al bosque. No hay estado nuevo en `HeroEntity` (sale de `clearedLevels`), así que F2 no tiene que guardar nada más.
- **Presentación:** `FighterRenderData.isTargeted` marca al primer enemigo en pie (al que apunta el héroe, igual que `Combat`); `FighterComponent` lleva un `TargetRingComponent` bajo los pies. Los caídos se dibujan al 50 %. Una primera victoria sobre el jefe añade un `ChampionEffect` (confeti con `ParticleBursts.confetti`, partículas `sparkle` y `magicSparkle` que caen) y el resultado se titula *¡Campeón de la arena!*. `HeroPanelData.isChampion` pinta la insignia *Campeón de la arena* junto al título del panel *Héroe*.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame, `easy_localization`; tests con `flutter_test`, `bloc_test`, `mockito`, `flame_test`. Arte con `asset-packs/lpc/build_assets.py` (Pillow).

**Precondición: C4 y C5 fusionadas en `feature/PROJECT-X-arena`** (commit `20c0a29` o posterior). Este plan usa exactamente estas firmas. Antes de empezar, comprueba que no han cambiado:
- `enum EnemyKind { bandit, barbarian, barbarianChief, wolf, bear }`; `ArenaLevelId.barbarianChief`; `ArenaLevels.all` (10 niveles, el jefe el último) y `ArenaLevels.byId`;
- `extension ArenaRules on HeroEntity { bool isUnlocked(ArenaLevelEntity); bool hasCleared(ArenaLevelId); Map<Resource, int> rewardFor(ArenaLevelEntity); HeroEntity afterFight(FightLogEntity); }`;
- `FightPlayedEntity({required FightLogEntity log, FightAdvice? advice})`; `HeroStatusEntity({required hero, required stats, required power})`; `GetHeroStatusUseCase`;
- `ArenaSpriteNames.enemy(EnemyKind)` (el jefe devuelve `'barbarian'`); `ArenaRenderConstants.fighterScale`, `chiefScale = 1.25`, `fallenAlpha = 0.8`, `enemySpots`;
- `FighterRenderData(side, index, enemyKind, health, maxHealth, pose, swingProgress = 0, targetIndex = 0)`; `FighterComponent` con `shadow`, `healthBar`, `shadowWidthOf`, `shadowHeight = 7`, `_place()`;
- `ArenaBloc._previewFighters`, `_replayFighters`, `_replayFighter`, `_emitReplay`, `_result`; `ArenaBlocMock.make` / `tickFor` / `collectEffects`;
- `ParticleBursts.sparkles` / `bloodDrops`, `ParticleKind { woodChip, dust, sparkle, bloodDrop, magicSparkle }`, `ParticleBurstComponent(particles:, sortY:)`;
- `HeroPanelData(power, attack, defense, health, rows, skills = const [])`; `HeroPanel._title()`; `ForestBloc._heroPanel` (construye `HeroPanelData` desde `GetHeroStatusUseCase`);
- `build_assets.py` con `CHARACTER_LAYERS` (nombres sueltos), `body_sheet(animation, recolours)`, `BARBARIAN_RECOLOURS`, `ARENA_FIGHTERS` (`(recolours, row)`), `build_arena`;
- mocks `HeroEntityMock.mock` / `packHunter`, `HeroStatusEntityMock.base` / `withTwoSkills`, `FighterRenderDataMock`, `ArenaDataMock`, `ArenaEffectMock`, `ArenaResultDataMock`, `HeroPanelDataMock`, `ParticleMock`, `GearScenarioMock.withoutWorkshops(hero:)`.

Si algo ha cambiado, adapta los fragmentos de este plan y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- `flutter test` en verde (18 tests nuevos: 0 de TC6.1, 6 de TC6.2, 4 de TC6.3 y 8 de TC6.4; TC6.1 cambia 3 tests existentes).
- La prueba manual de la sección *Prueba manual* en Chrome, el emulador Android y el simulador iOS, en horizontal.

**Cómo se ha comprobado este plan (2026-10-09):** en un worktree desechable sobre `feature/PROJECT-C6-barbarians` (`20c0a29`, igual que `feature/PROJECT-X-arena`):
- se descargaron las doce hojas con los comandos de TC6.1 (los sha256 coinciden) y se aplicaron **todos** los fragmentos de las cuatro tareas, una detrás de otra, con un commit por tarea;
- `python3 build_assets.py`: sólo cambian `arena.png` y `arena.json` (frames nuevos `barbarian-chief-idle-{0,1}` y `barbarian-chief-slash-{0..5}`; los `barbarian-*` cambian de dibujo); `forest.*`, `ground.png` y `hero-*.png` salen idénticos. Se miró el atlas: bárbaro con casco redondo, barba pelirroja, cuero y pantalón marrón; jefe con casco vikingo, barba negra y pantalón rojo;
- `flutter analyze` → `No issues found!` y `flutter test` en verde tras cada tarea: **612** (TC6.1, igual que antes), **618** (TC6.2), **622** (TC6.3) y **630** (TC6.4);
- en el ensayo, la documentación de dominio de `CLAUDE.md` se escribió en TC6.4; aquí está en TC6.2, que es donde va. Es texto, no cambia ningún test;
- los fragmentos de este documento son esos ficheros, ya pasados por `dart format --line-length 120`. **Ojo:** `dart format` sobre una carpeta entera de `test/` reformatea también los `*.mocks.dart`; formatea sólo los ficheros que escribes.

## Decisiones del plan

Lo que este plan fija o añade sobre la ficha (todo lo demás de la ficha se mantiene):

1. **Arte (elegido por el usuario el 2026-10-09 sobre una vista previa):**

   | Capa | Fichero en `sources/barbarians/` (`__idle` y `__slash`) | Ruta en el generador | Autores | Licencias |
   |---|---|---|---|---|
   | Pantalón corto | `legs_shorts_male` | `legs/shorts/shorts/male` | JaidynReiman, ElizaWy, bluecarrot16, Johannes Sjölund (wulax), Stephen Challener (Redshrike) | OGA-BY 3.0, GPL 3.0 |
   | Armadura de cuero | `torso_armour_leather_male` | `torso/armour/leather/male` | Johannes Sjölund (wulax), bluecarrot16, JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | Brazales | `arms_bracers_male` | `arms/bracers/male` | Matthew Krohn (makrohn), Johannes Sjölund (wulax), JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | Barba larga (*winter*) | `beards_beard_winter_male` | `beards/beard/winter/male` | bluecarrot16 | CC0 |
   | Casco bárbaro | `hat_helmet_barbarian_adult` | `hat/helmet/barbarian/adult` | bluecarrot16, JaidynReiman, Napsio (Vitruvian Studio) | CC-BY 3.0, CC-BY 4.0, OGA-BY 3.0, GPL 2.0, GPL 3.0 |
   | Casco vikingo (jefe) | `hat_helmet_barbarian_viking_adult` | `hat/helmet/barbarian_viking/adult` | los mismos | los mismos |

   - Se descargan del repositorio del generador fijado al commit `58ce1aa479e4df32845a73a5d0afc221c3a893c2` (`spritesheets/<ruta>/{idle,slash}.png`) y se comprueba el sha256 (TC6.1, Step 2). Todas tienen alguna licencia de las admitidas.
   - **Bárbaro:** cuerpo, cabeza y botas del héroe con la piel morena de siempre (`BARBARIAN_SKIN`), pantalón corto recoloreado en marrón (es la rampa neutra `CLOTH_RAMP`), cuero, brazales, barba pelirroja y casco bárbaro. Sin pelo: lo tapa el casco.
   - **Jefe:** lo mismo con el casco vikingo, la barba recoloreada en negro (la barba usa `HAIR_RAMP`) y el pantalón rojo oscuro. Se sigue dibujando ×1,25 (`chiefScale`). Frames propios `barbarian-chief-*`, así que `ArenaSpriteNames.enemy(barbarianChief)` pasa a `'barbarian-chief'`.
   - **Arma: el hacha de siempre** (desviación de la ficha, que pedía "hacha grande o maza"). Las hachas de guerra y mazas de LPC sólo existen en hojas de 192 px (`slash_oversize`) sin animación de reposo; meterlas exige otro flujo de frames y pivotes en `build_assets.py`. Se deja para el pulido (ARENA-FIXES §1.3, junto con las espadas).
   - La hombrera (`bauldron`) se descartó: de perfil no se ve.
2. **Formación de grupos:** ya está desde C2 (`enemySpots`: el primero delante en (300, 170); el segundo y el tercero detrás, en (340, 140) y (340, 200)) con profundidad por la `y` de los pies. No cambia.
3. **Anillo del objetivo:**
   - El héroe siempre golpea al primer enemigo con vida (`Combat._heroStrikes`). El BLoC marca ese mismo enemigo con `FighterRenderData.isTargeted`: en la vista previa, el enemigo 0; en la reproducción, el primero con `healthOf(enemy, i) > 0` (`_heroTarget`). Si no queda ninguno, nadie.
   - `TargetRingComponent`: un óvalo de 1 px (`targetRingStroke`) en `CustomColors.hudAccent`, con la prioridad de la sombra, 8 px más ancho y 4 px más alto que la sombra (`targetRingPadding`), por la escala del luchador. Con el bandido: 30 × 11 en (300, 170). Sigue al luchador cuando salta (`_place`). No se pinta si el luchador está caído.
4. **Caídos:** `fallenAlpha` baja de 0,8 a 0,5 (la ficha pedía "atenuados"). Sin charcos ni restos: sólo las gotas de cada golpe (C2).
5. **Campeón (dominio):**
   - `ArenaLevels.championship = ArenaLevelId.barbarianChief`. El jefe es el final de la arena aunque se inserten niveles detrás.
   - `StartFightUseCase`: `isFirstChampionship = log.isVictory && level.id == ArenaLevels.championship && !hero.isChampion`, con el héroe **de antes** de la pelea.
   - `ArenaRules.isChampion` = `hasCleared(ArenaLevels.championship)`; `HeroStatusEntity.isChampion` (obligatorio) lo rellena `GetHeroStatusUseCase`.
   - Mocks: `HeroEntityMock.chiefChallenger` (equipo de nivel 3, las tres habilidades, ha ganado `barbarianPair`, `fightsFought: 9`) gana al jefe con esa semilla; `newChampion` es cómo queda; `champion` (ya ganó al jefe, `fightsFought: 12`) le vuelve a ganar. Comprobado en el ensayo.
6. **Campeón (pantalla):**
   - `ChampionEffect` (sin campos) va **después** de `FightEndedEffect`, en el mismo estado, tanto al terminar la reproducción como al saltarla.
   - La escena lo pinta con `ParticleBursts.confetti(at: hero.headPoint)`: 24 piezas, alternando `sparkle` (dorado) y `magicSparkle` (azul), salen hacia arriba entre 220° y 320° a 60–120 px/s, caen con gravedad 140 y duran 1,2 s. Sin `ParticleKind` nuevo (la ficha pedía usar las partículas existentes).
   - El panel de resultado no cambia de widget: su título pasa a *¡Campeón de la arena!* y el detalle sigue siendo la recompensa (100 de oro). Repetir la victoria da *¡Victoria!* y un tercio del oro (33).
   - Panel *Héroe*: insignia *Campeón de la arena* (texto `hudAccent` sobre `hudAccentSoft` con borde) a la derecha del título, si `HeroPanelData.isChampion`.
7. **Estadísticas de los bárbaros:** no cambian (las equilibra C7).
8. **Textos** (`es.json`): `arena.champion` "¡Campeón de la arena!" y `forest.hero.champion` "Campeón de la arena".
9. **Persistencia (cruce con F2, README 3.2):** nada nuevo que guardar; `isChampion` sale de `clearedLevels`, que F2 ya guarda.
10. **`CLAUDE.md`:** TC6.1 cambia la línea del jefe en *Rendering constants*; TC6.2 documenta el campeón en el dominio; TC6.3 el anillo y los caídos; TC6.4 el efecto, el confeti y la insignia.

## Reparto

| Tarea | Qué | Depende de | Paralelizable |
|---|---|---|---|
| TC6.1 Arte de los bárbaros | descarga en `sources/barbarians/`, `build_assets.py`, `arena.{png,json}`, `CREDITS.md`, `ArenaSpriteNames.enemy`, tests del atlas y del jefe, `CLAUDE.md` | C4 | **Sí, con TC6.2** |
| TC6.2 Campeón en el dominio | `FightPlayedEntity`, `ArenaLevels.championship`, `ArenaRules.isChampion`, `StartFightUseCase`, `HeroStatusEntity`, `GetHeroStatusUseCase`, mocks y tests, `CLAUDE.md` | C4 | **Sí, con TC6.1** |
| TC6.3 Anillo del objetivo y caídos | `FighterRenderData.isTargeted`, `TargetRingComponent`, `FighterComponent`, `ArenaSceneComponent`, `ArenaBloc`, `fallenAlpha`, mocks y tests, `CLAUDE.md` | TC6.1 (misma línea de `CLAUDE.md`) | No |
| TC6.4 Campeón en pantalla | `ChampionEffect`, `ParticleBursts.confetti`, escena, `ArenaBloc`, textos, `HeroPanelData` / `HeroPanel` / `ForestBloc`, mocks y tests, `CLAUDE.md` | TC6.2, TC6.3 | No |

**Ficheros compartidos entre TC6.1 y TC6.2:** sólo `CLAUDE.md`, en líneas distintas (TC6.1 la de *Rendering constants*; TC6.2 las de `entities/`, `world/` y `use-cases/`). Si hay conflicto, se quedan los dos cambios.

**Ramas (README, sección 3.0, y regla de nombres del 2026-10-09):**
- Rama de fase `feature/PROJECT-C6-barbarians`, desde `feature/PROJECT-X-arena`. Su PR va a `feature/PROJECT-X-arena`.
- TC6.1 y TC6.2, cada una en su propio worktree y su rama desde la de fase: `feature/PROJECT-C6-art` y `feature/PROJECT-C6-champion`. TC6.3 y TC6.4 directamente en la rama de fase. Al terminar una tarea con rama propia se une a la de fase con `git merge --no-ff`.
- Commits `[PROJECT-C6]: Imperative description`, sin atribución a IA; `CLAUDE.md` se añade al índice **en un comando aparte**.
- Al cerrar cada tarea, `docs/boost/plans/PROGRESS.md` se actualiza en la misma rama (`/cerrar-tarea`).

---

### Task TC6.1: Arte de los bárbaros

**Files:**
- Create (descargados): `asset-packs/lpc/sources/barbarians/{legs_shorts_male,torso_armour_leather_male,arms_bracers_male,beards_beard_winter_male,hat_helmet_barbarian_adult,hat_helmet_barbarian_viking_adult}__{idle,slash}.png`
- Create: `asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt`
- Modify:
  - `asset-packs/lpc/build_assets.py`
  - `lib/core/assets/images/lpc/arena.png`, `lib/core/assets/images/lpc/arena.json` (generados)
  - `lib/core/assets/images/lpc/CREDITS.md`
  - `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
  - `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`
  - `test/layers/presentation/features/arena/game/components/fighter_component_test.dart`
  - `test/layers/presentation/features/arena/game/render/arena_frames_test.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: `body_sheet`, `with_idle_axe`, `work_sheet`, `recolour`, `CLOTH_RAMP`, `HAIR_RAMP`, `SKIN_RAMP`, `BARBARIAN_SKIN`, `build_arena` (`build_assets.py`).
- Produces:
  - `body_sheet(animation, recolours=RECOLOURS, layers=CHARACTER_LAYERS)`, con `layers` como lista de `(carpeta en sources, capa)`;
  - frames `barbarian-idle-{0,1}`, `barbarian-slash-{0..5}` (dibujo nuevo) y `barbarian-chief-idle-{0,1}`, `barbarian-chief-slash-{0..5}` (nuevos) en `arena.json`;
  - `ArenaSpriteNames.enemy(EnemyKind.barbarianChief) == 'barbarian-chief'`.

- [ ] **Step 1: Ramas**

```bash
git switch feature/PROJECT-C6-barbarians && git pull
git worktree add ../phaser-example-c6-art -b feature/PROJECT-C6-art feature/PROJECT-C6-barbarians
cd ../phaser-example-c6-art && flutter pub get
```

(TC6.2 a la vez, en otro worktree: `git worktree add ../phaser-example-c6-champion -b feature/PROJECT-C6-champion feature/PROJECT-C6-barbarians`, y allí `flutter pub get`.)

- [ ] **Step 2: Descargar las capas y comprobarlas**

```bash
mkdir -p asset-packs/lpc/sources/barbarians && cd asset-packs/lpc/sources/barbarians
B=https://raw.githubusercontent.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator/58ce1aa479e4df32845a73a5d0afc221c3a893c2/spritesheets
for pair in "legs/shorts/shorts/male:legs_shorts_male" "torso/armour/leather/male:torso_armour_leather_male" \
  "arms/bracers/male:arms_bracers_male" "beards/beard/winter/male:beards_beard_winter_male" \
  "hat/helmet/barbarian/adult:hat_helmet_barbarian_adult" "hat/helmet/barbarian_viking/adult:hat_helmet_barbarian_viking_adult"; do
  for animation in idle slash; do curl -sfL "$B/${pair%%:*}/$animation.png" -o "${pair##*:}__$animation.png"; done
done
shasum -a 256 *.png
cd ../../../..
```

Expected (`idle` 128 × 256, `slash` 384 × 256):

```
32fd096cd6aebe0b45f561f49be826d602078a2837c1281060849cf13cd580a1  arms_bracers_male__idle.png
dcd1b8a5f4b432a495da72b635d342acb18eb9f7c99b747da3b890098ba4b7df  arms_bracers_male__slash.png
ac8dc654fda1d8a8b0f47070d2517d3d6c5fad0c082d43135898f88b707e6a24  beards_beard_winter_male__idle.png
c34c0afe4a32a9802e146790534188959bf0a618bc5fb51908e059b6f39123b3  beards_beard_winter_male__slash.png
69cfdae3cbc83b8b6a2dcf7726eb4e834616f5d25bc169a605f352780ccd6d8e  hat_helmet_barbarian_adult__idle.png
227345b7537228316ec78069202dbb43fc8ba373cf8e4eef6292c39fbea343f2  hat_helmet_barbarian_adult__slash.png
75f88a16328e68771344aea7571bcbfaaf5dc890f1a2d90e8733596843dfcd96  hat_helmet_barbarian_viking_adult__idle.png
3113c44ecbb3915638dfcc98940d170f0f108c536fe0d2417c916f91916e5e18  hat_helmet_barbarian_viking_adult__slash.png
3c9d546f1721797e996c3fb2eb0eef3c2cfd121ff1955c7c18d02ed7c88d7e18  legs_shorts_male__idle.png
75257b7b7a1bcb95df382cea9fa01962101545a5361f7f4173d56f4e3b591117  legs_shorts_male__slash.png
fc3c6c52ccaf07041d6b51dba201299b00996e87888f18a54ae6db372388c226  torso_armour_leather_male__idle.png
9a7d2d8daf8a0ef4a69c555327b84b64ddace6e37f4ba98bdeb4cd2ea024f2a0  torso_armour_leather_male__slash.png
```

Si un sha256 no coincide, para: el repositorio puede haber cambiado una capa. No se ejecuta nada de lo descargado.

- [ ] **Step 3: Créditos de las fuentes**

Crea `asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt`:

```text
Arena barbarians (used by build_assets.py -> arena.png)
=====================================================

Layers of the Universal LPC Spritesheet Character Generator, commit 58ce1aa479e4df32845a73a5d0afc221c3a893c2:
https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator
Each file is spritesheets/<path>/{idle,slash}.png, renamed to <name>__{idle,slash}.png.

legs_shorts_male            <- legs/shorts/shorts/male
  JaidynReiman, ElizaWy, bluecarrot16, Johannes Sjölund (wulax), Stephen Challener (Redshrike)
  OGA-BY 3.0, GPL 3.0
  https://opengameart.org/content/lpc-expanded-pants

torso_armour_leather_male   <- torso/armour/leather/male
  Johannes Sjölund (wulax), bluecarrot16, JaidynReiman
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  https://opengameart.org/content/lpc-expanded-armor

arms_bracers_male           <- arms/bracers/male
  Matthew Krohn (makrohn), Johannes Sjölund (wulax), JaidynReiman
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites

beards_beard_winter_male    <- beards/beard/winter/male
  bluecarrot16
  CC0
  https://opengameart.org/content/lpc-santa

hat_helmet_barbarian_adult  <- hat/helmet/barbarian/adult
hat_helmet_barbarian_viking_adult <- hat/helmet/barbarian_viking/adult
  bluecarrot16, JaidynReiman, Napsio (Vitruvian Studio)
  CC-BY 3.0, CC-BY 4.0, OGA-BY 3.0, GPL 2.0, GPL 3.0
  https://opengameart.org/content/lpc-helmets
  https://opengameart.org/content/lpc-expanded-hats-facial-helmets
```

- [ ] **Step 4: Tests que fallan**

En `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`, el primer test pasa a:

```dart
  test('testWhenNamingFightersThenEveryKindHasItsOwnArt', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final names = [ArenaSpriteNames.fighter(null), for (final kind in kinds) ArenaSpriteNames.fighter(kind)];

    // then
    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian-chief', 'wolf', 'bear']);
    expect(ArenaSpriteNames.idle('bandit', 1), 'bandit-idle-1');
    expect(ArenaSpriteNames.slash('hero', 5), 'hero-slash-5');
  });
```

(El segundo test de ese fichero, `testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists`, ya pide `barbarian-chief-idle-*` y `barbarian-chief-slash-*` en cuanto cambia el nombre: fallará hasta el Step 6.)

En `test/layers/presentation/features/arena/game/components/fighter_component_test.dart`:

```dart
  testWithFlameGame('testWhenTheChiefIsShownThenItUsesItsOwnArtBigger', (game) async {
    // given
    final chief = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.chiefIdle);

    // when
    await game.ensureAdd(chief);

    // then
    expect(chief.scale, Vector2.all(1.25));
    expect(chief.frameName, 'barbarian-chief-idle-0');
    expect(chief.healthBar.position, Vector2(300, 105));
  });
```

(sustituye a `testWhenTheChiefIsShownThenItIsTheBarbarianBigger`). En `test/layers/presentation/features/arena/game/render/arena_frames_test.dart`, en `testWhenAFighterIsIdleHurtOrDownThenTheIdleFramesAreUsed`, la última línea pasa a:

```dart
    expect(ArenaFrames.frameName(FighterRenderDataMock.chiefIdle, 0), 'barbarian-chief-idle-0');
```

Run: `flutter test test/layers/presentation/features/arena`
Expected: FAIL en los cuatro tests nombrados (el nombre del jefe sigue siendo `'barbarian'`).

- [ ] **Step 5: Nombre del jefe**

En `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`:

```dart
    EnemyKind.barbarianChief => 'barbarian-chief',
```

(antes `'barbarian'`). `ArenaAssetsMock` construye los frames de cada `EnemyKind` con `ArenaSpriteNames.enemy`, así que no cambia.

Run: `flutter test test/layers/presentation/features/arena`
Expected: sólo falla `testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists` (el atlas real aún no tiene los frames del jefe).

- [ ] **Step 6: Generar el atlas**

En `asset-packs/lpc/build_assets.py`:

1. En el docstring, la línea de `arena.png` pasa a:

```text
  arena.png + arena.json           JSON-hash atlas for the arena: hero, bandit, barbarian and barbarian chief idle
                                   (64px, axe in hand) and slash (128px) frames in their one facing (pivot = feet), the wolf
```

2. `CHARACTER_LAYERS` lleva la carpeta de cada capa:

```python
# (folder in sources, layer), bottom to top, same z-order as the Universal LPC generator (zPos).
CHARACTER_LAYERS = [
    ("character", "body_bodies_male"),
    ("character", "feet_boots_basic_male"),
    ("character", "legs_pants_male"),
    ("character", "torso_clothes_longsleeve_longsleeve_male"),
    ("character", "head_heads_human_male"),
    ("character", "hair_plain_adult"),
]
```

3. `body_sheet` recibe las capas:

```python
def body_sheet(animation: str, recolours: dict = RECOLOURS, layers: list = CHARACTER_LAYERS) -> Image.Image:
    sheet = None
    for folder, layer in layers:
        image = Image.open(SOURCES / folder / f"{layer}__{animation}.png").convert("RGBA")
        if layer in recolours:
            image = recolour(image, *recolours[layer])
        sheet = image if sheet is None else Image.alpha_composite(sheet, image)
    return sheet
```

4. En la sección de la arena, `BARBARIAN_RECOLOURS` y `ARENA_FIGHTERS` se sustituyen por:

```python
# Barbarians: leather armour, shorts, bracers, a long beard and a helmet instead of hair (sources/barbarians). The
# chief swaps the helmet for the viking one and wears a black beard and red shorts; the arena draws him x1.25.
BARBARIAN_LAYERS = [
    ("character", "body_bodies_male"),
    ("character", "feet_boots_basic_male"),
    ("barbarians", "legs_shorts_male"),
    ("barbarians", "torso_armour_leather_male"),
    ("barbarians", "arms_bracers_male"),
    ("character", "head_heads_human_male"),
    ("barbarians", "beards_beard_winter_male"),
    ("barbarians", "hat_helmet_barbarian_adult"),
]
CHIEF_LAYERS = [*BARBARIAN_LAYERS[:-1], ("barbarians", "hat_helmet_barbarian_viking_adult")]
BARBARIAN_RECOLOURS = {
    **RECOLOURS,
    "body_bodies_male": (SKIN_RAMP, BARBARIAN_SKIN),
    "head_heads_human_male": (SKIN_RAMP, BARBARIAN_SKIN),
    "legs_shorts_male": (CLOTH_RAMP, [(36, 26, 18), (58, 42, 28), (80, 58, 38), (104, 76, 50), (128, 96, 64)]),
}
CHIEF_RECOLOURS = {
    **BARBARIAN_RECOLOURS,
    "legs_shorts_male": (CLOTH_RAMP, [(48, 14, 16), (82, 22, 24), (112, 32, 30), (140, 46, 40), (168, 64, 54)]),
    "beards_beard_winter_male": (HAIR_RAMP, [(20, 16, 16), (32, 26, 24), (46, 38, 34), (60, 50, 44), (76, 64, 56)]),
}
# Fighter -> (recolours, LPC row, layers): the hero faces right (row 3), the enemies face left (row 1).
ARENA_FIGHTERS = {
    "hero": (RECOLOURS, 3, CHARACTER_LAYERS),
    "bandit": (BANDIT_RECOLOURS, 1, CHARACTER_LAYERS),
    "barbarian": (BARBARIAN_RECOLOURS, 1, BARBARIAN_LAYERS),
    "barbarian-chief": (CHIEF_RECOLOURS, 1, CHIEF_LAYERS),
}
```

5. En `build_arena`, el bucle de los luchadores empieza así:

```python
    for fighter, (recolours, row, layers) in ARENA_FIGHTERS.items():
        idle = with_idle_axe(body_sheet("idle", recolours, layers))
        slash = work_sheet(body_sheet("slash", recolours, layers), "axe")
```

Run:

```bash
cd asset-packs/lpc && python3 build_assets.py && cd ../.. && git status --short
```

Expected: `Assets written to …`; sólo cambian `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/arena.png` y `arena.json`, más la carpeta nueva `sources/barbarians/`. Abre `arena.png` y comprueba el bárbaro (casco redondo, barba pelirroja, cuero, pantalón marrón) y el jefe (casco vikingo, barba negra, pantalón rojo), los dos mirando a la izquierda con el hacha.

Run: `flutter test test/layers/presentation/features/arena`
Expected: PASS.

- [ ] **Step 7: Créditos y guía**

En `lib/core/assets/images/lpc/CREDITS.md`, sección *Arena*, el primer párrafo pasa a:

```markdown
Fighters composed by `build_assets.py` from the same character layers and axe as `hero-*.png`
(see *Character* above), each kept in one facing. The bandit is a recolour of those layers
(clothes and hair). Same authors and licences as the character layers. The barbarian and the
barbarian chief add their own layers (see *Barbarians* below).
```

y, justo antes de `### Wolf and bear …`, añade:

```markdown
### Barbarians (`barbarian-*`, `barbarian-chief-*` frames in `arena.png`)

The character body, head and boots (skin recoloured) with layers of the [Universal LPC Spritesheet
Character Generator](https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator)
in `asset-packs/lpc/sources/barbarians/` (see `CREDITS-barbarians.txt` there). The chief wears the
viking helmet, a recoloured black beard and red shorts.

| Layer | Authors | Licences |
|---|---|---|
| Shorts (recoloured) | JaidynReiman, ElizaWy, bluecarrot16, Johannes Sjölund (wulax), Stephen Challener (Redshrike) | OGA-BY 3.0, GPL 3.0 |
| Leather armour | Johannes Sjölund (wulax), bluecarrot16, JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Bracers | Matthew Krohn (makrohn), Johannes Sjölund (wulax), JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Winter beard | bluecarrot16 | CC0 |
| Barbarian and viking helmets | bluecarrot16, JaidynReiman, Napsio (Vitruvian Studio) | CC-BY 3.0, CC-BY 4.0, OGA-BY 3.0, GPL 2.0, GPL 3.0 |

Sources: <https://opengameart.org/content/lpc-expanded-pants>,
<https://opengameart.org/content/lpc-medieval-fantasy-character-sprites>,
<https://opengameart.org/content/lpc-expanded-armor>, <https://opengameart.org/content/lpc-santa>,
<https://opengameart.org/content/lpc-helmets>,
<https://opengameart.org/content/lpc-expanded-hats-facial-helmets>
```

En `CLAUDE.md`, *Rendering constants*, el trozo `the barbarian chief is the barbarian drawn ×1.25 until C6` pasa a:

```text
barbarians wear their own LPC layers (leather armour, beard, helmet) and the barbarian chief has his own frames (viking helmet, black beard) drawn ×1.25
```

- [ ] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart \
  test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart \
  test/layers/presentation/features/arena/game/components/fighter_component_test.dart \
  test/layers/presentation/features/arena/game/render/arena_frames_test.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart '*.mocks.dart'
flutter analyze
flutter test
```

Expected: `git diff` sin salida, `No issues found!` y **612 tests** en verde.

- [ ] **Step 9: Commit y unión a la rama de fase**

```bash
git add asset-packs/lpc lib/core/assets/images/lpc lib/layers/presentation/features/arena/game/atlas test/layers/presentation/features/arena
git add CLAUDE.md
git commit -m "[PROJECT-C6]: Dress the barbarians and their chief with their own LPC layers"
git switch feature/PROJECT-C6-barbarians && git merge --no-ff feature/PROJECT-C6-art -m "[PROJECT-C6]: Merge the barbarian art into the phase"
```

---

### Task TC6.2: Campeón en el dominio

**Files:**
- Modify:
  - `lib/layers/domain/entities/combat/fight_result_entity.dart`
  - `lib/layers/domain/rules/arena_levels.dart`
  - `lib/layers/domain/world/extensions/arena_rules.dart`
  - `lib/layers/domain/use-cases/arena/start_fight_use_case.dart`
  - `lib/layers/domain/entities/hero/hero_status_entity.dart`
  - `lib/layers/domain/use-cases/hero/get_hero_status_use_case.dart`
  - `test/mocks/domain/entities/hero/hero_entity_mock.dart`
  - `test/mocks/domain/entities/hero/hero_status_entity_mock.dart`
  - `test/mocks/domain/entities/combat/fight_result_entity_mock.dart`
  - `test/layers/domain/use-cases/arena/start_fight_use_case_test.dart`
  - `test/layers/domain/use-cases/hero/get_hero_status_use_case_test.dart`
  - `test/layers/domain/world/extensions/arena_rules_test.dart`
  - `test/layers/domain/entities/combat/fight_result_entity_test.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: `ArenaRules.hasCleared`, `HeroRules.stats` / `power`, `Combat.resolve` / `adviceFor`, `World.earn` / `updateHero`.
- Produces:
  ```dart
  // fight_result_entity.dart
  const FightPlayedEntity({required FightLogEntity log, FightAdvice? advice, bool isFirstChampionship = false});
  final bool isFirstChampionship;
  // arena_levels.dart
  static const ArenaLevelId championship = ArenaLevelId.barbarianChief;
  // arena_rules.dart (extension ArenaRules on HeroEntity)
  bool get isChampion;
  // hero_status_entity.dart
  const HeroStatusEntity({required hero, required stats, required power, required bool isChampion});
  ```
  - mocks `HeroEntityMock.chiefChallenger` / `newChampion` / `champion`, `HeroStatusEntityMock.champion`, `FightResultEntityMock.championshipOverBandit()`.

- [ ] **Step 1: Rama**

En el worktree de TC6.2 (`../phaser-example-c6-champion`, rama `feature/PROJECT-C6-champion`) o, si va después de TC6.1:

```bash
git switch feature/PROJECT-C6-barbarians && git switch -c feature/PROJECT-C6-champion
```

- [ ] **Step 2: Datos de prueba**

Al final de `HeroEntityMock` (`test/mocks/domain/entities/hero/hero_entity_mock.dart`):

```dart
  static const HeroEntity chiefChallenger = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skills: {SkillId.doubleStrike, SkillId.secondWind, SkillId.dodge},
    clearedLevels: {ArenaLevelId.barbarianPair},
    fightsFought: 9,
  );

  static const HeroEntity newChampion = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skills: {SkillId.doubleStrike, SkillId.secondWind, SkillId.dodge},
    clearedLevels: {ArenaLevelId.barbarianPair, ArenaLevelId.barbarianChief},
    fightsFought: 10,
  );

  static const HeroEntity champion = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skills: {SkillId.doubleStrike, SkillId.secondWind, SkillId.dodge},
    clearedLevels: {ArenaLevelId.barbarianPair, ArenaLevelId.barbarianChief},
    fightsFought: 12,
  );
```

`test/mocks/domain/entities/hero/hero_status_entity_mock.dart` queda:

```dart
import 'package:rpg/layers/domain/entities/hero/hero_status_entity.dart';

import 'combat_stats_entity_mock.dart';
import 'hero_entity_mock.dart';

abstract final class HeroStatusEntityMock {
  static const HeroStatusEntity base = HeroStatusEntity(
    hero: HeroEntityMock.mock,
    stats: CombatStatsEntityMock.heroBase,
    power: 31,
    isChampion: false,
  );

  static const HeroStatusEntity withTwoSkills = HeroStatusEntity(
    hero: HeroEntityMock.withTwoSkills,
    stats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
    power: 64,
    isChampion: false,
  );

  static const HeroStatusEntity champion = HeroStatusEntity(
    hero: HeroEntityMock.champion,
    stats: CombatStatsEntityMock.heroFullyGeared,
    power: 144,
    isChampion: true,
  );
}
```

(Poder 144 = (14 × 3 + 8 × 4 + 75 ~/ 2) × 1,3 redondeado.) En `FightResultEntityMock`, antes de `almostBeatDuelist`:

```dart
  static FightPlayedEntity championshipOverBandit() =>
      FightPlayedEntity(log: FightLogEntityMock.victoryOverBandit(), isFirstChampionship: true);
```

- [ ] **Step 3: Tests que fallan**

Al final de `test/layers/domain/use-cases/arena/start_fight_use_case_test.dart`:

```dart
  test('testWhenTheHeroBeatsTheChiefForTheFirstTimeThenTheFightCrownsAChampion', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.chiefChallenger));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.barbarianChief);

    // then
    final played = result as FightPlayedEntity;
    expect((played.log.isVictory, played.isFirstChampionship), (true, true));
    expect(session.world.hero, HeroEntityMock.newChampion);
  });

  test('testWhenAChampionBeatsTheChiefAgainThenTheFightIsNotAFirstChampionship', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.champion));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.barbarianChief);

    // then
    final played = result as FightPlayedEntity;
    expect((played.log.isVictory, played.isFirstChampionship), (true, false));
  });

  test('testWhenTheHeroWinsAnotherLevelForTheFirstTimeThenItIsNotAChampionship', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditRookie);

    // then
    expect((result as FightPlayedEntity).isFirstChampionship, false);
  });
```

Al final de `test/layers/domain/use-cases/hero/get_hero_status_use_case_test.dart`:

```dart
  test('testWhenTheHeroHasBeatenTheChiefThenStatusSaysItIsAChampion', () {
    // given
    when(sessionRepository.current())
        .thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.champion)));

    // when
    final status = sut();

    // then
    expect(status, HeroStatusEntityMock.champion);
  });
```

En `test/layers/domain/world/extensions/arena_rules_test.dart`, antes de `group('rewardFor', …)`:

```dart
  group('isChampion', () {
    test('testWhenTheHeroHasBeatenTheChiefThenItIsAChampion', () {
      // given
      const champion = HeroEntityMock.champion;
      const challenger = HeroEntityMock.chiefChallenger;

      // when
      final champions = (champion.isChampion, challenger.isChampion);

      // then
      expect(champions, (true, false));
      expect(ArenaLevels.all.map((level) => level.id), contains(ArenaLevels.championship));
    });
  });
```

En `test/layers/domain/entities/combat/fight_result_entity_test.dart`, antes de `testWhenComparingALockedFightWithAPlayedOneThenTheyAreNotEqual`:

```dart
  test('testWhenOnlyOneFightCrownsAChampionThenTheyAreNotEqual', () {
    // given
    final result = FightResultEntityMock.victoryOverBandit();

    // when
    final equal = result == FightResultEntityMock.championshipOverBandit();

    // then
    expect(equal, isFalse);
  });
```

Run: `flutter test test/layers/domain`
Expected: no compila (`isFirstChampionship`, `isChampion`, `ArenaLevels.championship` no existen).

- [ ] **Step 4: Implementación**

`FightPlayedEntity` (`lib/layers/domain/entities/combat/fight_result_entity.dart`):

```dart
final class FightPlayedEntity extends FightResultEntity {
  final FightLogEntity log;
  final FightAdvice? advice;
  final bool isFirstChampionship;

  const FightPlayedEntity({required this.log, this.advice, this.isFirstChampionship = false});

  @override
  bool operator ==(Object other) =>
      other is FightPlayedEntity &&
      other.log == log &&
      other.advice == advice &&
      other.isFirstChampionship == isFirstChampionship;

  @override
  int get hashCode => Object.hash(FightPlayedEntity, log, advice, isFirstChampionship);
}
```

`ArenaLevels` (`lib/layers/domain/rules/arena_levels.dart`), primera línea de la clase:

```dart
abstract final class ArenaLevels {
  static const ArenaLevelId championship = ArenaLevelId.barbarianChief;

  static const List<ArenaLevelEntity> all = [
```

`ArenaRules` (`lib/layers/domain/world/extensions/arena_rules.dart`), tras `hasCleared`:

```dart
  bool hasCleared(ArenaLevelId id) => clearedLevels.contains(id);

  bool get isChampion => hasCleared(ArenaLevels.championship);
```

`StartFightUseCase` (`lib/layers/domain/use-cases/arena/start_fight_use_case.dart`), el final de `call`:

```dart
    if (log.isVictory) world.earn(log.reward);
    world.updateHero((current) => current.afterFight(log));
    return FightPlayedEntity(
      log: log,
      advice: Combat.adviceFor(log),
      isFirstChampionship: log.isVictory && level.id == ArenaLevels.championship && !hero.isChampion,
    );
```

(`hero` es el de antes de la pelea, leído al principio de `call`.)

`HeroStatusEntity` (`lib/layers/domain/entities/hero/hero_status_entity.dart`):

```dart
class HeroStatusEntity {
  final HeroEntity hero;
  final CombatStatsEntity stats;
  final int power;
  final bool isChampion;

  const HeroStatusEntity({required this.hero, required this.stats, required this.power, required this.isChampion});

  HeroStatusEntity copyWith({HeroEntity? hero, CombatStatsEntity? stats, int? power, bool? isChampion}) {
    return HeroStatusEntity(
      hero: hero ?? this.hero,
      stats: stats ?? this.stats,
      power: power ?? this.power,
      isChampion: isChampion ?? this.isChampion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HeroStatusEntity &&
      other.hero == hero &&
      other.stats == stats &&
      other.power == power &&
      other.isChampion == isChampion;

  @override
  int get hashCode => Object.hash(hero, stats, power, isChampion);
}
```

`GetHeroStatusUseCase` (`lib/layers/domain/use-cases/hero/get_hero_status_use_case.dart`): importa `'../../world/extensions/arena_rules.dart'` y devuelve

```dart
    return HeroStatusEntity(hero: hero, stats: hero.stats, power: hero.power, isChampion: hero.isChampion);
```

Run: `flutter test test/layers/domain`
Expected: PASS.

- [ ] **Step 5: Guía**

En `CLAUDE.md`:
- en `entities/<feature>/`: `HeroStatusEntity` pasa a `HeroStatusEntity` with `isChampion`, y `FightPlayedEntity` with an optional `FightAdvice` pasa a `FightPlayedEntity` with an optional `FightAdvice` and `isFirstChampionship`;
- en `world/`, la lista de `ArenaRules` pasa a `` `ArenaRules`: `isUnlocked`, `hasCleared`, `isChampion` (the hero has beaten `ArenaLevels.championship`, the barbarian chief), `rewardFor`, `afterFight` ``;
- en `use-cases/`, el paréntesis de `StartFightUseCase` termina en `; isFirstChampionship when the hero beats the chief for the first time)`.

- [ ] **Step 6: Verificación completa**

```bash
dart format --line-length 120 lib/layers/domain/entities/combat/fight_result_entity.dart lib/layers/domain/rules/arena_levels.dart \
  lib/layers/domain/world/extensions/arena_rules.dart lib/layers/domain/use-cases/arena/start_fight_use_case.dart \
  lib/layers/domain/entities/hero/hero_status_entity.dart lib/layers/domain/use-cases/hero/get_hero_status_use_case.dart \
  test/mocks/domain/entities/hero/hero_entity_mock.dart test/mocks/domain/entities/hero/hero_status_entity_mock.dart \
  test/mocks/domain/entities/combat/fight_result_entity_mock.dart test/layers/domain/use-cases/arena/start_fight_use_case_test.dart \
  test/layers/domain/use-cases/hero/get_hero_status_use_case_test.dart test/layers/domain/world/extensions/arena_rules_test.dart \
  test/layers/domain/entities/combat/fight_result_entity_test.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart
flutter analyze
flutter test
```

Expected: `di.config.dart` sin cambios, `No issues found!` y **618 tests** en verde (612 + 6).

- [ ] **Step 7: Commit y unión a la rama de fase**

```bash
git add lib/layers/domain test/mocks/domain test/layers/domain
git add CLAUDE.md
git commit -m "[PROJECT-C6]: Crown the hero champion the first time the chief falls"
git switch feature/PROJECT-C6-barbarians && git merge --no-ff feature/PROJECT-C6-champion -m "[PROJECT-C6]: Merge the champion rules into the phase"
```

Si TC6.1 y TC6.2 se hicieron a la vez, la segunda unión puede chocar en `CLAUDE.md`: se quedan los dos cambios. Después, `flutter analyze` y `flutter test` en la rama de fase (618).

---

### Task TC6.3: Anillo del objetivo y caídos

**Files:**
- Create: `lib/layers/presentation/features/arena/game/components/target_ring_component.dart`
- Modify:
  - `lib/layers/presentation/features/arena/models/fighter_render_data.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - `lib/layers/presentation/features/arena/game/components/fighter_component.dart`
  - `lib/layers/presentation/features/arena/game/arena_scene_component.dart`
  - `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
  - `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`
  - `test/layers/presentation/features/arena/game/components/fighter_component_test.dart`
  - `test/layers/presentation/features/arena/game/arena_scene_component_test.dart`
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: `FighterComponent.shadowWidthOf` / `shadowHeight`, `ArenaFrames.spot` / `groundSpot`, `RenderDepth.shadow`, `CustomColors.hudAccent`, `FightReplayData.healthOf`, `HeroEntityMock.packHunter`, `ArenaBlocMock.tickFor`.
- Produces:
  ```dart
  // fighter_render_data.dart
  final bool isTargeted;   // constructor: this.isTargeted = false
  // target_ring_component.dart
  class TargetRingComponent extends PositionComponent {
    TargetRingComponent({required Vector2 center, required Vector2 size});
    bool isShown;
  }
  // fighter_component.dart
  final TargetRingComponent ring;
  // arena_render_constants.dart
  static const double fallenAlpha = 0.5;
  static const double targetRingPadding = 8;
  static const double targetRingStroke = 1;
  ```

- [ ] **Step 1: Rama**

```bash
git switch feature/PROJECT-C6-barbarians && git pull
```

(TC6.3 se hace directamente en la rama de fase, con TC6.1 y TC6.2 ya unidas.)

- [ ] **Step 2: Tests que fallan**

Al final de `test/layers/presentation/features/arena/game/components/fighter_component_test.dart`:

```dart
  testWithFlameGame('testWhenTheEnemyIsTheHerosTargetThenARingIsDrawnUnderItsFeet', (game) async {
    // given
    final bandit = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);

    // when
    await game.ensureAdd(bandit);

    // then
    expect(bandit.ring.isShown, isTrue);
    expect(bandit.ring.position, Vector2(300, 170));
    expect(bandit.ring.size, Vector2(30, 11));
  });

  testWithFlameGame('testWhenTheTargetFallsThenTheRingIsHidden', (game) async {
    // given
    final bandit = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);
    await game.ensureAdd(bandit);

    // when
    bandit.show(FighterRenderDataMock.rookieBanditDown);

    // then
    expect(bandit.ring.isShown, isFalse);
  });

  testWithFlameGame('testWhenTheFighterIsNotTheTargetThenNoRingIsDrawn', (game) async {
    // given
    final hero = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.heroIdle);

    // when
    await game.ensureAdd(hero);

    // then
    expect(hero.ring.isShown, isFalse);
  });
```

En `test/layers/presentation/features/arena/game/arena_scene_component_test.dart`, importa `package:rpg/layers/presentation/features/arena/game/components/target_ring_component.dart` y:
- en `testWhenShowingTheFirstStateThenBuildsTheStageAndTheFighters`, tras `expect(scene.fighters.keys, ['hero-0', 'enemy-0']);`:

```dart
    expect(scene.children.whereType<TargetRingComponent>().where((ring) => ring.isShown), hasLength(1));
```

- en `testWhenTheLevelChangesThenFightersThatLeftAreRemoved`, tras `expect(scene.fighters.keys, ['hero-0']);`:

```dart
    expect(scene.children.whereType<TargetRingComponent>(), hasLength(1));
```

En `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`, antes de `testWhenTheReplayEndsThenEveryTurnPlayedOnceAndTheVictoryIsShown`:

```dart
  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheFirstWolfOfThePackFallsThenTheRingMovesToTheNextOne',
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
      final targeted = bloc.state.data.fighters.where((fighter) => fighter.isTargeted);
      expect(targeted.map((fighter) => fighter.index), [1]);
    },
  );
```

(4848 ms es el mismo momento que `testWhenTheHeroStrikesTheSecondWolfOfThePackThenThatWolfIsItsTarget`: el primer lobo ya ha caído.)

Run: `flutter test test/layers/presentation/features/arena`
Expected: no compila (`ring`, `isTargeted`, `TargetRingComponent` no existen).

- [ ] **Step 3: El anillo**

Crea `lib/layers/presentation/features/arena/game/components/target_ring_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../theme/colors/custom_colors.dart';
import '../../../forest/game/render/render_depth.dart';
import '../render/arena_render_constants.dart';

class TargetRingComponent extends PositionComponent {
  static final Paint _paint = Paint()
    ..color = CustomColors.hudAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = ArenaRenderConstants.targetRingStroke;

  bool isShown = false;

  TargetRingComponent({required Vector2 center, required Vector2 size})
    : super(position: center, size: size, anchor: Anchor.center, priority: RenderDepth.shadow);

  @override
  void render(Canvas canvas) {
    if (!isShown) return;
    canvas.drawOval(size.toRect(), _paint);
  }
}
```

En `ArenaRenderConstants`, `fallenAlpha` pasa a `0.5` y debajo:

```dart
  static const double fallenAlpha = 0.5;
  static const double targetRingPadding = 8;
  static const double targetRingStroke = 1;
```

En `FighterRenderData`, campo `final bool isTargeted;` tras `targetIndex`, parámetro `this.isTargeted = false,` al final del constructor, y:

```dart
          other.targetIndex == targetIndex &&
          other.isTargeted == isTargeted;

  @override
  int get hashCode =>
      Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress, targetIndex, isTargeted);
```

En `FighterComponent` (`fighter_component.dart`): importa `'target_ring_component.dart'`, añade `final TargetRingComponent ring;` tras `shadow` y, en la lista de inicialización, entre `shadow` y `healthBar`:

```dart
      ring = TargetRingComponent(
        center: ArenaFrames.spot(fighter.side, fighter.index).toVector2(),
        size:
            Vector2(
              shadowWidthOf(fighter.enemyKind) + ArenaRenderConstants.targetRingPadding,
              shadowHeight + ArenaRenderConstants.targetRingPadding / 2,
            ) *
            ArenaRenderConstants.fighterScale(fighter.enemyKind),
      ),
```

y en `_place()`, tras colocar la sombra:

```dart
    shadow.position.setValues(ground.x, ground.y);
    ring
      ..position.setValues(ground.x, ground.y)
      ..isShown = _fighter.isTargeted && _fighter.pose != FighterPose.down;
```

En `ArenaSceneComponent`: `add(created.ring);` justo después de `add(created.shadow);` en `_reconcile`, y `fighter.ring.removeFromParent();` justo después de `fighter.shadow.removeFromParent();` en `_removeFighter`.

- [ ] **Step 4: El BLoC marca el objetivo**

En `ArenaBloc` (`arena_bloc.dart`):

1. En `_previewFighters`, cada enemigo lleva `isTargeted: index == 0,` tras `pose: FighterPose.idle,`.
2. `_replayFighters` y el método nuevo `_heroTarget`:

```dart
  List<FighterRenderData> _replayFighters(FightReplayData replay) {
    final log = replay.log;
    final target = _heroTarget(replay);
    return [
      _replayFighter(replay, FightSide.hero, 0, null),
      for (final (index, enemy) in log.enemies.indexed)
        _replayFighter(replay, FightSide.enemy, index, enemy.kind, isTargeted: index == target),
    ];
  }

  int _heroTarget(FightReplayData replay) {
    for (var index = 0; index < replay.log.enemies.length; index++) {
      if (replay.healthOf(FightSide.enemy, index) > 0) return index;
    }
    return -1;
  }
```

3. `_replayFighter` recibe el parámetro y lo pasa:

```dart
  FighterRenderData _replayFighter(
    FightReplayData replay,
    FightSide side,
    int index,
    EnemyKind? kind, {
    bool isTargeted = false,
  }) {
```

y en el `FighterRenderData` que devuelve, tras `targetIndex: …`, `isTargeted: isTargeted,`.

- [ ] **Step 5: Mocks**

En `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`, añade `isTargeted: true,` como último argumento de `rookieBanditIdle`, `veteranBanditIdle`, `wolfIdle`, `rookieBanditHurt` y `wolfLeaping` (son el enemigo 0 con vida: el BLoC los marca). Ejemplo:

```dart
  static const FighterRenderData rookieBanditIdle = FighterRenderData(
    side: FightSide.enemy,
    index: 0,
    enemyKind: EnemyKind.bandit,
    health: 20,
    maxHealth: 20,
    pose: FighterPose.idle,
    isTargeted: true,
  );
```

Run: `flutter test test/layers/presentation/features/arena`
Expected: PASS (sin el Step 5 fallan cinco tests del BLoC que comparan luchadores).

- [ ] **Step 6: Guía**

En `CLAUDE.md`, *Rendering constants*, el final del paréntesis de la arena `and they lie on their own `down` frame instead of tipping over).` pasa a:

```text
and they lie on their own `down` frame instead of tipping over; the hero's target, the first enemy still standing, has a ring under its feet (`TargetRingComponent`, `FighterRenderData.isTargeted`), and fallen fighters are drawn at half alpha).
```

- [ ] **Step 7: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/arena \
  test/mocks/presentation/features/arena/fighter_render_data_mock.dart \
  test/layers/presentation/features/arena/game/components/fighter_component_test.dart \
  test/layers/presentation/features/arena/game/arena_scene_component_test.dart \
  test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart
flutter analyze
flutter test
```

Expected: `No issues found!` y **622 tests** en verde (618 + 4).

- [ ] **Step 8: Commit**

```bash
git add lib/layers/presentation/features/arena test/mocks/presentation/features/arena test/layers/presentation/features/arena
git add CLAUDE.md
git commit -m "[PROJECT-C6]: Ring the hero's target and dim the fallen"
```

---

### Task TC6.4: Campeón en pantalla

**Files:**
- Modify:
  - `lib/core/assets/i18n/translations/es.json`
  - `lib/core/assets/i18n/internationalize.dart`
  - `lib/layers/presentation/features/arena/models/arena_effect.dart`
  - `lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`
  - `lib/layers/presentation/features/arena/game/arena_scene_component.dart`
  - `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
  - `lib/layers/presentation/features/forest/models/hero_panel_data.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - `lib/layers/presentation/features/forest/widgets/hero_panel.dart`
  - `test/core/assets/i18n/internationalize_test.dart`
  - `test/mocks/presentation/features/arena/{arena_effect_mock,arena_data_mock,arena_result_data_mock}.dart`
  - `test/mocks/presentation/features/forest/hero_panel_data_mock.dart`
  - `test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`
  - `test/layers/presentation/features/arena/models/arena_effect_test.dart`
  - `test/layers/presentation/features/arena/game/arena_scene_component_test.dart`
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - `test/layers/presentation/features/forest/widgets/hero_panel_test.dart`
  - `test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: `FightPlayedEntity.isFirstChampionship`, `HeroStatusEntity.isChampion` (TC6.2); `FighterComponent.headPoint`; `ParticleBurstComponent`; `ParticleKind.sparkle` / `magicSparkle`; `HeroEntityMock.chiefChallenger` / `champion`.
- Produces:
  ```dart
  final class ChampionEffect extends ArenaEffect { const ChampionEffect(); }
  static List<Particle> confetti({required PositionEntity at, required math.Random random});  // ParticleBursts
  static String get arenaChampion;        // '¡Campeón de la arena!'
  static String get forestHeroChampion;   // 'Campeón de la arena'
  final bool isChampion;                  // HeroPanelData, this.isChampion = false
  ```

- [ ] **Step 1: Rama**

```bash
git switch feature/PROJECT-C6-barbarians && git pull
```

- [ ] **Step 2: Tests que fallan**

Mocks:
- `ArenaEffectMock`, tras `won`: `static const ChampionEffect champion = ChampionEffect();`
- `ArenaDataMock`, antes de `won`:

```dart
  static ArenaData get crowned => replaying.copyWith(effects: const [ArenaEffectMock.won, ArenaEffectMock.champion]);
```

- `ArenaResultDataMock`, antes de `defeatNeedAttack`:

```dart
  static ArenaResultData get championHundredGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaChampion,
    detail: Internationalize.arenaReward(amount: 100),
  );

  static ArenaResultData get victoryThirtyThreeGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaVictory,
    detail: Internationalize.arenaReward(amount: 33),
  );
```

- `HeroPanelDataMock`, antes de `readyToBuySword`:

```dart
  static HeroPanelData get newChampion => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.withoutTower,
    isChampion: true,
  );
```

Tests, al final de `particle_bursts_test.dart`:

```dart
  test('testWhenTheHeroBecomesChampionThenGoldAndBlueConfettiBurstsUpAndFalls', () {
    // given
    const head = ParticleMock.heroFeet;

    // when
    final confetti = ParticleBursts.confetti(at: head, random: ParticleMock.sparklesRandom);

    // then
    expect(confetti, hasLength(24));
    expect(confetti.map((piece) => piece.kind).toSet(), {ParticleKind.sparkle, ParticleKind.magicSparkle});
    for (final piece in confetti) {
      expect(piece.origin.y, 150);
      expect(piece.origin.x, inInclusiveRange(134, 166));
      expect(_angleDegrees(piece.velocityX, piece.velocityY), inInclusiveRange(220, 320));
      expect(piece.gravity, 140);
      expect(piece.lifespanSeconds, 1.2);
    }
  });
```

Al final de `arena_effect_test.dart`:

```dart
  test('testWhenComparingChampionEffectsThenTheyAreAllEqual', () {
    // given
    const champion = ArenaEffectMock.champion;

    // when
    final equal = champion == const ChampionEffect();

    // then
    expect(equal, isTrue);
    expect(champion.hashCode, const ChampionEffect().hashCode);
    expect(champion, isNot(ArenaEffectMock.won));
  });
```

Al final de `arena_scene_component_test.dart`:

```dart
  testWithFlameGame('testWhenTheHeroIsCrownedThenConfettiBurstsOverItsHead', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.crowned);
    await game.ready();

    // then
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
  });
```

En `arena_bloc_test.dart`, antes de `testWhenTheReplayIsRunningThenSelectingAndFightingAreIgnored`:

```dart
  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheChiefFallsForTheFirstTimeThenTheHeroIsCrownedChampion',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.chiefChallenger);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.barbarianChief))
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects, [ArenaEffectMock.won, ArenaEffectMock.champion]);
      expect(bloc.state.data.result, ArenaResultDataMock.championHundredGold);
    },
  );

  blocTest<ArenaBloc, ArenaState>(
    'testWhenAChampionBeatsTheChiefAgainThenItIsAnOrdinaryVictory',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.champion);
      return ArenaBlocMock.make(world, navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ArenaBlocMock.collectEffects(bloc);
      bloc
        ..add(const ArenaStarted())
        ..add(const ArenaLevelSelected(levelId: ArenaLevelId.barbarianChief))
        ..add(const ArenaFightRequested())
        ..add(const ArenaReplaySkipped());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects, [ArenaEffectMock.won]);
      expect(bloc.state.data.result, ArenaResultDataMock.victoryThirtyThreeGold);
    },
  );
```

En `hero_panel_test.dart`, antes de `testWhenBuyIsTappedThenReportsThePiece`:

```dart
  testWidgets('testWhenTheHeroIsChampionThenTheBadgeIsShownNextToTheTitle', (tester) async {
    // given
    final champion = HeroPanelDataMock.newChampion;

    // when
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: champion, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.text(Internationalize.forestHeroChampion), findsOneWidget);
  });

  testWidgets('testWhenTheHeroIsNotChampionThenThereIsNoBadge', (tester) async {
    // given
    final hero = HeroPanelDataMock.newHero;

    // when
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.text(Internationalize.forestHeroChampion), findsNothing);
  });
```

Al final de `forest_bloc_hero_test.dart` (importa `../../../../../mocks/domain/entities/hero/hero_entity_mock.dart`):

```dart
  blocTest<ForestBloc, ForestState>(
    'testWhenTheHeroHasBeatenTheChiefThenTheHeroPanelShowsTheChampionBadge',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withoutWorkshops(hero: HeroEntityMock.champion),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.hero.isChampion, isTrue);
    },
  );
```

En `internationalize_test.dart`:
- tras `expect((Internationalize.arenaFight, Internationalize.arenaVictory), ('Empezar pelea', '¡Victoria!'));`:

```dart
    expect(Internationalize.arenaChampion, '¡Campeón de la arena!');
```

- en `testWhenReadingEveryHeroTextThenNoneFallsBackToItsKey`, `Internationalize.forestHeroChampion,` tras `Internationalize.forestHeroPower,` en la lista de textos, y `'Campeón de la arena',` tras `'Poder',` en la lista esperada.

Run: `flutter test`
Expected: no compila (`ChampionEffect`, `confetti`, `arenaChampion`, `forestHeroChampion`, `HeroPanelData.isChampion` no existen).

- [ ] **Step 3: Textos**

`es.json`: en `arena`, tras `"victory": "¡Victoria!",`, `"champion": "¡Campeón de la arena!",`; en `forest.hero`, tras `"health": "Vida",`, `"champion": "Campeón de la arena",`.

`Internationalize`:

```dart
  static String get forestHeroChampion => '$_forest.hero.champion'.tr();
```

tras `forestHeroPower`, y

```dart
  static String get arenaChampion => '$_arena.champion'.tr();
```

tras `arenaVictory`.

- [ ] **Step 4: Efecto y confeti**

Al final de `arena_effect.dart`:

```dart
final class ChampionEffect extends ArenaEffect {
  const ChampionEffect();

  @override
  bool operator ==(Object other) => other is ChampionEffect;

  @override
  int get hashCode => (ChampionEffect).hashCode;
}
```

En `ParticleBursts` (`particle_bursts.dart`), constantes antes de `bloodDropsMin`:

```dart
  static const int confettiPieces = 24;
  static const double confettiAngleMin = 220;
  static const double confettiAngleMax = 320;
  static const double confettiSpeedMin = 60;
  static const double confettiSpeedMax = 120;
  static const double confettiSpreadX = 16;
  static const double confettiGravity = 140;
  static const double confettiLifespanSeconds = 1.2;
  static const double confettiAlphaStart = 1;
  static const double confettiAlphaEnd = 0;
  static const double confettiScale = 1;
```

y el método, antes de `bloodDrops`:

```dart
  static List<Particle> confetti({required PositionEntity at, required math.Random random}) {
    return List.generate(confettiPieces, (index) {
      final speed = _between(random, confettiSpeedMin, confettiSpeedMax);
      final angle = _between(random, confettiAngleMin, confettiAngleMax) * math.pi / 180;
      return Particle(
        kind: index.isEven ? ParticleKind.sparkle : ParticleKind.magicSparkle,
        origin: PositionEntity(x: at.x + _between(random, -confettiSpreadX, confettiSpreadX), y: at.y),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: confettiGravity,
        rotationDegrees: 0,
        lifespanSeconds: confettiLifespanSeconds,
        alphaStart: confettiAlphaStart,
        alphaEnd: confettiAlphaEnd,
        scaleStart: confettiScale,
        scaleEnd: confettiScale,
      );
    });
  }
```

En `ArenaSceneComponent._play`, antes de `case FightEndedEffect():`:

```dart
      case ChampionEffect():
        _celebrate();
```

y el método, antes de `_floatSkillName`:

```dart
  void _celebrate() {
    final hero = _fighters[FighterRenderData.keyOf(FightSide.hero, 0)];
    if (hero == null) return;
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.confetti(at: hero.headPoint, random: _random),
        sortY: hero.position.y + ParticleBursts.sortYOffset,
      ),
    );
  }
```

- [ ] **Step 5: El BLoC de la arena corona al campeón**

En `ArenaBloc`:

```dart
  FightAdvice? _advice;
  bool _isFirstChampionship = false;
```

En `_onFightRequested`:

```dart
      case FightPlayedEntity(:final log, :final advice, :final isFirstChampionship):
        _advice = advice;
        _isFirstChampionship = isFirstChampionship;
```

En `_emitReplay`, la lista de efectos termina en:

```dart
      if (next.isFinished) FightEndedEffect(isVictory: next.log.isVictory),
      if (next.isFinished && _isFirstChampionship) const ChampionEffect(),
    ];
```

En `_result`, el título de la victoria:

```dart
        title: _isFirstChampionship ? Internationalize.arenaChampion : Internationalize.arenaVictory,
```

- [ ] **Step 6: Insignia del panel *Héroe***

`HeroPanelData`: campo `final bool isChampion;` tras `skills`, parámetro `this.isChampion = false,` al final del constructor, y:

```dart
          const ListEquality<SkillItemData>().equals(other.skills, skills) &&
          other.isChampion == isChampion;

  @override
  int get hashCode =>
      Object.hash(power, attack, defense, health, Object.hashAll(rows), Object.hashAll(skills), isChampion);

  @override
  String toString() =>
      'HeroPanelData(power: $power, $attack/$defense/$health, rows: $rows, skills: $skills, isChampion: $isChampion)';
```

`ForestBloc`, en el `HeroPanelData` que construye, tras `skills: …,`: `isChampion: status.isChampion,`.

`HeroPanel._title()` pasa a:

```dart
  Widget _title() {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Text(
            Internationalize.forestHero.toUpperCase(),
            style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
          ),
        ),
        if (widget.hero.isChampion) _championBadge(),
      ],
    );
  }

  Widget _championBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CustomColors.hudAccentSoft,
        border: Border.all(color: CustomColors.hudAccent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          Internationalize.forestHeroChampion,
          style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudAccent),
        ),
      ),
    );
  }
```

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Guía**

En `CLAUDE.md`:
- `particles/`: `and blood drops: `ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`)` pasa a `blood drops: `ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`, and the champion confetti, `ParticleBursts.confetti`, gold and blue sparkles that fall)`;
- `widgets/`: `HeroPanel` (tabs *Equipo* … pasa a `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* …;
- `features/arena/`: tras `and refreshes the list with `GetArenaUseCase` when the replay ends` añade `; a first championship adds a `ChampionEffect` (confetti over the hero) after `FightEndedEffect` and titles the result *¡Campeón de la arena!*`.

- [ ] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/arena \
  lib/layers/presentation/features/forest/game/particles/particle_bursts.dart \
  lib/layers/presentation/features/forest/models/hero_panel_data.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart \
  lib/layers/presentation/features/forest/widgets/hero_panel.dart test/core/assets/i18n/internationalize_test.dart \
  test/mocks/presentation/features/arena/arena_effect_mock.dart test/mocks/presentation/features/arena/arena_data_mock.dart \
  test/mocks/presentation/features/arena/arena_result_data_mock.dart test/mocks/presentation/features/forest/hero_panel_data_mock.dart \
  test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart \
  test/layers/presentation/features/arena/models/arena_effect_test.dart \
  test/layers/presentation/features/arena/game/arena_scene_component_test.dart \
  test/layers/presentation/features/arena/bloc/arena_bloc_test.dart \
  test/layers/presentation/features/forest/widgets/hero_panel_test.dart \
  test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `No issues found!`, **630 tests** en verde (622 + 8) y los de Chrome en verde.

- [ ] **Step 9: Commit**

```bash
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-C6]: Celebrate the first championship with confetti and a hero badge"
```

## Prueba manual

En Chrome (`flutter run -d chrome`), el emulador Android y el simulador iOS, en horizontal. Para llegar al jefe sin jugar media hora, se puede arrancar con un héroe de prueba **sólo en local** (sin commit): en `GameSessionLocalDatasourceImpl` o en el `World` inicial, `hero: HeroEntity(weaponTier: 3, armorTier: 3, skills: {doubleStrike, secondWind, dodge}, clearedLevels: {...todos menos barbarianChief})`.

1. **Bárbaros:** abrir *Bárbaro*, *Pareja de bárbaros* y *Jefe bárbaro*. Se ven con casco, barba pelirroja y cuero; el jefe, más grande, con casco vikingo y barba negra, delante y en el centro, y los dos guardias detrás, arriba y abajo.
2. **Anillo:** antes de pelear, el anillo dorado está bajo el primer enemigo. Al caer, el anillo pasa al siguiente que sigue en pie. Los caídos quedan tumbados y bastante más transparentes.
3. **Campeón:** ganar al jefe por primera vez: confeti dorado y azul sobre el héroe, panel *¡Campeón de la arena!* con "+100 de oro". Volver al bosque: el panel *Héroe* muestra la insignia *Campeón de la arena*.
4. **Repetir:** volver a ganar al jefe: panel *¡Victoria!* con "+33 de oro" y sin confeti. *Saltar* en mitad de la pelea del primer campeonato también enseña el confeti y el panel de campeón.
5. **Móvil estrecho:** en 844 × 390 el panel de resultado y la insignia caben sin desbordar.

## Al cerrar C6

- Marca los checkboxes de las cuatro tareas, actualiza la fila de C6 en `docs/boost/plans/PROGRESS.md` y la tabla de fases del README (`/cerrar-tarea`), y apunta en la sección 5 del README las desviaciones: el arma (hacha en vez de hacha de guerra o maza) y lo que salga de la prueba manual.
- La PR de `feature/PROJECT-C6-barbarians` a `feature/PROJECT-X-arena` la abre `/cerrar-tarea`, con la prueba manual de las tres plataformas. Tras la unión, la batería de cierre en la rama de integración.
- Con C6 cerrada sólo queda C7 (misiones del héroe y equilibrado), que también repasa los números de los bárbaros.
