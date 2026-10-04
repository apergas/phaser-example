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

**Taller** (`BlueprintId.Workshop`): 20 de madera y 10 de piedra. Es el primer coste con varios recursos.

**Mejoras:**
- Las herramientas pasan a tener nivel: `Inventory.toolLevels: Map<ToolKind, Int>`, donde 1 es el nivel básico.
- Nueva entidad `Upgrade(id, tool, level, cost)` en `domain/entities/upgrade/`, con la lista `Upgrades.all`:

  | Mejora | Coste | Efecto |
  |---|---|---|
  | Hacha de hierro | 15 de madera y 15 de piedra | `hitsToFell` −40 % |
  | Pico de hierro | 10 de madera y 20 de piedra | `hitsToBreak` −40 % |

- Se compran **en un taller terminado** y se pagan del stock de F6, con `GameUseCase.buyUpgrade(id): UpgradeResult`. Resultados posibles: `Ok`, `NotEnoughResources`, `NoWorkshop` y `AlreadyOwned`.

**UI:**
- Nuevo panel "Mejoras" en el HUD, igual que "Construir", con un botón genérico por mejora: `HudState.upgradeItems: List<UpgradeItem>`.
- Nuevo `ForestIntent.UpgradeRequested(id)` y un `ForestEffect` para el sonido y las partículas.

**Arte:**
- Frame `workshop`, montado con piezas existentes.
- Las herramientas mejoradas se distinguen recoloreando el arma con `recolour()` en las hojas de trabajo **sólo si cabe en el plan**; si no, se apunta como desviación.

**Misiones del capítulo 2** (al cerrar la fase):
- picar 20 de piedra;
- construir una cantera;
- construir el taller;
- mejorar el hacha.

**Persistencia:** se guardan los niveles de las herramientas.

## Ficheros previstos

**Shared:**
- `Inventory.kt`
- `upgrade/*` (nuevo)
- `Woodcutting.kt` y `Mining.kt`: los golpes dependen del nivel de la herramienta.
- `GameUseCase(Impl).kt`
- `Quest.kt` y `QuestId.kt`
- `presentation/forest/*`
- `jsMain/web/*`

**Arte:** `build_assets.py`.

**Apps:** panel "Mejoras" en `Hud.ts` (web), `HudOverlay.kt` (Android) y `HudView.swift` (iOS).

## Cómo probarlo

- Construir el taller: se descuentan madera **y** piedra, y el botón muestra lo que falta de cada una.
- Comprar el hacha de hierro: el siguiente árbol necesita menos golpes.
- Sin un taller terminado, la mejora no está disponible.
- Las misiones del capítulo 2 avanzan.
