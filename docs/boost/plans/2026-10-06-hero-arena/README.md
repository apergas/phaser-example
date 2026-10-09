# Héroe y arena (`docs/GAME_DESIGN.md`, sección 3.8): hoja de ruta

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement each phase plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Start every session with the project skill `/siguiente-tarea` and finish every task with `/cerrar-tarea`.

**Goal:** Añadir un segundo modo de juego: el héroe mejora su equipo y sus habilidades en edificios de la aldea y se enfrenta, en una arena por niveles, a enemigos cada vez más fuertes en peleas automáticas que se ven animadas. El oro que se gana en la arena es lo que la aldea gasta en esas mejoras.

**Architecture:**
- Mismas capas y reglas que el plan de la aldea ([`2026-10-04-game-design/README.md`](../2026-10-04-game-design/README.md), *Global Constraints*), con lo que añade este plan:
  - **`HeroEntity` vive dentro del `World`** (`WorldState.hero`), pero no dentro de `PlayerEntity`. Así:
    - el `World` sigue siendo el único agregado mutable;
    - el guardado (F2) y las misiones lo ven sin hacer nada especial;
    - cuando lleguen los aldeanos (F10), el héroe no se mezcla con la lista de unidades.
  - **El motor de combate es una función pura** en `lib/layers/domain/combat/`, fuera de `world/`: recibe las estadísticas del héroe, sus habilidades, el nivel y una semilla, y devuelve un `FightLogEntity` completo. La presentación sólo lo reproduce.
  - **Pagar y cobrar pasan por `World.funds` / `World.earn` / `World.spend`** (C0). El combate nunca toca `player.inventory` ni el stock directamente; cuando F6 traiga el almacén, sólo cambia el cuerpo de esos tres métodos.
  - **Catálogos de datos** en `domain/rules/`, como `Blueprints`: `Gear` (C0), `ArenaLevels` (C1), `Skills` (C5).
  - **Pantalla nueva** `lib/layers/presentation/features/arena/` (BLoC + escena Flame). Se entra desde el HUD del bosque con `NavigationService.push`.

Ver `CLAUDE.md` → *Architecture*.

**Tech Stack:**
- Flutter 3.47.6 / Dart 3.13.
- BLoC (`flutter_bloc`), Flame + `flame_bloc`, `get_it` + `injectable`, `easy_localization` (sólo `es.json`).
- Tests: `flutter_test`, `mockito`, `bloc_test`, `flame_test`.
- Arte: LPC generado por `asset-packs/lpc/build_assets.py`.

## Global Constraints

Se aplican **todas** las *Global Constraints* del README del plan de la aldea (arquitectura, tests, idioma, plataforma, git, cierre de fase). Además:

**Dominio del combate:**
- `lib/layers/domain/combat/` es una carpeta nueva del dominio, como `world/` y `quests/`. Se documenta en `CLAUDE.md` ampliando la excepción **E1** (lo hace C0).
- El motor es **determinista**: usa `SeededRandom` de `lib/core/utils/seeded_random.dart` con la semilla `hero.fightsFought`. La misma partida da siempre la misma pelea, y los tests fijan resultados exactos.
- Los casos de uso siguen siendo síncronos (E3): la pelea se resuelve entera en el `call()`.

**Pagos:** todo coste o recompensa del héroe usa `World.spend(cost)` / `World.earn(reward)` (C0). Nadie del plan de la arena llama a `InventoryRules.spend` / `add` sobre `player.inventory`.

**Presentación:**
- Flame sólo en `features/forest/game/`, `features/arena/game/`, `forest_page.dart` y `arena_page.dart`. La regla de `test/architecture_test.dart` se amplía en C2.
- Textos de la arena bajo la clave `arena.*` de `es.json`; los del héroe en el HUD del bosque, bajo `forest.hero.*`.

