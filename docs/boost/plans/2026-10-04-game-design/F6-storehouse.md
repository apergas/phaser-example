# F6 · Almacén y capacidad de carga — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-village/F6-storehouse.md`); esta ficha manda sobre la versión anterior.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F6-storehouse`, desde `feature/PROJECT-X-town` |
| **Depende de** | F5. Ya **no** depende de F2: el guardado va el último y guarda el almacén entonces. |
| **Issue / milestone** | `phase:F6` · milestone `F6 Storehouse` |
| **Referencia iOS** | merge `020d442` (`[PROJECT-F6]: Merge the storehouse and the carried load`), commits `a19b855` (carga y almacén), `ea9ceb2` (entregar), `8b90e60` (arte), `7546d3f` (campamento en el nivel), `fc443ff` (HUD) |

## Objetivo

El bucle de *Age of Empires*: recoger, llevarlo al almacén y volver. Así importa dónde se coloca cada edificio.

## Decisiones ya tomadas

**Carga y almacén:**
- `PlayerEntity.inventory` es la **carga**, con sus herramientas.
- La carga admite `Rules.carryCapacity = 10`, sumando madera y piedra. Qué ocupa carga lo dice una regla del recurso (`ResourceRules.takesCargo`): madera y piedra sí, oro y maná no. Las herramientas no ocupan.
- **Lo que no cabe se pierde.** `TreeFelledEventEntity.wood` y `RockBrokenEventEntity.stone` llevan lo que **entra** (lo que dicen el aviso y el "+N"). El árbol o la roca que llenan la carga avisan con `forest.message.carryFull` después del "+N".
- Con la carga llena, talar y picar se rechazan (`carryFull` en `ChopResult` y `MineResult`, comprobado después de `unknown…` y `no…`).
- El **almacén de la aldea** es `WorldState.stock` (un `InventoryEntity` que solo usa recursos), expuesto por `World.stock`.
- `World.funds` / `earn` / `spend` pasan a usarlo: se conservan los dos nombres, y `funds` es lo que se puede gastar.
- Edificios, equipo y habilidades se pagan del almacén con **una sola regla de pago**, la misma en `Construction.place` y en `World.spend`.
- El oro y el maná de la arena entran directamente en el almacén. `HeroUseCase`/`StartFightUseCase` no cambian y el equilibrio de la arena no se mueve.
- `GetBuildOptionsUseCase` calcula lo que falta contra el almacén.
- El almacén se lee con un caso de uso nuevo (`GetStockUseCase`). `GetPlayerStatusUseCase` sigue dando el inventario del jugador, que ahora es la carga.

**Edificios nuevos** (al final de `BlueprintId`):
- `storehouse` (*Almacén*): 20 de madera, 8 golpes, radio 40, punto de entrega. Segundo en el menú.
- `camp` (*Campamento*): no construible, sin coste, radio 30, punto de entrega.
  - No sale en el menú: `BlueprintEntity` gana `isBuildable` y `GetBuildOptionsUseCase` solo ofrece los construibles.
  - `canPlace` da `false` para él, y construirlo da el rechazo `blocked` de siempre.
- Hasta F7, "punto de entrega" es un booleano del plano (F7 lo cambia por qué recursos acepta).

**Entregar:**
- `DepositIntentEntity(buildingId)` + sistema `Depositing` (`domain/world/depositing.dart`, pieza interna), como `Construction`: el jugador se pone delante y, a los 400 ms (`Rules.depositIntervalMs`), pasa **toda** la carga al almacén.
- `DepositResult { ok, unknownBuilding, notADropOff, emptyLoad }` (core) + `DepositUseCase` + `World.orderDeposit`. Se comprueba: edificio desconocido → no recibe (obra a medias o casa) → carga vacía.
- Al tocar un edificio, primero se intenta entregar:
  - `notADropOff` sigue con `ResumeConstructionUseCase` como hoy (una obra de almacén se reanuda);
  - `emptyLoad` avisa "No llevas nada que guardar.";
  - `ok` avisa al terminar con "Guardado en el almacén: 7 de madera".
- Sin efecto en la escena.

**El campamento en el nivel:**
- `LevelDBO.buildings: List<BuildingDBO>?` (`id`, `blueprint`, `position`) con el campamento (`id`/`blueprint` `camp`) en (700, 592), 100 a la izquierda del inicio.
- Llega **terminado**. Un `blueprint` desconocido es un error de nivel inválido.
- Se quita la decoración a menos de 64 de él, sin volver a tirar.
- `BuildingComponent` puede nacer terminado: completo, sin barra de obra ni rebote. Lo necesitará también F2.

**Misiones:** `gatherWood` pasa a medir el almacén y su texto a "Lleva 15 de madera al almacén". `gatherFortyWood` (F4) ya medía `funds` y su texto pasa a "Ten 40 de madera en el almacén".

