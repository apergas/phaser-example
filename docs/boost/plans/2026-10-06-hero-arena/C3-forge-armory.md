# C3 · Herrería y Armería — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | D (héroe) |
| **Depende de** | C0 |
| **Issue / milestone** | `phase:C3` · `stream:D` · milestone `C3 Forge and armory` (un issue por tarea: TC3.1, TC3.2, TC3.3, TC3.4) |

**Goal:** Que la aldea sirva para hacer más fuerte al héroe: se construyen la Herrería y la Armería y en ellas se compran armas y armaduras con madera y oro. El Poder del héroe sube y se ve en un panel nuevo, *Héroe*, en el HUD del bosque.

**Architecture:**
- **Edificios:** `BlueprintId.forge` / `armory` al final del enum y sus entradas al final de `Blueprints.all`. Siguen la receta de `CLAUDE.md` (*New resource, tool or building*): textos, `SpriteNames`, frame del atlas con `build_assets.py` y `RenderConstants.buildingFrontOffset`.
- **Compra (dominio):**
  - `Gear.workshopFor(slot)` dice qué edificio vende cada ranura.
  - `BuildingListRules.hasComplete(id)` (extensión sobre `Iterable<BuildingEntity>`, en `world/extensions/building_rules.dart`) dice si hay un edificio **terminado** de ese tipo.
  - `BuyGearUseCase` comprueba edificio, nivel siguiente y fondos, **en ese orden**; paga con `World.spend` y equipa con `World.updateHero`.
  - `GetGearOptionsUseCase` devuelve un `GearOptionEntity` por pieza, desde la equipada hasta la última de cada ranura.
- **Presentación:**
  - `HudData.hero: HeroPanelData` (Poder, tres atributos y una `GearRowData` por ranura). El BLoC lo construye en `_hudData` con `GetHeroStatusUseCase` y `GetGearOptionsUseCase`, como el resto del HUD.
  - `HeroPanel` (un `HudPanel`) con `GearRow` + `GearOptionTile`. Se abre con el botón *Héroe* (`HudMenu.hero`, icono `hero.svg`).
  - Evento `ForestGearPurchaseRequested(gear)`, efecto `GearPurchasedEffect` (destello dorado sobre el héroe con `ParticleBurstComponent`) y *snackbar* "Has comprado: Espada corta".
- Sin cambios en `World`, `WorldState` ni `HeroEntity` (C0 ya tiene `weaponTier` / `armorTier`, `funds`, `spend` y `updateHero`).

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame, `flutter_svg`, `injectable`, `easy_localization`; tests con `flutter_test`, `mockito`, `bloc_test`, `flame_test`; arte con `asset-packs/lpc/build_assets.py` (Pillow).

**Precondición: C0 fusionada en `feature/PROJECT-X-arena`.** Este plan usa estos nombres de C0. Antes de empezar, comprueba que siguen igual:
- `GearId` (8 valores), `GearSlot { weapon, armor }`, `Resource { wood, gold }`, `HudMenu { quests, build }`;
- `GearEntity` (`id`, `slot`, `tier`, `cost`, `attack`, `defense`, `health`) y el catálogo `Gear` (`all`, `byId`, `of`, `find`, `maxTier`) con los costes de la ficha de C0 (Espada corta: 20 de madera y 10 de oro);
- `HeroRules.tierOf` / `nextGear` / `withGear` / `stats` / `power`; `World.hero` / `updateHero` / `funds` / `earn` / `spend`; `InventoryRules.missing`;
- `GetHeroStatusUseCase` → `HeroStatusEntity(hero, stats, power)`;
- mocks `HeroEntityMock.mock`, `HeroEntityMock.fullyGeared`, `WorldMock.make` / `withHero`, `FundsMock`, `CombatStatsEntityMock`, `GameSessionEntityMock.playing`.

Si algo ha cambiado, adapta los fragmentos y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- `flutter test` en verde, en especial:
  - `blueprints_test.dart` (los dos edificios nuevos);
  - `buy_gear_use_case_test.dart` (cada `BuyGearResult` y el orden de las comprobaciones);
  - `get_gear_options_use_case_test.dart` y `gear_flow_test.dart` (construir la Herrería con los casos de uso reales, cobrar con `world.earn` y comprar: Ataque de 4 a 7, Poder de 31 a 40);
  - `forest_bloc_hero_test.dart` (panel, compra, efecto y mensajes);
  - `hero_panel_test.dart`, `gear_row_test.dart`, `gear_option_tile_test.dart`, `hud_overlay_test.dart`;
  - `forest_scene_component_test.dart` (el fantasma cambia de casa a Herrería: desviación de F0).
- Prueba manual en Chrome, el emulador Android y el simulador iOS (sección *Prueba manual*).

> **Coordinación C2 ↔ C3:** las dos fases añaden a `HudButton` el mismo parámetro opcional `final String? icon` (con `flutter_svg`, como primer hijo del `Row`). La que se fusione **primero** en `feature/PROJECT-X-arena` lo añade; la segunda se salta ese paso y usa el que ya existe (si la firma difiere, se queda la ya fusionada). Lo mismo con el fichero de tests del BLoC: C3 usa `forest_bloc_hero_test.dart` para no chocar con C2. La comprobación del ancho de la barra con cuatro botones (README, sección 3.2) la hace a ojo quien llegue segundo.

## Decisiones del plan

Lo que este plan fija o añade sobre la ficha (todo lo demás de la ficha se mantiene tal cual):

1. **Costes sólo de madera y oro.** En `feature/PROJECT-X-arena` (y en `develop`) todavía no están F5, F6 ni F8. Los edificios cuestan 25 de madera y el equipo usa los costes de `Gear` de C0. La piedra la añade la fase que llegue segunda (README 3.2; ver *Al cerrar C3*).
2. **Edificios:** Herrería y Armería con la misma huella que la casa (`footprintRadius: 40`), 10 martillazos y `RenderConstants.buildingFrontOffset = 24`. El muro y la puerta son de la misma altura que los de la casa y el pivote está abajo en el centro, así que el frente queda igual. La chimenea sólo alarga el frame por arriba.
3. **Arte, comprobado con el script:**
   - `thatched-roof.png` (la parte que usa la casa) tiene **exactamente 9 colores**, así que `recolour()` cambia el tejado entero con dos rampas de 9 colores (gris oscuro y rojo).
   - El tejado se recolorea **antes** de componer el edificio: si se recolorea la imagen entera, la puerta comparte colores con la paja y también cambia.
   - **Herrería:** muro de piedra con entramado (`cottage.png`, `(0, 256, 96, 352)`), tejado gris oscuro y una chimenea con el bloque de piedra agrietada del `terrain_atlas` (celda 32 × 32 en `(448, 480, 480, 512)`), que asoma 18 px por encima del tejado. Frame `forge`, 120 × 209.
   - **Armería:** el muro de la casa con el tejado rojo. Frame `armory`, 120 × 191.
   - `build_house()` pasa a usar una función común `build_cottage()`. El frame `house` sale idéntico, byte a byte (comprobado).
   - No entra ninguna fuente nueva: `cottage.png` y `terrain_atlas.png` ya están acreditados. `CREDITS.md` sólo amplía la sección de la casa.
4. **Orden de `BuyGearResult`:** `missingBuilding` → `notNextTier` → `notEnoughResources` → `ok`. Por eso comprar la pieza equipada (o una de nivel 0) sin edificio devuelve `missingBuilding`. Con edificio, devuelve `notNextTier`.
5. **"Edificio terminado"** es `building.isComplete`. Una Herrería a medio construir no vende nada. Se comprueba con la extensión `BuildingListRules.hasComplete` sobre `world.buildings` (E2: la operación va en `world/extensions/`).
6. **`GetGearOptionsUseCase`:**
   - Devuelve, por ranura (en el orden de `GearSlot.values`) y por nivel ascendente, las piezas **desde la equipada** hasta `Gear.maxTier(slot)`. Las de niveles inferiores no salen (ya se superaron).
   - Estados:
     - `equipped`: la del nivel actual, con `missing: {}`;
     - el nivel siguiente: `needsBuilding` si falta el edificio terminado; si no, `unaffordable` si `world.funds.missing(cost)` no está vacío; si no, `available`;
     - `locked`: dos o más niveles por encima.
   - `missing` se calcula para toda pieza no equipada (también las `locked`). Así C5 o C7 pueden usarlo sin tocar el caso de uso.
7. **`GearOptionEntity`** sigue las reglas de entidad (`copyWith`, `==`/`hashCode` a mano, getter `canBuy`). Va en `entities/gear/`, junto a `GearEntity`.
8. **Panel *Héroe*:**
   - Título "HÉROE".
   - Línea de atributos: Poder en grande y Ataque, Defensa y Vida (etiqueta y número, como `ResourceBar`).
   - Una `GearRow` por ranura:
     - título en mayúsculas ("ARMA", "ARMADURA");
     - la pieza equipada con sus atributos y la marca "En uso";
     - la siguiente en una `GearOptionTile` (nombre, atributos, coste, motivo en color de aviso y botón *Comprar*, desactivado si `canBuy` es `false`);
     - si ya no hay siguiente, "Ya tienes la mejor pieza".
   - Las piezas `locked` no se muestran.
   - Ancho 260–360. Alto máximo: el de la pantalla menos 96, con scroll (en un móvil en horizontal, 360 px de alto, no desborda).
9. **Motivos de "no se puede comprar"** (`GearItemData.reasonText`):
   - `needsBuilding` → "Construye la Herrería" / "Construye la Armería" (`forest.hero.needsBuilding` con el nombre del edificio);
   - `unaffordable` → "Faltan 5 de oro" (reutiliza `forest.hud.missing` y `forest.amount.*`, como el menú *Construir*).
10. **Si la compra falla desde el BLoC** (no debería, el botón está desactivado; pero el evento se puede lanzar igualmente):
    - `missingBuilding` → *snackbar* "Construye la Armería";
    - `notNextTier` → "Antes tienes que comprar la pieza anterior.";
    - `notEnoughResources` → "No tienes recursos suficientes." (el texto que ya existe).
11. **`HudMenu.hero`** se añade al final (`{ quests, build, hero }`). Abrir *Héroe* cierra *Misiones* / *Construir*, igual que entre ellos. Comprar **no** cierra el panel, para ver cómo sube el Poder.
12. **Icono del botón:**
    - `HudButton` gana un parámetro opcional `icon` (ruta de un SVG, 18 × 18, delante del texto). *Misiones* y *Construir* siguen sin icono.
    - `CustomIcons.hero` apunta a `lib/core/assets/images/icons/hero.svg`: un escudo de 22 × 22 con borde gris, fondo de madera y una cruz dorada, con los colores de `axe.svg` / `gold.svg` (contenido en TC3.3).
13. **Preparado para C5:** `enum HeroPanelSection { gear, skills }` (en `enum/forest/`). `HeroPanel` recibe `sections` (por defecto `[HeroPanelSection.gear]`):
    - con una sola sección no hay pestañas;
    - con dos, se ven pestañas (`HudButton`), y la de `skills` ahora mismo está vacía (`SizedBox.shrink()`);
    - C5 sólo tiene que pasar `HeroPanelSection.values` desde `HudOverlay`, añadir sus datos a `HeroPanelData` y cambiar el caso `skills` del `switch` por su lista. El test de pestañas ya existe.
14. **Destello:**
    - `ParticleKind.sparkle` + `ParticleBursts.sparkles(feet:, random:)`: 10 cuadraditos dorados que suben desde el pecho del héroe (24 px sobre los pies, ±10 px en horizontal), sin gravedad, durante 0,6 s.
    - Se dibuja delante del héroe (`sortY = pies + 1`).
    - `GearPurchasedEffect(gear: GearId)` lleva la pieza, por si C5/C7 quieren variarlo.
15. **Textos** (`es.json`):
    - `forest.blueprint.forge` "Herrería", `forest.blueprint.armory` "Armería";
    - `forest.hero.*`: `title` "Héroe", `power` "Poder", `attack` "Ataque", `defense` "Defensa", `health` "Vida", `weaponStats` "Ataque {attack}", `armorStats` "Defensa {defense} · Vida {health}", `slot.weapon` "Arma", `slot.armor` "Armadura", `section.gear` "Equipo", `section.skills` "Habilidades", `equipped` "En uso", `buy` "Comprar", `needsBuilding` "Construye la {name}", `maxed` "Ya tienes la mejor pieza";
    - `forest.gear.<GearId>`: los 8 nombres de la ficha;
    - `forest.message.gearPurchased` "Has comprado: {name}", `forest.message.gearNotNextTier` "Antes tienes que comprar la pieza anterior.".
16. **Tests del BLoC en un fichero propio**, `forest_bloc_hero_test.dart` (como `forest_bloc_start_test.dart`), para no chocar con C2 en `forest_bloc_test.dart`. Usan los casos de uso reales sobre `MockGameSessionRepository` y sólo `MockNavigationService` (E11).
17. **Mundos de prueba con edificios terminados:** `GearScenarioMock` (`test/mocks/domain/game/`) construye la Herrería y la Armería con la API real (`earn` del coste → `orderConstruction` → `advanceFor(10000)`). No se añade un constructor con edificios a `World` (`world.dart` es un fichero caliente que sólo toca C0).
18. **Fantasma de colocación (desviación de F0):** C3 es la primera fase con un segundo edificio construible. TC3.1 añade el test de `ForestSceneComponent` que cambia la previsualización de casa a Herrería y comprueba que el fantasma se sustituye. `LpcAssetsMock` pasa a crear un frame por cada `BlueprintId`.
19. **Persistencia:** `HeroEntity` no cambia. F2 no está en la rama de la arena; cuando llegue, guardará los edificios por `BlueprintId`, y el cruce lo resuelve el flujo de la arena al traer `develop` (README 3.0). TC3.1 lo comprueba con un `grep`.

## Reparto

| Tarea | Capa | Depende de | Paralelizable |
|---|---|---|---|
| TC3.1 Herrería y Armería construibles | core (enum, textos) + domain (`Blueprints`) + presentación (`SpriteNames`, `RenderConstants`) + arte | C0 | No: va primero (las demás usan `BlueprintId.forge` / `armory`) |
| TC3.2 Comprar equipo (dominio) | core (enums) + domain (entidad, extensión, `Gear.workshopFor`, casos de uso) + DI | TC3.1 | Sí, con TC3.3 (no comparten ficheros) |
| TC3.3 Panel *Héroe* (widgets) | core (textos, `HeroPanelSection`, `hero.svg`) + presentación (modelos, `HeroPanel`, `GearRow`, `GearOptionTile`, `HudButton.icon`) | TC3.1 | Sí, con TC3.2 |
| TC3.4 Integración en el bosque | presentación (BLoC, `HudData`, `HudOverlay`, `HudMenu`, efecto, partículas, página) + `CLAUDE.md` | TC3.2, TC3.3 | No |