**Arte:**
- A diferencia del plan de la aldea, **este plan sí puede traer arte LPC nuevo** (animales, ropa de bárbaro, espadas), siempre en `asset-packs/lpc/sources/`, procesado por `build_assets.py` y acreditado en `lib/core/assets/images/lpc/CREDITS.md`. Una pieza sin licencia compatible (CC-BY-SA 3.0, GPL 3.0, OGA-BY 3.0 o CC-BY 3.0/4.0, que sólo pide atribución) no entra. CC-BY se acepta desde C4 (lobo y oso), confirmado en `CREDITS.md` y `CLAUDE.md`.
- Si una pieza no existe, se usa `recolour()` sobre arte ya disponible y se apunta como desviación.
- El arte de la arena va en un atlas propio, `lib/core/assets/images/lpc/arena.{png,json}`, para no generar conflictos con `forest.{png,json}`. Las mismas reglas: nunca se resuelve un conflicto a mano, se regenera.

---

## 1. Cómo retomar contexto (para la IA)

Para trabajar en una tarea **no hace falta leer el proyecto**. Lee sólo esto:

1. `CLAUDE.md`.
2. Este README: sección 2 (fases) y sección 3 (convivencia con el plan de la aldea).
3. Las *Global Constraints* del [README del plan de la aldea](../2026-10-04-game-design/README.md) y su sección 3 (reglas de trabajo en paralelo), que también valen aquí.
4. El fichero de tu fase (`C<n>-*.md`) y, dentro de él, **sólo tu tarea**.
5. Tu issue de GitHub.

## 2. Fases

**Leyenda:**
- ✅ fase terminada (en `feature/PROJECT-X-arena`; ver la sección 3.0).
- 🟢 plan detallado listo para ejecutar.
- 📝 ficha: hay que escribir su plan detallado con `boost:writing-plans` al empezar la fase.

| Fase | Plan | Flujo | Depende de | Qué añade |
|---|---|---|---|---|
| **C0** Contrato común: oro y héroe | ✅ [C0-contract.md](C0-contract.md) | Común | F0 | `Resource.gold` en el HUD; `World.funds` / `earn` / `spend`; `HeroEntity` dentro del `World`; entidades de combate (`CombatStatsEntity`, `EnemyEntity`, `ArenaLevelEntity`, `FightLogEntity`); catálogo `Gear`; `HeroRules.stats` / `power`; `GetHeroStatusUseCase`. **Sin jugabilidad nueva** salvo el oro (a 0) en el HUD. |
| **C1** Motor de combate y niveles | ✅ [C1-combat-engine.md](C1-combat-engine.md) | C | C0 | `Combat.resolve`, `ArenaLevels` con los niveles de humanos, `GetArenaUseCase`, `StartFightUseCase`: pelear, cobrar y desbloquear. Sólo dominio. |
| **C2** Pantalla de la arena | ✅ [C2-arena-screen.md](C2-arena-screen.md) | C | C0 (C1 para pelear de verdad) | `ArenaPage` + `ArenaBloc` + escena Flame que reproduce el `FightLogEntity`; botón *Arena* en el HUD del bosque; bandidos con el arte del héroe recoloreado. |
| **C3** Herrería y Armería | ✅ [C3-forge-armory.md](C3-forge-armory.md) | D | C0 | Dos edificios nuevos; comprar armas y armaduras (`BuyGearUseCase`); panel *Héroe* en el HUD del bosque con Poder, atributos y equipo. |
| **C4** Lobos y oso | ✅ [C4-beasts.md](C4-beasts.md) | C | C2 | Arte LPC nuevo de animales; `EnemyKind.wolf` / `bear`; niveles 2, 4, 5 y 8. |
| **C5** Torre de magia y habilidades | ✅ [C5-mage-tower.md](C5-mage-tower.md) | D | C3 | Edificio *Torre de magia*; catálogo `Skills`; `LearnSkillUseCase`; pestaña *Habilidades* del panel *Héroe*. Los efectos en la pelea ya los aplica el motor de C1. |
| **C6** Bárbaros y jefe | ✅ [C6-barbarians.md](C6-barbarians.md) | C | C4 | Arte de bárbaros y jefe; peleas de grupo bien colocadas (hasta 3 enemigos); pantalla de victoria final. |
| **C7** Misiones del héroe y equilibrado | 🟢 [C7-hero-quests-balance.md](C7-hero-quests-balance.md) | D | C1, C3, C5 | Línea de misiones *Héroe*; consejo tras una derrota; test de equilibrado (Poder contra porcentaje de victorias) y números finales. |

### Flujos de trabajo (dos desarrolladores)

