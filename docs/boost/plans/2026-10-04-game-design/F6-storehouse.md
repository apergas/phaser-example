# F6 · Almacén y capacidad de carga — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | B |
| **Depende de** | F2 (para guardar el stock de la aldea) |
| **Issue / milestone** | `phase:F6` · milestone `F6 Storehouse` |

## Objetivo

El bucle de Age of Empires: recoger, llevarlo al almacén y volver. Así importa dónde se coloca cada edificio.

## Decisiones ya tomadas

**Dos inventarios:**
- `PlayerEntity.inventory` es **la carga**. Admite como máximo `Rules.carryCapacity = 10` unidades, sumando todos los recursos.
- El **almacén de la aldea** es un `InventoryEntity` nuevo en `WorldState.stock` (sólo usa `resources`), expuesto por `World.stock`.
- Las construcciones se pagan **del stock**: `Construction.place` deja de usar `player.inventory.spend` y usa el stock. `GetBuildOptionsUseCase` calcula `missing` contra el stock.

**Carga llena:**
- Si al caer un árbol no cabe toda la madera, se guarda lo que cabe y el resto se pierde. La alternativa es dejar un montón en el suelo; se propone perderlo porque es más simple. Se decide en el plan y se apunta.
- Con la carga llena, el jugador no empieza a talar: `ChopResult.carryFull` y el mensaje `forest.message.carryFull`.

**Entregar:**
- Nuevo `DepositIntentEntity(buildingId)` con un sistema `Depositing implements Work<DepositIntentEntity>` (`domain/world/depositing.dart`, pieza interna): un único "golpe" que pasa toda la carga al stock.
- Al tocar un almacén terminado, el jugador va hasta él y entrega (`DepositUseCase`).

**Edificios:**
- `BlueprintEntity` gana `isBuildable`. `GetBuildOptionsUseCase` sólo ofrece los construibles.
- **Campamento inicial** (`BlueprintId.camp`, no construible): ya viene colocado en el nivel junto al spawn (`LevelDBO.buildings` o un campo propio, se decide en el plan) y es el primer punto de entrega. Así no hace falta un almacén para poder construir el almacén.
- **Almacén** (`BlueprintId.storehouse`): cuesta 20 de madera y sirve de punto de entrega más cercano.

**Clic sobre edificios:** hoy `ForestMapClicked` sólo distingue árboles (y rocas si F5 ya está). Se añade el edificio como objetivo, con detección por la caja del sprite (`AtlasSpriteComponent.boundsContain`) o por píxel; se decide en el plan.

**HUD:**
- "Carga 7/10" junto a los recursos.
- El stock de la aldea se muestra como lista de recursos, reutilizando `ResourceItemData` / `ResourceBar`.
- `HudData` gana `carry: CarryItemData(text, isFull)` (modelo nuevo en `models/`) y `stock: List<ResourceItemData>`.

**Arte:**
- Almacén: se monta en `build_assets.py` con piezas de `cottage.png` y `thatched-roof.png`, cambiando proporción o color con `recolour`.
- Campamento: con piezas existentes, por ejemplo un tocón y un montón de troncos de `terrain_atlas`.
- Los frames se llaman `storehouse` y `camp` (`SpriteNames.building`). Su desplazamiento de dibujo va en `RenderConstants.buildingFrontOffset`.

**Misiones:** `gatherWood` pasa a medir el stock, no la carga. Hay que revisar `Quests.all` (y las de F4 si ya están).

**Persistencia:** se guardan el stock y la carga.

**Si la arena ya está** (plan *Héroe y arena*):
- `World.funds` / `earn` / `spend` (C0) pasan de `player.inventory` al stock (`_state.stock`) en esta fase, y el último test de `world_funds_test.dart` compara con `world.stock`. Ni las compras del héroe ni las recompensas de la arena cambian.
- **El oro no cuenta para la carga**: `earn` lo pone directamente en el stock, y `Rules.carryCapacity` sólo suma lo que el jugador recoge en el mapa.
- `Construction.place` (sistema interno, que no puede llamar al `World`) y `World.spend` usan la misma operación de cobro sobre el stock, para que sólo haya una regla de pago.

## Ficheros previstos

**Dominio:**
- `rules/rules.dart`, `rules/blueprints.dart`
- `world/world_state.dart`, `world.dart`, `depositing.dart` (nuevo), `construction.dart`, `woodcutting.dart`, `work.dart`
- `entities/building/blueprint_entity.dart` (`isBuildable`), `entities/player/intent_entity.dart`
- Enums de core: `blueprint_id.dart`, `chop_result.dart`
- Casos de uso: `deposit_use_case.dart` (nuevo), `get_build_options_use_case.dart`, `get_player_status_use_case.dart` o uno nuevo para el stock.

**Datos:** `lib/layers/data/datasources/level/**` y `repositories/level/**` (el campamento en el nivel).

**Presentación:** `bloc/*`, `models/hud_data.dart`, `models/carry_item_data.dart` (nuevo), `widgets/hud_overlay.dart`, `widgets/resource_bar.dart` si hace falta, `game/components/building_component.dart` (toque), `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`, `Internationalize`, `es.json`.

**Arte:** `build_assets.py`.

**Tests:** `test/architecture_test.dart` (nueva pieza interna).

## Cómo probarlo

- Talar hasta llenar la carga (10): aparece el aviso.
- Tocar el campamento: el jugador va y entrega. La carga baja a 0 y el stock sube.
- Construir una casa descuenta del stock.
- Construir un almacén lejos y entregar allí.
