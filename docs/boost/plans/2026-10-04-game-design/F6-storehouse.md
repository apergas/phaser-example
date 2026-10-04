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
- `Player.inventory` es **la carga**. Admite como máximo `Rules.CARRY_CAPACITY = 10` unidades, sumando todos los recursos.
- `WorldState.stock: Map<Resource, Int>` es el **almacén de la aldea**.
- Las construcciones se pagan **del stock**: `Construction.place` deja de usar `player.inventory.spend` y usa el stock.

**Carga llena:**
- Si al caer un árbol no cabe toda la madera, se guarda lo que cabe y el resto se pierde. La alternativa es dejar un montón en el suelo; se propone perderlo porque es más simple. Se decide en el plan y se apunta.
- Con la carga llena, el jugador no empieza a talar y se muestra el mensaje `CARRY_FULL`.

**Entregar:**
- Nuevo `Intent.Deposit(buildingId)` con `Depositing : Work`: un único "golpe" que pasa toda la carga al stock.
- Al hacer clic en un almacén terminado, el jugador va hasta él y entrega.

**Edificios:**
- **Campamento inicial** (`BlueprintId.Camp`, no construible): ya viene colocado en el nivel junto al spawn y es el primer punto de entrega. Así no hace falta un almacén para poder construir el almacén.
- **Almacén** (`BlueprintId.Storehouse`): cuesta 20 de madera y sirve de punto de entrega más cercano.

**HUD:**
- "Carga 7/10" junto a los recursos.
- El stock de la aldea se muestra como lista de recursos.
- `HudState` gana `carry: CarryItem(text, isFull)`.

**Arte:**
- Almacén: se monta en `build_assets.py` con piezas de `cottage.png` y `thatched-roof.png`, cambiando proporción o color con `recolour`.
- Campamento: con piezas existentes, por ejemplo un tocón y un montón de troncos de `terrain_atlas`.
- Los frames se llaman `storehouse` y `camp`. Su desplazamiento de dibujo va en `SpriteNames.buildingFrontOffset`.

**Misiones:** `GatherWood` pasa a medir el stock, no la carga. Hay que revisar `Quests.all`.

**Persistencia:** se guardan el stock y la carga.

## Ficheros previstos

**`shared`:**
- Dominio:
  - `Rules.kt`
  - `WorldState.kt`
  - `World.kt`
  - `world/Depositing.kt` (nuevo)
  - `Construction.kt`
  - `Woodcutting.kt`
  - `Work.kt`
- Edificios: `BlueprintId.kt` y `Blueprint.kt` (`isBuildable`).
- Nivel: `data/.../level/*` (el campamento en el nivel).
- Presentación: `presentation/forest/*` y `jsMain/web/*`.

**Arte:** `build_assets.py`.

**Apps:**
- Clic sobre un edificio. Hoy sólo se distinguen los árboles.
- Línea de carga en el HUD.

## Cómo probarlo

- Talar hasta llenar la carga (10): aparece el aviso.
- Clic en el campamento: el jugador va y entrega. La carga baja a 0 y el stock sube.
- Construir una casa descuenta del stock.
- Construir un almacén lejos y entregar allí.