```
F0 (plan de la aldea) ─▶ C0 contrato común (un desarrollador; el otro escribe los planes de C1 y C3)
                           │
          ┌────────────────┴─────────────────────┐
Flujo C (arena)                          Flujo D (héroe)
C1 ─▶ C2 ─▶ C4 ─▶ C6                      C3 ─▶ C5 ──┬─▶ C7
 └─────────────────────────────────────────────────┘ (C7 también espera a C1)
```

- **Punto común:** C0. Fija los nombres y tipos que usan los dos flujos, así que después cada uno trabaja con sus propios ficheros:
  - flujo C: `domain/combat/`, `rules/arena_levels.dart`, `features/arena/`, `arena.{png,json}`;
  - flujo D: `rules/gear.dart`, `rules/skills.dart`, `rules/blueprints.dart`, los widgets del panel *Héroe* y `forest.{png,json}`.
- **Flujo C** desarrollador 1; **flujo D** desarrollador 2.
- **C2 puede empezar antes de que C1 se fusione:** la escena reproduce `FightLogEntityMock` (C0). Cuando C1 llega, sólo cambia de dónde sale el registro.
- **C3 no necesita la arena:** se puede comprar equipo con el oro que se añada en los tests o en una partida guardada. En el juego real el oro sale de C1, que irá a la par.
- **C1 puede empezar mientras se hace F0:** el motor (`Combat.resolve`) sólo usa entidades nuevas. Si C0 todavía no está, se hace en una rama que sale de la de C0.

## 3. Convivencia con el plan de la aldea

### 3.0 Rama de integración de la arena (decidido el 2026-10-07)

La arena no entra en `develop` fase a fase. Se acumula en una rama de integración, **`feature/PROJECT-X-arena`**, que se fusiona en `develop` **una sola vez**, cuando el modo esté completo. Así `develop`, `main` y la web publicada nunca tienen la arena a medias.

- **Ramas de fase:** cada fase (por ejemplo `feature/PROJECT-C6-barbarians`; commits y PR `[PROJECT-C6]: …`, ver *Git* en el README de la aldea) sale de `feature/PROJECT-X-arena` (ya con las anteriores fusionadas) y su PR va hacia esa rama, no hacia `develop`.
- **Traer `develop` a menudo:** la aldea vive en `feature/PROJECT-X-town` y pasa a `develop` por bloques (README de la aldea, sección 3.0). Cada vez que entra un bloque de la aldea (o un arreglo urgente) en `develop`, se ejecuta `git merge develop` en `feature/PROJECT-X-arena`.
  - Los conflictos y los cruces de la sección 3.2 se resuelven en ese momento, en un commit propio.
  - La arena siempre "llega segunda", así que **todos los cruces los resuelve el flujo de la arena**.
- **Tests a mano:** el CI (`deploy.yml`) sólo se lanza con `main`. Tras cada unión en `feature/PROJECT-X-arena` hay que ejecutar la batería de cierre de fase (`build_runner` + `git diff`, `flutter analyze`, `flutter test`, tests en Chrome).
- **La documentación va con el código (decidido el 2026-10-09):** los cambios en `docs/` (planes, desviaciones, casillas y `PROGRESS.md`) se hacen en la misma rama de la tarea o fase, en un commit propio, y entran con ella en `feature/PROJECT-X-arena`. No hay rama ni PR aparte para la documentación.
- **Final:** una PR de `feature/PROJECT-X-arena` a `develop`, con la prueba manual completa en web, Android e iOS.

Los dos planes se pueden hacer **uno detrás de otro o a la vez**. La única dependencia dura es **F0 → C0**: el oro es un `Resource` y los costes son `Map<Resource, int>`. Ninguna fase de la aldea depende de una fase de la arena.

### 3.1 Escenarios para dos desarrolladores

| Escenario | Cómo se reparte | Cuándo conviene |
|---|---|---|
| **Secuencial** | F0 → flujos A/B hasta F8 → C0 → flujos C/D. | Si se quiere cerrar antes la economía de la aldea. |
| **Paralelo** (recomendado) | F0 (dev 1) → **dev 1: aldea** (F1, F2, F5, F3, F6, F4, F7, F8, en ese orden, que respeta las dependencias) · **dev 2: arena y héroe** (C0, C1, C3, C2, C5, C4, C7, C6). | Si se quiere un segundo modo jugable cuanto antes. Cada uno toca casi sólo sus ficheros. |
| **Mixto** | Se mantienen los flujos A/B. Cuando uno se bloquea (F7 espera a F6, F8 espera a F5), coge la siguiente fase libre de C o D. | Si el equipo prefiere seguir el reparto del plan de la aldea. |