**Ramas (README 3.0):**
- Rama de fase `feature/PROJECT-X-c3-forge-armory`, que sale de `feature/PROJECT-X-arena`. Su PR va a `feature/PROJECT-X-arena`.
- TC3.1 y TC3.4 se hacen directamente en la rama de fase.
- TC3.2 y TC3.3, si se hacen a la vez, van cada una en su propio *worktree* y su propia rama, las dos desde la rama de fase con TC3.1 ya hecha:
  - `feature/PROJECT-X-c3-gear-purchase`;
  - `feature/PROJECT-X-c3-hero-panel`.

  Después se unen en la rama de fase con `git merge` (como TC1.1 y TC1.2). Si las hace una sola persona, van seguidas en la rama de fase.
- Commits `[PROJECT-X]: Imperative description`, sin ninguna atribución a IA. `CLAUDE.md` se añade con un `git add` aparte.

**Ficheros compartidos:**
- TC3.2 y TC3.3 no comparten ficheros, así que se unen sin conflictos.
- Con C2 (pantalla de la arena, que otro desarrollador hace a la vez) se comparten ficheros calientes, todos con cambios **aditivos** (al final del bloque; casos de `switch` en orden de declaración):
  - `hud_overlay.dart` (C2 añade *Arena*) y `hud_button.dart` (las dos fases quieren un icono: la que llega segunda reutiliza el parámetro `icon` de la primera);
  - `forest_bloc.dart`, `forest_event.dart`, `forest_page.dart`, `custom_icons.dart`, `internationalize.dart`, `es.json`;
  - `particle_kind.dart`, `particle_bursts.dart` y `particle_burst_component.dart` (C2 añade `bloodDrop`; C3 añade `sparkle`);
  - `forest_bloc_mock.dart`, `hud_data_mock.dart`.
- **Botones del HUD (README 3.2):** con C3 hay tres (*Misiones*, *Construir*, *Héroe*). La fase que añada el **cuarto** (C2 si llega segunda; C3 si C2 ya está) comprueba la barra con fuentes reales en un móvil en horizontal (ancho 640) y en Chrome con una ventana de 640 × 360:
  - los botones no pueden tapar `ResourceBar`;
  - si no caben, *Arena* y *Héroe* se agrupan en un solo botón *Héroe* con dos pestañas, que es lo que permite `HeroPanel.sections`.

  El test de widgets sólo comprueba que no hay desbordamiento: la fuente de los tests (Ahem) no mide como la real.

---

### Task TC3.1: Herrería y Armería construibles

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
    - `test/layers/presentation/features/forest/game/forest_scene_component_test.dart`
    - `test/core/assets/i18n/internationalize_test.dart`
  - Mocks:
    - `test/mocks/domain/entities/building/blueprint_entity_mock.dart`
    - `test/mocks/domain/entities/game/build_option_entity_mock.dart`
    - `test/mocks/presentation/features/forest/build_item_data_mock.dart`
    - `test/mocks/presentation/features/forest/game/forest_data_mock.dart`
    - `test/mocks/presentation/features/forest/game/lpc_assets_mock.dart`

**Interfaces:**
- Consumes: `BlueprintEntity`, `Blueprints`, `SpriteNames.building`, `RenderConstants.buildingFrontOffset`, `Internationalize.forestBlueprint`, `recolour()` / `trim()` de `build_assets.py`.
- Produces:
  ```dart
  // lib/core/config/constants/enum/blueprint_id.dart
  enum BlueprintId { house, forge, armory }

  // lib/layers/domain/rules/blueprints.dart
  static const BlueprintEntity forge;   // 25 de madera, 10 martillazos, radio 40
  static const BlueprintEntity armory;  // 25 de madera, 10 martillazos, radio 40
  static const List<BlueprintEntity> all = [house, forge, armory];

  // SpriteNames.building: forge → 'forge', armory → 'armory'
  // RenderConstants.buildingFrontOffset: forge → 24, armory → 24
  // Internationalize.forestBlueprint: forge → "Herrería", armory → "Armería"

  // mocks nuevos
  BlueprintEntityMock.forge / .armory
  BuildOptionEntityMock.workshop(BlueprintId id, {required int missingWood})
  BuildItemDataMock.workshopUnaffordable(BlueprintId id, {required int missingWood})
  ForestDataMock.forgePlacement / .placingForge
  ```

- [ ] **Step 1: Crear la rama de fase**

```bash
git switch feature/PROJECT-X-arena && git pull && git switch -c feature/PROJECT-X-c3-forge-armory
```

- [ ] **Step 2: Ampliar los datos de prueba**

`test/mocks/domain/entities/building/blueprint_entity_mock.dart`, al final de la clase:

```dart
  static const BlueprintEntity forge = BlueprintEntity(
    id: BlueprintId.forge,
    cost: {Resource.wood: 25},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity armory = BlueprintEntity(
    id: BlueprintId.armory,
    cost: {Resource.wood: 25},
    hitsToBuild: 10,
    footprintRadius: 40,
  );
```

`test/mocks/domain/entities/game/build_option_entity_mock.dart`, al final de la clase:

```dart
  static BuildOptionEntity workshop(BlueprintId id, {required int missingWood}) => BuildOptionEntity(
    blueprint: id,
    cost: const {Resource.wood: 25},
    missing: {Resource.wood: missingWood},
  );
```

`test/mocks/presentation/features/forest/build_item_data_mock.dart`, al final de la clase:

```dart
  static BuildItemData workshopUnaffordable(BlueprintId id, {required int missingWood}) => BuildItemData(
    blueprint: id,
    name: Internationalize.forestBlueprint(id: id),
    costText: Internationalize.forestAmount(resource: Resource.wood, amount: 25),
    missingText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.wood, amount: missingWood),
    ),
    isEnabled: false,
  );
```

`test/mocks/presentation/features/forest/game/forest_data_mock.dart`: antes de `static final ForestData initial`:

```dart
  static final PlacementData forgePlacement = PlacementData(
    blueprint: BlueprintId.forge,
    position: const PositionEntity(x: 300, y: 200),
    isValid: true,
  );
```

y al final de la clase:

```dart
  static final ForestData placingForge = ForestData(world: world, player: player, placement: forgePlacement);
```

`test/mocks/presentation/features/forest/game/lpc_assets_mock.dart`: en `frameNames`, cambiar `SpriteNames.building(BlueprintId.house),` por:

```dart
    for (final id in BlueprintId.values) SpriteNames.building(id),
```

- [ ] **Step 3: Escribir los tests que fallan**

`test/layers/domain/rules/blueprints_test.dart` (sustituye el fichero):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

import '../../../mocks/domain/entities/building/blueprint_entity_mock.dart';

void main() {
  test('testWhenAskingForTheHouseThenReturnsItsCostHitsAndFootprint', () {
    // given
    const id = BlueprintId.house;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(blueprint, BlueprintEntityMock.mock);
  });

  test('testWhenAskingForTheWorkshopsThenTheyCostTwentyFiveWoodAndTakeTenHits', () {
    // given
    const forge = BlueprintId.forge;
    const armory = BlueprintId.armory;

    // when
    final blueprints = (Blueprints.of(forge), Blueprints.of(armory));

    // then
    expect(blueprints, (BlueprintEntityMock.forge, BlueprintEntityMock.armory));
  });

  test('testWhenListingBlueprintsThenEveryIdAppearsOnceInDeclarationOrder', () {
    // given
    final ids = Blueprints.all.map((blueprint) => blueprint.id).toList();

    // when
    final expected = BlueprintId.values;

    // then
    expect(ids, expected);
  });
}
```

`test/layers/domain/use-cases/game/get_build_options_use_case_test.dart`: añadir `import 'package:rpg/core/config/constants/enum/blueprint_id.dart';` y cambiar las tres expectativas. Las opciones salen en el orden de `Blueprints.all`:

```dart
    // testWhenResourcesAreNotEnoughThenHouseIsNotAffordable (10 de madera)
    expect(options, [
      BuildOptionEntityMock.unaffordable,
      BuildOptionEntityMock.workshop(BlueprintId.forge, missingWood: 15),
      BuildOptionEntityMock.workshop(BlueprintId.armory, missingWood: 15),
    ]);

    // testWhenWoodEqualsTheCostThenHouseIsAffordable (15 de madera)
    expect(options, [
      BuildOptionEntityMock.mock,
      BuildOptionEntityMock.workshop(BlueprintId.forge, missingWood: 10),
      BuildOptionEntityMock.workshop(BlueprintId.armory, missingWood: 10),
    ]);

    // testWhenWoodExceedsTheCostThenHouseIsAffordable (17 de madera)
    expect(options, [
      BuildOptionEntityMock.mock,
      BuildOptionEntityMock.workshop(BlueprintId.forge, missingWood: 8),
      BuildOptionEntityMock.workshop(BlueprintId.armory, missingWood: 8),
    ]);
```

`test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`, en `testWhenResourcesAreNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace`:

```dart
      expect(bloc.state.data.hud!.buildItems, [
        BuildItemDataMock.makeUnaffordable(missingWood: 5),
        BuildItemDataMock.workshopUnaffordable(BlueprintId.forge, missingWood: 15),
        BuildItemDataMock.workshopUnaffordable(BlueprintId.armory, missingWood: 15),
      ]);
```

`test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`, al final de `main`:

```dart
  test('testWhenNamingTheWorkshopsThenUsesTheirFramesAndTheHouseFrontOffset', () {
    // given
    const forge = BlueprintId.forge;
    const armory = BlueprintId.armory;

    // when
    final names = (SpriteNames.building(forge), SpriteNames.building(armory));
    final offsets = (RenderConstants.buildingFrontOffset(forge), RenderConstants.buildingFrontOffset(armory));

    // then
    expect(names, ('forge', 'armory'));
    expect(offsets, (24, 24));
  });
