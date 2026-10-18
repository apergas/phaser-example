# Recursos directos al almacén — ficha

> Mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-auto-stock`, desde `develop` |
| **Estado** | Ficha |
| **Cuándo** | Después de T1: con T1 cerrada vuelven los tests, así que esta mejora escribe y arregla los suyos |

**Qué se quiere** (pedido por el usuario el 2026-10-18): quitar la mecánica de llevar lo recogido al almacén. Al talar un árbol o romper una roca, la madera o la piedra se suman directamente al almacén de la aldea.

**Qué desaparece** (lo que añadió F6 y la parte de entrega de F7):
- **La carga:** `Rules.carryCapacity`, `InventoryRules.load` / `freeLoad` / `isLoadFull` / `cargo` / `cargoFor` / `unloading`, `ResourceRules.takesCargo`, los resultados `ChopResult.carryFull` y `MineResult.carryFull` y sus avisos.
- **La entrega:** `Depositing`, `DepositIntentEntity`, `PlayerActivity.depositing`, `World.orderDeposit`, `DepositUseCase`, `DepositResult`, `DepositedEventEntity`, `Rules.depositIntervalMs`, `BuildingRules.acceptsDeposits` y `BlueprintEntity.accepts`.
- **En el HUD:** `CarryItemData`, "Carga 7/10" y su separador en `ResourceBar`, los textos `forest.carry`, `carryFull`, `deposited` y `nothingToDeposit` (con sus variantes táctiles).
- **En `ForestBloc`:** tocar un edificio ya no intenta entregar; uno sin terminar reanuda la obra y uno terminado deja pasar el toque al movimiento, como antes de F6. El autoguardado tras una entrega desaparece (sigue el de árbol talado y roca rota).

**Qué cambia:**
- **`Woodcutting` y `Mining`:** el último golpe suma toda la madera del árbol (`treeKindStats`) o toda la piedra de la roca (`Rules.rockStoneYield`) a `WorldState.stock`, sin límite. El evento lleva esa cantidad entera y el "+N" flotante no cambia.
- **Inventario:** `InventoryEntity.resources` deja de usarse; se quita y el inventario guarda solo `tools` y `toolLevels`. `GetPlayerStatusUseCase` deja de dar la carga.
- **Almacén (`BlueprintId.storehouse`):** sin entrega ya no sirve para nada. Se quita del catálogo y del enum, con su frame del atlas, su icono SVG, sus textos y su `buildingFrontOffset` (decidido con el usuario el 2026-10-18).
- **Cantera:** pierde `accepts`, pero sigue acelerando la minería (`Rules.quarryMineIntervalMs`, `BuildingRules.boostsMining`) y sigue colocándose solo junto a una roca.
- **Campamento:** se queda como edificio inicial del mapa, ya sin función de entrega.
- **Misiones:** "Lleva 15 de madera al almacén" pasa a "Reúne 15 de madera"; las de 40 de madera y 20 de piedra se quedan, porque ya leen el almacén. Si el almacén sale del catálogo, ninguna misión lo pide hoy (comprobarlo al hacer el plan).
- **HUD:** `ResourceBar` se estrecha, así que hay que volver a medir `HudOverlay.buttonsBelowWidth` y `narrowWidth` con Roboto. La etiqueta "Almacén" del principio de la barra se queda.
- **Guardado:** `SaveDBO.currentVersion` pasa a 2, porque el inventario ya no lleva recursos y, si sale, el almacén ya no es un `BlueprintId`. Una partida de la versión 1 se migra al cargar: lo que llevaba el jugador se suma al almacén y los almacenes construidos se quitan del mapa (decidido con el usuario el 2026-10-18).
- **Documentación:** `CLAUDE.md` (la carga, `Depositing`, el almacén, el formato del guardado), `docs/GAME_DESIGN.md` y la ficha de F6, donde se anota que la carga se quitó aquí.
- **Tests:** los de la carga, la entrega, el almacén y el HUD de T1 se quitan o se adaptan, y se añaden los de la suma directa y la migración del guardado. El test de equilibrado no cambia, porque la arena no usa la carga.
- **iOS** no se toca: es un cambio nuevo, no de paridad.

## Prueba manual

En Chrome: talar un pino suma 3 de madera al almacén al instante y una roca suma su piedra, sin límite de carga. Tocar el campamento no hace nada especial. La barra ya no muestra "Carga" y los botones caben en la misma línea en pantallas más estrechas que antes. Una partida guardada antes del cambio carga con lo que llevaba el jugador ya sumado al almacén.
