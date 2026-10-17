# F8 · Taller y mejoras de herramientas — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **En iOS está a medias**: plan detallado `$IOS/docs/plans/2026-10-12-village/F8-workshop.md` (🟢), con solo la tarea 1 de 6 hecha (`0234537`, rama `feature/PROJECT-F8-workshop`). La fase se termina en Flutter y esta ficha recoge las decisiones de ese plan; manda sobre la versión anterior.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F8-workshop`, desde `feature/PROJECT-X-town` |
| **Depende de** | F7 |
| **Issue / milestone** | `phase:F8` · milestone `F8 Workshop` |
| **Referencia iOS** | plan detallado arriba; `0234537` (`[PROJECT-F8]: Add the workshop and the tool levels`) |

## Objetivo

Un taller donde se compran el hacha y el pico de hierro, que talan y pican con un 40 % menos de golpes, y el segundo capítulo de misiones de la aldea.

## Decisiones ya tomadas

**Taller** (`BlueprintId.workshop`, al final del enum):
- 20 de madera + 10 de piedra, 10 golpes (como la herrería y la armería), radio 40.
- `accepts` vacío y colocación en cualquier sitio.
- **Cuarto** en el menú: tras la cantera y antes de los edificios del héroe.
- Ya no es "el primer coste con dos recursos": desde F5 la herrería, la armería y la torre de magia cuestan piedra.

**Nivel de las herramientas:**
- `InventoryEntity.toolLevels: Map<ToolKind, int>`; un nivel que falta es el 1.
- Va aparte de tener la herramienta (`tools`) y del equipo del héroe: el hacha de hierro no cambia el ataque.
- Todas las operaciones de `InventoryRules` conservan los niveles; entregar en el almacén no los pierde.
- **Golpes con mejora:** `max(1, ⌈golpes × 60 %⌉)`, en enteros como `(golpes * 60 + 99) ~/ 100` (`Rules.upgradedHitsPercent = 60`), para no depender del redondeo de `double`.
- `TreeEntity.hitsToFell` y `RockEntity.hitsToBreak` no cambian:
  - `Woodcutting`/`Mining` comparan los golpes recibidos con `InventoryRules.hitsNeeded(tool, base)` en cada golpe;
  - `TreeHitEventEntity` lleva los golpes que faltan con la herramienta actual;
  - un árbol a medio talar al comprar la mejora cae en cuanto lleva los golpes nuevos.
- Quedan así: pino 3 → 2, árboles de 5 → 3, roble 7 → 5, viejo y grande 8 → 5, roca 8 → 5.
- El intervalo de trabajo no cambia; la cantera de F7 sigue acelerando el picado aparte.

**Mejoras:**
- `UpgradeEntity(id: UpgradeId, tool, level, cost)` en `domain/entities/upgrade/`, catálogo `Upgrades.all` en `domain/rules/upgrades.dart`, enum `UpgradeId` en core:

  | Mejora | Coste | Herramienta y nivel |
  |---|---|---|
  | `ironAxe` *Hacha de hierro* | 15 de madera + 15 de piedra | hacha, nivel 2 |
  | `ironPickaxe` *Pico de hierro* | 10 de madera + 20 de piedra | pico, nivel 2 |

- **Comprar:** `BuyUpgradeUseCase.call({required UpgradeId id})` devuelve `UpgradeResult { ok, notEnoughResources, noWorkshop, alreadyOwned }` (core). Comprueba, en este orden: ya comprada → sin taller terminado → sin recursos en el almacén (sin cobrar nada). Paga con `World.spend` y sube el nivel con `World.updatePlayer`; `World` no gana nada.
- Se puede mejorar una herramienta antes de recogerla: sirve en cuanto se recoge.
- **Listar:** `GetUpgradeOptionsUseCase` devuelve una `UpgradeOptionEntity` por mejora con `UpgradeOptionState { available, needsBuilding, unaffordable, owned }` y lo que falta, como `GearOptionEntity`/`SkillOptionEntity`.

**HUD:**
- Quinto botón **Taller**, **tercero** (*Misiones*, *Construir*, *Taller*, *Héroe*, *Arena*), siempre visible, con icono propio `workshop.svg` (martillo y llave; el de iOS cuando exista, si no se dibuja uno).
- `HudMenu.upgrades`, al final del enum.
- `UpgradeMenu` + `UpgradeOptionTile` (un fichero por clase). El panel lleva el título "Mejoras de herramientas" y una fila por mejora con:
  - su efecto;
  - su coste (o "Comprada");
  - el motivo si no se puede ("Construye el Taller", "Faltan …").
- Comprar no cierra el panel, como en *Héroe*.
- **La mejora se ve en la barra, sin recolorear el sprite:** la herramienta pasa a llamarse "Hacha de hierro" / "Pico de hierro" (`ToolItemData.name`, la última mejora del catálogo con su nivel alcanzado).
- `ForestUpgradeRequested(id)` y `UpgradePurchasedEffect(upgrade)`, con las chispas de comprar equipo sobre el jugador (sin `ParticleKind` nuevo). Aviso "Has mejorado tu herramienta: Hacha de hierro".
- Se vuelven a medir los umbrales con cinco botones y las herramientas mejoradas (en iOS, 1800 y 1200 pt: los botones van siempre debajo de la barra). La regla de los 640 px del README de la arena se comprueba aparte.