```

`test/core/assets/i18n/internationalize_test.dart`, al final de `main`:

```dart
  test('testWhenNamingEveryBlueprintThenNoneFallsBackToItsKey', () {
    // given
    final names = BlueprintId.values.map((id) => Internationalize.forestBlueprint(id: id)).toList();

    // when
    final untranslated = names.where((name) => name.contains('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(names, ['Casa', 'Herrería', 'Armería']);
  });
```

`test/layers/presentation/features/forest/game/forest_scene_component_test.dart`: añadir los imports `package:rpg/core/config/constants/enum/blueprint_id.dart` y `package:rpg/layers/presentation/features/forest/game/components/placement_ghost_component.dart`, y este test antes de `testWhenShowingTheSameSnapshotTwiceThenComponentCountsStayTheSame`. Cubre la rama de `_showGhost` que F0 dejó sin probar (sección 5 del README de la aldea):

```dart
  testWithFlameGame('testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced', (game) async {
    // given
    final scene = await _mountedScene(game);
    scene.show(ForestDataMock.placing);
    await game.ready();
    final houseGhost = scene.ghost!;

    // when
    scene.show(ForestDataMock.placingForge);
    await game.ready();

    // then
    expect(houseGhost.isMounted, isFalse);
    expect(scene.ghost, isNot(same(houseGhost)));
    expect(scene.ghost!.blueprint, BlueprintId.forge);
    expect(scene.ghost!.isMounted, isTrue);
    expect(scene.children.whereType<PlacementGhostComponent>(), hasLength(1));
  });
```

Run: `flutter test test/layers/domain/rules/blueprints_test.dart`
Expected: FAIL al compilar (`BlueprintId.forge` no existe).

- [ ] **Step 4: Enum, catálogo, textos, nombres de sprite y desplazamiento**

`lib/core/config/constants/enum/blueprint_id.dart`:

```dart
enum BlueprintId { house, forge, armory }
```

`lib/layers/domain/rules/blueprints.dart`: después de `house`, y cambiando `all`:

```dart
  static const BlueprintEntity forge = BlueprintEntity(
    id: BlueprintId.forge,
    cost: {Resource.wood: 25},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const BlueprintEntity armory = BlueprintEntity(
    id: BlueprintId.armory,
    cost: {Resource.wood: 25},
    hitsToBuild: 10,
    footprintRadius: 40,
  );

  static const List<BlueprintEntity> all = [house, forge, armory];
```

`lib/core/assets/i18n/translations/es.json`, bloque `forest.blueprint`:

```json
    "blueprint": {
      "house": "Casa",
      "forge": "Herrería",
      "armory": "Armería"
    },
```

`lib/core/assets/i18n/internationalize.dart`, en `forestBlueprint`:

```dart
  static String forestBlueprint({required BlueprintId id}) => switch (id) {
    BlueprintId.house => '$_forest.blueprint.house'.tr(),
    BlueprintId.forge => '$_forest.blueprint.forge'.tr(),
    BlueprintId.armory => '$_forest.blueprint.armory'.tr(),
  };
```

`lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`:

```dart
  static String building(BlueprintId id) => switch (id) {
    BlueprintId.house => 'house',
    BlueprintId.forge => 'forge',
    BlueprintId.armory => 'armory',
  };
```

`lib/layers/presentation/features/forest/game/render/render_constants.dart`:

```dart
  static double buildingFrontOffset(BlueprintId id) => switch (id) {
    BlueprintId.house => 24,
    BlueprintId.forge => 24,
    BlueprintId.armory => 24,
  };
```

Run: `flutter test test/layers/domain test/core/assets test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`
Expected: PASS.

Run: `flutter test test/layers/presentation/features/forest/game/atlas/lpc_atlas_test.dart`
Expected: FAIL en `testWhenParsingTheGeneratedAtlasThenEveryLevelSpriteExists`: faltan los frames `forge` y `armory` en `forest.json`. Es la guarda de F0; se arregla en el paso siguiente.

- [ ] **Step 5: Generar el arte**

En `asset-packs/lpc/build_assets.py`:

1. En el docstring, cambiar la línea del atlas por:

```python
                                   axe pickup, the house, the forge and the armory (pivot = bottom centre)
```

2. Después de `HOUSE_ROOF_OVERLAP = 28`:

```python

# Forge and armory reuse the house layout. The thatch ships in exactly these nine colours (dark -> light),
# so recolour() swaps the whole roof; the wall and door keep their own colours.
ROOF_RAMP = [(43, 28, 29), (48, 33, 36), (98, 53, 28), (112, 86, 55), (137, 103, 56), (154, 114, 57), (183, 149, 67), (227, 198, 84), (237, 226, 108)]
FORGE_ROOF = [(20, 20, 24), (26, 26, 30), (40, 40, 46), (54, 54, 60), (66, 66, 74), (76, 76, 84), (94, 94, 102), (118, 118, 126), (136, 136, 144)]
ARMORY_ROOF = [(40, 14, 16), (46, 18, 20), (90, 24, 22), (110, 32, 28), (132, 40, 34), (148, 46, 38), (176, 60, 46), (212, 90, 68), (228, 118, 90)]
FORGE_WALL_BOX = (0, 256, 96, 352)  # cottage.png, stone wall with timber frame
CHIMNEY_BOX = (448, 480, 480, 512)  # terrain_atlas.png, cracked stone block
CHIMNEY_RISE = 18  # pixels the chimney sticks out above the roof
CHIMNEY_INSET = 20  # distance from the chimney's right edge to the roof's right edge
```

3. Sustituir `build_house()` entera por:

```python
def build_cottage(wall_box: tuple, roof_colours: list = None, chimney: Image.Image = None) -> Image.Image:
    """Wall, door and thatched roof; optionally a recoloured roof and a chimney sticking out of it."""
    buildings = SOURCES / "buildings"
    wall = Image.open(buildings / "cottage.png").convert("RGBA").crop(wall_box)
    roof = Image.open(buildings / "thatched-roof.png").convert("RGBA").crop(HOUSE_ROOF_BOX)
    roof = roof.crop(roof.getbbox())
    if roof_colours is not None:
        roof = recolour(roof, ROOF_RAMP, roof_colours)
    door = Image.open(buildings / "doors_0.png").convert("RGBA").crop(HOUSE_DOOR_BOX)
    door = door.crop(door.getbbox())

    top = CHIMNEY_RISE if chimney is not None else 0
    width = max(roof.width, wall.width)
    image = Image.new("RGBA", (width, top + roof.height + wall.height - HOUSE_ROOF_OVERLAP))
    wall_x, wall_y = (width - wall.width) // 2, top + roof.height - HOUSE_ROOF_OVERLAP
    image.alpha_composite(wall, (wall_x, wall_y))
    image.alpha_composite(door, (wall_x + (wall.width - door.width) // 2, wall_y + wall.height - door.height))
    image.alpha_composite(roof, ((width - roof.width) // 2, top))
    if chimney is not None:
        image.alpha_composite(chimney, (width - chimney.width - CHIMNEY_INSET, 0))
    return image


def build_house() -> Image.Image:
    return build_cottage(HOUSE_WALL_BOX)


def build_forge(terrain: Image.Image) -> Image.Image:
    return build_cottage(FORGE_WALL_BOX, FORGE_ROOF, trim(terrain.crop(CHIMNEY_BOX), "chimney"))


def build_armory() -> Image.Image:
    return build_cottage(HOUSE_WALL_BOX, ARMORY_ROOF)
```

4. En `build_forest()`, después de `pivots["house"] = {"x": 0.5, "y": 1}`:

```python
    frames["forge"] = build_forge(terrain)
    pivots["forge"] = {"x": 0.5, "y": 1}
    frames["armory"] = build_armory()
    pivots["armory"] = {"x": 0.5, "y": 1}
```

Generar y comprobar:

```bash
cd asset-packs/lpc && python3 build_assets.py && cd ../..
git status --short lib/core/assets/images/lpc
python3 -c "import json; f = json.load(open('lib/core/assets/images/lpc/forest.json'))['frames']; print({k: (f[k]['frame']['w'], f[k]['frame']['h']) for k in ('house', 'forge', 'armory')})"
```

Expected:
- `Assets written to …`;
- sólo cambian `forest.png` y `forest.json` (las hojas `hero-*.png` y `ground.png` quedan igual);
- `{'house': (120, 191), 'forge': (120, 209), 'armory': (120, 191)}`.

Abre `lib/core/assets/images/lpc/forest.png` y comprueba a ojo que hay:
- una casa con el tejado de paja amarillo, como antes;
- una Herrería con muro de piedra, tejado gris oscuro y chimenea de piedra arriba a la derecha;
- una Armería con el muro de la casa y el tejado rojo.

En `lib/core/assets/images/lpc/CREDITS.md`, sustituir el título y el primer párrafo de la sección de la casa por:

```markdown
## House, forge and armory (`house`, `forge`, `armory` frames in `forest.png`)

Assembled from "[LPC] Thatched-roof Cottage" (timber-frame and stone walls, thatched roof) and
"[LPC] Windows & Doors" (door), both by bluecarrot16. CC-BY-SA 3.0 / GPL 3.0 —
<https://opengameart.org/content/lpc-thatched-roof-cottage>,
<https://opengameart.org/content/lpc-windows-doors>.
The forge and armory roofs are recoloured (dark grey, red); the forge chimney is a stone block
from the LPC Tile Atlas below.
```

- [ ] **Step 6: Ver que pasan**

```bash
flutter test test/layers/presentation/features/forest test/layers/domain test/core/assets
```

Expected: PASS, incluidos `lpc_atlas_test.dart` (los frames existen) y `testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced`.

- [ ] **Step 7: Comprobar la persistencia de edificios**

```bash
grep -rn "BlueprintId" lib/layers/data
```

- Sin resultados: F2 no está; no hay nada que hacer (decisión 19).
- Con un mapper que lee el id con `BlueprintId.values.byName`: no hay nada que hacer.
- Con un `switch` o una tabla a mano: se añaden `forge` y `armory` en el mismo commit y se apunta en la sección 5 del README.

- [ ] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/layers/domain/rules/blueprints.dart lib/layers/presentation/features/forest/game/atlas/sprite_names.dart lib/layers/presentation/features/forest/game/render/render_constants.dart test/layers/domain/rules/blueprints_test.dart test/layers/domain/use-cases/game/get_build_options_use_case_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart test/layers/presentation/features/forest/game/forest_scene_component_test.dart test/core/assets/i18n/internationalize_test.dart test/mocks/domain/entities/building/blueprint_entity_mock.dart test/mocks/domain/entities/game/build_option_entity_mock.dart test/mocks/presentation/features/forest/build_item_data_mock.dart test/mocks/presentation/features/forest/game/forest_data_mock.dart test/mocks/presentation/features/forest/game/lpc_assets_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida en lo generado (esta tarea no toca DI ni mocks de mockito), `No issues found!` y todo en verde.

- [ ] **Step 9: Commit**

```bash
git add asset-packs/lpc/build_assets.py lib/core/assets lib/core/config/constants/enum/blueprint_id.dart lib/layers/domain/rules/blueprints.dart lib/layers/presentation/features/forest/game test
git commit -m "[PROJECT-X]: Build the forge and the armory in the village"
```

Prueba rápida en Chrome (`flutter run -d chrome`): el menú *Construir* lista *Casa*, *Herrería* y *Armería* (25 de madera). Al colocar la Herrería, el fantasma es la Herrería. Construida, se ve con su chimenea; la Armería, con el tejado rojo.

---

### Task TC3.2: Comprar equipo (dominio)

**Files:**
- Create:
  - `lib/core/config/constants/enum/buy_gear_result.dart`
  - `lib/core/config/constants/enum/gear_option_state.dart`
  - `lib/layers/domain/entities/gear/gear_option_entity.dart`
  - `lib/layers/domain/use-cases/hero/buy_gear_use_case.dart`
  - `lib/layers/domain/use-cases/hero/get_gear_options_use_case.dart`
  - Tests:
    - `test/layers/domain/entities/gear/gear_option_entity_test.dart`
    - `test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart`
    - `test/layers/domain/use-cases/hero/get_gear_options_use_case_test.dart`
    - `test/layers/domain/use-cases/hero/gear_flow_test.dart`
  - Mocks:
    - `test/mocks/domain/entities/gear/gear_option_entity_mock.dart`
    - `test/mocks/domain/game/gear_scenario_mock.dart`
- Modify:
  - `lib/layers/domain/rules/gear.dart` (`workshopFor`)
  - `lib/layers/domain/world/extensions/building_rules.dart` (`BuildingListRules`)
  - `lib/core/config/di/di.config.dart` (generado)
  - Tests: `test/layers/domain/rules/gear_test.dart`, `test/layers/domain/world/extensions/building_rules_test.dart`, `test/core/config/di/di_test.dart`
  - Mocks: `test/mocks/domain/entities/hero/hero_entity_mock.dart`, `test/mocks/domain/entities/hero/combat_stats_entity_mock.dart`, `test/mocks/domain/world/funds_mock.dart`

**Interfaces:**
- Consumes: `BlueprintId.forge` / `armory` y `Blueprints.forge` / `armory` (TC3.1); `Gear`, `GearEntity`, `HeroRules`, `World.funds` / `spend` / `updateHero` / `buildings`, `InventoryRules.missing` (C0).
- Produces:
  ```dart
  // lib/core/config/constants/enum/buy_gear_result.dart
  enum BuyGearResult { ok, missingBuilding, notNextTier, notEnoughResources }

  // lib/core/config/constants/enum/gear_option_state.dart
  enum GearOptionState { equipped, available, needsBuilding, unaffordable, locked }

  // lib/layers/domain/rules/gear.dart
  static BlueprintId Gear.workshopFor(GearSlot slot);   // weapon → forge, armor → armory

  // lib/layers/domain/world/extensions/building_rules.dart
  extension BuildingListRules on Iterable<BuildingEntity> {
    bool hasComplete(BlueprintId id);
  }

  // lib/layers/domain/entities/gear/gear_option_entity.dart
  class GearOptionEntity {
    final GearEntity gear;
    final GearOptionState state;
    final Map<Resource, int> missing;     // {} si equipped
    const GearOptionEntity({required this.gear, required this.state, this.missing = const {}});
    bool get canBuy;                      // state == available
    GearOptionEntity copyWith({GearEntity? gear, GearOptionState? state, Map<Resource, int>? missing});
  }

  // lib/layers/domain/use-cases/hero/
  BuyGearResult BuyGearUseCase.call({required GearId id});
  List<GearOptionEntity> GetGearOptionsUseCase.call();   // por ranura, desde la equipada hasta maxTier

  // mocks nuevos
  HeroEntityMock.withShortSword
  CombatStatsEntityMock.heroWithShortSword
  FundsMock.shortSwordPrice / .fiveGoldShortOfShortSword
  GearOptionEntityMock.equipped(id) / .make(id, state, {missing}) / .shortSwordAvailable / .shortSwordFiveGoldShort / .newHeroWithoutWorkshops / .fullyGeared
  GearScenarioMock.forgeSite / .armorySite / .buildMs / .withoutWorkshops / .withForge / .withForgeAndArmory / .withForgeUnderConstruction
  ```

- [ ] **Step 1: Crear la rama (sólo si TC3.3 se hace a la vez)**

```bash
git switch feature/PROJECT-X-c3-forge-armory && git pull
git worktree add ../phaser-example-c3-gear-purchase -b feature/PROJECT-X-c3-gear-purchase
cd ../phaser-example-c3-gear-purchase && flutter pub get
```

Si no hay trabajo en paralelo, se sigue en la rama de fase.

- [ ] **Step 2: Escribir los datos de prueba**

`test/mocks/domain/entities/hero/hero_entity_mock.dart`, al final de la clase:

```dart
  static const HeroEntity withShortSword = HeroEntity(weaponTier: 1);
```

`test/mocks/domain/entities/hero/combat_stats_entity_mock.dart`, al final de la clase:

```dart
  static const CombatStatsEntity heroWithShortSword = CombatStatsEntity(attack: 7, defense: 1, health: 30);
```

`test/mocks/domain/world/funds_mock.dart`, al final de la clase:

```dart
  static const Map<Resource, int> shortSwordPrice = {Resource.wood: 20, Resource.gold: 10};

  static const Map<Resource, int> fiveGoldShortOfShortSword = {Resource.wood: 20, Resource.gold: 5};
```

`test/mocks/domain/game/gear_scenario_mock.dart`. Construye los talleres con la API real del `World` (decisión 17). Con `PlayerEntityMock.mock` (velocidad 100, en (100, 100)), 10 s bastan para caminar hasta cada obra y dar los 10 martillazos (10 × 650 ms):

```dart
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/building/blueprint_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/hero/hero_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class GearScenarioMock {
  static const PositionEntity forgeSite = PositionEntity(x: 300, y: 100);
  static const PositionEntity armorySite = PositionEntity(x: 500, y: 100);
  static const double buildMs = 10000;

  static World withoutWorkshops({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    return WorldMock.withHero(hero)..earn(funds);
  }

  static World withForge({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero);
    _build(world, Blueprints.forge, forgeSite);
    return world..earn(funds);
  }

  static World withForgeAndArmory({Map<Resource, int> funds = const {}, HeroEntity hero = HeroEntityMock.mock}) {
    final world = WorldMock.withHero(hero);
    _build(world, Blueprints.forge, forgeSite);
    _build(world, Blueprints.armory, armorySite);
    return world..earn(funds);
  }

  static World withForgeUnderConstruction({Map<Resource, int> funds = const {}}) {
    final world = WorldMock.make()..earn(Blueprints.forge.cost);
    world.orderConstruction(Blueprints.forge, forgeSite);
    return world..earn(funds);
  }

  static void _build(World world, BlueprintEntity blueprint, PositionEntity site) {
    world.earn(blueprint.cost);
    world.orderConstruction(blueprint, site);
    world.advanceFor(buildMs);
  }
}
```

`test/mocks/domain/entities/gear/gear_option_entity_mock.dart`. Por defecto, `missing` es el coste entero (sin fondos):

```dart
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/gear/gear_option_entity.dart';
import 'package:rpg/layers/domain/rules/gear.dart';

abstract final class GearOptionEntityMock {
  static GearOptionEntity equipped(GearId id) => GearOptionEntity(gear: Gear.byId(id), state: GearOptionState.equipped);

  static GearOptionEntity make(GearId id, GearOptionState state, {Map<Resource, int>? missing}) {
    final gear = Gear.byId(id);
    return GearOptionEntity(gear: gear, state: state, missing: missing ?? gear.cost);
  }

  static GearOptionEntity get shortSwordAvailable => make(GearId.shortSword, GearOptionState.available, missing: {});

  static GearOptionEntity get shortSwordFiveGoldShort =>
      make(GearId.shortSword, GearOptionState.unaffordable, missing: {Resource.gold: 5});

  static List<GearOptionEntity> get newHeroWithoutWorkshops => [
    equipped(GearId.woodcutterAxe),
    make(GearId.shortSword, GearOptionState.needsBuilding),
    make(GearId.ironSword, GearOptionState.locked),
    make(GearId.steelSword, GearOptionState.locked),
    equipped(GearId.workClothes),
    make(GearId.leatherArmor, GearOptionState.needsBuilding),
    make(GearId.chainMail, GearOptionState.locked),
    make(GearId.plateArmor, GearOptionState.locked),
  ];

  static List<GearOptionEntity> get fullyGeared => [equipped(GearId.steelSword), equipped(GearId.plateArmor)];
}
```

- [ ] **Step 3: Escribir los tests que fallan**

`test/layers/domain/rules/gear_test.dart`: añadir `import 'package:rpg/core/config/constants/enum/blueprint_id.dart';` y, al final de `main`:

```dart
  test('testWhenAskingWhereGearIsSoldThenWeaponsAreAtTheForgeAndArmorAtTheArmory', () {
    // given
    const weapon = GearSlot.weapon;
    const armor = GearSlot.armor;

    // when
    final workshops = (Gear.workshopFor(weapon), Gear.workshopFor(armor));

    // then
    expect(workshops, (BlueprintId.forge, BlueprintId.armory));
  });
```

`test/layers/domain/world/extensions/building_rules_test.dart`: añadir `import 'package:rpg/core/config/constants/enum/blueprint_id.dart';` y, al final de `main`:

```dart
  test('testWhenLookingForACompleteBuildingThenOnlyFinishedOnesOfThatBlueprintCount', () {
    // given
    const finished = [BuildingEntityMock.complete];
    const unfinished = [BuildingEntityMock.halfBuilt];

    // when
    final finishedHouse = finished.hasComplete(BlueprintId.house);
    final finishedForge = finished.hasComplete(BlueprintId.forge);
    final unfinishedHouse = unfinished.hasComplete(BlueprintId.house);

    // then
    expect(finishedHouse, isTrue);
    expect(finishedForge, isFalse);
    expect(unfinishedHouse, isFalse);
  });
```

`test/layers/domain/entities/gear/gear_option_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';

import '../../../../mocks/domain/entities/gear/gear_option_entity_mock.dart';

void main() {
  test('testWhenComparingOptionsThenGearStateAndMissingAllCount', () {
    // given
    final option = GearOptionEntityMock.shortSwordAvailable;

    // when
    final sameOption = option == GearOptionEntityMock.shortSwordAvailable;
    final otherMissing = option == GearOptionEntityMock.shortSwordFiveGoldShort;
    final otherState = option == option.copyWith(state: GearOptionState.locked);

    // then
    expect(sameOption, isTrue);
    expect(option.hashCode, GearOptionEntityMock.shortSwordAvailable.hashCode);
    expect(otherMissing, isFalse);
    expect(otherState, isFalse);
  });

  test('testWhenTheOptionIsAvailableThenItCanBeBoughtAndNoOtherStateCan', () {
    // given
    final available = GearOptionEntityMock.shortSwordAvailable;
    final others = [
      GearOptionEntityMock.equipped(GearId.woodcutterAxe),
      GearOptionEntityMock.shortSwordFiveGoldShort,
      GearOptionEntityMock.make(GearId.shortSword, GearOptionState.needsBuilding),
      GearOptionEntityMock.make(GearId.ironSword, GearOptionState.locked),
    ];

    // when
    final buyable = others.where((option) => option.canBuy).toList();

    // then
    expect(available.canBuy, isTrue);
    expect(buyable, isEmpty);
  });
}
```

`test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart`. Un test por resultado, más el orden de las comprobaciones (decisión 4):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/buy_gear_result.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/domain/use-cases/hero/buy_gear_use_case.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late BuyGearUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = BuyGearUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenThereIsNoForgeThenTheSwordNeedsTheBuildingAndNothingIsPaid', () {
    // given
    final world = playing(GearScenarioMock.withoutWorkshops(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.missingBuilding);
    expect(world.hero, HeroEntityMock.mock);
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenTheForgeIsStillBeingBuiltThenTheSwordNeedsTheBuilding', () {
    // given
    playing(GearScenarioMock.withForgeUnderConstruction(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.missingBuilding);
  });

  test('testWhenOnlyTheForgeIsBuiltThenArmorStillNeedsTheArmory', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.leatherArmor);

    // then
    expect(result, BuyGearResult.missingBuilding);
  });

  test('testWhenSkippingATierThenItIsNotTheNextTier', () {
    // given
    final world = playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.ironSword);

    // then
    expect(result, BuyGearResult.notNextTier);
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenBuyingTheEquippedGearAgainThenItIsNotTheNextTier', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice, hero: HeroEntityMock.withShortSword));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.notNextTier);
  });

  test('testWhenTheNextTierIsTooExpensiveThenNothingIsPaidOrEquipped', () {
    // given
    final world = playing(GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.notEnoughResources);
    expect(world.hero, HeroEntityMock.mock);
    expect((world.funds.amount(Resource.wood), world.funds.amount(Resource.gold)), (20, 5));
  });

  test('testWhenSeveralChecksFailThenTheyAreReportedInOrder', () {
    // given
    playing(GearScenarioMock.withoutWorkshops());
    final missingBuilding = sut(id: GearId.ironSword);
    playing(GearScenarioMock.withForge());

    // when
    final notNextTier = sut(id: GearId.ironSword);

    // then
    expect(missingBuilding, BuyGearResult.missingBuilding);
    expect(notNextTier, BuyGearResult.notNextTier);
  });

  test('testWhenEverythingIsInPlaceThenPaysAndEquipsTheSword', () {
    // given
    final world = playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final result = sut(id: GearId.shortSword);

    // then
    expect(result, BuyGearResult.ok);
    expect(world.hero, HeroEntityMock.withShortSword);
    expect(world.hero.stats, CombatStatsEntityMock.heroWithShortSword);
    expect((world.funds.amount(Resource.wood), world.funds.amount(Resource.gold)), (0, 0));
  });
}
```

`test/layers/domain/use-cases/hero/get_gear_options_use_case_test.dart`. La lista empieza por el hacha equipada (`[0]`) y la Espada corta (`[1]`); la armadura de cuero es `[5]`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_gear_options_use_case.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/gear/gear_option_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetGearOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetGearOptionsUseCase(sessionRepository: sessionRepository);
  });

  void playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
  }

  test('testWhenANewHeroHasNoWorkshopsThenTheNextTiersNeedThemAndTheRestAreLocked', () {
    // given
    playing(GearScenarioMock.withoutWorkshops());

    // when
    final options = sut();

    // then
    expect(options, GearOptionEntityMock.newHeroWithoutWorkshops);
  });

  test('testWhenTheForgeIsBuiltAndTheSwordIsPaidForThenItIsAvailable', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice));

    // when
    final options = sut();

    // then
    expect(options[1], GearOptionEntityMock.shortSwordAvailable);
    expect(options[5].state, GearOptionState.needsBuilding);
  });

  test('testWhenFundsAreShortThenTheSwordIsUnaffordableAndSaysWhatIsMissing', () {
    // given
    playing(GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword));

    // when
    final options = sut();

    // then
    expect(options[1], GearOptionEntityMock.shortSwordFiveGoldShort);
  });

  test('testWhenTheHeroHasTheBestGearThenOnlyTheEquippedPiecesAreListed', () {
    // given
    playing(GearScenarioMock.withForgeAndArmory(hero: HeroEntityMock.fullyGeared));

    // when
    final options = sut();

    // then
    expect(options, GearOptionEntityMock.fullyGeared);
  });
}
```

`test/layers/domain/use-cases/hero/gear_flow_test.dart`. Es el test de flujo de la ficha: construye la Herrería con `ConstructBuildingUseCase` + `AdvanceGameUseCase`, cobra el oro con `world.earn` (como lo hará la arena) y compra:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/buy_gear_result.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/buy_gear_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_gear_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/gear/gear_option_entity_mock.dart';
import '../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  test('testWhenTheForgeIsBuiltAndArenaGoldIsEarnedThenTheShortSwordRaisesAttackAndPower', () {
    // given
    final sessionRepository = MockGameSessionRepository();
    final world = GearScenarioMock.withoutWorkshops()..earn(Blueprints.forge.cost);
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    final construct = ConstructBuildingUseCase(sessionRepository: sessionRepository);
    final advance = AdvanceGameUseCase(sessionRepository: sessionRepository);
    final options = GetGearOptionsUseCase(sessionRepository: sessionRepository);
    final buy = BuyGearUseCase(sessionRepository: sessionRepository);
    final heroStatus = GetHeroStatusUseCase(sessionRepository: sessionRepository);
    final before = heroStatus();
    construct(blueprint: BlueprintId.forge, x: GearScenarioMock.forgeSite.x, y: GearScenarioMock.forgeSite.y);
    for (var elapsed = 0.0; elapsed < GearScenarioMock.buildMs; elapsed += 16) {
      advance(deltaMs: 16);
    }
    final ironSwordBefore = buy(id: GearId.ironSword);
    world.earn(FundsMock.shortSwordPrice);

    // when
    final result = buy(id: GearId.shortSword);

    // then
    final after = heroStatus();
    expect(ironSwordBefore, BuyGearResult.notNextTier);
    expect(result, BuyGearResult.ok);
    expect((before.stats.attack, after.stats.attack), (4, 7));
    expect((before.power, after.power), (31, 40));
    expect(options().first, GearOptionEntityMock.equipped(GearId.shortSword));
    expect(options()[1].state, GearOptionState.unaffordable);
  });
}
```

