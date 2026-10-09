# C5 · Torre de magia y habilidades — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | D (héroe) |
| **Depende de** | C3 (panel *Héroe*). Los efectos en la pelea ya los aplica el motor de C1, que también está en `feature/PROJECT-X-arena`. |
| **Issue / milestone** | `phase:C5` · `stream:D` · milestone `C5 Mage tower` (un issue por tarea: TC5.1, TC5.2, TC5.3, TC5.4, TC5.5) |

**Goal:** Un tercer edificio de mejora, la *Torre de magia*, que no da números sino **comportamientos**: en ella se aprenden con oro *Golpe doble*, *Esquiva* y *Segundo aliento*, cada una con un 10 % más de Poder. Se aprenden en una pestaña nueva, *Habilidades*, del panel *Héroe*, y en la arena se ve el nombre de la habilidad cuando salta.

**Architecture:**
- **Edificio:** `BlueprintId.mageTower` al final del enum y `Blueprints.mageTower` al final de `Blueprints.all` (30 de madera y 40 de oro, 12 martillazos, huella de la casa). Sigue la receta de `CLAUDE.md` (*New resource, tool or building*): textos, `SpriteNames`, frame del atlas con `build_assets.py` y `RenderConstants.buildingFrontOffset`.
- **Aprender (dominio):**
  - `SkillEntity` y `SkillOptionEntity` en `entities/hero/`; catálogo `Skills` en `rules/skills.dart` (`all`, `byId`, `building`).
  - `LearnSkillUseCase` comprueba la Torre terminada (`BuildingListRules.hasComplete`, de C3), que la habilidad no se sepa ya y los fondos, **en ese orden**; paga con `World.spend` y la añade con `World.updateHero`.
  - `GetSkillOptionsUseCase` devuelve un `SkillOptionEntity` por habilidad, en el orden de `Skills.all`.
- **Presentación (bosque):**
  - `HeroPanelData.skills: List<SkillItemData>`; `HeroPanel` pinta la pestaña *Habilidades* con una `SkillTile` por habilidad. `HudOverlay` le pasa siempre `HeroPanelSection.values`.
  - Evento `ForestSkillLearnRequested(skill)`, efecto `SkillLearnedEffect` (el destello de C3, en azul: `ParticleKind.magicSparkle`) y *snackbar* "Has aprendido: Golpe doble".
- **Presentación (arena):** `SkillUsedEffect` tras los turnos `doubleStrike` y `secondWind`; la escena hace flotar "¡Golpe doble!" / "¡Segundo aliento!" sobre el héroe. "¡Esquiva!" pasa a salir del mismo texto (`Internationalize.arenaSkillUsed`).
- Sin cambios en `World`, `WorldState`, `HeroEntity`, `HeroRules` ni `Combat` (C0 ya tiene `skills`, `funds`, `spend`, `updateHero` y `Rules.powerPerSkill`; C1 ya aplica las tres habilidades).

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame, `injectable`, `easy_localization`; tests con `flutter_test`, `mockito`, `bloc_test`, `flame_test`; arte con `asset-packs/lpc/build_assets.py` (Pillow).

**Precondición: C0–C3 fusionadas en `feature/PROJECT-X-arena`.** Este plan usa estos nombres. Antes de empezar, comprueba que siguen igual:
- `SkillId { doubleStrike, secondWind, dodge }`, `Resource { wood, gold }` (sin piedra: F5 no está), `BlueprintId { house, forge, armory }`, `HeroPanelSection { gear, skills }`, `ParticleKind { woodChip, dust, sparkle, bloodDrop }`, `FightAction { hit, doubleStrike, dodge, secondWind }`;
- `HeroEntity.skills` (`Set<SkillId>`), `HeroRules.power` (con `Rules.powerPerSkill = 0.1`), `World.funds` / `spend` / `updateHero` / `buildings`, `BuildingListRules.hasComplete`, `InventoryRules.missing`, `GetHeroStatusUseCase`;
- `HeroPanel({hero, onBuy, sections})` con el caso `HeroPanelSection.skills => const SizedBox.shrink()`, `HudOverlay({hud, onBuildSelected, onGearSelected, onArenaPressed})`, `ForestBloc` con `buyGearUseCase` como último caso de uso antes de `navigationService`;
- `ParticleBursts.sparkles({feet, random})`, `ForestSceneComponent._onGearPurchased`;
- `ArenaBloc._effectFor`, `ArenaSceneComponent._float`, `Internationalize.arenaDodge` ("¡Esquiva!");
- mocks `HeroEntityMock`, `WorldMock.withHero` / `advanceFor`, `FundsMock`, `GameSessionEntityMock.playing`, `HeroPanelDataMock.newHero` / `newHeroCopy` / `readyToBuySword`, `ArenaBlocMock`, `ArenaEffectMock`, `ArenaDataMock.replaying`.

Si algo ha cambiado, adapta los fragmentos y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- `flutter test` en verde, en especial:
  - `blueprints_test.dart` (la Torre) y `skills_test.dart` (el catálogo cubre todo `SkillId`);
  - `learn_skill_use_case_test.dart` (cada `LearnSkillResult` y el orden de las comprobaciones);
  - `get_skill_options_use_case_test.dart` y `skill_flow_test.dart` (construir la Torre con los casos de uso reales, cobrar 60 de oro con `world.earn` y aprender *Golpe doble*: Poder de 31 a 34);
  - `forest_bloc_skill_test.dart` (pestaña, aprender, efecto y mensajes);
  - `hero_panel_test.dart` (pestaña), `skill_tile_test.dart`, `hud_overlay_test.dart`, `forest_page_test.dart`;
  - `arena_bloc_test.dart` y `arena_scene_component_test.dart` (nombres de las habilidades en la arena).
- Prueba manual en Chrome, el emulador Android y el simulador iOS (sección *Prueba manual*).

**Cómo se ha comprobado este plan:** todo el código y los tests de las cinco tareas se aplicaron, tal cual están aquí, sobre una copia de `feature/PROJECT-X-arena` (`e182aae`, con C0–C3 y `develop` unidas):
- `build_assets.py`: los frames `house`, `forge` y `armory` salen idénticos píxel a píxel (y con el mismo pivote); el nuevo `mage-tower` mide 120 × 240;
- `build_runner`: `di.config.dart` sólo registra `LearnSkillUseCase` y `GetSkillOptionsUseCase`; una segunda pasada no cambia nada;
- `flutter analyze` → `No issues found!`;
- `flutter test` → **597 tests** en verde (552 antes de C5: TC5.1 +2, TC5.2 +18, TC5.3 +10, TC5.4 +11, TC5.5 +4);
- `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart` → 40 tests en verde;
- las tareas paralelas por separado: TC5.1 + TC5.3 sin TC5.2, y TC5.1 + TC5.2 sin los modelos, widgets y tests de TC5.3, también pasan `analyze` y `flutter test`.

Los fragmentos de este documento son esos ficheros, ya pasados por `dart format --line-length 120`.

> **Coordinación C4 ↔ C5:** C4 (lobos y oso, flujo C) se hace a la vez. TC5.5 toca ficheros de la arena que C4 también puede tocar (`arena_bloc.dart`, `arena_scene_component.dart`, `arena_effect.dart`, `arena_render_constants.dart`, `es.json`, `internationalize.dart`, `internationalize_test.dart`, `arena_effect_mock.dart`, `arena_data_mock.dart`) y las dos regeneran atlas con `build_assets.py` (C4 `arena.*`, C5 `forest.*`). Todos los cambios son aditivos salvo uno: C5 **sustituye** `arenaDodge` / `arena.dodge` por `arenaSkillUsed` / `arena.skillUsed` (decisión 14). La fase que llegue segunda a `feature/PROJECT-X-arena` resuelve los conflictos (siempre al final del bloque, `switch` en orden de declaración) y **regenera** los atlas en lugar de resolverlos a mano. Si C4 usa `arenaDodge` en algún sitio nuevo, se cambia por `arenaSkillUsed(id: SkillId.dodge)`.

## Decisiones del plan

Lo que este plan fija o añade sobre la ficha (todo lo demás de la ficha se mantiene tal cual):

1. **Costes sin piedra.** En `feature/PROJECT-X-arena` (y en `develop`) todavía no está F5: `Resource` es `{ wood, gold }`. La Torre cuesta 30 de madera y 40 de oro; los 10 de piedra los añade la fase que llegue segunda (README 3.2; ver *Al cerrar C5*). Las habilidades cuestan sólo oro, como pide la ficha (y en línea con el punto 2 de `ARENA-FIXES.md`).
2. **Edificio:** `footprintRadius: 40` (la huella de la casa), 12 martillazos y `RenderConstants.buildingFrontOffset = 24`: el muro y la puerta tienen la altura de los de la casa y el pivote está abajo en el centro, así que el frente queda igual; el tejado más alto sólo alarga el frame por arriba.
3. **Arte, comprobado con el script** (provisional: es la primera propuesta visual; se revisa en la prueba manual):
   - Frame **`mage-tower`** (no `mageTower`, como decía la ficha): los nombres de frame del atlas van en *kebab-case* (`axe-pickup`, `tree-*`, `decor-*`).
   - Muro de piedra con riostras diagonales largas de `cottage.png` (`(96, 256, 192, 352)`), distinto del de la Herrería (`(0, 256, 96, 352)`); puerta de la casa.
   - Tejado de paja recoloreado **violeta** (`MAGE_TOWER_ROOF`, rampa de 9 colores como `FORGE_ROOF` / `ARMORY_ROOF`) y **un 40 % más alto**: se estira en vertical con `Image.NEAREST` (`MAGE_TOWER_ROOF_STRETCH = 1.4`), como una aguja. Frame de 120 × 240 (la casa mide 120 × 191).
   - `build_cottage()` gana un parámetro `roof_stretch` (por defecto 1). Con 1 no se toca el tejado, así que `house`, `forge` y `armory` salen idénticos (comprobado).
   - No entra ninguna fuente nueva: `CREDITS.md` sólo amplía la sección de la casa.
4. **Catálogo `Skills`** (`rules/skills.dart`):
   - Orden de `Skills.all` por precio: *Golpe doble* (60), *Esquiva* (90), *Segundo aliento* (130), el de la tabla de la ficha, **no** el de declaración de `SkillId` (`doubleStrike, secondWind, dodge`). Así la pestaña va de la más barata a la más cara (provisional). El test comprueba que cada `SkillId` aparece una vez.
   - `Skills.building = BlueprintId.mageTower` dice dónde se aprenden (como `Gear.workshopFor`).
   - `Skills.byId(id)`: `firstWhere` sobre `all`.
5. **Entidades** en `entities/hero/` (como dice la ficha), con las reglas de entidad (`copyWith`, `==`/`hashCode` a mano):
   - `SkillEntity { SkillId id; Map<Resource, int> cost; }`;
   - `SkillOptionEntity { SkillEntity skill; SkillOptionState state; Map<Resource, int> missing; }` con el getter `canLearn` (`state == available`).
6. **Orden de `LearnSkillResult`:** `missingBuilding` → `alreadyKnown` → `notEnoughResources` → `ok`. Por eso, sin Torre, aprender una habilidad que ya se sabe devuelve `missingBuilding`. Pagar y aprender usan la línea de la ficha, `world.updateHero((hero) => hero.copyWith(skills: {...hero.skills, id}))`, sin extensión nueva: `hero_rules.dart` es de C0 y la operación es una sola línea. "Torre terminada" es `world.buildings.hasComplete(Skills.building)`: una Torre a medio construir no enseña nada.
7. **`GetSkillOptionsUseCase`:** una opción por habilidad de `Skills.all`.
   - `known` si el héroe ya la sabe, con `missing: {}`;
   - si no: `needsBuilding` sin la Torre terminada; si no, `unaffordable` si `world.funds.missing(cost)` no está vacío; si no, `available`.
   - `missing` se calcula para toda habilidad no aprendida (también con `needsBuilding`), como `GearOptionEntity`. Así C7 puede usarlo sin tocar el caso de uso.
8. **Pestaña *Habilidades*** (avisos de C3 en la sección 5 del README):
   - `HudOverlay` pasa siempre `sections: HeroPanelSection.values`: con C5 el panel *Héroe* siempre tiene las pestañas *Equipo* y *Habilidades*.
   - `HeroPanel` gana `onLearn` **opcional** (`ValueChanged<SkillId>?`). Sin él, los botones *Aprender* salen desactivados. Así TC5.3 no necesita tocar `HudOverlay`, que es de TC5.4.
   - `assert(sections.length > 0)` en el constructor. El aviso de C3 decía `isNotEmpty`, pero el analizador lo rechaza en el `assert` de un constructor `const` (`invalid_constant`); `length > 0` sí se acepta mientras nadie cree el panel con `const` (nadie lo hace: sus datos no son constantes).
   - `didUpdateWidget` vuelve a la primera pestaña si la abierta ya no está en `sections`.
   - Cada `SkillTile`: nombre, descripción corta, coste ("60 de oro"), motivo en color de aviso ("Construye la Torre de magia", "Faltan 30 de oro") y botón *Aprender*, desactivado si `canLearn` es `false`. Una habilidad aprendida dice "Aprendida" en verde, sin coste ni botón.
   - La pestaña no añade una línea propia: "Construye la Torre de magia" sale en cada habilidad, igual que "Construye la Herrería" en el equipo.
   - Ancho y alto los de C3 (260–360; alto de la pantalla menos 96, con scroll). En el HUD estrecho de C2 (botones bajo la `ResourceBar` por debajo de 920 px), el panel se desplaza; hay test de 640 × 360 con la pestaña abierta.
9. **`HeroPanelData.skills`** tiene valor por defecto `const []`, para que TC5.3 no dependa del BLoC. TC5.4 lo rellena, y es entonces cuando `HeroPanelDataMock.newHero` / `newHeroCopy` / `readyToBuySword` ganan `skills: SkillItemDataMock.withoutTower` (antes, los tests del BLoC de C3 compararían con un panel sin habilidades y fallarían).
10. **Textos** (`es.json`):
    - `forest.blueprint.mageTower` "Torre de magia";
    - `forest.skill.<SkillId>.name` / `.description`: "Golpe doble" / "Cada tercer ataque golpea dos veces.", "Segundo aliento" / "Una vez por pelea, por debajo del 30 % de vida recupera el 40 %.", "Esquiva" / "Un 20 % de posibilidades de esquivar cada golpe.";
    - `forest.hero.learn` "Aprender", `forest.hero.known` "Aprendida"; "Construye la Torre de magia" reutiliza `forest.hero.needsBuilding`;
    - `forest.message.skillLearned` "Has aprendido: {name}", `forest.message.skillAlreadyKnown` "Ya conoces esa habilidad.";
    - `arena.skillUsed` "¡{name}!" (sustituye a `arena.dodge`, decisión 14).
11. **Si aprender falla desde el BLoC** (no debería, el botón está desactivado; pero el evento se puede lanzar igualmente):
    - `missingBuilding` → *snackbar* "Construye la Torre de magia";
    - `alreadyKnown` → "Ya conoces esa habilidad.";
    - `notEnoughResources` → "No tienes recursos suficientes." (el texto que ya existe).
    Aprender **no** cierra el panel, para ver cómo sube el Poder.