En el escenario paralelo, mientras el dev 1 hace F0 (dos tareas secuenciales), el dev 2 escribe los planes detallados de C1 y C3, y puede empezar el motor de C1 en una rama.

### 3.2 Cruces entre los dos planes

Cada cruce dice **quién** lo resuelve según el orden en que se fusionen. Lo resuelve siempre **la fase que llega segunda**, en el mismo PR.

| Cruce | Si la aldea llega primero | Si la arena llega primero |
|---|---|---|
| **Guardado (F2)** ↔ estado del héroe (C0, C1, C3, C5) | Cada fase C que añade estado (`HeroEntity` y sus campos) lo añade al `SaveDBO` (`HeroDBO`) y sube `SaveDBO.currentVersion`. | F2 guarda y restaura `World.hero` con un `HeroDBO`, con todos los campos que existan. |
| **Almacén (F6)** ↔ `World.funds` / `earn` / `spend` (C0) | C0 implementa los tres métodos sobre `WorldState.stock`. | F6 cambia el cuerpo de los tres métodos de `player.inventory` a `stock`. Los tests de C siguen pasando sin tocarlos. En ambos casos **el oro nunca cuenta para la carga** (`Rules.carryCapacity`) y se cobra directamente en el stock. |
| **Piedra (F5)** ↔ coste del equipo (C3) | C3 pone piedra en las armas y armaduras de nivel 3 (`steelSword`, `plateArmor`), 15 de piedra cada una. | F5 añade esa piedra en `Gear.all` (dos líneas) y ajusta el test de `Gear`. |
| **Taller (F8)** ↔ Herrería (C3) | Son edificios distintos (`BlueprintId.workshop` frente a `forge`). Las herramientas tienen nivel (`toolLevels`), el equipo tiene nivel (`weaponTier` / `armorTier`), y **son independientes**: el hacha de hierro de F8 tala más rápido pero no cambia el Ataque. | Igual. |
| **Misiones (F4, F8 capítulo 2)** ↔ misiones del héroe (C7) | C7 crea una **línea de misiones** propia (`QuestLine.hero`) para no mezclar la cadena de la aldea con la de la arena; `QuestPanel` muestra las dos líneas. El recorte de F4 (completadas recogidas, actual y 2 pendientes) se aplica a cada línea. | F4 aplica su recorte por línea. Las misiones nuevas de F4/F8 van en `QuestLine.village`. |
| **HUD del bosque** | Botones nuevos: *Mejoras* (F8), *Arena* (C2), *Héroe* (C3). La fase que añade el **cuarto botón** comprueba la barra en un móvil en horizontal (ancho mínimo 640 px) y, si no cabe, agrupa *Arena* y *Héroe* en un solo botón *Héroe* con dos pestañas. | Igual. |
| **Misiones que miden el `World`** | `Quest.progress(World world)` no cambia: el héroe se lee con `world.hero`. | Igual. |
| **Aldeanos (F10)** | `PlayerEntity` pasa a ser una lista de unidades. `HeroEntity` **no** está en `PlayerEntity`, así que no le afecta; el héroe sigue siendo el jugador. | Igual. |
| **Atlas** | La arena usa su propio atlas (`arena.{png,json}`). Los edificios C3/C5 van en `forest.{png,json}`, con las reglas de regeneración de siempre. | Igual. |

### 3.3 Ficheros calientes que añade este plan

Además de los del plan de la aldea, con las mismas reglas (cambios aditivos al final del bloque, `switch` en orden de declaración):
- `lib/layers/domain/world/world.dart` y `world_state.dart` (sólo C0 los toca; después se usa `World.updateHero`);
- `lib/core/config/constants/enum/resource.dart`, `enemy_kind.dart`, `arena_level_id.dart`, `gear_id.dart`, `skill_id.dart`;
- `lib/layers/domain/rules/gear.dart`, `arena_levels.dart`, `blueprints.dart`;
- `lib/layers/presentation/features/forest/widgets/hud_overlay.dart` y `core/config/constants/enum/forest/hud_menu.dart`;
- `asset-packs/lpc/build_assets.py`.