**Dibujo y arte** (sin autores nuevos; `build_cottage()` del script):
- `storehouse`: la pared ocre de postes, el techo de paja sin recolorear y dos cajas cerradas del *LPC Tile Atlas* junto a la puerta (120 × 191). `buildingFrontOffset` 24.
- `camp`: el tocón de siempre delante de tres troncos hechos con un tramo de tronco del atlas tumbado (106 × 41). `buildingFrontOffset` 12.

**HUD:**
- La barra pasa a ser "Almacén" (el rótulo, solo con nombres) + los cuatro recursos del almacén + una raya + "Carga 7/10" + las herramientas.
- "Carga 7/10" va en color de aviso si está llena, y no se desglosa por recurso.
- Modelos: `HudData.stock: List<ResourceItemData>` y `HudData.carry: CarryItemData(text, isFull)`.
- Se vuelven a medir los dos umbrales (en iOS, 1500 y 1000 pt).

**Textos:**
- Edificios y rótulos: `forest.blueprint.camp` "Campamento", `forest.blueprint.storehouse` "Almacén", `forest.hud.carry` "Carga {amount}/{capacity}", `forest.hud.stock` "Almacén".
- `forest.message.carryFull`: "Llevas la carga llena. Déjala en el campamento o en un almacén."
- `forest.message.deposited`: "Guardado en el almacén: {amounts}"
- `forest.message.nothingToDeposit`: "No llevas nada que guardar."

**Navegación:** sin cambios (línea recta). Desde lejos, el camino al campamento puede quedar cortado ("Hay algo en medio").

**Guardado:** en F2 (almacén, carga y edificios con el campamento).

## Ficheros previstos

- **Dominio:**
  - `rules/rules.dart`, `rules/blueprints.dart`;
  - `world/world.dart`, `world_state.dart`, `depositing.dart` (nuevo), `construction.dart`, `woodcutting.dart`, `mining.dart`, `work.dart`;
  - `extensions/inventory_rules.dart`, `extensions/resource_rules.dart` (nuevo);
  - `entities/building/blueprint_entity.dart`, `entities/player/intent_entity.dart`;
  - casos de uso `deposit_use_case.dart` y `get_stock_use_case.dart` (nuevos), y `get_build_options_use_case.dart`;
  - `quests/quests.dart`.
- **Core:** `blueprint_id.dart`, `chop_result.dart`, `mine_result.dart`, `deposit_result.dart` (nuevo), `es.json`, `internationalize.dart`.
- **Datos:** `dbo/building_dbo.dart` (nuevo), `dbo/level_dbo.dart`, `mappers/building_mapper_dbo.dart` (nuevo), `level_local_datasource_impl.dart`, `level_repository_impl.dart`.
- **Presentación:** `bloc/*`, `models/hud_data.dart`, `models/carry_item_data.dart` (nuevo), `widgets/hud_overlay.dart`, `widgets/resource_bar.dart`, `game/components/building_component.dart` (nace terminado), `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`.
- **Arte:** `build_assets.py`, `forest.{png,json}`, `CREDITS.md`.
- **Tests:** `architecture_test.dart` (pieza nueva) y `world_funds_test.dart`, que ahora compara con `world.stock`.

## Cómo probarlo

- Junto al inicio, a la izquierda, está el campamento.
- Al talar, la carga sube y el almacén no. Con 10, el siguiente árbol da "+1" y avisa, y tocar otro árbol también avisa.
- Tocar el campamento entrega: la carga vuelve a 0 y el almacén sube. Tocarlo vacío avisa.
- *Lleva 15 de madera al almacén* se cumple al segundo viaje.
- El Almacén (20 de madera) es el segundo del menú. Terminado recibe la carga; a medio hacer se sigue construyendo al tocarlo.
- El oro de la arena aparece en el almacén.
- Tests:
  - **`world_deposit_test.dart`:**
    - capacidad, pérdida de lo que no cabe y `carryFull`;
    - entregar en el campamento y en un almacén terminado;
    - `notADropOff`, `emptyLoad` y `unknownBuilding`;
    - el oro y el maná no ocupan carga.
  - **`world_funds_test.dart`:** pagos y cobros sobre el almacén.
  - **`get_build_options_use_case_test.dart`:** sin el campamento, y con lo que falta medido en el almacén.
  - **Nivel:**
    - el datasource da el campamento y quita la decoración cercana;
    - `building_mapper_dbo_test.dart` rechaza un blueprint desconocido.
  - **Presentación:**
    - `forest_bloc_test.dart`: tocar un edificio entrega o reanuda; los avisos; `HudData.stock` y `carry`;
    - `building_component_test.dart`: el campamento nace terminado sin barra;
    - `resource_bar_test.dart` y los umbrales.
  - `lpc_atlas_test.dart` e `internationalize_test.dart`.