12. **Destello azul:**
    - `ParticleKind.magicSparkle` al final del enum; `ParticleBursts.sparkles` gana `kind` (por defecto `sparkle`): la misma ráfaga de C3 (10 cuadraditos que suben desde el pecho, 0,6 s), sólo cambia el color (`ParticleBurstComponent.magicSparkleColor = 0xFF8FC8FF`).
    - `ForestSceneComponent._onGearPurchased` pasa a `_sparkleOnPlayer(ParticleKind kind)`, que usan los dos efectos.
    - `SkillLearnedEffect(skill: SkillId)` lleva la habilidad, por si C7 quiere variarlo.
13. **Evento `ForestSkillLearnRequested({required SkillId skill})`.** La ficha lo escribía `(id)`; el campo se llama `skill`, como `ForestGearPurchaseRequested(gear:)` y el efecto.
14. **Nombres en la arena.** C2 ya hacía flotar "¡Esquiva!" (`arena.dodge`) en las esquivas, pero nada en los turnos `doubleStrike` (sólo "−N" sobre el enemigo) ni `secondWind` (sólo "+N").
    - `Internationalize.arenaSkillUsed(id:)` ("¡{name}!" con `forestSkillName`) sustituye a `arenaDodge`; el texto de la esquiva no cambia.
    - `SkillUsedEffect(skill)` (al final de `arena_effect.dart`) se emite justo **después** del efecto del turno en los turnos `doubleStrike` y `secondWind`. La esquiva ya tiene su `DodgeEffect`.
    - La escena hace flotar el nombre sobre el héroe, 12 px por encima de su `headPoint` (`ArenaRenderConstants.skillNameLift`), para no tapar el "+12" del segundo aliento.
    - Índices de los tests de C2: no cambian; en la pelea del segundo aliento, el `SkillUsedEffect` es el `[11]`, justo después del `HealEffect` del `[10]` (comprobado).
15. **Tests del BLoC en un fichero propio**, `forest_bloc_skill_test.dart` (como `forest_bloc_hero_test.dart`). Usan los casos de uso reales sobre `MockGameSessionRepository` y sólo `MockNavigationService` (E11).
16. **Mundos de prueba con la Torre terminada:** `SkillScenarioMock` (`test/mocks/domain/game/`) la construye con la API real (`earn` del coste → `orderConstruction` → `advanceFor(10000)`), como `GearScenarioMock`. Con `PlayerEntityMock.mock`, 10 s bastan para llegar y dar los 12 martillazos (12 × 650 ms; comprobado).
17. **Persistencia:** `HeroEntity.skills` ya existe (C0) y no cambia. F2 no está en la rama de la arena; cuando llegue, el `HeroDBO` debe guardar `skills` y el mapper de edificios aceptar `mageTower` (README 3.0 y 3.2). TC5.1 lo comprueba con un `grep`.
18. **Botones del HUD:** C5 no añade botón (la Torre se usa desde la pestaña del panel *Héroe*), así que no hay que volver a medir la barra (README 3.2).
19. **`ARENA-FIXES.md` no se implementa** (sus puntos 2 y 4 pasan a C7). Nada de este plan lo contradice: las habilidades sólo cuestan oro (punto 2), el daño por rangos (punto 4) no toca las habilidades (el Poder sigue siendo `stats.power` × 1,1 por habilidad), y el punto 5 (botones a la izquierda) sólo mueve el `Align` de `HudOverlay`, no el interior del panel.

## Reparto

| Tarea | Capa | Depende de | Paralelizable |
|---|---|---|---|
| TC5.1 Torre de magia construible | core (enum, textos) + domain (`Blueprints`) + presentación (`SpriteNames`, `RenderConstants`) + arte | C3 | No: va primero (las demás usan `BlueprintId.mageTower`) |
| TC5.2 Aprender habilidades (dominio) | core (enums) + domain (entidades, `Skills`, casos de uso) + DI | TC5.1 | Sí, con TC5.3 (no comparten ficheros) |
| TC5.3 Pestaña *Habilidades* (widgets) | core (textos) + presentación (`SkillItemData`, `HeroPanelData`, `SkillTile`, `HeroPanel`) | TC5.1 | Sí, con TC5.2 |
| TC5.4 Integración en el bosque | presentación (BLoC, `HudOverlay`, efecto, partículas, página) + `CLAUDE.md` | TC5.2, TC5.3 | No |
| TC5.5 Nombres de las habilidades en la arena | core (textos) + presentación de la arena + `CLAUDE.md` | TC5.4 (usa `forestSkillName` de TC5.3 y `HeroEntityMock.withDoubleStrike` de TC5.2) | No: las dos últimas tocan líneas vecinas de `CLAUDE.md` |

**Ramas (README 3.0):**
- Rama de fase `feature/PROJECT-X-c5-mage-tower`, que sale de `feature/PROJECT-X-arena`. Su PR va a `feature/PROJECT-X-arena` (la abre el usuario al final, *Al cerrar C5*).
- TC5.1, TC5.4 y TC5.5 se hacen directamente en la rama de fase.
- TC5.2 y TC5.3, si se hacen a la vez, van cada una en su propio *worktree* y su propia rama, las dos desde la rama de fase con TC5.1 ya hecha:
  - `feature/PROJECT-X-c5-skills-domain`;
  - `feature/PROJECT-X-c5-skills-tab`.

  Después se unen en la rama de fase con `git merge --no-ff` (como en C3). Si las hace una sola persona, van seguidas en la rama de fase.
- Commits `[PROJECT-X]: Imperative description`, sin ninguna atribución a IA. `CLAUDE.md` se añade con un `git add` aparte.
- Sin `push` ni PR durante la implementación.

**Ficheros compartidos:**
- TC5.2 y TC5.3 no comparten ficheros, así que se unen sin conflictos.
- Con C4 (a la vez, flujo C): ver *Coordinación C4 ↔ C5* arriba.
- Ficheros calientes que toca C5, todos con cambios **aditivos** (al final del bloque; casos de `switch` en orden de declaración): `blueprint_id.dart`, `blueprints.dart`, `particle_kind.dart`, `build_assets.py`, `forest.{png,json}` (regenerados), `forest_bloc.dart`, `forest_event.dart`, `forest_effect.dart`, `forest_page.dart`, `hud_overlay.dart`, `internationalize.dart`, `es.json`, `di.config.dart` (generado), `forest_bloc_mock.dart`, `hud_data_mock.dart`, `hero_entity_mock.dart`, `funds_mock.dart`.

---

### Task TC5.1: Torre de magia construible

**Files:**
- Modify:
  - `lib/core/config/constants/enum/blueprint_id.dart`
  - `lib/layers/domain/rules/blueprints.dart`
  - `lib/core/assets/i18n/internationalize.dart`, `lib/core/assets/i18n/translations/es.json`
  - `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`
  - `lib/layers/presentation/features/forest/game/render/render_constants.dart`
  - `asset-packs/lpc/build_assets.py`
  - `lib/core/assets/images/lpc/forest.png`, `forest.json` (generados), `lib/core/assets/images/lpc/CREDITS.md`
  - Tests:
    - `test/layers/domain/rules/blueprints_test.dart`
    - `test/layers/domain/use-cases/game/get_build_options_use_case_test.dart`
    - `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart` (una expectativa)
    - `test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`
    - `test/core/assets/i18n/internationalize_test.dart`
  - Mocks:
    - `test/mocks/domain/entities/building/blueprint_entity_mock.dart`
    - `test/mocks/domain/entities/game/build_option_entity_mock.dart`
    - `test/mocks/presentation/features/forest/build_item_data_mock.dart`

**Interfaces:**
- Consumes: `BlueprintEntity`, `Blueprints`, `SpriteNames.building`, `RenderConstants.buildingFrontOffset`, `Internationalize.forestBlueprint`, `build_cottage()` / `recolour()` / `ROOF_RAMP` de `build_assets.py` (C3).
- Produces:
  ```dart
  // lib/core/config/constants/enum/blueprint_id.dart
  enum BlueprintId { house, forge, armory, mageTower }

  // lib/layers/domain/rules/blueprints.dart
  static const BlueprintEntity mageTower;  // 30 de madera y 40 de oro, 12 martillazos, radio 40
  static const List<BlueprintEntity> all = [house, forge, armory, mageTower];

  // SpriteNames.building: mageTower → 'mage-tower'
  // RenderConstants.buildingFrontOffset: mageTower → 24
  // Internationalize.forestBlueprint: mageTower → "Torre de magia"

  // mocks nuevos
  BlueprintEntityMock.mageTower
  BuildOptionEntityMock.mageTower({required int missingWood})          // le faltan además los 40 de oro
  BuildItemDataMock.mageTowerUnaffordable({required int missingWood})
  ```

- [x] **Step 1: Crear la rama de fase**

```bash
git switch feature/PROJECT-X-arena && git pull && git switch -c feature/PROJECT-X-c5-mage-tower
```

- [x] **Step 2: Ampliar los datos de prueba**

`test/mocks/domain/entities/building/blueprint_entity_mock.dart`, al final de la clase:

```dart
  static const BlueprintEntity mageTower = BlueprintEntity(
    id: BlueprintId.mageTower,
    cost: {Resource.wood: 30, Resource.gold: 40},
    hitsToBuild: 12,
    footprintRadius: 40,
  );
```

`test/mocks/domain/entities/game/build_option_entity_mock.dart`, al final de la clase. Los mundos de estos tests no tienen oro, así que faltan siempre los 40:

```dart
  static BuildOptionEntity mageTower({required int missingWood}) => BuildOptionEntity(
    blueprint: BlueprintId.mageTower,
    cost: const {Resource.wood: 30, Resource.gold: 40},
    missing: {Resource.wood: missingWood, Resource.gold: 40},
  );
```

`test/mocks/presentation/features/forest/build_item_data_mock.dart`, al final de la clase. Los costes se escriben como los forma el BLoC (`_amounts`: por orden de `Resource`, separados por coma):

```dart
  static BuildItemData mageTowerUnaffordable({required int missingWood}) => BuildItemData(
    blueprint: BlueprintId.mageTower,
    name: Internationalize.forestBlueprint(id: BlueprintId.mageTower),
    costText: [
      Internationalize.forestAmount(resource: Resource.wood, amount: 30),
      Internationalize.forestAmount(resource: Resource.gold, amount: 40),
    ].join(', '),
    missingText: Internationalize.forestMissing(
      amounts: [
        Internationalize.forestAmount(resource: Resource.wood, amount: missingWood),
        Internationalize.forestAmount(resource: Resource.gold, amount: 40),
      ].join(', '),
    ),
    isEnabled: false,
  );
```

`BuildItemDataMock.everyBlueprintUnaffordable` (C2) recorre `BlueprintId.values` y ya incluye la Torre; no hay que tocarlo.

- [x] **Step 3: Escribir los tests que fallan**

`test/layers/domain/rules/blueprints_test.dart`, antes de `testWhenListingBlueprintsThenEveryIdAppearsOnceInDeclarationOrder`:

```dart
  test('testWhenAskingForTheMageTowerThenItCostsWoodAndGoldAndTakesTwelveHits', () {
    // given
    const id = BlueprintId.mageTower;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(blueprint, BlueprintEntityMock.mageTower);
  });
```

`test/layers/domain/use-cases/game/get_build_options_use_case_test.dart`: en cada una de las tres expectativas, una línea más al final de la lista (las opciones salen en el orden de `Blueprints.all`):

```dart
    // testWhenResourcesAreNotEnoughThenHouseIsNotAffordable (10 de madera)
      BuildOptionEntityMock.mageTower(missingWood: 20),

    // testWhenWoodEqualsTheCostThenHouseIsAffordable (15 de madera)
      BuildOptionEntityMock.mageTower(missingWood: 15),

    // testWhenWoodExceedsTheCostThenHouseIsAffordable (17 de madera)
      BuildOptionEntityMock.mageTower(missingWood: 13),
```

`test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`, en `testWhenResourcesAreNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace`:

```dart
      expect(bloc.state.data.hud!.buildItems, [
        BuildItemDataMock.makeUnaffordable(missingWood: 5),
        BuildItemDataMock.workshopUnaffordable(BlueprintId.forge, missingWood: 15),
        BuildItemDataMock.workshopUnaffordable(BlueprintId.armory, missingWood: 15),
        BuildItemDataMock.mageTowerUnaffordable(missingWood: 20),
      ]);
```

`test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`, al final de `main`:

```dart
  test('testWhenNamingTheMageTowerThenUsesItsFrameAndTheHouseFrontOffset', () {
    // given
    const id = BlueprintId.mageTower;

    // when
    final name = SpriteNames.building(id);
    final offset = RenderConstants.buildingFrontOffset(id);

    // then
    expect(name, 'mage-tower');
    expect(offset, 24);
  });
```

`test/core/assets/i18n/internationalize_test.dart`, en `testWhenNamingEveryBlueprintThenNoneFallsBackToItsKey`:

```dart
    expect(names, ['Casa', 'Herrería', 'Armería', 'Torre de magia']);
```

Run: `flutter test test/layers/domain/rules/blueprints_test.dart`
Expected: FAIL al compilar (`BlueprintId.mageTower` no existe).

- [x] **Step 4: Enum, catálogo, textos, nombre de sprite y desplazamiento**

`lib/core/config/constants/enum/blueprint_id.dart`:

```dart
enum BlueprintId { house, forge, armory, mageTower }
```

`lib/layers/domain/rules/blueprints.dart`: después de `armory`, y cambiando `all`:

```dart
  static const BlueprintEntity mageTower = BlueprintEntity(
    id: BlueprintId.mageTower,
    cost: {Resource.wood: 30, Resource.gold: 40},
    hitsToBuild: 12,
    footprintRadius: 40,
  );

  static const List<BlueprintEntity> all = [house, forge, armory, mageTower];
```

`lib/core/assets/i18n/translations/es.json`, bloque `forest.blueprint`:

```json
    "blueprint": {
      "house": "Casa",
      "forge": "Herrería",
      "armory": "Armería",
      "mageTower": "Torre de magia"
    },
```

`lib/core/assets/i18n/internationalize.dart`, en `forestBlueprint`:

```dart
  static String forestBlueprint({required BlueprintId id}) => switch (id) {
    BlueprintId.house => '$_forest.blueprint.house'.tr(),
    BlueprintId.forge => '$_forest.blueprint.forge'.tr(),
    BlueprintId.armory => '$_forest.blueprint.armory'.tr(),
    BlueprintId.mageTower => '$_forest.blueprint.mageTower'.tr(),
  };
```

`lib/layers/presentation/features/forest/game/atlas/sprite_names.dart` (decisión 3):

```dart
  static String building(BlueprintId id) => switch (id) {
    BlueprintId.house => 'house',
    BlueprintId.forge => 'forge',
    BlueprintId.armory => 'armory',
    BlueprintId.mageTower => 'mage-tower',
  };
```

`lib/layers/presentation/features/forest/game/render/render_constants.dart`:

