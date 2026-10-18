# Recursos directos al almacén — ficha

> Mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-auto-stock`, desde `develop` |
| **Estado** | Ficha |
| **Cuándo** | T1 ya está en `develop` (#84): esta mejora escribe y arregla sus tests con TDD |

**Qué se quiere** (pedido por el usuario el 2026-10-18): quitar la mecánica de llevar lo recogido al almacén. Al talar un árbol o romper una roca, la madera o la piedra se suman directamente al almacén de la aldea.

**Qué desaparece** (lo que añadió F6 y toda F7):
- **La carga:** `Rules.carryCapacity`, `InventoryRules.load` / `freeLoad` / `isLoadFull` / `cargo` / `cargoFor` / `unloading`, `ResourceRules.takesCargo`, los resultados `ChopResult.carryFull` y `MineResult.carryFull` y sus avisos.
- **La entrega:** `Depositing`, `DepositIntentEntity`, `PlayerActivity.depositing`, `World.orderDeposit`, `DepositUseCase`, `DepositResult`, `DepositedEventEntity`, `Rules.depositIntervalMs`, `BuildingRules.acceptsDeposits` y `BlueprintEntity.accepts`.
- **En el HUD:** `CarryItemData`, "Carga 7/10" y su separador en `ResourceBar`, los textos `forest.carry`, `carryFull`, `deposited` y `nothingToDeposit` (con sus variantes táctiles).
- **En `ForestBloc`:** tocar un edificio ya no intenta entregar; uno sin terminar reanuda la obra y uno terminado deja pasar el toque al movimiento, como antes de F6. El autoguardado tras una entrega desaparece (sigue el de árbol talado y roca rota).

**Qué cambia:**
- **`Woodcutting` y `Mining`:** el último golpe suma toda la madera del árbol (`treeKindStats`) o toda la piedra de la roca (`Rules.rockStoneYield`) a `WorldState.stock`, sin límite. El evento lleva esa cantidad entera y el "+N" flotante no cambia.
- **Inventario:** `InventoryEntity.resources` deja de usarse; se quita y el inventario guarda solo `tools` y `toolLevels`. `GetPlayerStatusUseCase` deja de dar la carga.
- **Almacén (`BlueprintId.storehouse`):** sin entrega ya no sirve para nada. Se quita del catálogo y del enum, con su frame del atlas, su icono SVG, sus textos y su `buildingFrontOffset` (decidido con el usuario el 2026-10-18).
- **Cantera (`BlueprintId.quarry`):** se quita del todo, como el almacén (decidido con el usuario el 2026-10-18): catálogo, enum, frame del atlas (`build_assets.py` y `forest.json`, y `CREDITS.md` si deja de usarse algo), icono SVG, textos, `buildingFrontOffset` y `SpriteNames`. Con ella se van la aceleración de la minería (`Rules.quarryMineIntervalMs`, `quarryBoostRange`, `BuildingRules.boostsMining`; `Mining` vuelve a un ritmo fijo de `Rules.mineIntervalMs`) y la regla de colocación junto a una roca (`Rules.quarryRockRange`, `NearRockPlacementRuleEntity`, `PlacementRuleRules`, `ConstructionRejection.needsNearbyRock` y su texto). Si `PlacementRuleEntity` se queda solo con `AnywherePlacementRuleEntity`, se quita la jerarquía entera y `BlueprintEntity.placementRule`.
- **Picar piedra:** una roca pasa de 8 a 7 golpes (`Rules.rockHitsToBreak` 7). Con el pico de hierro bajan a ⌈7 × 60 %⌉ = 5, igual que ahora; cada golpe tarda lo mismo que un hachazo (decidido con el usuario el 2026-10-18): `Rules.mineIntervalMs` se quita y `Mining` usa `Rules.chopIntervalMs` (750 ms), así que si cambia el ritmo de la tala cambia también el de la minería.
- **Campamento:** se queda como edificio inicial del mapa, ya sin función de entrega.
- **Misiones:** "Lleva 15 de madera al almacén" pasa a "Reúne 15 de madera"; las de 40 de madera y 20 de piedra se quedan, porque ya leen el almacén. *Construye una cantera* (`QuestId.buildQuarry`) sale de `Quests.all` y del enum: el capítulo 2 queda en reunir piedra, taller y hacha de hierro, y la línea de la aldea pasa de 11 a 10 misiones (19 → 18 en total).
- **HUD:** `ResourceBar` se estrecha, así que hay que volver a medir `HudOverlay.buttonsBelowWidth` y `narrowWidth` con Roboto. La etiqueta "Almacén" del principio de la barra se queda.
- **Guardado:** `SaveDBO.currentVersion` pasa a 2, porque el inventario ya no lleva recursos y, si sale, el almacén ya no es un `BlueprintId`. Una partida de la versión 1 se migra al cargar: lo que llevaba el jugador se suma al almacén los almacenes y canteras construidos se quitan del mapa y la misión `buildQuarry` completada se descarta (decidido con el usuario el 2026-10-18).
- **Documentación:** `CLAUDE.md` (la carga, `Depositing`, el almacén, el formato del guardado), `docs/GAME_DESIGN.md` y las fichas de F6 y F7, donde se anota que la carga, el almacén y la cantera se quitaron aquí.
- **Tests:** los de la carga, la entrega, el almacén y el HUD de T1 se quitan o se adaptan, y se añaden los de la suma directa y la migración del guardado. El test de equilibrado no cambia, porque la arena no usa la carga.
- **iOS** no se toca: es un cambio nuevo, no de paridad.

## Prueba manual

En Chrome: talar un pino suma 3 de madera al almacén al instante y una roca se rompe en 7 golpes (5 con el pico de hierro) y suma su piedra, sin límite de carga. El menú *Construir* ya no ofrece almacén ni cantera. Tocar el campamento no hace nada especial. La barra ya no muestra "Carga" y los botones caben en la misma línea en pantallas más estrechas que antes. Una partida guardada antes del cambio carga con lo que llevaba el jugador ya sumado al almacén.
