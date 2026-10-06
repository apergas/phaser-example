# F8 · Taller y mejoras de herramientas — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | B |
| **Depende de** | F5 (piedra) y F6 (stock) |
| **Issue / milestone** | `phase:F8` · milestone `F8 Workshop` |

## Objetivo

Dar uso a lo acumulado y una sensación clara de progreso. También comprueba que los costes con varios recursos de F0 funcionan.

## Decisiones ya tomadas

**Taller** (`BlueprintId.workshop`): 20 de madera y 10 de piedra. Es el primer coste con varios recursos.

**Mejoras:**
- Las herramientas pasan a tener nivel: `InventoryEntity.toolLevels: Map<ToolKind, int>`, donde 1 es el nivel básico.
- Nueva entidad `UpgradeEntity(id: UpgradeId, tool, level, cost)` en `domain/entities/upgrade/`, con el catálogo `Upgrades.all` en `domain/rules/upgrades.dart` (como `Blueprints`) y el enum `UpgradeId` en core:

  | Mejora | Coste | Efecto |
  |---|---|---|
  | Hacha de hierro | 15 de madera y 15 de piedra | `hitsToFell` −40 % |
  | Pico de hierro | 10 de madera y 20 de piedra | `hitsToBreak` −40 % |

- Redondeo: los golpes con mejora son `max(1, (golpes * 0.6).ceil())`. Con los pinos de F1 (3 golpes) quedan 2.
- Se compran **en un taller terminado** y se pagan del stock de F6, con `BuyUpgradeUseCase.call({required UpgradeId id})`, que devuelve el enum de core `UpgradeResult { ok, notEnoughResources, noWorkshop, alreadyOwned }`.

**UI:**
- Nuevo panel "Mejoras" en el HUD, igual que "Construir": `HudMenu.upgrades`, widgets `UpgradeMenu` + `UpgradeOptionTile` (un fichero por clase) y `HudData.upgradeItems: List<UpgradeItemData>`.
- Nuevo evento `ForestUpgradeRequested(id)` y un `UpgradePurchasedEffect` para las partículas.

**Arte:**
- Frame `workshop`, montado con piezas existentes.
- Las herramientas mejoradas se distinguen recoloreando el arma con `recolour()` en las hojas de trabajo **sólo si cabe en el plan**; si no, se apunta como desviación.

**Misiones del capítulo 2** (al cerrar la fase):
- picar 20 de piedra;
- construir una cantera;
- construir el taller;
- mejorar el hacha.

**Persistencia:** se guardan los niveles de las herramientas.

**Si la arena ya está** (plan *Héroe y arena*):
- El *Taller* (`BlueprintId.workshop`, herramientas) y la *Herrería* (`BlueprintId.forge`, armas, C3) son edificios distintos.
- `InventoryEntity.toolLevels` (herramientas) y `HeroEntity.weaponTier` / `armorTier` (equipo) son independientes: el hacha de hierro tala más rápido pero no cambia el Ataque del héroe.
- Las compras pagan con `World.spend` (C0) en lugar de llamar a `spend` sobre el stock directamente.
- Si con el botón *Mejoras* el HUD tiene cuatro botones (*Construir*, *Mejoras*, *Arena*, *Héroe*), se comprueba la barra a 640 px de ancho en horizontal. Si no cabe, *Arena* y *Héroe* se agrupan (sección 3.2 del README de la arena).

## Ficheros previstos

**Dominio:**
- `entities/player/inventory_entity.dart`, `world/extensions/inventory_rules.dart`
- `entities/upgrade/upgrade_entity.dart` (nuevo), `rules/upgrades.dart` (nuevo), `rules/blueprints.dart`
- `world/woodcutting.dart` y `world/mining.dart`: los golpes dependen del nivel de la herramienta.
- `use-cases/game/buy_upgrade_use_case.dart` (nuevo) y uno para listar las mejoras disponibles.
- `quests/quests.dart`
- Enums de core: `blueprint_id.dart`, `upgrade_id.dart` y `upgrade_result.dart` (nuevos), `quest_id.dart`, `forest/hud_menu.dart`.

**Presentación:** `bloc/*`, `models/hud_data.dart`, `models/upgrade_item_data.dart` (nuevo), `models/forest_effect.dart`, `widgets/hud_overlay.dart`, `widgets/upgrade_menu.dart` y `widgets/upgrade_option_tile.dart` (nuevos), `game/forest_scene_component.dart`, `Internationalize`, `es.json`.

**Arte:** `build_assets.py`.

## Cómo probarlo

- Construir el taller: se descuentan madera **y** piedra, y el botón muestra lo que falta de cada una ("Faltan 5 de madera, 3 de piedra").
- Comprar el hacha de hierro: el siguiente árbol necesita menos golpes.
- Sin un taller terminado, la mejora no está disponible.
- Las misiones del capítulo 2 avanzan.