```dart
  static double buildingFrontOffset(BlueprintId id) => switch (id) {
    BlueprintId.house => 24,
    BlueprintId.forge => 24,
    BlueprintId.armory => 24,
    BlueprintId.mageTower => 24,
  };
```

Run: `flutter test test/layers/domain test/core/assets test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`
Expected: PASS.

Run: `flutter test test/layers/presentation/features/forest/game/atlas/lpc_atlas_test.dart`
Expected: FAIL en `testWhenParsingTheGeneratedAtlasThenEveryLevelSpriteExists`: falta el frame `mage-tower` en `forest.json`. Es la guarda de F0; se arregla en el paso siguiente.

- [x] **Step 5: Generar el arte**

En `asset-packs/lpc/build_assets.py`:

1. En el docstring, cambiar la línea del atlas por:

```python
  forest.png + forest.json         JSON-hash atlas (TexturePacker format): trees (pivot = trunk base), decor, stump,
                                   axe pickup, the house, the forge, the armory and the mage tower
                                   (pivot = bottom centre)
```

2. Después de `CHIMNEY_INSET = 20  # …`:

```python
MAGE_TOWER_ROOF = [(30, 16, 40), (38, 20, 52), (62, 30, 92), (78, 40, 112), (96, 52, 136), (110, 62, 152), (134, 84, 178), (168, 120, 210), (190, 150, 226)]
MAGE_TOWER_WALL_BOX = (96, 256, 192, 352)  # cottage.png, stone wall with long diagonal braces
MAGE_TOWER_ROOF_STRETCH = 1.4  # the violet roof is drawn 40 % taller, like a spire
```

3. La cabecera y el docstring de `build_cottage()` pasan a ser:

```python
def build_cottage(
    wall_box: tuple, roof_colours: list = None, chimney: Image.Image = None, roof_stretch: float = 1
) -> Image.Image:
    """Wall, door and thatched roof; optionally a recoloured, taller roof and a chimney sticking out of it."""
```

   y, justo después del `recolour` del tejado:

```python
    if roof_colours is not None:
        roof = recolour(roof, ROOF_RAMP, roof_colours)
    if roof_stretch != 1:
        roof = roof.resize((roof.width, round(roof.height * roof_stretch)), Image.NEAREST)
```

4. Después de `build_armory()`:

```python
def build_mage_tower() -> Image.Image:
    return build_cottage(MAGE_TOWER_WALL_BOX, MAGE_TOWER_ROOF, roof_stretch=MAGE_TOWER_ROOF_STRETCH)
```

5. En `build_forest()`, después de `pivots["armory"] = {"x": 0.5, "y": 1}`:

```python
    frames["mage-tower"] = build_mage_tower()
    pivots["mage-tower"] = {"x": 0.5, "y": 1}
```

Generar y comprobar:

```bash
cd asset-packs/lpc && python3 build_assets.py && cd ../..
git status --short lib/core/assets/images/lpc
python3 -c "import json; f = json.load(open('lib/core/assets/images/lpc/forest.json'))['frames']; print({k: (f[k]['frame']['w'], f[k]['frame']['h']) for k in ('house', 'forge', 'armory', 'mage-tower')})"
```

Expected:
- `Assets written to …`;
- sólo cambian `forest.png` y `forest.json` (las hojas `hero-*.png`, `ground.png` y `arena.*` quedan igual);
- `{'house': (120, 191), 'forge': (120, 209), 'armory': (120, 191), 'mage-tower': (120, 240)}`.

Abre `lib/core/assets/images/lpc/forest.png` y comprueba a ojo que la casa, la Herrería y la Armería no han cambiado y que hay una Torre con muro de piedra con riostras diagonales, la puerta de la casa y un tejado violeta alto, como una aguja.

En `lib/core/assets/images/lpc/CREDITS.md`, el título de la sección de la casa pasa a ser:

```markdown
## House, forge, armory and mage tower (`house`, `forge`, `armory`, `mage-tower` frames in `forest.png`)
```

y la última frase de su primer párrafo:

```markdown
The forge and armory roofs are recoloured (dark grey, red); the forge chimney is a stone block
from the LPC Tile Atlas above. The mage tower roof is recoloured violet and stretched 40 % taller.
```

- [x] **Step 6: Ver que pasan**

```bash
flutter test test/layers/presentation/features/forest test/layers/domain test/core/assets
```

Expected: PASS, incluido `lpc_atlas_test.dart` (el frame existe).

- [x] **Step 7: Comprobar la persistencia de edificios**

```bash
grep -rn "BlueprintId" lib/layers/data
```

- Sin resultados: F2 no está; no hay nada que hacer (decisión 17).
- Con un mapper que lee el id con `BlueprintId.values.byName`: no hay nada que hacer.
- Con un `switch` o una tabla a mano: se añade `mageTower` en el mismo commit y se apunta en la sección 5 del README.

- [x] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/core/config/constants/enum/blueprint_id.dart lib/layers/domain/rules/blueprints.dart lib/layers/presentation/features/forest/game/atlas/sprite_names.dart lib/layers/presentation/features/forest/game/render/render_constants.dart test/layers/domain/rules/blueprints_test.dart test/layers/domain/use-cases/game/get_build_options_use_case_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart test/core/assets/i18n/internationalize_test.dart test/mocks/domain/entities/building/blueprint_entity_mock.dart test/mocks/domain/entities/game/build_option_entity_mock.dart test/mocks/presentation/features/forest/build_item_data_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida en lo generado (esta tarea no toca DI ni mocks de mockito), `No issues found!` y todo en verde (554 tests en la máquina virtual de Dart).

- [x] **Step 9: Commit**

```bash
git add asset-packs/lpc/build_assets.py lib/core/assets lib/core/config/constants/enum/blueprint_id.dart lib/layers/domain/rules/blueprints.dart lib/layers/presentation/features/forest/game test
git commit -m "[PROJECT-X]: Build the mage tower in the village"
```

Prueba rápida en Chrome (`flutter run -d chrome`): el menú *Construir* lista *Torre de magia* ("30 de madera, 40 de oro") y dice lo que falta. Sin oro no se puede colocar; con la arena (C2) se gana el oro.

---

### Task TC5.2: Aprender habilidades (dominio)

**Files:**
- Create:
  - `lib/core/config/constants/enum/learn_skill_result.dart`
  - `lib/core/config/constants/enum/skill_option_state.dart`
  - `lib/layers/domain/entities/hero/skill_entity.dart`, `skill_option_entity.dart`
  - `lib/layers/domain/rules/skills.dart`
  - `lib/layers/domain/use-cases/hero/learn_skill_use_case.dart`, `get_skill_options_use_case.dart`
  - Tests:
    - `test/layers/domain/rules/skills_test.dart`
    - `test/layers/domain/entities/hero/skill_entity_test.dart`, `skill_option_entity_test.dart`
    - `test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart`, `get_skill_options_use_case_test.dart`, `skill_flow_test.dart`
  - Mocks:
    - `test/mocks/domain/entities/hero/skill_entity_mock.dart`, `skill_option_entity_mock.dart`
    - `test/mocks/domain/game/skill_scenario_mock.dart`
- Modify:
  - `lib/core/config/di/di.config.dart` (generado)
  - Tests: `test/core/config/di/di_test.dart`
  - Mocks: `test/mocks/domain/entities/hero/hero_entity_mock.dart`, `test/mocks/domain/world/funds_mock.dart`

**Interfaces:**
- Consumes: `BlueprintId.mageTower` y `Blueprints.mageTower` (TC5.1); `SkillId`, `HeroEntity.skills`, `HeroRules.power`, `World.funds` / `spend` / `updateHero` / `buildings` / `orderConstruction`, `InventoryRules.missing` (C0); `BuildingListRules.hasComplete` (C3).
- Produces:
  ```dart
  // lib/core/config/constants/enum/
  enum LearnSkillResult { ok, missingBuilding, alreadyKnown, notEnoughResources }
  enum SkillOptionState { known, available, needsBuilding, unaffordable }

  // lib/layers/domain/entities/hero/skill_entity.dart
  class SkillEntity { final SkillId id; final Map<Resource, int> cost; SkillEntity copyWith({SkillId? id, Map<Resource, int>? cost}); }

  // lib/layers/domain/entities/hero/skill_option_entity.dart
  class SkillOptionEntity {
    final SkillEntity skill;
    final SkillOptionState state;
    final Map<Resource, int> missing;     // {} si known
    const SkillOptionEntity({required this.skill, required this.state, this.missing = const {}});
    bool get canLearn;                    // state == available
    SkillOptionEntity copyWith({SkillEntity? skill, SkillOptionState? state, Map<Resource, int>? missing});
  }

  // lib/layers/domain/rules/skills.dart
  abstract final class Skills {
    static const BlueprintId building = BlueprintId.mageTower;
    static const SkillEntity doubleStrike;  // 60 de oro
    static const SkillEntity dodge;         // 90 de oro
    static const SkillEntity secondWind;    // 130 de oro
    static const List<SkillEntity> all = [doubleStrike, dodge, secondWind];
    static SkillEntity byId(SkillId id);
  }

  // lib/layers/domain/use-cases/hero/
  LearnSkillResult LearnSkillUseCase.call({required SkillId id});
  List<SkillOptionEntity> GetSkillOptionsUseCase.call();   // una por habilidad, en el orden de Skills.all

  // mocks nuevos
  HeroEntityMock.withDoubleStrike
  FundsMock.doubleStrikePrice / .tenGoldShortOfDoubleStrike
  SkillEntityMock.doubleStrike / .dodge / .secondWind
  SkillOptionEntityMock.known(id) / .make(id, state, {missing}) / .doubleStrikeAvailable / .doubleStrikeTenGoldShort
    / .newHeroWithoutTower / .readyToLearnDoubleStrike / .afterLearningDoubleStrike
  SkillScenarioMock.towerSite / .buildMs / .withoutTower / .withTower / .withTowerUnderConstruction
  ```

- [x] **Step 1: Crear la rama (sólo si TC5.3 se hace a la vez)**

```bash
git switch feature/PROJECT-X-c5-mage-tower
git worktree add ../phaser-example-c5-skills-domain -b feature/PROJECT-X-c5-skills-domain
cd ../phaser-example-c5-skills-domain && flutter pub get
```

Si no hay trabajo en paralelo, se sigue en la rama de fase.

- [x] **Step 2: Escribir los datos de prueba**

`test/mocks/domain/entities/hero/hero_entity_mock.dart`, al final de la clase:

```dart
  static const HeroEntity withDoubleStrike = HeroEntity(skills: {SkillId.doubleStrike});
```

`test/mocks/domain/world/funds_mock.dart`, al final de la clase:

```dart
  static const Map<Resource, int> doubleStrikePrice = {Resource.gold: 60};

  static const Map<Resource, int> tenGoldShortOfDoubleStrike = {Resource.gold: 50};
```

`test/mocks/domain/entities/hero/skill_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/entities/hero/skill_entity.dart';

abstract final class SkillEntityMock {
  static const SkillEntity doubleStrike = SkillEntity(id: SkillId.doubleStrike, cost: {Resource.gold: 60});

  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90});

  static const SkillEntity secondWind = SkillEntity(id: SkillId.secondWind, cost: {Resource.gold: 130});
}
```

`test/mocks/domain/game/skill_scenario_mock.dart`. Construye la Torre con la API real del `World` (decisión 16):

```dart
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/hero/hero_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class SkillScenarioMock {
  static const PositionEntity towerSite = PositionEntity(x: 300, y: 100);
  static const double buildMs = 10000;

  static World withoutTower({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    return WorldMock.withHero(hero)..earn(funds);
  }

  static World withTower({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero)..earn(Blueprints.mageTower.cost);
    world.orderConstruction(Blueprints.mageTower, towerSite);
    world.advanceFor(buildMs);
    return world..earn(funds);
  }

  static World withTowerUnderConstruction({Map<Resource, int> funds = const {}}) {
    final world = WorldMock.make()..earn(Blueprints.mageTower.cost);
    world.orderConstruction(Blueprints.mageTower, towerSite);
    return world..earn(funds);
  }
}
```

`test/mocks/domain/entities/hero/skill_option_entity_mock.dart`. Por defecto, `missing` es el coste entero (sin fondos):

```dart
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/core/config/constants/enum/skill_option_state.dart';
import 'package:rpg/layers/domain/entities/hero/skill_option_entity.dart';
import 'package:rpg/layers/domain/rules/skills.dart';

abstract final class SkillOptionEntityMock {
  static SkillOptionEntity known(SkillId id) =>
      SkillOptionEntity(skill: Skills.byId(id), state: SkillOptionState.known);

  static SkillOptionEntity make(SkillId id, SkillOptionState state, {Map<Resource, int>? missing}) {
    final skill = Skills.byId(id);
    return SkillOptionEntity(skill: skill, state: state, missing: missing ?? skill.cost);
  }

  static SkillOptionEntity get doubleStrikeAvailable =>
      make(SkillId.doubleStrike, SkillOptionState.available, missing: {});

  static SkillOptionEntity get doubleStrikeTenGoldShort =>
      make(SkillId.doubleStrike, SkillOptionState.unaffordable, missing: {Resource.gold: 10});

  static List<SkillOptionEntity> get newHeroWithoutTower => [
    make(SkillId.doubleStrike, SkillOptionState.needsBuilding),
    make(SkillId.dodge, SkillOptionState.needsBuilding),
    make(SkillId.secondWind, SkillOptionState.needsBuilding),
  ];

  static List<SkillOptionEntity> get readyToLearnDoubleStrike => [
    doubleStrikeAvailable,
    make(SkillId.dodge, SkillOptionState.unaffordable, missing: {Resource.gold: 30}),
    make(SkillId.secondWind, SkillOptionState.unaffordable, missing: {Resource.gold: 70}),
  ];

  static List<SkillOptionEntity> get afterLearningDoubleStrike => [
    known(SkillId.doubleStrike),
    make(SkillId.dodge, SkillOptionState.unaffordable),
    make(SkillId.secondWind, SkillOptionState.unaffordable),
  ];
}
```

- [x] **Step 3: Escribir los tests que fallan**

`test/layers/domain/rules/skills_test.dart` (decisión 4):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/rules/skills.dart';

import '../../../mocks/domain/entities/hero/skill_entity_mock.dart';

void main() {
  test('testWhenListingSkillsThenEverySkillIdAppearsOnce', () {
    // given
    final ids = Skills.all.map((skill) => skill.id).toList();

    // when
    final unique = ids.toSet();

    // then
    expect(ids, hasLength(SkillId.values.length));
    expect(unique, SkillId.values.toSet());
  });

  test('testWhenAskingForEachSkillThenItCostsOnlyGoldFromCheapestToDearest', () {
    // given
    final ids = [SkillId.doubleStrike, SkillId.dodge, SkillId.secondWind];

    // when
    final skills = ids.map(Skills.byId).toList();
    final prices = Skills.all.map((skill) => skill.cost[Resource.gold]).toList();

    // then
    expect(skills, [SkillEntityMock.doubleStrike, SkillEntityMock.dodge, SkillEntityMock.secondWind]);
    expect(prices, [60, 90, 130]);
  });

  test('testWhenAskingWhereSkillsAreLearnedThenItIsTheMageTower', () {
    // given
    const expected = BlueprintId.mageTower;

    // when
    const building = Skills.building;

    // then
    expect(building, expected);
  });
}
```

`test/layers/domain/entities/hero/skill_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';