## 4. Tracker en GitHub

El mismo repositorio y el mismo Project *Gameplay roadmap* que el plan de la aldea (sección 4 de su README), con:
- **Labels:** fase `phase:C0` … `phase:C7`; flujo `stream:C` (arena), `stream:D` (héroe); `blocked`.
- **Milestones:** `C0 Contract`, `C1 Combat engine`, `C2 Arena screen`, `C3 Forge and armory`, `C4 Beasts`, `C5 Mage tower`, `C6 Barbarians`, `C7 Hero quests and balance`.
- **Issues:** C0 tiene uno por tarea (TC0.1, TC0.2); C1–C7, uno por fase, que se divide cuando se escribe su plan.
- El campo *Stream* del Project gana los valores `C` y `D`.

Quien empiece C0 crea estas labels, milestones e issues si todavía no existen.

## 5. Desviaciones registradas

Aquí se apunta todo lo que se haga distinto de lo que dicen los planes: qué, por qué y en qué fase/tarea.

- **C0 (2026-10-06):**
  - **Ramas:** las dos tareas se hicieron en una sola rama de fase, `feature/PROJECT-X-c0-contract`, sin ramas ni PR por tarea (como F0). Su PR va a `feature/PROJECT-X-arena`, no a `develop` (sección 3.0). El tracker de GitHub todavía no existe.
  - **`ArenaLevelEntity` sin `assert` de 1 a 3 enemigos:** Dart no permite `List.length` en un constructor `const`. Lo cubre el test del catálogo de C1 (`arena_levels_test.dart`).
  - **El HUD ya lista el oro ("Oro 0"):** `forest_bloc_test.dart` espera madera y oro, y hay un `ResourceItemDataMock.gold` nuevo.
  - **Añadidos de la revisión final:**
    - `Gear.of` lanza `StateError` si el nivel no existe, en lugar de un `!`;
    - `FightTurnEntity` comprueba `round >= 1` y que los índices no sean negativos;
    - tests para el Poder con habilidades en `GetHeroStatusUseCase`, para el pago atómico (un recurso basta y otro no) y para que `earn` ignore cantidades negativas;
    - `CLAUDE.md` aclara que `earn` / `spend` son la vía de pago del héroe y de la arena, y que la aldea sigue usando el inventario hasta F6.
- **C1 (2026-10-07):**
  - **Ramas:** una rama de fase, `feature/PROJECT-X-c1-combat-engine`, apilada sobre la de C0 (las dos van hacia `feature/PROJECT-X-arena`, sección 3.0). TC1.1 y TC1.2 se hicieron a la vez, cada una en su propio worktree y su propia rama, y luego se unieron en la de la fase. Al unirlas solo hubo conflictos aditivos (constantes al final de `rules.dart` y entradas nuevas en `arena_level_entity_mock.dart`). TC1.3 se hizo encima.
  - **Añadidos de la revisión final:**
    - el test de la esquiva comprueba que el turno conserva la vida del héroe;
    - el test de flujo calcula la recompensa repetida a partir del catálogo;
    - `CLAUDE.md` aclara que la semilla la pasa `StartFightUseCase`.
  - **Aviso para C7 (y C4, si toca el primer nivel):** tres tests de casos de uso comparan el primer nivel del catálogo con mocks (`ArenaLevelEntityMock.banditRookie`, `FightResultEntityMock.victoryOverBandit`, `ArenaLevelStatusEntityMock.rookieForNewHero`). Si se cambia ese nivel, hay que actualizar esos mocks. Los tests del motor usan sus propios mocks y no dependen del catálogo.