Run: `flutter test test/layers/domain`
Expected: FAIL al compilar (`BuyGearResult`, `GearOptionEntity`, `Gear.workshopFor`… no existen).

- [ ] **Step 4: Enums, `Gear.workshopFor` y `BuildingListRules`**

`lib/core/config/constants/enum/buy_gear_result.dart`:

```dart
enum BuyGearResult { ok, missingBuilding, notNextTier, notEnoughResources }
```

`lib/core/config/constants/enum/gear_option_state.dart`:

```dart
enum GearOptionState { equipped, available, needsBuilding, unaffordable, locked }
```

`lib/layers/domain/rules/gear.dart`: añadir `import '../../../core/config/constants/enum/blueprint_id.dart';` y, al final de la clase:

```dart
  static BlueprintId workshopFor(GearSlot slot) => switch (slot) {
    GearSlot.weapon => BlueprintId.forge,
    GearSlot.armor => BlueprintId.armory,
  };
```

`lib/layers/domain/world/extensions/building_rules.dart` (fichero completo):

```dart
import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/building/building_entity.dart';

extension BuildingRules on BuildingEntity {
  BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
}

extension BuildingListRules on Iterable<BuildingEntity> {
  bool hasComplete(BlueprintId id) => any((building) => building.blueprint.id == id && building.isComplete);
}
```

- [ ] **Step 5: `GearOptionEntity`**

`lib/layers/domain/entities/gear/gear_option_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/gear_option_state.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'gear_entity.dart';

class GearOptionEntity {
  final GearEntity gear;
  final GearOptionState state;
  final Map<Resource, int> missing;

  const GearOptionEntity({required this.gear, required this.state, this.missing = const {}});

  bool get canBuy => state == GearOptionState.available;

  GearOptionEntity copyWith({GearEntity? gear, GearOptionState? state, Map<Resource, int>? missing}) {
    return GearOptionEntity(gear: gear ?? this.gear, state: state ?? this.state, missing: missing ?? this.missing);
  }

  @override
  bool operator ==(Object other) =>
      other is GearOptionEntity &&
      other.gear == gear &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(gear, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'GearOptionEntity(gear: ${gear.id}, state: $state, missing: $missing)';
}
```

- [ ] **Step 6: Casos de uso**

`lib/layers/domain/use-cases/hero/buy_gear_use_case.dart`. Las comprobaciones van en el orden de la ficha. `world.spend` es atómico (C0): si falla, no se ha cobrado nada.

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/buy_gear_result.dart';
import '../../../../core/config/constants/enum/gear_id.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/gear.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class BuyGearUseCase {
  final GameSessionRepository _sessionRepository;

  const BuyGearUseCase({required this._sessionRepository});

  BuyGearResult call({required GearId id}) {
    final world = _sessionRepository.current().world;
    final gear = Gear.byId(id);
    if (!world.buildings.hasComplete(Gear.workshopFor(gear.slot))) return BuyGearResult.missingBuilding;
    if (world.hero.nextGear(gear.slot)?.id != id) return BuyGearResult.notNextTier;
    if (!world.spend(gear.cost)) return BuyGearResult.notEnoughResources;
    world.updateHero((hero) => hero.withGear(gear));
    return BuyGearResult.ok;
  }
}
```

`lib/layers/domain/use-cases/hero/get_gear_options_use_case.dart` (decisión 6). Importa `World`, que no es una pieza interna de `world/` (la regla de `architecture_test.dart` lo permite):

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/gear_option_state.dart';
import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../entities/gear/gear_entity.dart';
import '../../entities/gear/gear_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/gear.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/hero_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/world.dart';

@Injectable()
final class GetGearOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetGearOptionsUseCase({required this._sessionRepository});

  List<GearOptionEntity> call() {
    final world = _sessionRepository.current().world;
    return [
      for (final slot in GearSlot.values)
        for (var tier = world.hero.tierOf(slot); tier <= Gear.maxTier(slot); tier++)
          _option(world, Gear.of(slot, tier)),
    ];
  }

  GearOptionEntity _option(World world, GearEntity gear) {
    final equippedTier = world.hero.tierOf(gear.slot);
    if (gear.tier == equippedTier) return GearOptionEntity(gear: gear, state: GearOptionState.equipped);
    final missing = world.funds.missing(gear.cost);
    final GearOptionState state;
    if (gear.tier > equippedTier + 1) {
      state = GearOptionState.locked;
    } else if (!world.buildings.hasComplete(Gear.workshopFor(gear.slot))) {
      state = GearOptionState.needsBuilding;
    } else if (missing.isNotEmpty) {
      state = GearOptionState.unaffordable;
    } else {
      state = GearOptionState.available;
    }
    return GearOptionEntity(gear: gear, state: state, missing: missing);
  }
}
```

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --stat -- lib/core/config/di/di.config.dart
flutter test test/layers/domain
```

Expected: `di.config.dart` sólo registra `BuyGearUseCase` y `GetGearOptionsUseCase`; PASS.

- [ ] **Step 7: Registrar los casos de uso en el test de DI**

En `test/core/config/di/di_test.dart`, añadir los imports

```dart
import 'package:rpg/layers/domain/use-cases/hero/buy_gear_use_case.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_gear_options_use_case.dart';
```

y, en `testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered`, después de `locator.isRegistered<StartFightUseCase>(),`:

```dart
      locator.isRegistered<BuyGearUseCase>(),
      locator.isRegistered<GetGearOptionsUseCase>(),
```

Run: `flutter test test/core/config/di/di_test.dart`
Expected: PASS.

- [ ] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/buy_gear_result.dart lib/core/config/constants/enum/gear_option_state.dart lib/layers/domain/entities/gear lib/layers/domain/rules/gear.dart lib/layers/domain/world/extensions/building_rules.dart lib/layers/domain/use-cases/hero test/layers/domain/entities/gear test/layers/domain/rules/gear_test.dart test/layers/domain/world/extensions/building_rules_test.dart test/layers/domain/use-cases/hero test/core/config/di/di_test.dart test/mocks/domain/entities/gear test/mocks/domain/game/gear_scenario_mock.dart test/mocks/domain/entities/hero test/mocks/domain/world/funds_mock.dart
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `No issues found!` y todo en verde.

- [ ] **Step 9: Commit**

```bash
git add lib/core/config/constants/enum lib/core/config/di/di.config.dart lib/layers/domain test/layers/domain test/core/config/di/di_test.dart test/mocks/domain
git commit -m "[PROJECT-X]: Buy weapons and armor at finished workshops"
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida.