import '../../../../mocks/domain/entities/hero/skill_entity_mock.dart';

void main() {
  test('testWhenComparingSkillsThenIdAndCostBothCount', () {
    // given
    const skill = SkillEntityMock.doubleStrike;

    // when
    final sameSkill = skill == skill.copyWith();
    final otherId = skill == skill.copyWith(id: SkillId.dodge);
    final otherCost = skill == skill.copyWith(cost: SkillEntityMock.dodge.cost);

    // then
    expect(sameSkill, isTrue);
    expect(skill.hashCode, skill.copyWith().hashCode);
    expect(otherId, isFalse);
    expect(otherCost, isFalse);
  });
}
```

`test/layers/domain/entities/hero/skill_option_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/core/config/constants/enum/skill_option_state.dart';

import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';

void main() {
  test('testWhenComparingOptionsThenSkillStateAndMissingAllCount', () {
    // given
    final option = SkillOptionEntityMock.doubleStrikeAvailable;

    // when
    final sameOption = option == SkillOptionEntityMock.doubleStrikeAvailable;
    final otherMissing = option == SkillOptionEntityMock.doubleStrikeTenGoldShort;
    final otherState = option == option.copyWith(state: SkillOptionState.known);

    // then
    expect(sameOption, isTrue);
    expect(option.hashCode, SkillOptionEntityMock.doubleStrikeAvailable.hashCode);
    expect(otherMissing, isFalse);
    expect(otherState, isFalse);
  });

  test('testWhenTheOptionIsAvailableThenItCanBeLearnedAndNoOtherStateCan', () {
    // given
    final available = SkillOptionEntityMock.doubleStrikeAvailable;
    final others = [
      SkillOptionEntityMock.known(SkillId.doubleStrike),
      SkillOptionEntityMock.doubleStrikeTenGoldShort,
      SkillOptionEntityMock.make(SkillId.doubleStrike, SkillOptionState.needsBuilding),
    ];

    // when
    final learnable = others.where((option) => option.canLearn).toList();

    // then
    expect(available.canLearn, isTrue);
    expect(learnable, isEmpty);
  });
}
```

`test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart`. Un test por resultado, más el orden de las comprobaciones (decisión 6):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/learn_skill_result.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/use-cases/hero/learn_skill_use_case.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late LearnSkillUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = LearnSkillUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenThereIsNoMageTowerThenTheSkillNeedsTheBuildingAndNothingIsPaid', () {
    // given
    final world = playing(SkillScenarioMock.withoutTower(funds: FundsMock.doubleStrikePrice));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.missingBuilding);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 60);
  });

  test('testWhenTheMageTowerIsStillBeingBuiltThenTheSkillNeedsTheBuilding', () {
    // given
    playing(SkillScenarioMock.withTowerUnderConstruction(funds: FundsMock.doubleStrikePrice));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.missingBuilding);
  });

  test('testWhenTheSkillIsAlreadyKnownThenNothingIsPaid', () {
    // given
    final world = playing(
      SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice, hero: HeroEntityMock.withDoubleStrike),
    );

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.alreadyKnown);
    expect(world.hero, HeroEntityMock.withDoubleStrike);
    expect(world.funds.amount(Resource.gold), 60);
  });

  test('testWhenTheSkillIsTooExpensiveThenNothingIsPaidOrLearned', () {
    // given
    final world = playing(SkillScenarioMock.withTower(funds: FundsMock.tenGoldShortOfDoubleStrike));

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.notEnoughResources);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 50);
  });

  test('testWhenSeveralChecksFailThenTheyAreReportedInOrder', () {
    // given
    playing(SkillScenarioMock.withoutTower(hero: HeroEntityMock.withDoubleStrike));
    final missingBuilding = sut(id: SkillId.doubleStrike);
    playing(SkillScenarioMock.withTower(hero: HeroEntityMock.withDoubleStrike));

    // when
    final alreadyKnown = sut(id: SkillId.doubleStrike);

    // then
    expect(missingBuilding, LearnSkillResult.missingBuilding);
    expect(alreadyKnown, LearnSkillResult.alreadyKnown);
  });

  test('testWhenEverythingIsInPlaceThenPaysLearnsTheSkillAndRaisesPower', () {
    // given
    final world = playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice));
    final powerBefore = world.hero.power;

    // when
    final result = sut(id: SkillId.doubleStrike);

    // then
    expect(result, LearnSkillResult.ok);
    expect(world.hero, HeroEntityMock.withDoubleStrike);
    expect((powerBefore, world.hero.power), (31, 34));
    expect(world.funds.amount(Resource.gold), 0);
  });
}
```

`test/layers/domain/use-cases/hero/get_skill_options_use_case_test.dart` (decisión 7):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/skill_option_state.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_skill_options_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';
import '../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetSkillOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetSkillOptionsUseCase(sessionRepository: sessionRepository);
  });

  void playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
  }

  test('testWhenThereIsNoMageTowerThenEverySkillNeedsTheBuildingEvenIfItIsPaidFor', () {
    // given
    playing(SkillScenarioMock.withoutTower(funds: FundsMock.doubleStrikePrice));

    // when
    final options = sut();

    // then
    expect(options.map((option) => option.state).toSet(), {SkillOptionState.needsBuilding});
    expect(options.first.missing, isEmpty);
  });

  test('testWhenTheNewHeroHasNoTowerAndNoGoldThenEverySkillSaysItsFullPriceIsMissing', () {
    // given
    playing(SkillScenarioMock.withoutTower());

    // when
    final options = sut();

    // then
    expect(options, SkillOptionEntityMock.newHeroWithoutTower);
  });

  test('testWhenTheTowerIsBuiltAndTheDoubleStrikeIsPaidForThenOnlyItIsAvailable', () {
    // given
    playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice));

    // when
    final options = sut();

    // then
    expect(options, SkillOptionEntityMock.readyToLearnDoubleStrike);
  });

  test('testWhenFundsAreShortThenTheSkillIsUnaffordableAndSaysWhatIsMissing', () {
    // given
    playing(SkillScenarioMock.withTower(funds: FundsMock.tenGoldShortOfDoubleStrike));

    // when
    final options = sut();

    // then
    expect(options.first, SkillOptionEntityMock.doubleStrikeTenGoldShort);
  });

  test('testWhenTheHeroKnowsASkillThenItIsListedAsKnownWithNothingMissing', () {
    // given
    playing(SkillScenarioMock.withTower(hero: HeroEntityMock.withDoubleStrike));

    // when
    final options = sut();

    // then
    expect(options, SkillOptionEntityMock.afterLearningDoubleStrike);
  });
}
```

`test/layers/domain/use-cases/hero/skill_flow_test.dart`. Es el test de flujo de la ficha: construye la Torre con `ConstructBuildingUseCase` + `AdvanceGameUseCase`, cobra el oro con `world.earn` (como lo hará la arena) y aprende:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/learn_skill_result.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_skill_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/learn_skill_use_case.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/skill_option_entity_mock.dart';
import '../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  test('testWhenTheMageTowerIsBuiltAndArenaGoldIsEarnedThenTheDoubleStrikeRaisesPowerByTenPercent', () {
    // given
    final sessionRepository = MockGameSessionRepository();
    final world = SkillScenarioMock.withoutTower()..earn(Blueprints.mageTower.cost);
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    final construct = ConstructBuildingUseCase(sessionRepository: sessionRepository);
    final advance = AdvanceGameUseCase(sessionRepository: sessionRepository);
    final options = GetSkillOptionsUseCase(sessionRepository: sessionRepository);
    final learn = LearnSkillUseCase(sessionRepository: sessionRepository);
    final heroStatus = GetHeroStatusUseCase(sessionRepository: sessionRepository);
    final before = heroStatus();
    final beforeTheTower = learn(id: SkillId.doubleStrike);
    construct(blueprint: BlueprintId.mageTower, x: SkillScenarioMock.towerSite.x, y: SkillScenarioMock.towerSite.y);
    for (var elapsed = 0.0; elapsed < SkillScenarioMock.buildMs; elapsed += 16) {
      advance(deltaMs: 16);
    }
    world.earn(FundsMock.doubleStrikePrice);

    // when
    final result = learn(id: SkillId.doubleStrike);

    // then
    final after = heroStatus();
    expect(beforeTheTower, LearnSkillResult.missingBuilding);
    expect(result, LearnSkillResult.ok);
    expect((before.power, after.power), (31, 34));
    expect(after.stats, before.stats);
    expect(options(), SkillOptionEntityMock.afterLearningDoubleStrike);
  });
}
```

Run: `flutter test test/layers/domain`
Expected: FAIL al compilar (`LearnSkillResult`, `SkillEntity`, `Skills`… no existen).

- [x] **Step 4: Enums, entidades y catálogo**

`lib/core/config/constants/enum/learn_skill_result.dart`:

```dart
enum LearnSkillResult { ok, missingBuilding, alreadyKnown, notEnoughResources }
```

`lib/core/config/constants/enum/skill_option_state.dart`:

```dart
enum SkillOptionState { known, available, needsBuilding, unaffordable }
```

`lib/layers/domain/entities/hero/skill_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class SkillEntity {
  final SkillId id;
  final Map<Resource, int> cost;

  const SkillEntity({required this.id, required this.cost});

  SkillEntity copyWith({SkillId? id, Map<Resource, int>? cost}) {
    return SkillEntity(id: id ?? this.id, cost: cost ?? this.cost);
  }

  @override
  bool operator ==(Object other) =>
      other is SkillEntity && other.id == id && const MapEquality<Resource, int>().equals(other.cost, cost);

  @override
  int get hashCode => Object.hash(id, const MapEquality<Resource, int>().hash(cost));

  @override
  String toString() => 'SkillEntity(id: $id, cost: $cost)';
}
```

`lib/layers/domain/entities/hero/skill_option_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_option_state.dart';
import 'skill_entity.dart';

class SkillOptionEntity {
  final SkillEntity skill;
  final SkillOptionState state;
  final Map<Resource, int> missing;

  const SkillOptionEntity({required this.skill, required this.state, this.missing = const {}});

  bool get canLearn => state == SkillOptionState.available;

  SkillOptionEntity copyWith({SkillEntity? skill, SkillOptionState? state, Map<Resource, int>? missing}) {
    return SkillOptionEntity(
      skill: skill ?? this.skill,
      state: state ?? this.state,
      missing: missing ?? this.missing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SkillOptionEntity &&
      other.skill == skill &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(skill, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'SkillOptionEntity(skill: ${skill.id}, state: $state, missing: $missing)';
}
```

`lib/layers/domain/rules/skills.dart`:

```dart
import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/skill_id.dart';
import '../entities/hero/skill_entity.dart';

abstract final class Skills {
  static const BlueprintId building = BlueprintId.mageTower;

  static const SkillEntity doubleStrike = SkillEntity(id: SkillId.doubleStrike, cost: {Resource.gold: 60});

  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90});

  static const SkillEntity secondWind = SkillEntity(id: SkillId.secondWind, cost: {Resource.gold: 130});

  static const List<SkillEntity> all = [doubleStrike, dodge, secondWind];

  static SkillEntity byId(SkillId id) => all.firstWhere((skill) => skill.id == id);
}
```

- [x] **Step 5: Casos de uso**

`lib/layers/domain/use-cases/hero/learn_skill_use_case.dart`. Las comprobaciones van en el orden de la ficha. `world.spend` es atómico (C0): si falla, no se ha cobrado nada.

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/learn_skill_result.dart';
import '../../../../core/config/constants/enum/skill_id.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/skills.dart';
import '../../world/extensions/building_rules.dart';

@Injectable()
final class LearnSkillUseCase {
  final GameSessionRepository _sessionRepository;

  const LearnSkillUseCase({required this._sessionRepository});

  LearnSkillResult call({required SkillId id}) {
    final world = _sessionRepository.current().world;
    if (!world.buildings.hasComplete(Skills.building)) return LearnSkillResult.missingBuilding;
    if (world.hero.skills.contains(id)) return LearnSkillResult.alreadyKnown;
    if (!world.spend(Skills.byId(id).cost)) return LearnSkillResult.notEnoughResources;
    world.updateHero((hero) => hero.copyWith(skills: {...hero.skills, id}));
    return LearnSkillResult.ok;
  }
}
```

`lib/layers/domain/use-cases/hero/get_skill_options_use_case.dart` (decisión 7). Importa `World`, que no es una pieza interna de `world/` (la regla de `architecture_test.dart` lo permite):

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/skill_option_state.dart';
import '../../entities/hero/skill_entity.dart';
import '../../entities/hero/skill_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/skills.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/world.dart';

@Injectable()
final class GetSkillOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetSkillOptionsUseCase({required this._sessionRepository});

  List<SkillOptionEntity> call() {
    final world = _sessionRepository.current().world;
    return [for (final skill in Skills.all) _option(world, skill)];
  }

  SkillOptionEntity _option(World world, SkillEntity skill) {
    if (world.hero.skills.contains(skill.id)) return SkillOptionEntity(skill: skill, state: SkillOptionState.known);
    final missing = world.funds.missing(skill.cost);
    final SkillOptionState state;
    if (!world.buildings.hasComplete(Skills.building)) {
      state = SkillOptionState.needsBuilding;
    } else if (missing.isNotEmpty) {
      state = SkillOptionState.unaffordable;
    } else {
      state = SkillOptionState.available;
    }
    return SkillOptionEntity(skill: skill, state: state, missing: missing);
  }
}
```

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --stat -- lib/core/config/di/di.config.dart
flutter test test/layers/domain
```

Expected: `di.config.dart` sólo registra `LearnSkillUseCase` y `GetSkillOptionsUseCase`; PASS.

- [x] **Step 6: Registrar los casos de uso en el test de DI**

En `test/core/config/di/di_test.dart`, añadir los imports

```dart
import 'package:rpg/layers/domain/use-cases/hero/get_skill_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/learn_skill_use_case.dart';
```

y, en `testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered`, después de `locator.isRegistered<GetGearOptionsUseCase>(),`:

```dart
      locator.isRegistered<LearnSkillUseCase>(),
      locator.isRegistered<GetSkillOptionsUseCase>(),
```

Run: `flutter test test/core/config/di/di_test.dart`
Expected: PASS.

- [x] **Step 7: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/learn_skill_result.dart lib/core/config/constants/enum/skill_option_state.dart lib/layers/domain/entities/hero lib/layers/domain/rules/skills.dart lib/layers/domain/use-cases/hero test/layers/domain/entities/hero test/layers/domain/rules/skills_test.dart test/layers/domain/use-cases/hero test/core/config/di/di_test.dart test/mocks/domain/entities/hero test/mocks/domain/game/skill_scenario_mock.dart test/mocks/domain/world/funds_mock.dart
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `No issues found!` y todo en verde (18 tests más que TC5.1).

- [x] **Step 8: Commit**

```bash
git add lib/core/config/constants/enum lib/core/config/di/di.config.dart lib/layers/domain test/layers/domain test/core/config/di/di_test.dart test/mocks/domain
git commit -m "[PROJECT-X]: Learn skills at a finished mage tower"
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida.

