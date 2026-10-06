# C3 · Herrería y Armería — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | D (héroe) |
| **Depende de** | C0 |
| **Issue / milestone** | `phase:C3` · `stream:D` · milestone `C3 Forge and armory` |

## Objetivo

Que la aldea sirva para hacer más fuerte al héroe: se construyen la Herrería y la Armería y en ellas se compran armas y armaduras con madera y oro. El Poder del héroe sube y se ve en un panel nuevo, *Héroe*.

## Decisiones ya tomadas

**Edificios** (`BlueprintId.forge`, `BlueprintId.armory`, al final del enum; entradas al final de `Blueprints.all`):

| Edificio | Coste | Martillazos | Huella |
|---|---|---|---|
| Herrería | 25 de madera | 10 | como la casa |
| Armería | 25 de madera | 10 | como la casa |

- Si F5 (piedra) ya está fusionada, los dos cuestan además 10 de piedra.
- Si F5 llega después, lo añade F5 (ver la sección 3.2 del README).

**Compra:**
- `Gear.workshopFor(GearSlot slot) → BlueprintId` en `rules/gear.dart`: `weapon → forge`, `armor → armory`.
- `BuyGearUseCase.call({required GearId id}) → BuyGearResult`, con el enum de core `BuyGearResult { ok, missingBuilding, notNextTier, notEnoughResources }`, que se comprueba en ese orden.
  - `missingBuilding`: no hay un edificio **terminado** de `Gear.workshopFor(gear.slot)` (se mira en `world.buildings`).
  - `notNextTier`: sólo se puede comprar el nivel siguiente al equipado (`hero.nextGear(slot)?.id == id`). Así no hay "saltos" ni compras repetidas.
  - `notEnoughResources`: `world.spend(gear.cost)` devuelve `false`.
  - `ok`: `world.updateHero((hero) => hero.withGear(gear))`.
- `GetGearOptionsUseCase → List<GearOptionEntity>`, con `GearOptionEntity(gear, state: GearOptionState, missing: Map<Resource, int>)` y el enum de core `GearOptionState { equipped, available, needsBuilding, unaffordable, locked }`.
  - `locked`: un nivel por encima del siguiente.
  - `missing` se calcula con `InventoryRules.missing` sobre `world.funds`.

**Escena:** el tipo de edificio sólo cambia el sprite (`SpriteNames.building(id)`, de F0). No hay clic sobre los edificios: se compra desde el panel, si el edificio existe.

**UI** (en el HUD del bosque):
- Botón *Héroe* (`HudMenu.hero`, icono `hero.svg`) que abre `HeroPanel` (un `HudPanel`).
- El panel muestra:
  - Poder y los tres atributos;
  - una fila por ranura (`GearRow`: arma, armadura) con la pieza equipada y la siguiente, su coste y lo que falta;
  - un botón *Comprar* (`GearOptionTile`), desactivado con el motivo ("Construye la Herrería", "Faltan 5 de oro").
- Modelos nuevos: `HeroPanelData(power, attack, defense, health, rows: List<GearRowData>)`, `GearRowData`, `GearItemData`. `HudData` gana `hero: HeroPanelData`.
- Evento `ForestGearPurchaseRequested(id)` y efecto `GearPurchasedEffect`: destello sobre el héroe, con el `ParticleBurstComponent` existente. Mensaje con *snackbar*: "Has comprado: Espada corta".
- C5 añade a este mismo panel una pestaña *Habilidades*: deja `HeroPanel` preparado con dos secciones, *Equipo* (ahora) y *Habilidades* (vacía hasta C5, sin mostrarse).

**Arte** (atlas `forest`, con piezas de `cottage.png` y `thatched-roof.png`):
- Herrería: tejado recoloreado gris oscuro y una chimenea hecha con un bloque de piedra del `terrain_atlas`. Frame `forge`.
- Armería: tejado recoloreado rojo. Frame `armory`.
- Su desplazamiento de dibujo va en `RenderConstants.buildingFrontOffset`.

**Textos:**
- `forest.blueprint.forge` / `armory`;
- `forest.hero.*`: título, Poder, atributos, *Comprar*, motivos;
- `forest.gear.<GearId>`: los 8 nombres ("Hacha de leñador", "Espada corta", "Espada de hierro", "Espada de acero", "Ropa de trabajo", "Armadura de cuero", "Cota de malla", "Armadura de placas").

**Persistencia:** los niveles ya están en `HeroEntity` (C0). Los edificios nuevos se guardan como los demás (F2).

## Ficheros previstos

**Dominio:**
- `rules/gear.dart` (`workshopFor`), `rules/blueprints.dart`
- `entities/gear/gear_option_entity.dart` (nuevo)
- `use-cases/hero/buy_gear_use_case.dart`, `get_gear_options_use_case.dart` (nuevos)
- Enums de core: `blueprint_id.dart`, `buy_gear_result.dart` y `gear_option_state.dart` (nuevos), `forest/hud_menu.dart`

**Presentación:**
- `features/forest/bloc/*`
- `models/hud_data.dart`, `models/hero_panel_data.dart`, `models/gear_row_data.dart`, `models/gear_item_data.dart` (nuevos), `models/forest_effect.dart`
- `widgets/hud_overlay.dart`, `widgets/hero_panel.dart`, `widgets/gear_row.dart`, `widgets/gear_option_tile.dart` (nuevos)
- `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`, `game/forest_scene_component.dart`
- `theme/images/custom_icons.dart`

**Core:** `Internationalize`, `es.json`, `icons/hero.svg`.

**Arte:** `build_assets.py`.

## Cómo probarlo

- Construir la Herrería. En el panel *Héroe*, la Espada corta pide "20 de madera, 10 de oro".
- Con el oro de la arena (o, si C1/C2 no están, con un test de flujo que use `world.earn`), comprarla: el Ataque pasa de 4 a 7 y el Poder sube.
- La Espada de hierro no se puede comprar antes que la corta.
- Sin Armería, las armaduras dicen "Construye la Armería".
- Tests:
  - `buy_gear_use_case_test.dart`, con cada `BuyGearResult`;
  - `get_gear_options_use_case_test.dart`;
  - `forest_bloc_test.dart` (compra y efecto);
  - `hero_panel_test.dart`;
  - `blueprints_test.dart` (los edificios nuevos);
  - si la Herrería es el primer edificio construible después de la casa (F6 no está fusionada): un test de `ForestSceneComponent` que cambia la previsualización de casa a Herrería y comprueba que el fantasma se sustituye (desviación de F0).