Si se hizo en su propio *worktree*, se une cuando TC3.3 también esté (TC3.4, Step 1).

---

### Task TC3.3: Panel *Héroe* (widgets)

**Files:**
- Create:
  - `lib/core/config/constants/enum/forest/hero_panel_section.dart`
  - `lib/core/assets/images/icons/hero.svg`
  - `lib/layers/presentation/features/forest/models/gear_item_data.dart`, `gear_row_data.dart`, `hero_panel_data.dart`
  - `lib/layers/presentation/features/forest/widgets/gear_option_tile.dart`, `gear_row.dart`, `hero_panel.dart`
  - Tests:
    - `test/layers/presentation/features/forest/models/hero_panel_data_test.dart`
    - `test/layers/presentation/features/forest/widgets/gear_option_tile_test.dart`
    - `test/layers/presentation/features/forest/widgets/gear_row_test.dart`
    - `test/layers/presentation/features/forest/widgets/hero_panel_test.dart`
  - Mocks: `test/mocks/presentation/features/forest/gear_item_data_mock.dart`, `gear_row_data_mock.dart`, `hero_panel_data_mock.dart`
- Modify:
  - `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`
  - `lib/layers/presentation/features/forest/widgets/hud_button.dart` (`icon`)
  - `lib/layers/presentation/theme/images/custom_icons.dart` (`hero`)
  - Tests: `test/core/assets/i18n/internationalize_test.dart`, `test/layers/presentation/features/forest/widgets/hud_button_test.dart`, `test/layers/presentation/theme/images/custom_icons_test.dart`

**Interfaces:**
- Consumes: `GearId`, `GearSlot` (C0); `BlueprintId.forge` / `armory` y `Internationalize.forestBlueprint` (TC3.1, sólo en los mocks); `HudPanel`, `HudButton`, `CustomColors`, `CustomTextStyles`. **No** usa nada de TC3.2.
- Produces:
  ```dart
  // lib/core/config/constants/enum/forest/hero_panel_section.dart
  enum HeroPanelSection { gear, skills }

  // models/
  class GearItemData { GearId id; String name; String statsText; String? costText; String? reasonText; bool canBuy; }
  class GearRowData { GearSlot slot; String title; GearItemData equipped; GearItemData? next; }
  class HeroPanelData { int power; int attack; int defense; int health; List<GearRowData> rows; }

  // widgets/
  HeroPanel({required HeroPanelData hero, required ValueChanged<GearId> onBuy, List<HeroPanelSection> sections = const [HeroPanelSection.gear]})
  HeroPanel.reservedHeight = 96
  GearRow({required GearRowData row, required ValueChanged<GearId> onBuy})
  GearOptionTile({required GearItemData item, VoidCallback? onBuy}); static Key GearOptionTile.buyKey(GearId id)
  HudButton({…, String? icon, …})

  // CustomIcons.hero = 'lib/core/assets/images/icons/hero.svg'

  // Internationalize
  forestHero, forestHeroPower, forestHeroAttack, forestHeroDefense, forestHeroHealth,
  forestHeroWeaponStats({attack}), forestHeroArmorStats({defense, health}), forestHeroSlot({slot}),
  forestHeroSection({section}), forestHeroEquipped, forestHeroBuy, forestHeroNeedsBuilding({name}),
  forestHeroMaxed, forestGear({id}), forestMessageGearPurchased({name}), forestMessageGearNotNextTier

  // mocks nuevos
  GearItemDataMock.woodcutterAxe / .shortSwordEquipped / .shortSwordNeedsForge / .shortSwordAvailable / .shortSwordFiveGoldShort / .steelSword / .workClothes / .leatherArmorNeedsArmory
  GearRowDataMock.weaponNeedsForge / .weaponReadyToBuy / .weaponMaxed / .armorNeedsArmory
  HeroPanelDataMock.newHero / .newHeroCopy / .readyToBuySword
  ```

- [ ] **Step 1: Crear la rama (sólo si TC3.2 se hace a la vez)**

```bash
git switch feature/PROJECT-X-c3-forge-armory && git pull
git worktree add ../phaser-example-c3-hero-panel -b feature/PROJECT-X-c3-hero-panel
cd ../phaser-example-c3-hero-panel && flutter pub get
```

- [ ] **Step 2: Textos**

`lib/core/assets/i18n/translations/es.json`:
- en el bloque `forest.message`, después de `"questCompleted"` (con su coma):

```json
      "gearPurchased": "Has comprado: {name}",
      "gearNotNextTier": "Antes tienes que comprar la pieza anterior."
```

- después del bloque `forest.message` y antes de `forest.placement`:

```json
    "hero": {
      "title": "Héroe",
      "power": "Poder",
      "attack": "Ataque",
      "defense": "Defensa",
      "health": "Vida",
      "weaponStats": "Ataque {attack}",
      "armorStats": "Defensa {defense} · Vida {health}",
      "slot": {
        "weapon": "Arma",
        "armor": "Armadura"
      },
      "section": {
        "gear": "Equipo",
        "skills": "Habilidades"
      },
      "equipped": "En uso",
      "buy": "Comprar",
      "needsBuilding": "Construye la {name}",
      "maxed": "Ya tienes la mejor pieza"
    },
    "gear": {
      "woodcutterAxe": "Hacha de leñador",
      "shortSword": "Espada corta",
      "ironSword": "Espada de hierro",
      "steelSword": "Espada de acero",
      "workClothes": "Ropa de trabajo",
      "leatherArmor": "Armadura de cuero",
      "chainMail": "Cota de malla",
      "plateArmor": "Armadura de placas"
    },
```

`lib/core/config/constants/enum/forest/hero_panel_section.dart`:

```dart
enum HeroPanelSection { gear, skills }
```

`lib/core/assets/i18n/internationalize.dart`: añadir los imports

```dart
import '../../config/constants/enum/forest/hero_panel_section.dart';
import '../../config/constants/enum/gear_id.dart';
import '../../config/constants/enum/gear_slot.dart';
```

y, al final de la clase (después de `forestRetry`):

```dart
  static String get forestHero => '$_forest.hero.title'.tr();
  static String get forestHeroPower => '$_forest.hero.power'.tr();
  static String get forestHeroAttack => '$_forest.hero.attack'.tr();
  static String get forestHeroDefense => '$_forest.hero.defense'.tr();
  static String get forestHeroHealth => '$_forest.hero.health'.tr();
  static String forestHeroWeaponStats({required int attack}) =>
      '$_forest.hero.weaponStats'.tr(namedArgs: {'attack': '$attack'});
  static String forestHeroArmorStats({required int defense, required int health}) =>
      '$_forest.hero.armorStats'.tr(namedArgs: {'defense': '$defense', 'health': '$health'});
  static String forestHeroSlot({required GearSlot slot}) => switch (slot) {
    GearSlot.weapon => '$_forest.hero.slot.weapon'.tr(),
    GearSlot.armor => '$_forest.hero.slot.armor'.tr(),
  };
  static String forestHeroSection({required HeroPanelSection section}) => switch (section) {
    HeroPanelSection.gear => '$_forest.hero.section.gear'.tr(),
    HeroPanelSection.skills => '$_forest.hero.section.skills'.tr(),
  };
  static String get forestHeroEquipped => '$_forest.hero.equipped'.tr();
  static String get forestHeroBuy => '$_forest.hero.buy'.tr();
  static String forestHeroNeedsBuilding({required String name}) =>
      '$_forest.hero.needsBuilding'.tr(namedArgs: {'name': name});
  static String get forestHeroMaxed => '$_forest.hero.maxed'.tr();
  static String forestGear({required GearId id}) => switch (id) {
    GearId.woodcutterAxe => '$_forest.gear.woodcutterAxe'.tr(),
    GearId.shortSword => '$_forest.gear.shortSword'.tr(),
    GearId.ironSword => '$_forest.gear.ironSword'.tr(),
    GearId.steelSword => '$_forest.gear.steelSword'.tr(),
    GearId.workClothes => '$_forest.gear.workClothes'.tr(),
    GearId.leatherArmor => '$_forest.gear.leatherArmor'.tr(),
    GearId.chainMail => '$_forest.gear.chainMail'.tr(),
    GearId.plateArmor => '$_forest.gear.plateArmor'.tr(),
  };
  static String forestMessageGearPurchased({required String name}) =>
      '$_forest.message.gearPurchased'.tr(namedArgs: {'name': name});
  static String get forestMessageGearNotNextTier => '$_forest.message.gearNotNextTier'.tr();
```

`test/core/assets/i18n/internationalize_test.dart`: añadir los imports de `hero_panel_section.dart`, `gear_id.dart` y `gear_slot.dart` y, al final de `main`:

```dart
  test('testWhenNamingEveryGearPieceThenUsesTheSpanishNames', () {
    // given
    final names = GearId.values.map((id) => Internationalize.forestGear(id: id)).toList();

    // when
    final untranslated = names.where((name) => name.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(names, [
      'Hacha de leñador',
      'Espada corta',
      'Espada de hierro',
      'Espada de acero',
      'Ropa de trabajo',
      'Armadura de cuero',
      'Cota de malla',
      'Armadura de placas',
    ]);
  });
```

```dart
  test('testWhenReadingEveryHeroTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestHero,
      Internationalize.forestHeroPower,
      Internationalize.forestHeroAttack,
      Internationalize.forestHeroDefense,
      Internationalize.forestHeroHealth,
      Internationalize.forestHeroWeaponStats(attack: 7),
      Internationalize.forestHeroArmorStats(defense: 3, health: 40),
      for (final slot in GearSlot.values) Internationalize.forestHeroSlot(slot: slot),
      for (final section in HeroPanelSection.values) Internationalize.forestHeroSection(section: section),
      Internationalize.forestHeroEquipped,
      Internationalize.forestHeroBuy,
      Internationalize.forestHeroNeedsBuilding(name: 'Herrería'),
      Internationalize.forestHeroMaxed,
      Internationalize.forestMessageGearPurchased(name: 'Espada corta'),
      Internationalize.forestMessageGearNotNextTier,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Héroe',
      'Poder',
      'Ataque',
      'Defensa',
      'Vida',
      'Ataque 7',
      'Defensa 3 · Vida 40',
      'Arma',
      'Armadura',
      'Equipo',
      'Habilidades',
      'En uso',
      'Comprar',
      'Construye la Herrería',
      'Ya tienes la mejor pieza',
      'Has comprado: Espada corta',
      'Antes tienes que comprar la pieza anterior.',
    ]);
  });
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: PASS.

- [ ] **Step 3: Icono y `HudButton.icon` (TDD)**

`test/layers/presentation/theme/images/custom_icons_test.dart`, al final de `main`:

```dart
  test('testWhenResolvingTheHeroIconThenTheSvgFileExists', () {
    // given
    const path = CustomIcons.hero;

    // when
    final exists = File(path).existsSync();

    // then
    expect(exists, isTrue);
  });
```

`test/layers/presentation/features/forest/widgets/hud_button_test.dart`: añadir los imports `package:flutter_svg/flutter_svg.dart` y `package:rpg/layers/presentation/theme/images/custom_icons.dart` y, al final de `main`:

```dart
  testWidgets('testWhenAnIconIsGivenThenItIsDrawnBeforeTheLabel', (tester) async {
    // given
    final button = HudButton(label: Internationalize.forestHero, icon: CustomIcons.hero, onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    final icon = find.byType(SvgPicture);
    expect(icon, findsOneWidget);
    expect(tester.getCenter(icon).dx, lessThan(tester.getCenter(find.text(Internationalize.forestHero)).dx));
  });
```

Run: `flutter test test/layers/presentation/theme test/layers/presentation/features/forest/widgets/hud_button_test.dart`
Expected: FAIL al compilar (`CustomIcons.hero` y el parámetro `icon` no existen).

`lib/core/assets/images/icons/hero.svg` (decisión 12):

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
  <path d="M11 1.5L19.5 4.5V10.5Q19.5 17 11 20.5Q2.5 17 2.5 10.5V4.5Z" fill="#C9CED6"/>
  <path d="M11 3.6L17.5 5.9V10.5Q17.5 15.6 11 18.4Q4.5 15.6 4.5 10.5V5.9Z" fill="#8A5A2B"/>
  <path d="M11 6.5V15.5M7.5 9.5H14.5" stroke="#E2B33C" stroke-width="2" stroke-linecap="round"/>
</svg>
```

`lib/layers/presentation/theme/images/custom_icons.dart`, después de `axe`:

```dart
  static const String hero = '$_path/hero.svg';
```

`lib/layers/presentation/features/forest/widgets/hud_button.dart`:
- import `package:flutter_svg/flutter_svg.dart`;
- campo `final String? icon;` después de `label`, y `this.icon,` en el constructor después de `required this.label,`;
- en `build`, `final iconPath = icon;` junto a `badgeText`, y como primer hijo de la `Row`:

```dart
                  if (iconPath != null) SvgPicture.asset(iconPath, width: 18, height: 18, excludeFromSemantics: true),
```

Run: `flutter test test/layers/presentation/theme test/layers/presentation/features/forest/widgets/hud_button_test.dart`
Expected: PASS.

- [ ] **Step 4: Datos de prueba de los modelos**

`test/mocks/presentation/features/forest/gear_item_data_mock.dart`. Los costes se escriben como los forma el BLoC (`_amounts`: por orden de `Resource`, separados por coma):

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/presentation/features/forest/models/gear_item_data.dart';

abstract final class GearItemDataMock {
  static GearItemData get woodcutterAxe => GearItemData(
    id: GearId.woodcutterAxe,
    name: Internationalize.forestGear(id: GearId.woodcutterAxe),
    statsText: Internationalize.forestHeroWeaponStats(attack: 4),
    canBuy: false,
  );

  static GearItemData get shortSwordEquipped => GearItemData(
    id: GearId.shortSword,
    name: Internationalize.forestGear(id: GearId.shortSword),
    statsText: Internationalize.forestHeroWeaponStats(attack: 7),
    canBuy: false,
  );

  static GearItemData get shortSwordNeedsForge => _shortSword(
    reasonText: Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.forge)),
    canBuy: false,
  );

  static GearItemData get shortSwordAvailable => _shortSword(reasonText: null, canBuy: true);

  static GearItemData get shortSwordFiveGoldShort => _shortSword(
    reasonText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.gold, amount: 5),
    ),
    canBuy: false,
  );

  static GearItemData get steelSword => GearItemData(
    id: GearId.steelSword,
    name: Internationalize.forestGear(id: GearId.steelSword),
    statsText: Internationalize.forestHeroWeaponStats(attack: 14),
    canBuy: false,
  );

  static GearItemData get workClothes => GearItemData(
    id: GearId.workClothes,
    name: Internationalize.forestGear(id: GearId.workClothes),
    statsText: Internationalize.forestHeroArmorStats(defense: 1, health: 30),
    canBuy: false,
  );

  static GearItemData get leatherArmorNeedsArmory => GearItemData(
    id: GearId.leatherArmor,
    name: Internationalize.forestGear(id: GearId.leatherArmor),
    statsText: Internationalize.forestHeroArmorStats(defense: 3, health: 40),
    costText: [
      Internationalize.forestAmount(resource: Resource.wood, amount: 15),
      Internationalize.forestAmount(resource: Resource.gold, amount: 15),
    ].join(', '),
    reasonText: Internationalize.forestHeroNeedsBuilding(
      name: Internationalize.forestBlueprint(id: BlueprintId.armory),
    ),
    canBuy: false,
  );

  static GearItemData _shortSword({required String? reasonText, required bool canBuy}) => GearItemData(
    id: GearId.shortSword,
    name: Internationalize.forestGear(id: GearId.shortSword),
    statsText: Internationalize.forestHeroWeaponStats(attack: 7),
    costText: [
      Internationalize.forestAmount(resource: Resource.wood, amount: 20),
      Internationalize.forestAmount(resource: Resource.gold, amount: 10),
    ].join(', '),
    reasonText: reasonText,
    canBuy: canBuy,
  );
}
```

`test/mocks/presentation/features/forest/gear_row_data_mock.dart`:

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/layers/presentation/features/forest/models/gear_row_data.dart';

import 'gear_item_data_mock.dart';

abstract final class GearRowDataMock {
  static GearRowData get weaponNeedsForge => GearRowData(
    slot: GearSlot.weapon,
    title: Internationalize.forestHeroSlot(slot: GearSlot.weapon),
    equipped: GearItemDataMock.woodcutterAxe,
    next: GearItemDataMock.shortSwordNeedsForge,
  );

  static GearRowData get weaponReadyToBuy => GearRowData(
    slot: GearSlot.weapon,
    title: Internationalize.forestHeroSlot(slot: GearSlot.weapon),
    equipped: GearItemDataMock.woodcutterAxe,
    next: GearItemDataMock.shortSwordAvailable,
  );

  static GearRowData get weaponMaxed => GearRowData(
    slot: GearSlot.weapon,
    title: Internationalize.forestHeroSlot(slot: GearSlot.weapon),
    equipped: GearItemDataMock.steelSword,
  );

  static GearRowData get armorNeedsArmory => GearRowData(
    slot: GearSlot.armor,
    title: Internationalize.forestHeroSlot(slot: GearSlot.armor),
    equipped: GearItemDataMock.workClothes,
    next: GearItemDataMock.leatherArmorNeedsArmory,
  );
}
```