Si se hizo en su propio *worktree*, se une cuando TC5.3 también esté (TC5.4, Step 1).

---

### Task TC5.3: Pestaña *Habilidades* (widgets)

**Files:**
- Create:
  - `lib/layers/presentation/features/forest/models/skill_item_data.dart`
  - `lib/layers/presentation/features/forest/widgets/skill_tile.dart`
  - Tests: `test/layers/presentation/features/forest/widgets/skill_tile_test.dart`
  - Mocks: `test/mocks/presentation/features/forest/skill_item_data_mock.dart`
- Modify:
  - `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`
  - `lib/layers/presentation/features/forest/models/hero_panel_data.dart` (`skills`)
  - `lib/layers/presentation/features/forest/widgets/hero_panel.dart` (pestaña, `onLearn`, `assert`, `didUpdateWidget`)
  - Tests:
    - `test/core/assets/i18n/internationalize_test.dart`
    - `test/layers/presentation/features/forest/models/hero_panel_data_test.dart`
    - `test/layers/presentation/features/forest/widgets/hero_panel_test.dart`
  - Mocks: `test/mocks/presentation/features/forest/hero_panel_data_mock.dart`

**Interfaces:**
- Consumes: `SkillId` (C0); `BlueprintId.mageTower` y `Internationalize.forestBlueprint` (TC5.1, sólo en los mocks y en un test de textos); `HeroPanel`, `HeroPanelSection`, `HudButton`, `CustomColors`, `CustomTextStyles` (C3). **No** usa nada de TC5.2.
- Produces:
  ```dart
  // models/
  class SkillItemData { SkillId id; String name; String description; String? costText; String? reasonText; bool isKnown; bool canLearn; }
  HeroPanelData({…, List<SkillItemData> skills = const []})

  // widgets/
  SkillTile({required SkillItemData item, VoidCallback? onLearn}); static Key SkillTile.learnKey(SkillId id)
  HeroPanel({required hero, required onBuy, ValueChanged<SkillId>? onLearn, List<HeroPanelSection> sections = const [HeroPanelSection.gear]})
    // assert(sections.length > 0); la pestaña abierta vuelve a la primera si deja de estar en sections

  // Internationalize
  forestHeroLearn, forestHeroKnown, forestSkillName({id}), forestSkillDescription({id}),
  forestMessageSkillLearned({name}), forestMessageSkillAlreadyKnown

  // mocks nuevos
  SkillItemDataMock.needsTower(id) / .unaffordable(id, {missingGold}) / .doubleStrikeAvailable / .doubleStrikeKnown
    / .withoutTower / .readyToLearnDoubleStrike / .afterLearningDoubleStrike
  HeroPanelDataMock.readyToLearnDoubleStrike
  ```

- [x] **Step 1: Crear la rama (sólo si TC5.2 se hace a la vez)**

```bash
git switch feature/PROJECT-X-c5-mage-tower
git worktree add ../phaser-example-c5-skills-tab -b feature/PROJECT-X-c5-skills-tab
cd ../phaser-example-c5-skills-tab && flutter pub get
```

- [x] **Step 2: Textos (TDD)**

`test/core/assets/i18n/internationalize_test.dart`: añadir el import `package:rpg/core/config/constants/enum/skill_id.dart` y, antes de `testWhenFormattingArenaNumbersThenUsesTheSpanishTexts`:

```dart
  test('testWhenNamingEverySkillThenUsesTheSpanishNamesAndDescriptions', () {
    // given
    // when
    final names = SkillId.values.map((id) => Internationalize.forestSkillName(id: id)).toList();
    final descriptions = SkillId.values.map((id) => Internationalize.forestSkillDescription(id: id)).toList();

    // then
    expect(names, ['Golpe doble', 'Segundo aliento', 'Esquiva']);
    expect(descriptions, [
      'Cada tercer ataque golpea dos veces.',
      'Una vez por pelea, por debajo del 30 % de vida recupera el 40 %.',
      'Un 20 % de posibilidades de esquivar cada golpe.',
    ]);
  });

  test('testWhenReadingEverySkillTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestHeroLearn,
      Internationalize.forestHeroKnown,
      Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.mageTower)),
      Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: SkillId.doubleStrike)),
      Internationalize.forestMessageSkillAlreadyKnown,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Aprender',
      'Aprendida',
      'Construye la Torre de magia',
      'Has aprendido: Golpe doble',
      'Ya conoces esa habilidad.',
    ]);
  });
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: FAIL al compilar (`forestSkillName`… no existen).

`lib/core/assets/i18n/translations/es.json` (decisión 10):
- en el bloque `forest.message`, después de `"gearNotNextTier"` (con su coma):

```json
      "skillLearned": "Has aprendido: {name}",
      "skillAlreadyKnown": "Ya conoces esa habilidad."
```

- en el bloque `forest.hero`, después de `"maxed"` (con su coma):

```json
      "learn": "Aprender",
      "known": "Aprendida"
```

- después del bloque `forest.gear` y antes de `forest.placement`:

```json
    "skill": {
      "doubleStrike": {
        "name": "Golpe doble",
        "description": "Cada tercer ataque golpea dos veces."
      },
      "secondWind": {
        "name": "Segundo aliento",
        "description": "Una vez por pelea, por debajo del 30 % de vida recupera el 40 %."
      },
      "dodge": {
        "name": "Esquiva",
        "description": "Un 20 % de posibilidades de esquivar cada golpe."
      }
    },
```

`lib/core/assets/i18n/internationalize.dart`: añadir el import `import '../../config/constants/enum/skill_id.dart';` y, después de `forestMessageGearNotNextTier`:

```dart
  static String get forestHeroLearn => '$_forest.hero.learn'.tr();
  static String get forestHeroKnown => '$_forest.hero.known'.tr();
  static String forestSkillName({required SkillId id}) => switch (id) {
    SkillId.doubleStrike => '$_forest.skill.doubleStrike.name'.tr(),
    SkillId.secondWind => '$_forest.skill.secondWind.name'.tr(),
    SkillId.dodge => '$_forest.skill.dodge.name'.tr(),
  };
  static String forestSkillDescription({required SkillId id}) => switch (id) {
    SkillId.doubleStrike => '$_forest.skill.doubleStrike.description'.tr(),
    SkillId.secondWind => '$_forest.skill.secondWind.description'.tr(),
    SkillId.dodge => '$_forest.skill.dodge.description'.tr(),
  };
  static String forestMessageSkillLearned({required String name}) =>
      '$_forest.message.skillLearned'.tr(namedArgs: {'name': name});
  static String get forestMessageSkillAlreadyKnown => '$_forest.message.skillAlreadyKnown'.tr();
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: PASS.

- [x] **Step 3: Datos de prueba de los modelos**

`test/mocks/presentation/features/forest/skill_item_data_mock.dart`. Los precios se escriben como los forma el BLoC (`_amounts`), en el orden de `Skills.all` (decisión 4):

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/skill_item_data.dart';

abstract final class SkillItemDataMock {
  static SkillItemData needsTower(SkillId id) => _make(
    id,
    reasonText: Internationalize.forestHeroNeedsBuilding(
      name: Internationalize.forestBlueprint(id: BlueprintId.mageTower),
    ),
    canLearn: false,
  );

  static SkillItemData unaffordable(SkillId id, {required int missingGold}) => _make(
    id,
    reasonText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.gold, amount: missingGold),
    ),
    canLearn: false,
  );

  static SkillItemData get doubleStrikeAvailable => _make(SkillId.doubleStrike, reasonText: null, canLearn: true);

  static SkillItemData get doubleStrikeKnown => SkillItemData(
    id: SkillId.doubleStrike,
    name: Internationalize.forestSkillName(id: SkillId.doubleStrike),
    description: Internationalize.forestSkillDescription(id: SkillId.doubleStrike),
    isKnown: true,
    canLearn: false,
  );

  static List<SkillItemData> get withoutTower => [
    needsTower(SkillId.doubleStrike),
    needsTower(SkillId.dodge),
    needsTower(SkillId.secondWind),
  ];

  static List<SkillItemData> get readyToLearnDoubleStrike => [
    doubleStrikeAvailable,
    unaffordable(SkillId.dodge, missingGold: 30),
    unaffordable(SkillId.secondWind, missingGold: 70),
  ];

  static List<SkillItemData> get afterLearningDoubleStrike => [
    doubleStrikeKnown,
    unaffordable(SkillId.dodge, missingGold: 90),
    unaffordable(SkillId.secondWind, missingGold: 130),
  ];

  static SkillItemData _make(SkillId id, {required String? reasonText, required bool canLearn}) => SkillItemData(
    id: id,
    name: Internationalize.forestSkillName(id: id),
    description: Internationalize.forestSkillDescription(id: id),
    costText: Internationalize.forestAmount(resource: Resource.gold, amount: _price(id)),
    reasonText: reasonText,
    isKnown: false,
    canLearn: canLearn,
  );

  static int _price(SkillId id) => switch (id) {
    SkillId.doubleStrike => 60,
    SkillId.secondWind => 130,
    SkillId.dodge => 90,
  };
}
```

`test/mocks/presentation/features/forest/hero_panel_data_mock.dart`: añadir el import `skill_item_data_mock.dart` y, al final de la clase. `newHero`, `newHeroCopy` y `readyToBuySword` **no** se tocan todavía (decisión 9):

```dart
  static HeroPanelData get readyToLearnDoubleStrike => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
    skills: SkillItemDataMock.readyToLearnDoubleStrike,
  );
```

- [x] **Step 4: Tests de modelos y widgets que fallan**

`test/layers/presentation/features/forest/models/hero_panel_data_test.dart`, al final de `main`:

```dart
  test('testWhenASkillChangesThenThePanelsAreNotEqual', () {
    // given
    final first = HeroPanelDataMock.newHero;
    final second = HeroPanelDataMock.readyToLearnDoubleStrike;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
    expect(first.rows, second.rows);
  });
```

`test/layers/presentation/features/forest/widgets/skill_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/skill_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/skill_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheSkillCanBeLearnedThenTappingLearnCallsOnLearn', (tester) async {
    // given
    var learns = 0;
    final item = SkillItemDataMock.doubleStrikeAvailable;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: SkillTile(item: item, onLearn: () => learns++),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));

    // then
    expect(learns, 1);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.description), findsOneWidget);
    expect(find.text(item.costText!), findsOneWidget);
  });

  testWidgets('testWhenTheTowerIsMissingThenLearnIsDisabledAndTheReasonIsShown', (tester) async {
    // given
    var learns = 0;
    final item = SkillItemDataMock.needsTower(SkillId.dodge);

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: SkillTile(item: item, onLearn: () => learns++),
        ),
      ),
    );
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.dodge)));

    // then
    expect(learns, 0);
    expect(tester.widget<HudButton>(find.byKey(SkillTile.learnKey(SkillId.dodge))).onPressed, isNull);
    expect(find.text(item.reasonText!), findsOneWidget);
  });

  testWidgets('testWhenTheSkillIsKnownThenSaysSoInsteadOfALearnButton', (tester) async {
    // given
    final item = SkillItemDataMock.doubleStrikeKnown;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(width: 340, child: SkillTile(item: item)),
      ),
    );

    // then
    expect(find.byType(HudButton), findsNothing);
    expect(find.text(Internationalize.forestHeroKnown), findsOneWidget);
  });
}
```

`test/layers/presentation/features/forest/widgets/hero_panel_test.dart` (sustituye el fichero). El test de C3 de la pestaña vacía pasa a comprobar las `SkillTile`; se añaden el de *Aprender*, el reinicio de la pestaña, el `assert` y el móvil en horizontal con la pestaña abierta (decisión 8):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/forest/hero_panel_section.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_row.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hero_panel.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/skill_tile.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenShownThenListsPowerTheThreeStatsAndOneRowPerSlot', (tester) async {
    // given
    final hero = HeroPanelDataMock.newHero;

    // when
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.text(Internationalize.forestHeroPower), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text(Internationalize.forestHeroAttack), findsOneWidget);
    expect(find.text(Internationalize.forestHeroDefense), findsOneWidget);
    expect(find.text(Internationalize.forestHeroHealth), findsOneWidget);
    expect(find.byType(GearRow), findsNWidgets(2));
    expect(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.gear)), findsNothing);
  });

  testWidgets('testWhenBuyIsTappedThenReportsThePiece', (tester) async {
    // given
    final bought = <GearId>[];
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: HeroPanelDataMock.readyToBuySword, onBuy: bought.add),
      ),
    );

    // when
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(bought, [GearId.shortSword]);
  });

  testWidgets('testWhenTheSkillsTabIsTappedThenListsOneTilePerSkillInsteadOfTheGear', (tester) async {
    // given
    final hero = HeroPanelDataMock.readyToLearnDoubleStrike;
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}, onLearn: (_) {}, sections: HeroPanelSection.values),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // then
    expect(find.byType(SkillTile), findsNWidgets(hero.skills.length));
    expect(find.byType(GearRow), findsNothing);
    expect(find.text(hero.skills.first.description), findsOneWidget);
  });

  testWidgets('testWhenLearnIsTappedThenReportsTheSkill', (tester) async {
    // given
    final learned = <SkillId>[];
    await tester.pumpHud(
      Center(
        child: HeroPanel(
          hero: HeroPanelDataMock.readyToLearnDoubleStrike,
          onBuy: (_) {},
          onLearn: learned.add,
          sections: HeroPanelSection.values,
        ),
      ),
    );
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // when
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));

    // then
    expect(learned, [SkillId.doubleStrike]);
  });

  testWidgets('testWhenTheOpenSectionIsNoLongerOfferedThenThePanelGoesBackToTheFirstOne', (tester) async {
    // given
    final hero = HeroPanelDataMock.newHero;
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}, sections: HeroPanelSection.values),
      ),
    );
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // when
    await tester.pumpHud(
      Center(
        child: HeroPanel(hero: hero, onBuy: (_) {}),
      ),
    );

    // then
    expect(find.byType(GearRow), findsNWidgets(2));
    expect(find.byType(SkillTile), findsNothing);
  });

  test('testWhenThereAreNoSectionsThenThePanelCannotBeCreated', () {
    // given
    final hero = HeroPanelDataMock.newHero;

    // when
    HeroPanel create() => HeroPanel(hero: hero, onBuy: (_) {}, sections: const []);

    // then
    expect(create, throwsAssertionError);
  });

  testWidgets('testWhenTheScreenIsAShortLandscapePhoneThenThePanelScrollsWithoutOverflowing', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await tester.pumpHud(
      Align(
        alignment: Alignment.topRight,
        child: HeroPanel(hero: HeroPanelDataMock.newHero, onBuy: (_) {}),
      ),
    );

    // then
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HeroPanel)).height, lessThanOrEqualTo(360 - HeroPanel.reservedHeight));
  });

  testWidgets('testWhenTheSkillsTabIsOpenOnAShortLandscapePhoneThenItScrollsWithoutOverflowing', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpHud(
      Align(
        alignment: Alignment.topRight,
        child: HeroPanel(
          hero: HeroPanelDataMock.readyToLearnDoubleStrike,
          onBuy: (_) {},
          onLearn: (_) {},
          sections: HeroPanelSection.values,
        ),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // then
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HeroPanel)).height, lessThanOrEqualTo(360 - HeroPanel.reservedHeight));
  });
}
```