- **Tracker (2026-10-07):** se crea al empezar C2 y C3 (issues #12–#40, Project *Gameplay roadmap*). Los issues de C0 y C1 se crearon ya cerrados, apuntando a #9 y #10. C2 y C3 tienen un issue por tarea.
- **C2 y C3 a la vez (2026-10-07):** las dos fases se hicieron en paralelo, cada una en su rama de fase y su worktree. Las tareas paralelas tuvieron rama propia (`-c2-scene` / `-c2-hud`, `-c3-gear-purchase` / `-c3-hero-panel`) y se unieron en su fase con `git merge --no-ff`, sin PR por tarea. C3 va primero a `feature/PROJECT-X-arena`; C2 llega segunda y resuelve los cruces: antes de su PR se le une la rama de C3 (`[PROJECT-X]: Merge the forge and armory phase into the arena screen phase`). Hubo 17 ficheros en conflicto, todos aditivos. Los atlas se regeneraron con `build_assets.py`: `forest.*` sale igual que en C3 y `arena.*` igual que en C2.
- **C2 (2026-10-07):**
  - **Arte:** todos los luchadores golpean con el hacha, porque no hay espadas en `sources/` (llegan con C3/C6). El jefe usa los frames del bárbaro escalados ×1,25 al dibujarlo, no en el atlas.
  - **Modelos:** `ArenaData` lleva además `fighters`, `result` y `effects`. El BLoC usa también `GetHeroStatusUseCase` para la vida del héroe antes de la primera pelea.
  - **Números flotantes:** no hay `FloatingNumberComponent`. Se usa `FloatingTextComponent` con la API de F1 (TF1.2): si F1 llega después a la rama, se queda cualquiera de los dos ficheros, porque son idénticos.
  - **Pausa del bosque:** `NavigationService` expone `routeObserver`. Al contrario que el código del plan, `ForestPage` lo recibe **por constructor**: se lo pasa `ContainerAppBloc` y la página ya no lee `locator`. Así se cumple la convención de que sólo se usa `locator` en `BlocProvider.create`.
  - **Panel de victoria sin botón.**
  - **Decisiones provisionales**, a revisar en la fase de pruebas de la arena: el `RouteObserver`, los luchadores sólo con hacha, el panel de victoria sin botón y el umbral de color ámbar (×1,25).
  - **Añadidos de la revisión final:**
    - el candado de nivel bloqueado es un SVG propio (`lock.svg`, `CustomIcons.lock`), no `Icons.lock`;
    - `ArenaInProgress` y `ArenaFailure` se emiten sin los efectos anteriores (si no, al reiniciar se repetían);
    - hay un test del tono `PowerTone.even`;
    - la escena tiene un único método para quitar un luchador y una única clave (`FighterRenderData.keyOf`).
  - **HUD con cuatro botones (README 3.2):** a 640 × 360 los cuatro botones (*Misiones*, *Construir*, *Héroe*, *Arena*) no caben junto a la `ResourceBar`. Con la fuente real se solapan unos 200 px; ya con los tres botones de C3 se solapaban unos 80 px. Agrupar *Arena* y *Héroe* no bastaba. Se decide que, por debajo de `HudOverlay.buttonsBelowWidth = 920` px, la fila de botones baje a una segunda línea bajo la `ResourceBar`, alineada a la derecha. En pantallas anchas todo sigue en una línea. Los menús *Misiones* y *Construir* se desplazan, igual que el panel *Héroe*, si no caben de alto. **Aviso para la aldea (F5, F9…):** cada recurso o herramienta nueva ensancha la barra unos 90 px. Los tests de 919 y 920 px (con `HudDataMock.withEveryResourceAndTool`) fallarán entonces, y habrá que volver a medir el umbral.
  - **Pendiente para F2 (guardado):** `ArenaBloc._emitReplay` llama a `GetArenaUseCase` sin `try/catch`. Hoy no puede fallar, porque a la arena sólo se entra con una partida en marcha. Si F2 introduce errores de almacenamiento, hay que capturarlos ahí.
- **C3 (2026-10-07):**
  - **Ramas:** TC3.1 y TC3.4 se hicieron en la rama de fase. TC3.2 y TC3.3 se hicieron a la vez, cada una en su worktree, y se unieron sin conflictos.
  - **Test del fantasma de F0:** ya existe (`testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced`). F6 ya no tiene que añadirlo.
  - **Añadidos de la revisión final:**
    - en `CREDITS.md`, la chimenea apunta a la sección de arriba (el plan decía "below");
    - las estadísticas del panel *Héroe* se leen una sola vez con lector de pantalla (`excludeSemantics`);
    - hay tests del BLoC para `notEnoughResources` y para que saltarse un nivel no emita el efecto de compra.
  - **Sin oro en el juego hasta C2:** con C3 sola no hay forma de ganar oro. La compra se prueba a mano con las dos fases juntas.
  - **Aviso para C5:** `HeroPanel(sections:)` ya pinta pestañas. Falta pasar `sections` desde `HudOverlay`, y añadir un `assert(sections.isNotEmpty)` y el reinicio de `_section` en `didUpdateWidget`.
- **C4 (2026-10-08):**
  - **Ramas:** TC4.1 (`-c4-art`) y TC4.2 (`-c4-levels`) se hicieron a la vez, cada una en su worktree, y se unieron en `feature/PROJECT-X-c4-beasts` sin conflictos. TC4.3 (`-c4-leap`) se hizo encima.
  - **Sin PR a la rama de integración:** la fase se unió a `feature/PROJECT-X-arena` con `git merge --no-ff` (`[PROJECT-X]: Merge the C4 beasts phase into the arena`), no con una PR como C0–C3. Por eso sus issues (#37, #48, #49) se cierran a mano.
  - **Licencias:** el oso es CC-BY 4.0 (también CC0 según su autor) y el lobo OGA-BY 3.0 / CC-BY 3.0-4.0 / GPL. Se acepta CC-BY, que sólo pide atribución; `CREDITS.md` lo dice en la cabecera y `CLAUDE.md` en *Constraints*.
- **C5 (2026-10-08, unida a la arena el 2026-10-09):**
  - **Ramas:** TC5.1, TC5.4 y TC5.5 en la rama de fase; TC5.2 (`-c5-skills-domain`) y TC5.3 (`-c5-skills-tab`) a la vez, cada una en su worktree, unidas sin conflictos.
  - **Sin PR a la rama de integración:** como C4, se unió con `git merge --no-ff` (`[PROJECT-X]: Merge the C5 mage tower phase into the arena`). Llegó segunda y resolvió los cruces con C4: sólo dos conflictos, los dos aditivos (`CLAUDE.md`, línea de `rules/`: catálogos de C5 más la regla de desbloqueo de C4; `hero_entity_mock.dart`: mocks de las dos fases). Los atlas se regeneraron con `build_assets.py` y salen idénticos. Ningún sitio de C4 usaba `arenaDodge`.
  - **Verificación tras la unión:** `build_runner` sin cambios, `flutter analyze` limpio, `flutter test` con 612 tests en verde (597 de C5 + 15 de C4) y los tests de Chrome en verde.
- **C6 (2026-10-09):**
  - **Ramas:** las cuatro tareas se hicieron una detrás de otra directamente en `feature/PROJECT-C6-barbarians` (con subagentes, una revisión por tarea y una revisión final), sin las ramas ni los worktrees por tarea del plan (`-c6-art`, `-c6-champion`).
  - **Arma:** los bárbaros y el jefe pelean con el hacha de siempre, no con hacha de guerra o maza como pedía la ficha: esas armas de LPC sólo existen en hojas de 192 px sin reposo. Elegido por el usuario; queda para el pulido (ARENA-FIXES §1.3).
  - **Arte elegido por el usuario** sobre una vista previa: armadura de cuero, barba larga y casco bárbaro; el jefe con casco vikingo, barba negra y pantalón rojo. Capas del generador LPC fijadas a un commit, con sha256 (`CREDITS-barbarians.txt`).
  - **Revisión final:** sin fallos de código; se arreglaron dos detalles de redacción de `CLAUDE.md`. Cerrar la arena a mitad de la reproducción de la primera victoria sobre el jefe se salta el confeti y el título (la insignia sí sale en el bosque): se deja así, como el resto de la arena (la pelea ya está pagada).
  - **Prueba manual (2026-10-09):** en Chrome y en el emulador Android, con un héroe de prueba sólo en local y un guion que recorre los niveles de bárbaros, la pelea contra el jefe, la repetición y la vuelta al bosque. Todo correcto: el jefe se distingue bien del bárbaro (más grande, barba negra, casco vikingo), el anillo pasa al siguiente guardia cuando cae el jefe, el confeti y el panel *¡Campeón de la arena!* (+100) salen la primera vez, la repetición da *¡Victoria!* (+33) sin confeti, y la insignia cabe en el panel *Héroe* también a 844 px. El confeti es discreto (24 chispas pequeñas). iOS no se probó por decisión del usuario (se comporta como Android).