`test/mocks/presentation/features/forest/hero_panel_data_mock.dart`:

```dart
import 'package:rpg/layers/presentation/features/forest/models/hero_panel_data.dart';

import 'gear_row_data_mock.dart';

abstract final class HeroPanelDataMock {
  static HeroPanelData get newHero => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
  );

  static HeroPanelData get newHeroCopy => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
  );

  static HeroPanelData get readyToBuySword => HeroPanelData(
    power: 31,
    attack: 4,
    defense: 1,
    health: 30,
    rows: [GearRowDataMock.weaponReadyToBuy, GearRowDataMock.armorNeedsArmory],
  );
}
```

- [ ] **Step 5: Tests de modelos y widgets que fallan**

`test/layers/presentation/features/forest/models/hero_panel_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenComparingPanelsWithEqualRowsThenTheyAreEqual', () {
    // given
    final first = HeroPanelDataMock.newHero;
    final second = HeroPanelDataMock.newHeroCopy;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenAGearRowChangesThenThePanelsAreNotEqual', () {
    // given
    final first = HeroPanelDataMock.newHero;
    final second = HeroPanelDataMock.readyToBuySword;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });
}
```

`test/layers/presentation/features/forest/widgets/gear_option_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/gear_item_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenTheGearCanBeBoughtThenTappingBuyCallsOnBuy', (tester) async {
    // given
    var buys = 0;
    final item = GearItemDataMock.shortSwordAvailable;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearOptionTile(item: item, onBuy: () => buys++),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(buys, 1);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.statsText), findsOneWidget);
    expect(find.text(item.costText!), findsOneWidget);
  });

  testWidgets('testWhenTheWorkshopIsMissingThenBuyIsDisabledAndTheReasonIsShown', (tester) async {
    // given
    var buys = 0;
    final item = GearItemDataMock.shortSwordNeedsForge;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearOptionTile(item: item, onBuy: () => buys++),
        ),
      ),
    );
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(buys, 0);
    expect(tester.widget<HudButton>(find.byKey(GearOptionTile.buyKey(GearId.shortSword))).onPressed, isNull);
    expect(find.text(item.reasonText!), findsOneWidget);
  });
}
```

`test/layers/presentation/features/forest/widgets/gear_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_row.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/forest/gear_row_data_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWidgets('testWhenThereIsANextPieceThenShowsTheEquippedOneAndReportsTheNextOnBuy', (tester) async {
    // given
    final bought = <GearId>[];
    final row = GearRowDataMock.weaponReadyToBuy;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearRow(row: row, onBuy: bought.add),
        ),
      ),
    );

    // when
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));

    // then
    expect(bought, [GearId.shortSword]);
    expect(find.text(row.title.toUpperCase()), findsOneWidget);
    expect(find.text(row.equipped.name), findsOneWidget);
    expect(find.text(Internationalize.forestHeroEquipped), findsOneWidget);
  });

  testWidgets('testWhenTheBestPieceIsEquippedThenSaysSoInsteadOfATile', (tester) async {
    // given
    final row = GearRowDataMock.weaponMaxed;

    // when
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 340,
          child: GearRow(row: row, onBuy: (_) {}),
        ),
      ),
    );

    // then
    expect(find.byType(GearOptionTile), findsNothing);
    expect(find.text(Internationalize.forestHeroMaxed), findsOneWidget);
  });
}
```

`test/layers/presentation/features/forest/widgets/hero_panel_test.dart`. El último test es el del móvil en horizontal (decisión 8); el tercero deja probada la pestaña de C5 (decisión 13):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/forest/hero_panel_section.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_option_tile.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/gear_row.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hero_panel.dart';

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

  testWidgets('testWhenThereAreTwoSectionsThenTabsSwitchBetweenGearAndAnEmptySkillsSection', (tester) async {
    // given
    await tester.pumpHud(
      Center(
        child: HeroPanel(
          hero: HeroPanelDataMock.newHero,
          onBuy: (_) {},
          sections: HeroPanelSection.values,
        ),
      ),
    );

    // when
    await tester.tap(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.skills)));
    await tester.pump();

    // then
    expect(find.text(Internationalize.forestHeroSection(section: HeroPanelSection.gear)), findsOneWidget);
    expect(find.byType(GearRow), findsNothing);
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
}
```

Run: `flutter test test/layers/presentation/features/forest/models test/layers/presentation/features/forest/widgets`
Expected: FAIL al compilar (los modelos y widgets no existen).

- [ ] **Step 6: Modelos**

`lib/layers/presentation/features/forest/models/gear_item_data.dart`:

```dart
import '../../../../../core/config/constants/enum/gear_id.dart';

class GearItemData {
  final GearId id;
  final String name;
  final String statsText;
  final String? costText;
  final String? reasonText;
  final bool canBuy;

