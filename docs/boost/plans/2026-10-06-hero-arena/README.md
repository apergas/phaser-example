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
- A diferencia del plan de la aldea, **este plan sí puede traer arte LPC nuevo** (animales, ropa de bárbaro, espadas), siempre en `asset-packs/lpc/sources/`, procesado por `build_assets.py` y acreditado en `lib/core/assets/images/lpc/CREDITS.md`. Una pieza sin licencia compatible (CC-BY-SA 3.0, GPL 3.0, OGA-BY 3.0) no entra.
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
- ✅ fase terminada.
- 🟢 plan detallado listo para ejecutar.
- 📝 ficha: hay que escribir su plan detallado con `boost:writing-plans` al empezar la fase.

| Fase | Plan | Flujo | Depende de | Qué añade |
|---|---|---|---|---|
| **C0** Contrato común: oro y héroe | ✅ [C0-contract.md](C0-contract.md) | Común | F0 | `Resource.gold` en el HUD; `World.funds` / `earn` / `spend`; `HeroEntity` dentro del `World`; entidades de combate (`CombatStatsEntity`, `EnemyEntity`, `ArenaLevelEntity`, `FightLogEntity`); catálogo `Gear`; `HeroRules.stats` / `power`; `GetHeroStatusUseCase`. **Sin jugabilidad nueva** salvo el oro (a 0) en el HUD. |
| **C1** Motor de combate y niveles | ✅ [C1-combat-engine.md](C1-combat-engine.md) | C | C0 | `Combat.resolve`, `ArenaLevels` con los niveles de humanos, `GetArenaUseCase`, `StartFightUseCase`: pelear, cobrar y desbloquear. Sólo dominio. |
| **C2** Pantalla de la arena | 📝 [C2-arena-screen.md](C2-arena-screen.md) | C | C0 (C1 para pelear de verdad) | `ArenaPage` + `ArenaBloc` + escena Flame que reproduce el `FightLogEntity`; botón *Arena* en el HUD del bosque; bandidos con el arte del héroe recoloreado. |
| **C3** Herrería y Armería | 📝 [C3-forge-armory.md](C3-forge-armory.md) | D | C0 | Dos edificios nuevos; comprar armas y armaduras (`BuyGearUseCase`); panel *Héroe* en el HUD del bosque con Poder, atributos y equipo. |
| **C4** Lobos y oso | 📝 [C4-beasts.md](C4-beasts.md) | C | C2 | Arte LPC nuevo de animales; `EnemyKind.wolf` / `bear`; niveles 2, 4, 5 y 8. |
| **C5** Torre de magia y habilidades | 📝 [C5-mage-tower.md](C5-mage-tower.md) | D | C3 | Edificio *Torre de magia*; catálogo `Skills`; `LearnSkillUseCase`; pestaña *Habilidades* del panel *Héroe*. Los efectos en la pelea ya los aplica el motor de C1. |
| **C6** Bárbaros y jefe | 📝 [C6-barbarians.md](C6-barbarians.md) | C | C4 | Arte de bárbaros y jefe; peleas de grupo bien colocadas (hasta 3 enemigos); pantalla de victoria final. |
| **C7** Misiones del héroe y equilibrado | 📝 [C7-hero-quests-balance.md](C7-hero-quests-balance.md) | D | C1, C3, C5 | Línea de misiones *Héroe*; consejo tras una derrota; test de equilibrado (Poder contra porcentaje de victorias) y números finales. |

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
  - **Ramas:** las dos tareas se hicieron en una sola rama de fase, `feature/PROJECT-X-c0-contract`, sin ramas ni PR por tarea (como F0). El tracker de GitHub todavía no existe.
  - **`ArenaLevelEntity` sin `assert` de 1 a 3 enemigos:** Dart no permite `List.length` en un constructor `const`. Lo cubre el test del catálogo de C1 (`arena_levels_test.dart`).
  - **El HUD ya lista el oro ("Oro 0"):** `forest_bloc_test.dart` espera madera y oro, y hay un `ResourceItemDataMock.gold` nuevo.
  - **Añadidos de la revisión final:**
    - `Gear.of` lanza `StateError` si el nivel no existe, en lugar de un `!`;
    - `FightTurnEntity` comprueba `round >= 1` y que los índices no sean negativos;
    - tests para el Poder con habilidades en `GetHeroStatusUseCase`, para el pago atómico (un recurso basta y otro no) y para que `earn` ignore cantidades negativas;
    - `CLAUDE.md` aclara que `earn` / `spend` son la vía de pago del héroe y de la arena, y que la aldea sigue usando el inventario hasta F6.
- **C1 (2026-10-07):**
  - **Ramas:** una rama de fase, `feature/PROJECT-X-c1-combat-engine`, que sale de la de C0 porque C0 aún no estaba en `develop`. TC1.1 y TC1.2 se hicieron a la vez, cada una en su propio worktree y su propia rama, y luego se unieron en la de la fase. Al unirlas solo hubo conflictos aditivos (constantes al final de `rules.dart` y entradas nuevas en `arena_level_entity_mock.dart`). TC1.3 se hizo encima.
  - **Añadidos de la revisión final:**
    - el test de la esquiva comprueba que el turno conserva la vida del héroe;
    - el test de flujo calcula la recompensa repetida a partir del catálogo;
    - `CLAUDE.md` aclara que la semilla la pasa `StartFightUseCase`.
  - **Aviso para C7 (y C4, si toca el primer nivel):** tres tests de casos de uso comparan el primer nivel del catálogo con mocks (`ArenaLevelEntityMock.banditRookie`, `FightResultEntityMock.victoryOverBandit`, `ArenaLevelStatusEntityMock.rookieForNewHero`). Si se cambia ese nivel, hay que actualizar esos mocks. Los tests del motor usan sus propios mocks y no dependen del catálogo.
