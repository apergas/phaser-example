# F5 · Piedra y pico — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F0 |
| **Issue / milestone** | `phase:F5` · milestone `F5 Stone` |

## Objetivo

Añadir un segundo recurso. Así aparece la decisión de qué recoger primero, y se prepara la piedra para los edificios de F7 y F8.

## Decisiones ya tomadas

**Dominio:**
- `Resource.Stone`.
- `ToolKind.Pickaxe`: está en el suelo, como el hacha, a unos 300 u del spawn para obligar a explorar.
- Entidad `Rock(id, position, radius, stoneYield, hitsToBreak, hitsTaken)` en `domain/entities/rock/`. Es un obstáculo: entra en `WorldState.obstacles()`.

**Mecánica:**
- `Intent.Mine(rockId)` y `internal object Mining : Work<Intent.Mine>`.
- Una rama en `workFor()` y otra en `toPlayerActivity()` (`PlayerActivity.Mining`).
- Eventos `RockHit` y `RockBroken`.
- `MineResult { Ok, NoPickaxe, UnknownRock }` y `GameUseCase.mineRock(rockId)`.

**Nivel:**
- 10–15 rocas grandes, generadas con su **propia semilla** después de los árboles.
- No pueden cambiar las posiciones de árboles ni de la decoración: los tests dorados no se tocan.
- La decoración, que se genera después, también se separa de las rocas. Si eso la cambia, se acepta: se actualizan sus valores dorados y se apunta en las desviaciones.

**Clic:**
- `ForestIntent.MapClicked` pasa a llevar `targetId` + `targetKind` (árbol o roca), o bien un `rockId` aparte. Se decide en el plan.
- Detección por píxel, igual que en los árboles.

**Arte** (sólo LPC ya disponible):
- Roca grande: un bloque de rocas de `terrain_atlas.png`, frame `rock-large`.
- **En `asset-packs/lpc/sources/tools/` no hay pico.** Solución provisional:
  - El ítem del suelo es el sprite del hacha recoloreado en gris con `recolour()`.
  - La animación de picar reutiliza la **hoja del martillo** (`hero-hammer`) con su secuencia.
  - Se apunta como desviación. Queda abierta la opción de traer el pico LPC, que necesitaría créditos.
- Partículas: esquirlas grises, como variante de `WOOD_CHIP` / `woodChips` / `ParticleEmitters`.
- HUD: iconos CSS `hud__icon--stone` y `hud__icon--pickaxe`. Android e iOS sólo muestran el texto que llega de `shared`.

**Textos:**
- `Resource.Stone → "Piedra"`, `ToolKind.Pickaxe → "Pico"`.
- Mensajes `NEED_PICKAXE` y `PICKED_UP_PICKAXE`. El mensaje de `ItemPickedUp` pasa a depender del tipo de ítem.

**Persistencia:** se guardan las rocas y el pico.

## Ficheros previstos

**`shared`:**
- Entidades: `shared/.../domain/entities/rock/Rock.kt` (nuevo), `Resource.kt`, `ToolKind.kt`.
- Mundo: `world/Mining.kt` (nuevo), `Work.kt`, `World.kt`, `WorldState.kt`, `Navigation.kt`.
- Juego: `GameEvent.kt`, `PlayerStatus.kt`, `GameUseCase(Impl).kt`.
- Datos: `data/.../level/LevelLocalDataSourceImpl.kt`, `dto/LevelDto.kt` (`RockDto`), `LevelMappers.kt`.
- Presentación: `presentation/forest/*`, `jsMain/web/*`.

**Arte:** `asset-packs/lpc/build_assets.py` y `shared/assets/lpc/CREDITS.md`.

**Apps:**
- Web: `RockView.ts` (nuevo) y `ForestScene.ts`.
- Android: `WorldSceneState.kt`, `WorldCanvas.kt` y `Particles.kt`.
- iOS: `ForestScene.swift` y `ParticleEmitters.swift`.

## Cómo probarlo

- Clic en una roca sin pico: aparece un mensaje que pide el pico.
- Recoger el pico y picar una roca: la roca se rompe y la piedra sube en el HUD.
- La roca bloquea el paso hasta que se rompe.
- La madera y el hacha siguen funcionando igual que antes.