  const GearItemData({
    required this.id,
    required this.name,
    required this.statsText,
    this.costText,
    this.reasonText,
    required this.canBuy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearItemData &&
          other.id == id &&
          other.name == name &&
          other.statsText == statsText &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.canBuy == canBuy;

  @override
  int get hashCode => Object.hash(id, name, statsText, costText, reasonText, canBuy);

  @override
  String toString() => 'GearItemData($id, $name, $statsText, $costText, $reasonText, canBuy: $canBuy)';
}
```

`lib/layers/presentation/features/forest/models/gear_row_data.dart`:

```dart
import '../../../../../core/config/constants/enum/gear_slot.dart';
import 'gear_item_data.dart';

class GearRowData {
  final GearSlot slot;
  final String title;
  final GearItemData equipped;
  final GearItemData? next;

  const GearRowData({required this.slot, required this.title, required this.equipped, this.next});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearRowData &&
          other.slot == slot &&
          other.title == title &&
          other.equipped == equipped &&
          other.next == next;

  @override
  int get hashCode => Object.hash(slot, title, equipped, next);

  @override
  String toString() => 'GearRowData($slot, $title, equipped: $equipped, next: $next)';
}
```

`lib/layers/presentation/features/forest/models/hero_panel_data.dart`:

```dart
import 'package:collection/collection.dart';

import 'gear_row_data.dart';

class HeroPanelData {
  final int power;
  final int attack;
  final int defense;
  final int health;
  final List<GearRowData> rows;

  const HeroPanelData({
    required this.power,
    required this.attack,
    required this.defense,
    required this.health,
    required this.rows,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeroPanelData &&
          other.power == power &&
          other.attack == attack &&
          other.defense == defense &&
          other.health == health &&
          const ListEquality<GearRowData>().equals(other.rows, rows);

  @override
  int get hashCode => Object.hash(power, attack, defense, health, Object.hashAll(rows));

  @override
  String toString() => 'HeroPanelData(power: $power, $attack/$defense/$health, rows: $rows)';
}
```

- [ ] **Step 7: Widgets**

`lib/layers/presentation/features/forest/widgets/gear_option_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/gear_item_data.dart';
import 'hud_button.dart';

class GearOptionTile extends StatelessWidget {
  final GearItemData item;
  final VoidCallback? onBuy;

  const GearOptionTile({super.key, required this.item, this.onBuy});

  static Key buyKey(GearId id) => Key('gearOptionTileBuy-${id.name}');

  @override
  Widget build(BuildContext context) {
    final costText = item.costText;
    final reasonText = item.reasonText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CustomColors.hudOptionBackground,
        borderRadius: BorderRadius.circular(6),
      ),
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
                      color: item.canBuy ? CustomColors.hudText : CustomColors.hudMuted,
                    ),
                  ),
                  Text(item.statsText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudMuted)),
                  if (costText != null)
                    Text(
                      costText,
                      style: CustomTextStyles.system13w500.copyWith(
                        color: item.canBuy ? CustomColors.hudAccent : CustomColors.hudMuted,
                      ),
                    ),
                  if (reasonText != null)
                    Text(reasonText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
                ],
              ),
            ),
            HudButton(
              key: buyKey(item.id),
              label: Internationalize.forestHeroBuy,
              onPressed: item.canBuy ? onBuy : null,
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/layers/presentation/features/forest/widgets/gear_row.dart`. La pieza equipada va en dos líneas (nombre y atributos): en una sola, "Defensa 1 · Vida 30" + "En uso" desborda a 340 px:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/gear_row_data.dart';
import 'gear_option_tile.dart';

class GearRow extends StatelessWidget {
  final GearRowData row;
  final ValueChanged<GearId> onBuy;

  const GearRow({super.key, required this.row, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final next = row.next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          row.title.toUpperCase(),
          style: CustomTextStyles.system12w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.72),
        ),
        _equipped(),
        if (next != null)
          GearOptionTile(item: next, onBuy: () => onBuy(next.id))
        else
          Text(
            Internationalize.forestHeroMaxed,
            style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
          ),
      ],
    );
  }

  Widget _equipped() {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(row.equipped.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
              Text(
                row.equipped.statsText,
                style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudAccent),
              ),
            ],
          ),
        ),
        Text(
          Internationalize.forestHeroEquipped,
          style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
        ),
      ],
    );
  }
}
```

`lib/layers/presentation/features/forest/widgets/hero_panel.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/forest/hero_panel_section.dart';
import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/hero_panel_data.dart';
import 'gear_row.dart';
import 'hud_button.dart';
import 'hud_panel.dart';

class HeroPanel extends StatefulWidget {
  static const double reservedHeight = 96;

  final HeroPanelData hero;
  final ValueChanged<GearId> onBuy;
  final List<HeroPanelSection> sections;

  const HeroPanel({
    super.key,
    required this.hero,
    required this.onBuy,
    this.sections = const [HeroPanelSection.gear],
  });

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  late HeroPanelSection _section = widget.sections.first;

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
            children: [
              _title(),
              _stats(),
              if (widget.sections.length > 1) _tabs(),
              _body(),
            ],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Text(label, style: CustomTextStyles.system13w500.copyWith(color: CustomColors.hudMuted)),
          Text(
            '$value',
            style: style.copyWith(
              color: CustomColors.hudAccent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
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
      HeroPanelSection.skills => const SizedBox.shrink(),
    };
  }
}
```

Run: `flutter test test/layers/presentation/features/forest/models test/layers/presentation/features/forest/widgets`
Expected: PASS.

- [ ] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/core/config/constants/enum/forest/hero_panel_section.dart lib/layers/presentation/features/forest/models lib/layers/presentation/features/forest/widgets lib/layers/presentation/theme/images/custom_icons.dart test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/forest/models test/layers/presentation/features/forest/widgets test/layers/presentation/theme test/mocks/presentation/features/forest/gear_item_data_mock.dart test/mocks/presentation/features/forest/gear_row_data_mock.dart test/mocks/presentation/features/forest/hero_panel_data_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
```

Expected: `git diff` sin salida en lo generado, `No issues found!` y todo en verde. El panel todavía no se ve en el juego (lo conecta TC3.4).

- [ ] **Step 9: Commit**

```bash
git add lib/core/assets lib/core/config/constants/enum/forest/hero_panel_section.dart lib/layers/presentation test
git commit -m "[PROJECT-X]: Add the hero panel with gear rows and buy buttons"
```

---

### Task TC3.4: Integración en el bosque

**Files:**
- Create: `test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart`
- Modify:
  - `lib/core/config/constants/enum/forest/hud_menu.dart`, `lib/core/config/constants/enum/forest/particle_kind.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `forest_event.dart`
  - `lib/layers/presentation/features/forest/models/hud_data.dart`, `forest_effect.dart`
  - `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`
  - `lib/layers/presentation/features/forest/game/forest_scene_component.dart`
  - `lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`, `particle_burst_component.dart`
  - `lib/layers/presentation/features/forest/forest_page.dart`
  - Tests:
    - `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`
    - `test/layers/presentation/features/forest/models/forest_effect_test.dart`, `hud_data_test.dart`
    - `test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`
    - `test/layers/presentation/features/forest/game/forest_scene_component_test.dart`
    - `test/layers/presentation/features/forest/forest_page_test.dart`
  - Mocks: `test/mocks/presentation/features/forest/forest_bloc_mock.dart`, `hud_data_mock.dart`, `forest_effect_mock.dart`, `game/particle_mock.dart`, `game/forest_data_mock.dart`
  - `CLAUDE.md`

**Interfaces:**
- Consumes: todo lo de TC3.2 (`BuyGearUseCase`, `GetGearOptionsUseCase`, `GearOptionEntity`, `GearOptionState`, `BuyGearResult`, `Gear.workshopFor`, `GearScenarioMock`, `FundsMock`) y de TC3.3 (modelos, `HeroPanel`, `GearOptionTile.buyKey`, textos, `CustomIcons.hero`); `GetHeroStatusUseCase` (C0).
- Produces:
  ```dart
  enum HudMenu { quests, build, hero }
  enum ParticleKind { woodChip, dust, sparkle }

  // forest_event.dart
  final class ForestGearPurchaseRequested extends ForestEvent { final GearId gear; }

  // forest_effect.dart
  final class GearPurchasedEffect extends ForestEffect { final GearId gear; }

  // hud_data.dart
  HudData({…, required HeroPanelData hero})

  // hud_overlay.dart
  HudOverlay({required HudData hud, required ValueChanged<BlueprintId> onBuildSelected, required ValueChanged<GearId> onGearSelected})

  // ForestBloc: + getHeroStatusUseCase, getGearOptionsUseCase, buyGearUseCase (antes de navigationService)

  // particle_bursts.dart
  static List<Particle> ParticleBursts.sparkles({required PositionEntity feet, required math.Random random});
  static double ParticleBursts.sparklesSortY(PositionEntity feet);

  // mocks nuevos
  HudDataMock.withHeroReadyToBuy
  ForestEffectMock.shortSwordPurchased / .shortSwordPurchasedCopy / .leatherArmorPurchased
  ParticleMock.heroFeet / .sparklesRandom
  ForestDataMock.gearPurchased
  ```

- [ ] **Step 1: Unir TC3.2 y TC3.3 (sólo si se hicieron en paralelo)**

```bash
git switch feature/PROJECT-X-c3-forge-armory
git merge --no-ff feature/PROJECT-X-c3-gear-purchase
git merge --no-ff feature/PROJECT-X-c3-hero-panel
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
flutter analyze && flutter test
git worktree remove ../phaser-example-c3-gear-purchase && git worktree remove ../phaser-example-c3-hero-panel
```

Expected: las dos uniones sin conflictos (no comparten ficheros), lo generado al día y todo en verde. Los mensajes de los *merge* son los que propone git (`Merge branch '…'`), que el hook acepta como en C1.

- [ ] **Step 2: Datos de prueba**

`test/mocks/presentation/features/forest/forest_bloc_mock.dart`: importar los tres casos de uso de `use-cases/hero/` y, después de `getQuestsUseCase: …`:

```dart
      getHeroStatusUseCase: GetHeroStatusUseCase(sessionRepository: sessionRepository),
      getGearOptionsUseCase: GetGearOptionsUseCase(sessionRepository: sessionRepository),
      buyGearUseCase: BuyGearUseCase(sessionRepository: sessionRepository),
```

`test/mocks/presentation/features/forest/hud_data_mock.dart` (fichero completo):

```dart
import 'package:rpg/layers/presentation/features/forest/models/hero_panel_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';

import 'build_item_data_mock.dart';
import 'hero_panel_data_mock.dart';
import 'quest_item_data_mock.dart';
import 'resource_item_data_mock.dart';
import 'tool_item_data_mock.dart';

abstract final class HudDataMock {
  static HudData get mock => _make(wood: 0);

  static HudData get mockCopy => _make(wood: 0);

  static HudData get withWood => _make(wood: 6);

  static HudData get withAxeOwned => _make(wood: 0, isAxeOwned: true);

  static HudData get withHeroReadyToBuy => _make(wood: 0, hero: HeroPanelDataMock.readyToBuySword);

  static HudData get start => HudData(
    resources: [ResourceItemDataMock.wood(0)],
    tools: [ToolItemDataMock.axe(isOwned: false)],
    questBadge: '0/3',
    quests: [QuestItemDataMock.current, QuestItemDataMock.pending],
    buildItems: [BuildItemDataMock.unaffordable],
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get gathering => HudData(
    resources: [ResourceItemDataMock.wood(23)],
    tools: [ToolItemDataMock.axe(isOwned: true)],
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get placing => HudData(
    resources: [ResourceItemDataMock.wood(23)],
    tools: [ToolItemDataMock.axe(isOwned: true)],
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: true,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData _make({required int wood, bool isAxeOwned = false, HeroPanelData? hero}) {
    return HudData(
      resources: [ResourceItemDataMock.wood(wood)],
      tools: [ToolItemDataMock.axe(isOwned: isAxeOwned)],
      questBadge: '0/3',
      quests: [QuestItemDataMock.pickUpAxeCurrent],
      buildItems: [BuildItemDataMock.makeUnaffordable(missingWood: 15)],
      isBuildLocked: false,
      hero: hero ?? HeroPanelDataMock.newHero,
    );
  }
}
```

`test/mocks/presentation/features/forest/forest_effect_mock.dart`: importar `gear_id.dart` y, al final de la clase:

```dart
  static const GearPurchasedEffect shortSwordPurchased = GearPurchasedEffect(gear: GearId.shortSword);

  static const GearPurchasedEffect shortSwordPurchasedCopy = GearPurchasedEffect(gear: GearId.shortSword);

  static const GearPurchasedEffect leatherArmorPurchased = GearPurchasedEffect(gear: GearId.leatherArmor);
```

`test/mocks/presentation/features/forest/game/particle_mock.dart`, al final de la clase:

```dart
  static const PositionEntity heroFeet = PositionEntity(x: 150, y: 150);

  static math.Random get sparklesRandom => math.Random(5);
```

`test/mocks/presentation/features/forest/game/forest_data_mock.dart`: importar `gear_id.dart` y, al final de la clase:

```dart
  static final ForestData gearPurchased = ForestData(
    world: world,
    player: player,
    effects: const [GearPurchasedEffect(gear: GearId.shortSword)],
  );
```

- [ ] **Step 3: Tests que fallan**

`test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart` (decisión 16):

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/domain/game/gear_scenario_mock.dart';
import '../../../../../mocks/domain/world/funds_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_effect_mock.dart';
import '../../../../../mocks/presentation/features/forest/gear_item_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/hero_panel_data_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenTheGameStartsThenTheHeroPanelShowsBaseStatsAndWhatEachWorkshopNeeds',
    build: () {
      // given
      return ForestBlocMock.make(GearScenarioMock.withoutWorkshops(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.hero, HeroPanelDataMock.newHero);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheForgeIsBuiltAndTheSwordIsPaidForThenItCanBeBought',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
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
      expect(bloc.state.data.hud!.hero, HeroPanelDataMock.readyToBuySword);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenFundsAreShortThenTheSwordSaysWhatIsMissing',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.fiveGoldShortOfShortSword),
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
      expect(bloc.state.data.hud!.hero.rows.first.next, GearItemDataMock.shortSwordFiveGoldShort);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenBuyingTheShortSwordThenEquipsItSparklesAndAnnouncesIt',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.shortSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hero = bloc.state.data.hud!.hero;
      expect(effects, contains(ForestEffectMock.shortSwordPurchased));
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(Internationalize.forestMessageGearPurchased(name: Internationalize.forestGear(id: GearId.shortSword))),
      );
      expect((hero.attack, hero.power), (7, 40));
      expect(hero.rows.first.equipped, GearItemDataMock.shortSwordEquipped);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenBuyingArmorWithoutTheArmoryThenExplainsWhichBuildingIsMissing',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.leatherArmor));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects.whereType<GearPurchasedEffect>(), isEmpty);
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains(
          Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.armory)),
        ),
      );
      expect(bloc.state.data.hud!.hero.attack, 4);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenSkippingATierThenSaysThePreviousPieceComesFirst',
    build: () {
      // given
      return ForestBlocMock.make(
        GearScenarioMock.withForge(funds: FundsMock.shortSwordPrice),
        navigationService: navigationService,
      );
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestGearPurchaseRequested(gear: GearId.ironSword));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageGearNotNextTier));
    },
  );
}
```

`test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`:
- imports `gear_id.dart`, `gear_option_tile.dart` y `hero_panel.dart`;
- `pumpOverlay` recibe la lista de piezas compradas:

```dart
  Future<List<BlueprintId>> pumpOverlay(WidgetTester tester, HudData hud, {List<GearId>? gears}) async {
    final selected = <BlueprintId>[];
    await tester.pumpHud(HudOverlay(hud: hud, onBuildSelected: selected.add, onGearSelected: (gears ?? []).add));
    return selected;
  }
```

- al final de `main`:

```dart
  testWidgets('testWhenHeroIsTappedThenTheHeroPanelOpensAndBuyingReportsThePiece', (tester) async {
    // given
    final gears = <GearId>[];
    await pumpOverlay(tester, HudDataMock.withHeroReadyToBuy, gears: gears);

    // when
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();
    await tester.tap(find.byKey(GearOptionTile.buyKey(GearId.shortSword)));
    await tester.pump();

    // then
    expect(find.byType(HeroPanel), findsOneWidget);
    expect(gears, [GearId.shortSword]);
  });
```

```dart
  testWidgets('testWhenBuildIsTappedWhileTheHeroPanelIsOpenThenOnlyTheBuildMenuIsShown', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(find.byType(BuildMenu), findsOneWidget);
    expect(find.byType(HeroPanel), findsNothing);
  });
```

```dart
  testWidgets('testWhenTheScreenIsALandscapePhoneThenTheThreeButtonsFitOnScreen', (tester) async {
    // given
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.gathering);

    // then
    final buttons = find.byType(HudButton);
    expect(buttons, findsNWidgets(3));
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(buttons.first).dx, greaterThanOrEqualTo(0));
    expect(tester.getTopRight(buttons.last).dx, lessThanOrEqualTo(640));
  });
```

`test/layers/presentation/features/forest/models/forest_effect_test.dart`, al final de `main`:

```dart
  test('testWhenComparingGearPurchasesThenOnlyTheSamePieceIsEqual', () {
    // given
    const first = ForestEffectMock.shortSwordPurchased;

    // when
    final sameGear = first == ForestEffectMock.shortSwordPurchasedCopy;
    final otherGear = first == ForestEffectMock.leatherArmorPurchased;

    // then
    expect(sameGear, isTrue);
    expect(first.hashCode, ForestEffectMock.shortSwordPurchasedCopy.hashCode);
    expect(otherGear, isFalse);
  });
```

`test/layers/presentation/features/forest/models/hud_data_test.dart`, al final de `main`:

```dart
  test('testWhenTheHeroPanelChangesThenTheHudsAreNotEqual', () {
    // given
    final first = HudDataMock.mock;
    final second = HudDataMock.withHeroReadyToBuy;

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });
```

`test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`, al final de `main`:

```dart
  test('testWhenGearIsBoughtThenTenSparklesRiseAroundTheHerosChest', () {
    // given
    const feet = ParticleMock.heroFeet;

    // when
    final sparkles = ParticleBursts.sparkles(feet: feet, random: ParticleMock.sparklesRandom);

    // then
    expect(sparkles, hasLength(10));
    for (final sparkle in sparkles) {
      expect(sparkle.kind, ParticleKind.sparkle);
      expect(sparkle.origin.y, 126);
      expect(sparkle.origin.x, inInclusiveRange(140, 160));
      expect(_angleDegrees(sparkle.velocityX, sparkle.velocityY), inInclusiveRange(200, 340));
      expect(sparkle.gravity, 0);
      expect(sparkle.lifespanSeconds, 0.6);
    }
    expect(ParticleBursts.sparklesSortY(feet), 151);
  });
```

`test/layers/presentation/features/forest/game/forest_scene_component_test.dart`, antes de `testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced`:

```dart
  testWithFlameGame('testWhenGearIsBoughtThenSparklesBurstOnTheHero', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.gearPurchased);
    await game.ready();

    // then
    final bursts = scene.children.whereType<ParticleBurstComponent>();
    expect(bursts, hasLength(1));
    expect(bursts.single.priority, greaterThan(scene.player!.priority));
  });
```

`test/layers/presentation/features/forest/forest_page_test.dart`: importar `hero_panel.dart` y, antes de `testWhenEscapeIsPressedDuringPlacementThenThePlacementIsCancelled` (usa la DI real, así que también comprueba que la página pide los tres casos de uso nuevos a `locator`):

```dart
  testWidgets('testWhenHeroIsTappedThenTheHeroPanelShowsTheHerosPower', (tester) async {
    // given
    await pumpGame(tester);

    // when
    await tester.tap(find.text(Internationalize.forestHero));
    await tester.pump();

    // then
    expect(find.byType(HeroPanel), findsOneWidget);
    expect(find.text(Internationalize.forestHeroPower), findsOneWidget);
  });
```

Run: `flutter test test/layers/presentation/features/forest`
Expected: FAIL al compilar (`ForestGearPurchaseRequested`, `GearPurchasedEffect`, `HudData.hero`, `onGearSelected`, `ParticleBursts.sparkles`… no existen).

- [ ] **Step 4: Enums, efecto y partículas**

`lib/core/config/constants/enum/forest/hud_menu.dart`:

```dart
enum HudMenu { quests, build, hero }
```

`lib/core/config/constants/enum/forest/particle_kind.dart`:

```dart
enum ParticleKind { woodChip, dust, sparkle }
```

`lib/layers/presentation/features/forest/models/forest_effect.dart`: importar `../../../../../core/config/constants/enum/gear_id.dart` y, al final del fichero:

```dart
final class GearPurchasedEffect extends ForestEffect {
  final GearId gear;

  const GearPurchasedEffect({required this.gear});

  @override
  bool operator ==(Object other) => identical(this, other) || other is GearPurchasedEffect && other.gear == gear;

  @override
  int get hashCode => Object.hash(GearPurchasedEffect, gear);
}
```

`lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`. Constantes después de `sortYOffset`:

```dart
  static const int sparklesPerPurchase = 10;
  static const double sparkleLift = 24;
  static const double sparkleSpreadX = 10;
  static const double sparkleAngleMin = 200;
  static const double sparkleAngleMax = 340;
  static const double sparkleSpeedMin = 15;
  static const double sparkleSpeedMax = 40;
  static const double sparkleLifespanSeconds = 0.6;
  static const double sparkleAlphaStart = 1;
  static const double sparkleAlphaEnd = 0;
  static const double sparkleScaleStart = 1;
  static const double sparkleScaleEnd = 0.4;
```

y, antes de `chipsSortY`:

```dart
  static List<Particle> sparkles({required PositionEntity feet, required math.Random random}) {
    return List.generate(sparklesPerPurchase, (_) {
      final speed = _between(random, sparkleSpeedMin, sparkleSpeedMax);
      final angle = _between(random, sparkleAngleMin, sparkleAngleMax) * math.pi / 180;
      return Particle(
        kind: ParticleKind.sparkle,
        origin: PositionEntity(x: feet.x + _between(random, -sparkleSpreadX, sparkleSpreadX), y: feet.y - sparkleLift),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 0,
        rotationDegrees: 0,
        lifespanSeconds: sparkleLifespanSeconds,
        alphaStart: sparkleAlphaStart,
        alphaEnd: sparkleAlphaEnd,
        scaleStart: sparkleScaleStart,
        scaleEnd: sparkleScaleEnd,
      );
    });
  }

  static double sparklesSortY(PositionEntity feet) => feet.y + sortYOffset;