Run: `flutter test test/layers/presentation/features/forest/models test/layers/presentation/features/forest/widgets`
Expected: FAIL al compilar (`SkillItemData`, `SkillTile`, `HeroPanel.onLearn`… no existen).

- [x] **Step 5: Modelos**

`lib/layers/presentation/features/forest/models/skill_item_data.dart`:

```dart
import '../../../../../core/config/constants/enum/skill_id.dart';

class SkillItemData {
  final SkillId id;
  final String name;
  final String description;
  final String? costText;
  final String? reasonText;
  final bool isKnown;
  final bool canLearn;

  const SkillItemData({
    required this.id,
    required this.name,
    required this.description,
    this.costText,
    this.reasonText,
    required this.isKnown,
    required this.canLearn,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillItemData &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.isKnown == isKnown &&
          other.canLearn == canLearn;

  @override
  int get hashCode => Object.hash(id, name, description, costText, reasonText, isKnown, canLearn);

  @override
  String toString() => 'SkillItemData($id, $name, $costText, $reasonText, isKnown: $isKnown, canLearn: $canLearn)';
}
```

`lib/layers/presentation/features/forest/models/hero_panel_data.dart`:
- import `skill_item_data.dart`;
- campo `final List<SkillItemData> skills;` después de `rows`, y `this.skills = const [],` al final del constructor;
- `==`, `hashCode` y `toString`:

```dart
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeroPanelData &&
          other.power == power &&
          other.attack == attack &&
          other.defense == defense &&
          other.health == health &&
          const ListEquality<GearRowData>().equals(other.rows, rows) &&
          const ListEquality<SkillItemData>().equals(other.skills, skills);

  @override
  int get hashCode => Object.hash(power, attack, defense, health, Object.hashAll(rows), Object.hashAll(skills));

  @override
  String toString() => 'HeroPanelData(power: $power, $attack/$defense/$health, rows: $rows, skills: $skills)';
```

- [x] **Step 6: Widgets**

`lib/layers/presentation/features/forest/widgets/skill_tile.dart` (mismo aspecto que `GearOptionTile`):

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/skill_item_data.dart';
import 'hud_button.dart';

class SkillTile extends StatelessWidget {
  final SkillItemData item;
  final VoidCallback? onLearn;

  const SkillTile({super.key, required this.item, this.onLearn});

  static Key learnKey(SkillId id) => Key('skillTileLearn-${id.name}');

  @override
  Widget build(BuildContext context) {
    final costText = item.costText;
    final reasonText = item.reasonText;
    return DecoratedBox(
      decoration: BoxDecoration(color: CustomColors.hudOptionBackground, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    item.name,
                    style: CustomTextStyles.system15w600.copyWith(
                      color: item.isKnown || item.canLearn ? CustomColors.hudText : CustomColors.hudMuted,
                    ),
                  ),
                  Text(item.description, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudMuted)),
                  if (costText != null)
                    Text(
                      costText,
                      style: CustomTextStyles.system13w500.copyWith(
                        color: item.canLearn ? CustomColors.hudAccent : CustomColors.hudMuted,
                      ),
                    ),
                  if (reasonText != null)
                    Text(reasonText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
                ],
              ),
            ),
            if (item.isKnown)
              Text(
                Internationalize.forestHeroKnown,
                style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
              )
            else
              HudButton(
                key: learnKey(item.id),
                label: Internationalize.forestHeroLearn,
                onPressed: item.canLearn ? onLearn : null,
              ),
          ],
        ),
      ),
    );
  }
}
```

`lib/layers/presentation/features/forest/widgets/hero_panel.dart` (fichero completo; sólo cambian los imports de `skill_id.dart` y `skill_tile.dart`, `onLearn`, el `assert`, `didUpdateWidget`, el caso `skills` del `switch` y `_onLearn`):

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/forest/hero_panel_section.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/hero_panel_data.dart';
import 'gear_row.dart';
import 'hud_button.dart';
import 'hud_panel.dart';
import 'skill_tile.dart';

class HeroPanel extends StatefulWidget {
  static const double reservedHeight = 96;

  final HeroPanelData hero;
  final ValueChanged<GearId> onBuy;
  final ValueChanged<SkillId>? onLearn;
  final List<HeroPanelSection> sections;

  const HeroPanel({
    super.key,
    required this.hero,
    required this.onBuy,
    this.onLearn,
    this.sections = const [HeroPanelSection.gear],
  }) : assert(sections.length > 0);

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  late HeroPanelSection _section = widget.sections.first;

  @override
  void didUpdateWidget(HeroPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.sections.contains(_section)) {
      _section = widget.sections.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = math.max(0.0, MediaQuery.sizeOf(context).height - HeroPanel.reservedHeight);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 260, maxWidth: 360, maxHeight: maxHeight),
      child: HudPanel(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [_title(), _stats(), if (widget.sections.length > 1) _tabs(), _body()],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      Internationalize.forestHero.toUpperCase(),
      style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
    );
  }

  Widget _stats() {
    final hero = widget.hero;
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _stat(label: Internationalize.forestHeroPower, value: hero.power, style: CustomTextStyles.system18w600),
        _stat(label: Internationalize.forestHeroAttack, value: hero.attack, style: CustomTextStyles.system15w600),
        _stat(label: Internationalize.forestHeroDefense, value: hero.defense, style: CustomTextStyles.system15w600),
        _stat(label: Internationalize.forestHeroHealth, value: hero.health, style: CustomTextStyles.system15w600),
      ],
    );
  }

  Widget _stat({required String label, required int value, required TextStyle style}) {
    return Semantics(
      label: label,
      value: '$value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(label, style: CustomTextStyles.system13w500.copyWith(color: CustomColors.hudMuted)),
          Text(
            '$value',
            style: style.copyWith(color: CustomColors.hudAccent, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      spacing: 8,
      children: [
        for (final section in widget.sections)
          HudButton(
            label: Internationalize.forestHeroSection(section: section),
            isActive: section == _section,
            onPressed: () => setState(() => _section = section),
          ),
      ],
    );
  }

  Widget _body() {
    return switch (_section) {
      HeroPanelSection.gear => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [for (final row in widget.hero.rows) GearRow(row: row, onBuy: widget.onBuy)],
      ),
      HeroPanelSection.skills => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [for (final skill in widget.hero.skills) SkillTile(item: skill, onLearn: _onLearn(skill.id))],
      ),
    };
  }

  VoidCallback? _onLearn(SkillId id) {
    final onLearn = widget.onLearn;
    return onLearn == null ? null : () => onLearn(id);
  }
}
```

Run: `flutter test test/layers/presentation/features/forest/models test/layers/presentation/features/forest/widgets`
Expected: PASS.

- [x] **Step 7: Verificación completa**

```bash
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/forest/models lib/layers/presentation/features/forest/widgets test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/forest/models test/layers/presentation/features/forest/widgets test/mocks/presentation/features/forest/skill_item_data_mock.dart test/mocks/presentation/features/forest/hero_panel_data_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
```

Expected: `git diff` sin salida en lo generado, `No issues found!` y todo en verde (10 tests más que TC5.1). La pestaña todavía no se ve en el juego (la conecta TC5.4).

- [x] **Step 8: Commit**

```bash
git add lib/core/assets lib/layers/presentation test
git commit -m "[PROJECT-X]: Add the skills tab to the hero panel"
```

---

### Task TC5.4: Integración en el bosque

**Files:**
- Create: `test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart`
- Modify:
  - `lib/core/config/constants/enum/forest/particle_kind.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `forest_event.dart`
  - `lib/layers/presentation/features/forest/models/forest_effect.dart`
  - `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`
  - `lib/layers/presentation/features/forest/game/forest_scene_component.dart`
  - `lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`, `particle_burst_component.dart`
  - `lib/layers/presentation/features/forest/forest_page.dart`
  - Tests:
    - `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`
    - `test/layers/presentation/features/forest/models/forest_effect_test.dart`
    - `test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`
    - `test/layers/presentation/features/forest/game/forest_scene_component_test.dart`
    - `test/layers/presentation/features/forest/forest_page_test.dart`
  - Mocks: `test/mocks/presentation/features/forest/forest_bloc_mock.dart`, `hero_panel_data_mock.dart`, `hud_data_mock.dart`, `forest_effect_mock.dart`, `game/forest_data_mock.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: todo lo de TC5.2 (`LearnSkillUseCase`, `GetSkillOptionsUseCase`, `SkillOptionEntity`, `SkillOptionState`, `LearnSkillResult`, `Skills.building`, `SkillScenarioMock`, `FundsMock`, `HeroEntityMock.withDoubleStrike`) y de TC5.3 (`SkillItemData`, `HeroPanel.onLearn`, `SkillTile.learnKey`, textos, `SkillItemDataMock`, `HeroPanelDataMock.readyToLearnDoubleStrike`).
- Produces:
  ```dart
  enum ParticleKind { woodChip, dust, sparkle, bloodDrop, magicSparkle }

  // forest_event.dart
  final class ForestSkillLearnRequested extends ForestEvent { final SkillId skill; }

  // forest_effect.dart
  final class SkillLearnedEffect extends ForestEffect { final SkillId skill; }

  // hud_overlay.dart
  HudOverlay({…, required ValueChanged<SkillId> onSkillSelected})   // y HeroPanel(sections: HeroPanelSection.values)

  // ForestBloc: + getSkillOptionsUseCase, learnSkillUseCase (después de buyGearUseCase, antes de navigationService)

  // particle_bursts.dart
  static List<Particle> ParticleBursts.sparkles({required PositionEntity feet, required math.Random random, ParticleKind kind = ParticleKind.sparkle});

  // mocks nuevos
  HudDataMock.withSkillReadyToLearn
  ForestEffectMock.doubleStrikeLearned / .doubleStrikeLearnedCopy / .dodgeLearned
  ForestDataMock.skillLearned
  ```

- [x] **Step 1: Unir TC5.2 y TC5.3 (sólo si se hicieron en paralelo)**

```bash
git switch feature/PROJECT-X-c5-mage-tower
git merge --no-ff feature/PROJECT-X-c5-skills-domain
git merge --no-ff feature/PROJECT-X-c5-skills-tab
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
flutter analyze && flutter test
git worktree remove ../phaser-example-c5-skills-domain && git worktree remove ../phaser-example-c5-skills-tab
```

Expected: las dos uniones sin conflictos (no comparten ficheros), lo generado al día y todo en verde (582 tests). Los mensajes de los *merge* son los que propone git (`Merge branch '…'`), que el hook acepta como en C3.

- [x] **Step 2: Datos de prueba**

`test/mocks/presentation/features/forest/forest_bloc_mock.dart`: importar los dos casos de uso nuevos de `use-cases/hero/` y, después de `buyGearUseCase: …`:

```dart
      getSkillOptionsUseCase: GetSkillOptionsUseCase(sessionRepository: sessionRepository),
      learnSkillUseCase: LearnSkillUseCase(sessionRepository: sessionRepository),
```

`test/mocks/presentation/features/forest/hero_panel_data_mock.dart`: en `newHero`, `newHeroCopy` y `readyToBuySword`, una línea más después de `rows: […],` (decisión 9; los mundos de C3 no tienen la Torre):

```dart
    skills: SkillItemDataMock.withoutTower,
```

`test/mocks/presentation/features/forest/hud_data_mock.dart`, después de `withHeroReadyToBuy`:

```dart
  static HudData get withSkillReadyToLearn => _make(wood: 0, hero: HeroPanelDataMock.readyToLearnDoubleStrike);
```

`test/mocks/presentation/features/forest/forest_effect_mock.dart`: importar `skill_id.dart` y, al final de la clase:

```dart
  static const SkillLearnedEffect doubleStrikeLearned = SkillLearnedEffect(skill: SkillId.doubleStrike);

  static const SkillLearnedEffect doubleStrikeLearnedCopy = SkillLearnedEffect(skill: SkillId.doubleStrike);

  static const SkillLearnedEffect dodgeLearned = SkillLearnedEffect(skill: SkillId.dodge);
```

`test/mocks/presentation/features/forest/game/forest_data_mock.dart`: importar `skill_id.dart` y, al final de la clase:

```dart
  static final ForestData skillLearned = ForestData(
    world: world,
    player: player,
    effects: const [SkillLearnedEffect(skill: SkillId.doubleStrike)],
  );
```

- [x] **Step 3: Tests que fallan**

`test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart` (decisiones 11 y 15):

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/game/skill_scenario_mock.dart';
import '../../../../../mocks/domain/world/funds_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/skill_item_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenTheGameStartsWithoutTheMageTowerThenEverySkillAsksForIt',
    build: () {
      // given
      return ForestBlocMock.make(SkillScenarioMock.withoutTower(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.hero.skills, SkillItemDataMock.withoutTower);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheTowerIsBuiltAndTheDoubleStrikeIsPaidForThenItCanBeLearned',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice),
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
      expect(bloc.state.data.hud!.hero, HeroPanelDataMock.readyToLearnDoubleStrike);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenLearningTheDoubleStrikeThenItIsKnownSparklesInBlueAndRaisesPower',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hero = bloc.state.data.hud!.hero;
      expect(effects, contains(ForestEffectMock.doubleStrikeLearned));
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(
          Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: SkillId.doubleStrike)),
        ),
      );
      expect((hero.attack, hero.power), (4, 34));
      expect(hero.skills, SkillItemDataMock.afterLearningDoubleStrike);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenLearningWithoutTheMageTowerThenSaysWhichBuildingIsMissing',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withoutTower(funds: FundsMock.doubleStrikePrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<SkillLearnedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(
          Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.mageTower)),
        ),
      );
      expect(bloc.state.data.hud!.hero.power, 31);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenLearningAKnownSkillThenSaysItIsAlreadyKnown',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.doubleStrikePrice, hero: HeroEntityMock.withDoubleStrike),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageSkillAlreadyKnown),
      );
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenGoldIsShortThenSaysThereAreNotEnoughResources',
    build: () {
      // given
      return ForestBlocMock.make(
        SkillScenarioMock.withTower(funds: FundsMock.tenGoldShortOfDoubleStrike),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestSkillLearnRequested(skill: SkillId.doubleStrike));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<SkillLearnedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageNotEnoughResources),
      );
    },
  );
}
```

`test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`:
- imports `forest/hero_panel_section.dart`, `skill_id.dart` y `skill_tile.dart`;
- `pumpOverlay` recibe la lista de habilidades aprendidas:

```dart
  Future<List<BlueprintId>> pumpOverlay(
    WidgetTester tester,
    HudData hud, {
    List<GearId>? gears,
    VoidCallback? onArenaPressed,
    List<SkillId>? skills,
  }) async {
    final selected = <BlueprintId>[];
    await tester.pumpHud(
      HudOverlay(
        hud: hud,
        onBuildSelected: selected.add,
        onGearSelected: (gears ?? []).add,
        onArenaPressed: onArenaPressed ?? () {},
        onSkillSelected: (skills ?? []).add,
      ),
    );
    return selected;
  }