**Arte:** `workshop` = la casita de `build_cottage()` con el muro de piedra y entramado de la herrería y el tejado de paja recoloreado en **verde**, sin chimenea (120 × 191, pivote `(0.5, 1)`). `buildingFrontOffset` 24. Sin autores nuevos.

**Misiones del capítulo 2** (al final de `QuestId` y detrás de las siete de F4 en `QuestLine.village`; la insignia pasa a `x/19`):

| Misión | Objetivo | Texto | Mide |
|---|---|---|---|
| `gatherTwentyStone` | 20 | Ten 20 de piedra en el almacén | `funds` (piedra), como `gatherFortyWood`: sin estadística nueva |
| `buildQuarry` | 1 | Construye una cantera | edificios terminados |
| `buildWorkshop` | 1 | Construye el Taller | edificios terminados |
| `upgradeAxe` | 1 | Compra el Hacha de hierro | nivel del hacha ≥ el de `ironAxe` |

**Textos:**
- Taller: `forest.blueprint.workshop` y `forest.hud.workshop` "Taller".
- Panel de mejoras:
  - `forest.upgrade.title` "Mejoras de herramientas";
  - `forest.upgrade.ironAxe` "Hacha de hierro" y `forest.upgrade.ironPickaxe` "Pico de hierro";
  - `forest.upgrade.ironAxe.effect` "Talas con un {percent} % menos de golpes" y `forest.upgrade.ironPickaxe.effect` "Picas con un {percent} % menos de golpes";
  - `forest.upgrade.owned` "Comprada", `forest.upgrade.needsWorkshop` "Construye el Taller".
- Avisos: `forest.message.upgradePurchased` "Has mejorado tu herramienta: {name}", `forest.message.upgradeOwned` "Ya tienes esa mejora.".
- Las cuatro misiones.

**Guardado:** en F2 (`toolLevels` con la clave del `ToolKind`, y al cargar un nivel sin mejora se recorta al máximo del catálogo; el taller como edificio; las misiones nuevas).

## Ficheros previstos

- **Dominio:**
  - `entities/player/inventory_entity.dart`, `world/extensions/inventory_rules.dart`;
  - `entities/upgrade/upgrade_entity.dart` y `upgrade_option_entity.dart` (nuevos), `rules/upgrades.dart` (nuevo);
  - `rules/blueprints.dart`, `rules/rules.dart`;
  - `world/woodcutting.dart`, `world/mining.dart`;
  - casos de uso `buy_upgrade_use_case.dart` y `get_upgrade_options_use_case.dart` (nuevos);
  - `quests/quests.dart`.
- **Core:** `blueprint_id.dart`, `upgrade_id.dart`, `upgrade_result.dart` y `upgrade_option_state.dart` (nuevos), `quest_id.dart`, `forest/hud_menu.dart`, `es.json`, `internationalize.dart`, `images/icons/workshop.svg`.
- **Presentación:** `bloc/*`, `models/hud_data.dart`, `models/upgrade_item_data.dart` (nuevo), `models/tool_item_data.dart`, `models/forest_effect.dart`, `widgets/hud_overlay.dart`, `widgets/upgrade_menu.dart` y `upgrade_option_tile.dart` (nuevos), `game/forest_state_listener.dart`, `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`, `theme/images/custom_icons.dart`.
- **Arte:** `build_assets.py`, `forest.{png,json}`, `CREDITS.md`.
- **Tests:** `di.config.dart` regenerado.

## Cómo probarlo

- Construir el taller (madera y piedra).
- *Taller* abre el panel; sin taller, las mejoras dicen "Construye el Taller".
- Comprar el hacha descuenta 15 y 15 del almacén, echa chispas, avisa y la barra dice "Hacha de hierro". Después, un pino cae en 2 golpes, un roble en 5 y, con el pico, una roca en 5. Volver a comprar avisa.
- Las cuatro misiones avanzan y la insignia llega a 19/19.
- Tests:
  - `inventory_rules_test.dart`: `hitsNeeded` en todos los casos de arriba, y los niveles se conservan al entregar;
  - `world_woodcutting_test.dart` / `world_mining_test.dart`: con nivel 1, los mismos golpes y eventos que antes; con la mejora, menos golpes; un árbol a medias cae con los golpes nuevos;
  - `buy_upgrade_use_case_test.dart`: el orden de las comprobaciones y que no se cobra nada si falla;
  - `get_upgrade_options_use_case_test.dart`: estados y lo que falta;
  - `upgrades_test.dart` y `blueprints_test.dart`: costes y orden del menú;
  - `forest_bloc_test.dart`: compra, aviso, efecto, nombre mejorado en la barra y que el panel no se cierra;
  - `upgrade_menu_test.dart` / `upgrade_option_tile_test.dart`;
  - misiones del capítulo 2;
  - `lpc_atlas_test.dart`, `custom_icons_test.dart`, `internationalize_test.dart` y los umbrales del HUD.