```

`lib/layers/presentation/features/forest/game/particles/particle_burst_component.dart`: constantes después de `dustRadius`

```dart
  static const Color sparkleColor = Color(0xFFF4D77A);
  static const double sparkleSize = 3;
```

y el caso nuevo del `switch` de `render`, después de `ParticleKind.dust`:

```dart
        case ParticleKind.sparkle:
          final size = sparkleSize * particle.scale(_ageSeconds);
          _paint.color = sparkleColor.withValues(alpha: alpha);
          canvas.drawRect(Rect.fromCenter(center: Offset(at.x, at.y), width: size, height: size), _paint);
```

`lib/layers/presentation/features/forest/game/forest_scene_component.dart`: caso nuevo al final del `switch` de `_play`

```dart
      case GearPurchasedEffect():
        _onGearPurchased();
```

y el método, antes de `_building`:

```dart
  void _onGearPurchased() {
    final player = _player;
    if (player == null) return;
    final feet = PositionEntity(x: player.position.x, y: player.position.y);
    add(
      ParticleBurstComponent(
        particles: ParticleBursts.sparkles(feet: feet, random: _random),
        sortY: ParticleBursts.sparklesSortY(feet),
      ),
    );
  }
```

- [ ] **Step 5: `HudData`, `HudOverlay` y la página**

`lib/layers/presentation/features/forest/models/hud_data.dart`:
- import `hero_panel_data.dart`;
- campo `final HeroPanelData hero;` después de `isBuildLocked`, y `required this.hero,` al final del constructor;
- `other.hero == hero` al final de `==` y `hero` al final de `Object.hash`.

`lib/layers/presentation/features/forest/widgets/hud_overlay.dart`:
- imports `gear_id.dart`, `../../../theme/images/custom_icons.dart` y `hero_panel.dart`;
- campo y constructor:

```dart
  final ValueChanged<GearId> onGearSelected;

  const HudOverlay({super.key, required this.hud, required this.onBuildSelected, required this.onGearSelected});
```

- tercer botón en `_buttonRow`, después de *Construir*:

```dart
        HudButton(
          label: Internationalize.forestHero,
          icon: CustomIcons.hero,
          isActive: _openMenu == HudMenu.hero,
          onPressed: () => _toggle(HudMenu.hero),
        ),
```

- caso nuevo en `_menu`:

```dart
      HudMenu.hero => HeroPanel(hero: widget.hud.hero, onBuy: widget.onGearSelected),
```

`lib/layers/presentation/features/forest/forest_page.dart`:
- imports `../../../domain/use-cases/hero/buy_gear_use_case.dart`, `get_gear_options_use_case.dart` y `get_hero_status_use_case.dart`;
- en `BlocProvider.create`, después de `getQuestsUseCase: …`:

```dart
        getHeroStatusUseCase: locator.get<GetHeroStatusUseCase>(),
        getGearOptionsUseCase: locator.get<GetGearOptionsUseCase>(),
        buyGearUseCase: locator.get<BuyGearUseCase>(),
```

- en `_hudOverlay`:

```dart
      onGearSelected: (gear) => bloc.add(ForestGearPurchaseRequested(gear: gear)),
```

- [ ] **Step 6: Evento y BLoC**

`lib/layers/presentation/features/forest/bloc/forest_event.dart`, al final:

```dart
final class ForestGearPurchaseRequested extends ForestEvent {
  final GearId gear;

  const ForestGearPurchaseRequested({required this.gear});
}
```

`lib/layers/presentation/features/forest/bloc/forest_bloc.dart`:
- imports: `buy_gear_result.dart`, `gear_id.dart`, `gear_option_state.dart`, `gear_slot.dart` (de `core/config/constants/enum/`); `domain/entities/gear/gear_entity.dart`, `gear_option_entity.dart`; `domain/rules/gear.dart`; los tres casos de uso de `domain/use-cases/hero/`; `../models/gear_item_data.dart`, `gear_row_data.dart`, `hero_panel_data.dart`;
- campos y parámetros del constructor, después de los de `GetQuestsUseCase`:

```dart
  final GetHeroStatusUseCase _getHeroStatusUseCase;
  final GetGearOptionsUseCase _getGearOptionsUseCase;
  final BuyGearUseCase _buyGearUseCase;
```

```dart
    required this._getHeroStatusUseCase,
    required this._getGearOptionsUseCase,
    required this._buyGearUseCase,
```

- caso nuevo al final del `switch` de `on<ForestEvent>`:

```dart
        ForestGearPurchaseRequested() => _onGearPurchaseRequested(event, emit),
```

- el manejador (síncrono por dentro, como los demás), después de `_onPlacementCancelled`:

```dart
  Future<void> _onGearPurchaseRequested(ForestGearPurchaseRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    final effects = <ForestEffect>[];
    _buyGear(event.gear, effects: effects);
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }
```

- la compra (decisión 10), antes de `_react`:

```dart
  void _buyGear(GearId id, {required List<ForestEffect> effects}) {
    switch (_buyGearUseCase(id: id)) {
      case BuyGearResult.ok:
        _showMessage(Internationalize.forestMessageGearPurchased(name: Internationalize.forestGear(id: id)));
        effects.add(GearPurchasedEffect(gear: id));
      case BuyGearResult.missingBuilding:
        _showMessage(Internationalize.forestHeroNeedsBuilding(name: _workshopName(Gear.byId(id))));
      case BuyGearResult.notNextTier:
        _showMessage(Internationalize.forestMessageGearNotNextTier);
      case BuyGearResult.notEnoughResources:
        _showMessage(Internationalize.forestMessageNotEnoughResources);
    }
  }
```

- en `_hudData`, al final de `HudData(…)`: `hero: _heroPanel(),`; y los métodos, después de `_hudData` (decisiones 8 y 9; las `locked` no se muestran):

```dart
  HeroPanelData _heroPanel() {
    final status = _getHeroStatusUseCase();
    final options = _getGearOptionsUseCase();
    return HeroPanelData(
      power: status.power,
      attack: status.stats.attack,
      defense: status.stats.defense,
      health: status.stats.health,
      rows: [
        for (final slot in GearSlot.values) _gearRow(slot, options.where((option) => option.gear.slot == slot)),
      ],
    );
  }

  GearRowData _gearRow(GearSlot slot, Iterable<GearOptionEntity> options) {
    final equipped = options.firstWhere((option) => option.state == GearOptionState.equipped);
    final next = options.firstWhereOrNull(
      (option) => option.state != GearOptionState.equipped && option.state != GearOptionState.locked,
    );
    return GearRowData(
      slot: slot,
      title: Internationalize.forestHeroSlot(slot: slot),
      equipped: _gearItem(equipped),
      next: next == null ? null : _gearItem(next),
    );
  }

  GearItemData _gearItem(GearOptionEntity option) {
    final gear = option.gear;
    return GearItemData(
      id: gear.id,
      name: Internationalize.forestGear(id: gear.id),
      statsText: switch (gear.slot) {
        GearSlot.weapon => Internationalize.forestHeroWeaponStats(attack: gear.attack),
        GearSlot.armor => Internationalize.forestHeroArmorStats(defense: gear.defense, health: gear.health),
      },
      costText: option.state == GearOptionState.equipped ? null : _amounts(gear.cost),
      reasonText: switch (option.state) {
        GearOptionState.needsBuilding => Internationalize.forestHeroNeedsBuilding(name: _workshopName(gear)),
        GearOptionState.unaffordable => Internationalize.forestMissing(amounts: _amounts(option.missing)),
        GearOptionState.equipped || GearOptionState.available || GearOptionState.locked => null,
      },
      canBuy: option.canBuy,
    );
  }

  String _workshopName(GearEntity gear) => Internationalize.forestBlueprint(id: Gear.workshopFor(gear.slot));
```

Run: `flutter test test/layers/presentation/features/forest`
Expected: PASS, incluidos los tests anteriores del BLoC y del HUD (sólo cambian por el campo `hero` de los mocks).

- [ ] **Step 7: Documentar en `CLAUDE.md`**

En *Architecture*:
- `lib/layers/domain/` → `entities/<feature>/`: "gear (`GearEntity`)" pasa a "gear (`GearEntity`, `GearOptionEntity` with a `GearOptionState`, `missing` and `canBuy`)".
- `world/extensions/`: añadir `BuildingListRules.hasComplete` (a finished building of a blueprint).
- `rules/`: "`Blueprints` catalogue (house, forge, armory)" y "`Gear` catalogue (`workshopFor`: weapons at the forge, armor at the armory)".
- `use-cases/`: en `hero/`, añadir "`BuyGearUseCase` (checks a finished workshop, the next tier and the funds, in that order; pays with `World.spend` and equips with `World.updateHero`), `GetGearOptionsUseCase` (per slot, from the equipped tier up)".
- `features/forest/bloc/`: añadir el evento `ForestGearPurchaseRequested`.
- `features/forest/models/`: añadir `HeroPanelData`, `GearRowData`, `GearItemData` y el efecto `GearPurchasedEffect`.
- `features/forest/game/`: en `particles/`, "chips, dust and the gear-purchase sparkles".
- `features/forest/widgets/`: añadir "`HeroPanel` (sections: gear now; the skills tab is ready for C5 and hidden while `sections` has one entry) + `GearRow` + `GearOptionTile`", y que `HudButton` acepta un `icon` SVG opcional.

En *Key cross-cutting conventions*, en la línea *New resource, tool or building*, añadir al final: "`LpcAssetsMock` builds a frame for every `BlueprintId`, and new buildings reuse `build_cottage()` in `build_assets.py` (recoloured roof via `ROOF_RAMP`)."

- [ ] **Step 8: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/forest lib/layers/presentation/features/forest test/layers/presentation/features/forest test/mocks/presentation/features/forest/forest_bloc_mock.dart test/mocks/presentation/features/forest/hud_data_mock.dart test/mocks/presentation/features/forest/forest_effect_mock.dart test/mocks/presentation/features/forest/game/particle_mock.dart test/mocks/presentation/features/forest/game/forest_data_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test/mocks
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida en lo generado, `No issues found!` y todo en verde.

- [ ] **Step 9: Commit**

```bash
git add lib/core/config/constants/enum/forest lib/layers/presentation test
git commit -m "[PROJECT-X]: Open the hero panel from the forest and buy gear with a sparkle"
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the forge, the armory and the hero panel in the project guide"
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida.

---

## Prueba manual

En Chrome (`flutter run -d chrome`), en el emulador Android (`flutter run -d emulator-5554`) y en el simulador iOS (`flutter run -d "iPhone 17"`), en horizontal:

1. **Botón y panel:**
   - El HUD muestra *Misiones*, *Construir* y *Héroe* (con el escudo).
   - *Héroe* abre el panel: "Poder 31", "Ataque 4", "Defensa 1", "Vida 30".
   - Fila *ARMA*: "Hacha de leñador · Ataque 4 · En uso" y, debajo, *Espada corta* (Ataque 7, "20 de madera, 10 de oro", "Construye la Herrería", *Comprar* desactivado).
   - Fila *ARMADURA*: "Ropa de trabajo" y *Armadura de cuero* con "Construye la Armería".
   - Abrir *Construir* cierra el panel, y al revés.
2. **Edificios:**
   - Tala hasta tener 25 de madera. En *Construir*, *Herrería*: el fantasma es la Herrería (muro de piedra, tejado gris, chimenea).
   - Constrúyela: 10 martillazos y "Construcción terminada: Herrería".
   - En *Héroe*, la Espada corta ya no dice "Construye la Herrería": dice "Faltan 10 de oro" (o "Faltan 20 de madera, 10 de oro" si no queda madera).
   - Construye la Armería (tejado rojo): la armadura de cuero pasa a decir lo que falta.
3. **Comprar:**
   - Con C2 ya fusionada: gana oro en la arena, vuelve y compra la Espada corta. Se ve el destello dorado sobre el héroe, el *snackbar* "Has comprado: Espada corta", el Ataque pasa a 7 y el Poder a 40. La fila *ARMA* muestra ahora la Espada corta "En uso" y la *Espada de hierro* como siguiente.
   - Sin C2 no hay forma de ganar oro en el juego; la compra la cubren `gear_flow_test.dart` y `forest_bloc_hero_test.dart`. En la prueba manual basta con ver el motivo "Faltan 10 de oro" y el botón desactivado.
4. **Móvil en horizontal:**
   - En el emulador y el simulador, el panel *Héroe* cabe (o se desplaza) sin rayas amarillas de desbordamiento.
   - Los tres botones no tapan la barra de recursos.
   - Si en ese momento ya está el botón *Arena* de C2, se hace la comprobación de los cuatro botones (sección *Reparto*, README 3.2).
5. **Web:** en Chrome, con una ventana de 640 × 360, lo mismo que el punto 4. Esc sigue cancelando la colocación con el panel *Héroe* abierto.

## Al cerrar C3

- Marca los checkboxes de las cuatro tareas.
- PR de `feature/PROJECT-X-c3-forge-armory` a `feature/PROJECT-X-arena`, con la prueba manual de las tres plataformas. Tras la unión, la batería de cierre en la rama de integración (README 3.0).
- Apunta en la sección 5 del README de la arena:
  - si TC3.2 y TC3.3 se hicieron en paralelo (ramas y uniones), como en C1;
  - que el test del fantasma que pedía F0 ya existe (`testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced`). Avisa al flujo de la aldea: F6 ya no tiene que añadirlo.
- Avisa a quien lleve C2:
  - `HudButton` ya tiene `icon` (para `arena.svg`);
  - `ParticleKind` ya tiene `sparkle` (C2 añade `bloodDrop` detrás);
  - si C2 se fusiona después, le toca la comprobación de los cuatro botones.
- Avisa a quien lleve C5: `HeroPanel(sections: HeroPanelSection.values)` muestra las pestañas; falta pasar `sections` desde `HudOverlay`, añadir sus datos a `HeroPanelData` y rellenar el caso `skills`.
- **Cruces pendientes con la aldea** (README 3.2; los resuelve el flujo de la arena al traer `develop`):
  - **F5 (piedra):** añadir `Resource.stone: 10` al coste de `Blueprints.forge` / `armory` y `Resource.stone: 15` a `steelSword` y `plateArmor` en `Gear.all`, y ajustar `BlueprintEntityMock.forge` / `armory`, `BuildOptionEntityMock.workshop`, `BuildItemDataMock.workshopUnaffordable` y `blueprints_test.dart`.
  - **F2 (guardado):** comprobar que el mapper de edificios acepta `forge` y `armory` (TC3.1, Step 7).
  - **F8 (taller):** `BlueprintId.workshop` es otro edificio; no se mezcla con `forge`.
- Si alguna firma de *Interfaces* cambió al implementar, actualízala aquí **y** en las fichas de C5 y C7, y apúntalo en la sección 5 del README.