```

- antes de `testWhenBuildIsTappedWhileTheHeroPanelIsOpenThenOnlyTheBuildMenuIsShown`:

```dart
  testWidgets('testWhenTheSkillsTabIsOpenedThenLearningReportsTheSkill', (tester) async {
    // given
    final skills = <SkillId>[];
    await pumpOverlay(tester, HudDataMock.withSkillReadyToLearn, skills: skills);
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();
    await tester.tap(find.byKey(SkillTile.learnKey(SkillId.doubleStrike)));
    await tester.pump();

    // then
    expect(find.byType(SkillTile), findsNWidgets(3));
    expect(skills, [SkillId.doubleStrike]);
  });
```

`test/layers/presentation/features/forest/models/forest_effect_test.dart`, al final de `main`:

```dart
  test('testWhenComparingLearnedSkillsThenOnlyTheSameSkillIsEqual', () {
    // given
    const first = ForestEffectMock.doubleStrikeLearned;

    // when
    final sameSkill = first == ForestEffectMock.doubleStrikeLearnedCopy;
    final otherSkill = first == ForestEffectMock.dodgeLearned;

    // then
    expect(sameSkill, isTrue);
    expect(first.hashCode, ForestEffectMock.doubleStrikeLearnedCopy.hashCode);
    expect(otherSkill, isFalse);
  });
```

`test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`, antes de `testWhenTheHeroHitsAnEnemyThenAFewDropsOfBloodFlyAwayFromHim` (decisión 12: la misma ráfaga, sólo cambia el tipo):

```dart
  test('testWhenASkillIsLearnedThenTheSameSparklesRiseInBlue', () {
    // given
    const feet = ParticleMock.heroFeet;
    final gold = ParticleBursts.sparkles(feet: feet, random: ParticleMock.sparklesRandom);

    // when
    final blue = ParticleBursts.sparkles(
      feet: feet,
      random: ParticleMock.sparklesRandom,
      kind: ParticleKind.magicSparkle,
    );

    // then
    expect(blue.map((sparkle) => sparkle.kind).toSet(), {ParticleKind.magicSparkle});
    expect(blue.map((sparkle) => sparkle.origin), gold.map((sparkle) => sparkle.origin));
    expect(blue.map((sparkle) => sparkle.velocityX), gold.map((sparkle) => sparkle.velocityX));
  });
```

`test/layers/presentation/features/forest/game/forest_scene_component_test.dart`, antes de `testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced`:

```dart
  testWithFlameGame('testWhenASkillIsLearnedThenBlueSparklesBurstOnTheHero', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.skillLearned);
    await game.ready();

    // then
    final bursts = scene.children.whereType<ParticleBurstComponent>();
    expect(bursts, hasLength(1));
    expect(bursts.single.priority, greaterThan(scene.player!.priority));
  });
```

`test/layers/presentation/features/forest/forest_page_test.dart`: importar `forest/hero_panel_section.dart`, `skill_id.dart` y `skill_tile.dart` y, antes de `testWhenEscapeIsPressedDuringPlacementThenThePlacementIsCancelled` (usa la DI real, así que también comprueba que la página pide los dos casos de uso nuevos a `locator`):

```dart
  testWidgets('testWhenTheSkillsTabIsOpenedThenEachSkillAsksForTheMageTower', (tester) async {
    // given
    await pumpGame(tester);
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // then
    expect(find.byType(SkillTile), findsNWidgets(SkillId.values.length));
    expect(
      find.text(
        Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.mageTower)),
      ),
      findsNWidgets(SkillId.values.length),
    );
  });
```

Run: `flutter test test/layers/presentation/features/forest`
Expected: FAIL al compilar (`ForestSkillLearnRequested`, `SkillLearnedEffect`, `onSkillSelected`, `ParticleKind.magicSparkle`… no existen).

- [x] **Step 4: Enum, efecto, partículas y escena**

`lib/core/config/constants/enum/forest/particle_kind.dart`:

```dart
enum ParticleKind { woodChip, dust, sparkle, bloodDrop, magicSparkle }
```

`lib/layers/presentation/features/forest/models/forest_effect.dart`: importar `../../../../../core/config/constants/enum/skill_id.dart` y, al final del fichero:

```dart
final class SkillLearnedEffect extends ForestEffect {
  final SkillId skill;

  const SkillLearnedEffect({required this.skill});

  @override
  bool operator ==(Object other) => identical(this, other) || other is SkillLearnedEffect && other.skill == skill;

  @override
  int get hashCode => Object.hash(SkillLearnedEffect, skill);
}
```

`lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`, la cabecera de `sparkles` y la primera línea del `Particle` (el resto no cambia):

```dart
  static List<Particle> sparkles({
    required PositionEntity feet,
    required math.Random random,
    ParticleKind kind = ParticleKind.sparkle,
  }) {
    return List.generate(sparklesPerPurchase, (_) {
      final speed = _between(random, sparkleSpeedMin, sparkleSpeedMax);
      final angle = _between(random, sparkleAngleMin, sparkleAngleMax) * math.pi / 180;
      return Particle(
        kind: kind,
```

`lib/layers/presentation/features/forest/game/particles/particle_burst_component.dart`:
- constante después de `bloodDrop`:

```dart
  static const Color magicSparkleColor = Color(0xFF8FC8FF);
```

- el caso `sparkle` pasa a usar un método común, y el caso nuevo va al final del `switch` de `render`:

```dart
        case ParticleKind.sparkle:
          _renderSparkle(canvas, at, sparkleSize * particle.scale(_ageSeconds), sparkleColor.withValues(alpha: alpha));
        case ParticleKind.bloodDrop:
          _paint.color = bloodColor.withValues(alpha: alpha);
          canvas.drawRect(bloodDrop.shift(Offset(at.x, at.y)), _paint);
        case ParticleKind.magicSparkle:
          _renderSparkle(
            canvas,
            at,
            sparkleSize * particle.scale(_ageSeconds),
            magicSparkleColor.withValues(alpha: alpha),
          );
```

- el método, antes de `_renderChip`:

```dart
  void _renderSparkle(Canvas canvas, PositionEntity at, double size, Color color) {
    _paint.color = color;
    canvas.drawRect(Rect.fromCenter(center: Offset(at.x, at.y), width: size, height: size), _paint);
  }
```

`lib/layers/presentation/features/forest/game/forest_scene_component.dart`:
- import `../../../../../core/config/constants/enum/forest/particle_kind.dart`;
- los dos últimos casos del `switch` de `_play`:

```dart
      case GearPurchasedEffect():
        _sparkleOnPlayer(ParticleKind.sparkle);
      case SkillLearnedEffect():
        _sparkleOnPlayer(ParticleKind.magicSparkle);
```

- `_onGearPurchased` pasa a ser:

```dart
  void _sparkleOnPlayer(ParticleKind kind) {
    final player = _player;
    if (player == null) return;
    final feet = PositionEntity(x: player.position.x, y: player.position.y);
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.sparkles(feet: feet, random: _random, kind: kind),
        sortY: ParticleBursts.sparklesSortY(feet),
      ),
    );
  }
```

- [x] **Step 5: `HudOverlay` y la página**

`lib/layers/presentation/features/forest/widgets/hud_overlay.dart` (decisión 8):
- imports `../../../../../core/config/constants/enum/forest/hero_panel_section.dart` y `../../../../../core/config/constants/enum/skill_id.dart`;
- campo `final ValueChanged<SkillId> onSkillSelected;` después de `onArenaPressed`, y `required this.onSkillSelected,` al final del constructor;
- el caso `hero` de `_menu`:

```dart
      HudMenu.hero => HeroPanel(
        hero: widget.hud.hero,
        onBuy: widget.onGearSelected,
        onLearn: widget.onSkillSelected,
        sections: HeroPanelSection.values,
      ),
```

`lib/layers/presentation/features/forest/forest_page.dart`:
- imports `../../../domain/use-cases/hero/get_skill_options_use_case.dart` y `learn_skill_use_case.dart`;
- en `BlocProvider.create`, después de `buyGearUseCase: …`:

```dart
        getSkillOptionsUseCase: locator.get<GetSkillOptionsUseCase>(),
        learnSkillUseCase: locator.get<LearnSkillUseCase>(),
```

- en `_hudOverlay`, al final de `HudOverlay(…)`:

```dart
      onSkillSelected: (skill) => bloc.add(ForestSkillLearnRequested(skill: skill)),
```

- [x] **Step 6: Evento y BLoC**

`lib/layers/presentation/features/forest/bloc/forest_event.dart`, al final (decisión 13):

```dart
final class ForestSkillLearnRequested extends ForestEvent {
  final SkillId skill;

  const ForestSkillLearnRequested({required this.skill});
}
```

`lib/layers/presentation/features/forest/bloc/forest_bloc.dart`:
- imports: `learn_skill_result.dart`, `skill_id.dart`, `skill_option_state.dart` (de `core/config/constants/enum/`); `domain/entities/hero/skill_option_entity.dart`; `domain/rules/skills.dart`; `domain/use-cases/hero/get_skill_options_use_case.dart` y `learn_skill_use_case.dart`; `../models/skill_item_data.dart`;
- campos y parámetros del constructor, después de los de `BuyGearUseCase`:

```dart
  final GetSkillOptionsUseCase _getSkillOptionsUseCase;
  final LearnSkillUseCase _learnSkillUseCase;
```

```dart
    required this._getSkillOptionsUseCase,
    required this._learnSkillUseCase,
```

- caso nuevo al final del `switch` de `on<ForestEvent>`:

```dart
        ForestSkillLearnRequested() => _onSkillLearnRequested(event, emit),
```

- el manejador y el aprendizaje (decisión 11), antes de `_react`:

```dart
  Future<void> _onSkillLearnRequested(ForestSkillLearnRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    final effects = <ForestEffect>[];
    _learnSkill(event.skill, effects: effects);
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }

  void _learnSkill(SkillId id, {required List<ForestEffect> effects}) {
    switch (_learnSkillUseCase(id: id)) {
      case LearnSkillResult.ok:
        _showMessage(Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: id)));
        effects.add(SkillLearnedEffect(skill: id));
      case LearnSkillResult.missingBuilding:
        _showMessage(Internationalize.forestHeroNeedsBuilding(name: _skillBuildingName));
      case LearnSkillResult.alreadyKnown:
        _showMessage(Internationalize.forestMessageSkillAlreadyKnown);
      case LearnSkillResult.notEnoughResources:
        _showMessage(Internationalize.forestMessageNotEnoughResources);
    }
  }
```

- en `_heroPanel`, al final de `HeroPanelData(…)`:

```dart
      skills: [for (final option in _getSkillOptionsUseCase()) _skillItem(option)],
```

- y, después de `_workshopName` (decisiones 8 y 10):

```dart
  SkillItemData _skillItem(SkillOptionEntity option) {
    final skill = option.skill;
    return SkillItemData(
      id: skill.id,
      name: Internationalize.forestSkillName(id: skill.id),
      description: Internationalize.forestSkillDescription(id: skill.id),
      costText: option.state == SkillOptionState.known ? null : _amounts(skill.cost),
      reasonText: switch (option.state) {
        SkillOptionState.needsBuilding => Internationalize.forestHeroNeedsBuilding(name: _skillBuildingName),
        SkillOptionState.unaffordable => Internationalize.forestMissing(amounts: _amounts(option.missing)),
        SkillOptionState.known || SkillOptionState.available => null,
      },
      isKnown: option.state == SkillOptionState.known,
      canLearn: option.canLearn,
    );
  }

  String get _skillBuildingName => Internationalize.forestBlueprint(id: Skills.building);
```

Run: `flutter test test/layers/presentation/features/forest`
Expected: PASS, incluidos los tests anteriores del BLoC y del HUD (`forest_bloc_hero_test.dart` sigue igual: sus paneles esperados ya llevan `SkillItemDataMock.withoutTower`).

- [x] **Step 7: Documentar en `CLAUDE.md`**

En *Architecture*:
- `entities/<feature>/`: "hero (`CombatStatsEntity`, `HeroEntity`, `HeroStatusEntity`)" pasa a "hero (`CombatStatsEntity`, `HeroEntity`, `HeroStatusEntity`, `SkillEntity`, `SkillOptionEntity` with a `SkillOptionState`, `missing` and `canLearn`)".
- `rules/`: "`Blueprints` catalogue (house, forge, armory, mage tower)" y, después del de `Gear`, "`Skills` catalogue (gold only, cheapest first; `Skills.building`: learned at the mage tower),".
- `use-cases/`: en `hero/`, después de `GetGearOptionsUseCase`, "`LearnSkillUseCase` (checks a finished mage tower, that the skill is not known yet and the funds, in that order; pays with `World.spend` and adds the skill with `World.updateHero`), `GetSkillOptionsUseCase` (one option per skill, in `Skills.all` order)".
- `features/forest/bloc/`: añadir el evento `ForestSkillLearnRequested` después de `ForestArenaRequested (…)`.
- `features/forest/models/`: añadir `SkillItemData` y el efecto `SkillLearnedEffect` ("with `GearPurchasedEffect`, `SkillLearnedEffect`").
- `features/forest/game/`: en `particles/`, "chips, dust, the gear-purchase sparkles, the same sparkles in blue when a skill is learned (`ParticleKind.magicSparkle`) and blood drops: …".
- `features/forest/widgets/`: "`HeroPanel` (sections: gear now; the skills tab is ready for C5 and hidden while `sections` has one entry) + `GearRow` + `GearOptionTile`" pasa a "`HeroPanel` (tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`".

En *Key cross-cutting conventions*, en la línea *New resource, tool or building*: "(recoloured roof via `ROOF_RAMP`)" pasa a "(recoloured roof via `ROOF_RAMP`, taller with `roof_stretch`)".

- [x] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/forest lib/layers/presentation/features/forest test/layers/presentation/features/forest test/mocks/presentation/features/forest
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida en lo generado, `No issues found!` y todo en verde (593 tests).

- [x] **Step 9: Commit**

```bash
git add lib/core/config/constants/enum/forest lib/layers/presentation test
git commit -m "[PROJECT-X]: Learn skills from the hero panel with a blue sparkle"
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the mage tower and the skills in the project guide"
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida.

---

### Task TC5.5: Nombres de las habilidades en la arena

**Files:**
- Modify:
  - `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart` (`arenaSkillUsed` en lugar de `arenaDodge`)
  - `lib/layers/presentation/features/arena/models/arena_effect.dart`
  - `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
  - `lib/layers/presentation/features/arena/game/arena_scene_component.dart`
  - `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - Tests:
    - `test/core/assets/i18n/internationalize_test.dart`
    - `test/layers/presentation/features/arena/models/arena_effect_test.dart`
    - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
    - `test/layers/presentation/features/arena/game/arena_scene_component_test.dart`
  - Mocks: `test/mocks/presentation/features/arena/arena_effect_mock.dart`, `arena_data_mock.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: `Internationalize.forestSkillName` (TC5.3); `HeroEntityMock.withDoubleStrike` (TC5.2); `HeroEntityMock.veteranWithSecondWind`, `ArenaBlocMock`, `ArenaEffectMock`, `ArenaDataMock.replaying`, `FloatingTextComponent`, `FighterComponent.headPoint` (C2).
- Produces:
  ```dart
  // internationalize.dart (sustituye a arenaDodge)
  static String Internationalize.arenaSkillUsed({required SkillId id});   // "¡Golpe doble!", "¡Segundo aliento!", "¡Esquiva!"

  // arena_effect.dart
  final class SkillUsedEffect extends ArenaEffect { final SkillId skill; }

  // ArenaRenderConstants.skillNameLift = 12

  // mocks nuevos
  ArenaEffectMock.doubleStrikeUsed / .doubleStrikeUsedCopy / .secondWindUsed
  ArenaDataMock.heroGotASecondWind
  ```

- [x] **Step 1: Datos de prueba**

`test/mocks/presentation/features/arena/arena_effect_mock.dart`: importar `skill_id.dart` y, antes de `won`:

```dart
  static const SkillUsedEffect doubleStrikeUsed = SkillUsedEffect(skill: SkillId.doubleStrike);

  static const SkillUsedEffect doubleStrikeUsedCopy = SkillUsedEffect(skill: SkillId.doubleStrike);

  static const SkillUsedEffect secondWindUsed = SkillUsedEffect(skill: SkillId.secondWind);
```

`test/mocks/presentation/features/arena/arena_data_mock.dart`, después de `heroDodged`:

```dart
  static ArenaData get heroGotASecondWind => replaying.copyWith(
    effects: const [ArenaEffectMock.heroHealedTwelve, ArenaEffectMock.secondWindUsed],
  );
```

- [x] **Step 2: Tests que fallan**

`test/core/assets/i18n/internationalize_test.dart`, al final de `main`:

```dart
  test('testWhenASkillIsUsedInTheArenaThenItsNameIsShouted', () {
    // given
    // when
    final shouts = SkillId.values.map((id) => Internationalize.arenaSkillUsed(id: id)).toList();

    // then
    expect(shouts, ['¡Golpe doble!', '¡Segundo aliento!', '¡Esquiva!']);
  });
```

`test/layers/presentation/features/arena/models/arena_effect_test.dart`, al final de `main`:

```dart
  test('testWhenComparingUsedSkillsThenOnlyTheSameSkillIsEqual', () {
    // given
    const first = ArenaEffectMock.doubleStrikeUsed;

    // when
    final sameSkill = first == ArenaEffectMock.doubleStrikeUsedCopy;
    final otherSkill = first == ArenaEffectMock.secondWindUsed;

    // then
    expect(sameSkill, isTrue);
    expect(first.hashCode, ArenaEffectMock.doubleStrikeUsedCopy.hashCode);
    expect(otherSkill, isFalse);
  });
```

`test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`:
- antes de `testWhenTheHeroGetsASecondWindThenTheHealIsPlayedWithTheHealthGained`. Contra el bandido novato, el tercer ataque del héroe (`[4]`) va seguido del golpe doble (`[5]`) y de su nombre (`[6]`):

```dart
  blocTest<ArenaBloc, ArenaState>(
    'testWhenTheHeroStrikesTwiceThenTheSecondBlowIsFollowedByTheSkillName',
    build: () {
      // given
      world = WorldMock.withHero(HeroEntityMock.withDoubleStrike);
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
      expect(effects.sublist(4, 7), [
        ArenaEffectMock.banditHitForFour,
        ArenaEffectMock.banditHitForFour,
        ArenaEffectMock.doubleStrikeUsed,
      ]);
      expect(effects.whereType<SkillUsedEffect>(), [ArenaEffectMock.doubleStrikeUsed]);
    },
  );
```

- en `testWhenTheHeroGetsASecondWindThenTheHealIsPlayedWithTheHealthGained`, el `then` pasa a ser (decisión 14):

```dart
      expect(effects[10], ArenaEffectMock.heroHealedTwelve);
      expect(effects[11], ArenaEffectMock.secondWindUsed);
      expect(effects.last, ArenaEffectMock.lost);
```

`test/layers/presentation/features/arena/game/arena_scene_component_test.dart`:
- importar `package:rpg/core/config/constants/enum/skill_id.dart`;
- en `testWhenTheHeroDodgesThenTheDodgeFloatsWithoutBlood`:

```dart
    expect(texts, [Internationalize.arenaSkillUsed(id: SkillId.dodge)]);
```

- antes de `testWhenTheFightEndsThenTheBarsJumpToTheFinalHealth`:

```dart
  testWithFlameGame('testWhenASkillIsUsedThenItsNameFloatsAboveTheHerosHeal', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.heroGotASecondWind);
    await game.ready();

    // then
    final texts = scene.children.whereType<FloatingTextComponent>().toList();
    expect(texts.map((text) => text.text), [
      Internationalize.arenaHeal(amount: 12),
      Internationalize.arenaSkillUsed(id: SkillId.secondWind),
    ]);
    expect(texts.last.position.y, lessThan(texts.first.position.y));
    expect(texts.last.position.x, texts.first.position.x);
  });
```

Run: `flutter test test/core/assets test/layers/presentation/features/arena`
Expected: FAIL al compilar (`arenaSkillUsed`, `SkillUsedEffect` no existen).

- [x] **Step 3: Texto y efecto**

`lib/core/assets/i18n/translations/es.json`, bloque `arena`: la línea `"dodge": "¡Esquiva!",` pasa a ser

```json
    "skillUsed": "¡{name}!",
```

`lib/core/assets/i18n/internationalize.dart`: `arenaDodge` pasa a ser

```dart
  static String arenaSkillUsed({required SkillId id}) =>
      '$_arena.skillUsed'.tr(namedArgs: {'name': forestSkillName(id: id)});
```

`lib/layers/presentation/features/arena/models/arena_effect.dart`: importar `../../../../../core/config/constants/enum/skill_id.dart` y, al final del fichero:

```dart
final class SkillUsedEffect extends ArenaEffect {
  final SkillId skill;

  const SkillUsedEffect({required this.skill});

  @override
  bool operator ==(Object other) => identical(this, other) || other is SkillUsedEffect && other.skill == skill;

  @override
  int get hashCode => Object.hash(SkillUsedEffect, skill);
}
```

- [x] **Step 4: BLoC y escena**

`lib/layers/presentation/features/arena/bloc/arena_bloc.dart`:
- import `../../../../../core/config/constants/enum/skill_id.dart`;
- en `_emitReplay`, la línea de los turnos:

```dart
        for (var turn = previous.turnIndex + 1; turn <= next.turnIndex; turn++) ..._effectsFor(next, turn),
```

- antes de `_effectFor` (casos en el orden de `FightAction`):

```dart
  List<ArenaEffect> _effectsFor(FightReplayData replay, int turnIndex) {
    final effect = _effectFor(replay, turnIndex);
    return switch (replay.log.turns[turnIndex].action) {
      FightAction.hit => [effect],
      FightAction.doubleStrike => [effect, const SkillUsedEffect(skill: SkillId.doubleStrike)],
      FightAction.dodge => [effect],
      FightAction.secondWind => [effect, const SkillUsedEffect(skill: SkillId.secondWind)],
    };
  }
```

`lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`, después de `floatingTextHeight`:

```dart
  static const double skillNameLift = 12;
```

`lib/layers/presentation/features/arena/game/arena_scene_component.dart`:
- imports `../../../../../core/config/constants/enum/skill_id.dart`, `../../../../domain/entities/geometry/position_entity.dart` y `render/arena_render_constants.dart`;
- el caso de la esquiva y el caso nuevo, al final del `switch` de `_play`:

```dart
      case DodgeEffect(:final side, :final index):
        _float(side, index, Internationalize.arenaSkillUsed(id: SkillId.dodge), FloatingTextComponent.defaultColor);
```

```dart
      case SkillUsedEffect(:final skill):
        _floatSkillName(skill);
```

- el método, antes de `_float`:

```dart
  void _floatSkillName(SkillId skill) {
    final hero = _fighters[FighterRenderData.keyOf(FightSide.hero, 0)];
    if (hero == null) return;
    final head = hero.headPoint;
    add(
      FloatingTextComponent(
        text: Internationalize.arenaSkillUsed(id: skill),
        at: PositionEntity(x: head.x, y: head.y - ArenaRenderConstants.skillNameLift),
      ),
    );
  }
```

Run: `flutter test test/core/assets test/layers/presentation/features/arena`
Expected: PASS, incluidos los tests de C2 con los índices de siempre.

- [x] **Step 5: Documentar en `CLAUDE.md`**

En *Architecture*, `features/arena/`: "`ArenaResultData` and sealed `ArenaEffect`s);" pasa a "`ArenaResultData` and sealed `ArenaEffect`s; a double strike or a second wind adds a `SkillUsedEffect` after its own effect, and the scene floats the skill name (`Internationalize.arenaSkillUsed`, also used for the dodge) above the hero);".

- [x] **Step 6: Verificación completa**

```bash
cd asset-packs/lpc && python3 build_assets.py && cd ../.. && git status --short lib/core/assets/images/lpc
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/arena test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/arena test/mocks/presentation/features/arena
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `build_assets.py` no cambia nada (`git status` sin salida), `git diff` sin salida en lo generado, `No issues found!` y todo en verde (597 tests en la máquina virtual de Dart y 40 en Chrome).

- [x] **Step 7: Commit**

```bash
git add lib/core/assets lib/layers/presentation test
git commit -m "[PROJECT-X]: Shout the skill names in the arena"
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the arena skill names in the project guide"
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida.

---

## Prueba manual

En Chrome (`flutter run -d chrome`), en el emulador Android (`flutter run -d emulator-5554`) y en el simulador iOS (`flutter run -d "iPhone 17"`), en horizontal:

1. **Pestañas:**
   - *Héroe* abre el panel con las pestañas *Equipo* (abierta) y *Habilidades*.
   - *Habilidades* lista *Golpe doble* (60 de oro), *Esquiva* (90) y *Segundo aliento* (130), cada una con su descripción, "Construye la Torre de magia" en color de aviso y *Aprender* desactivado.
   - Cerrar y volver a abrir el panel lo deja otra vez en *Equipo*.
2. **Edificio:**
   - En *Construir*, *Torre de magia* cuesta "30 de madera, 40 de oro". Sin oro no se puede colocar y dice lo que falta.
   - Gana oro en la arena (con 40 basta), tala hasta 30 de madera y colócala: el fantasma es la Torre (muro de piedra, tejado violeta alto).
   - Constrúyela: 12 martillazos y "Construcción terminada: Torre de magia". Se ve detrás del héroe y delante de los árboles de más arriba, como la casa.
   - En *Habilidades*, las tres pasan a decir "Faltan N de oro" (o nada, si ya hay oro de sobra).
3. **Aprender:**
   - Con 60 de oro, *Aprender* en *Golpe doble*: destello azul sobre el héroe, *snackbar* "Has aprendido: Golpe doble", el Poder sube de 31 a 34 (un 10 %) y la habilidad dice "Aprendida". El panel sigue abierto.
   - Las otras dos piden el oro que falta.
4. **Arena:**
   - Con *Golpe doble*, en una pelea, sobre el héroe flota "¡Golpe doble!" en su tercer ataque, justo después del segundo "−N" sobre el enemigo.
   - Con *Esquiva*, sigue saliendo "¡Esquiva!" cuando un golpe falla.
   - Con *Segundo aliento*, al bajar del 30 % de vida salen "+N" en verde y, encima, "¡Segundo aliento!".
5. **Móvil en horizontal:**
   - En el emulador y el simulador, el panel *Héroe* con la pestaña *Habilidades* abierta cabe (o se desplaza) sin rayas amarillas de desbordamiento, también bajo la `ResourceBar` (HUD estrecho de C2).
   - El frente de la Torre queda alineado con su huella (el héroe no la atraviesa ni se queda lejos al construir).
6. **Web:** en Chrome, con una ventana de 640 × 360, lo mismo que el punto 5. Esc sigue cancelando la colocación con el panel *Héroe* abierto.

Si el arte de la Torre (decisión 3) o el orden de las habilidades (decisión 4) no convencen, se apunta y se ajusta antes de cerrar la fase.

## Al cerrar C5

- Marca los checkboxes de las cinco tareas.
- **Sin `push` ni PR durante la implementación:** las ramas se quedan locales. El usuario hará después el `push` y la PR de `feature/PROJECT-X-c5-mage-tower` a `feature/PROJECT-X-arena`, con la prueba manual de las tres plataformas. Tras la unión, la batería de cierre en la rama de integración (README 3.0).
- Apunta en la sección 5 del README de la arena:
  - si TC5.2 y TC5.3 se hicieron en paralelo (ramas y uniones), como en C3;
  - las decisiones provisionales que sigan en pie tras la prueba manual (arte de la Torre, orden de las habilidades);
  - que `arenaDodge` / `arena.dodge` ya no existen (ahora `arenaSkillUsed` / `arena.skillUsed`), por si C4 o C6 los usaban;
  - que el `assert` de `HeroPanel` usa `sections.length > 0` y no `isNotEmpty` (decisión 8).
- Avisa a quien lleve C7:
  - el catálogo `Skills` (precios 60/90/130, sólo oro) y la Torre (30 de madera y 40 de oro) entran en el test de equilibrado;
  - `SkillOptionEntity.missing` y `HeroEntity.skills` sirven para las misiones `buildMageTower` y `learnASkill`; `SkillScenarioMock` y `HeroEntityMock.withDoubleStrike` ya existen;
  - el daño por rangos (que C7 trae de `ARENA-FIXES.md`) cambia números que fija C5: el Poder 31 → 34 de `learn_skill_use_case_test.dart`, `skill_flow_test.dart` y `forest_bloc_skill_test.dart`, y los índices y el daño de `testWhenTheHeroStrikesTwiceThenTheSecondBlowIsFollowedByTheSkillName` (`arena_bloc_test.dart`).
- **Cruces pendientes con la aldea** (README 3.2; los resuelve el flujo de la arena al traer `develop`):
  - **F5 (piedra):** añadir `Resource.stone: 10` al coste de `Blueprints.mageTower`, y ajustar `BlueprintEntityMock.mageTower`, `BuildOptionEntityMock.mageTower`, `BuildItemDataMock.mageTowerUnaffordable`, `SkillScenarioMock` (paga `Blueprints.mageTower.cost`, así que no cambia) y las listas de `get_build_options_use_case_test.dart` y `forest_bloc_test.dart`.
  - **F2 (guardado):** el `HeroDBO` debe guardar `skills`, y el mapper de edificios aceptar `mageTower` (TC5.1, Step 7).
- Si alguna firma de *Interfaces* cambió al implementar, actualízala aquí **y** en la ficha de C7, y apúntalo en la sección 5 del README.
