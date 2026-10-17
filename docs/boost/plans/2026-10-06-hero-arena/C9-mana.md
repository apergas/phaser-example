# C9 · Maná — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS**: la ficha dice qué hay que portar; el plan detallado de iOS (`$IOS/docs/plans/2026-10-12-arena/C9-mana.md`) tiene el porqué de cada cifra.

| | |
|---|---|
| **Rama** | `feature/PROJECT-C9-mana`, desde `feature/PROJECT-X-arena` |
| **Depende de** | [X · Alineación con iOS](X-ios-alignment.md) |
| **Issue / milestone** | `phase:C9` · milestone `C9 Mana` · #56 |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios`, merge `f8f7792` (`[PROJECT-C9]: Merge the mana`), commits `b509d71`…`20e83f7` |

## Objetivo

Un recurso nuevo, el **maná**, que solo se gana venciendo en la mitad difícil de la arena (de *Tres bandidos* en adelante, junto con el oro) y que, junto con el oro, paga las habilidades de la torre de magia.

## Decisiones ya tomadas

**Dominio:**
- `Resource.mana`, al final del enum (`wood, gold, mana`). Los `switch` sobre `Resource` (`Internationalize`, `CustomIcons`) ganan su caso el último.
- `ArenaLevels`: los niveles 6–10 del orden de juego dan oro **y** maná. Los niveles 1–5 siguen dando solo oro.

  | Nivel | Oro | Maná |
  |---|---|---|
  | 6 *Tres bandidos* (`banditTrio`) | 75 | 20 |
  | 7 *Bárbaro* (`barbarian`) | 90 | 25 |
  | 8 *Manada de tres lobos* (`wolfPack`) | 100 | 30 |
  | 9 *Dos bárbaros* (`barbarianPair`) | 120 | 35 |
  | 10 *Jefe bárbaro* (`barbarianChief`) | 150 | 50 |

- Repetir un nivel ganado da un tercio de **cada** recurso (`ArenaRules.rewardFor` ya trabaja por recurso): *Tres bandidos* repetido da 25 de oro + 6 de maná.
- `Skills`: oro + maná. *Golpe doble* 60 + **20**, *Esquiva* 90 + **30**, *Segundo aliento* 130 + **45**. El equipo (`Gear`) sigue costando solo oro.
- Nada más cambia en el dominio: `World.earn`/`spend`, `InventoryRules.missing`/`spend` y `LearnSkillUseCase` ya recorren los recursos. Con oro suficiente y sin maná, `LearnSkillUseCase` devuelve `notEnoughResources` y no gasta nada (todo o nada).

**Equilibrado** (comprobado en iOS con el mismo dominio y el mismo `SeededRandom`, así que en Flutter sale igual):
- `balance_test.dart` comprueba el presupuesto **por recurso**: oro como hasta ahora, y maná con la misma regla (primeras victorias de los niveles anteriores + 3 repeticiones del anterior ≥ lo que gasta el héroe esperado). Maná: 38 ≥ 20, 69 ≥ 50, 105 ≥ 50 y 143 ≥ 50. Con todo ganado una vez hay 160 de maná y las tres habilidades cuestan 95.
- Las tasas de victoria no cambian (el combate no cambia). La tabla de `docs/GAME_DESIGN.md` 3.8 gana la columna de maná.

**Presentación:**
- `ResourceBar` enseña el maná detrás del oro (lo hace sola: pinta `Resource.values`). Icono `lib/core/assets/images/icons/mana.svg`: el rombo azul de 22 × 22 de iOS (`$IOS/Farming/Assets.xcassets/Icons/mana.imageset/mana.svg`), diseño propio sin créditos.
- Recompensa entera en la arena: `es.json` `arena.reward` pasa de `+{amount} de oro` a `+{amounts}`, e `Internationalize.arenaReward(amounts:)` recibe el mapa de recursos, descarta las cantidades ≤ 0 y une con `", "` cada `forestAmount` en el orden del enum: `+10 de oro`, `+75 de oro, 20 de maná`. Lo usan la fila de cada nivel (`LevelTile`) y el panel de resultado (`ResultPanel`); nadie lee ya solo `[Resource.gold]`.
- Fichas de habilidad y equipo: sin cambios (`costText` y `missing` ya recorren los recursos: `60 de oro, 20 de maná`, `Faltan 20 de maná`). Sin iconos en las fichas.
- **Umbral del HUD:** el maná ensancha la barra. Se vuelve a medir `HudOverlay.buttonsBelowWidth` (hoy 920) con la barra de tres recursos con etiquetas y 9999 en cada cifra, manteniendo la misma holgura de 24 px de hoy. En iOS pasó de 920 a 1060 pt; en Flutter se mide con un test de widget (`tester.getSize` de `ResourceBar` + la fila de botones), no se copia la cifra. `narrowWidth` (480) no cambia.

## Ficheros previstos

- **Core:** `config/constants/enum/resource.dart`, `assets/i18n/internationalize.dart`, `es.json`, `assets/images/icons/mana.svg` (nuevo).
- **Dominio:** `rules/arena_levels.dart`, `rules/skills.dart`.
- **Presentación:** `theme/images/custom_icons.dart`, `features/forest/widgets/hud_overlay.dart` (umbral), `features/arena/bloc/arena_bloc.dart` (texto de la recompensa), `features/arena/widgets/level_tile.dart` y `result_panel.dart` si hace falta.
- **Docs:** `docs/GAME_DESIGN.md` 3.8 (tabla con maná), `CLAUDE.md` (maná en *Architecture* y en el balance).

## Cómo probarlo

- Ganar *Tres bandidos*: el resultado dice `+75 de oro, 20 de maná` y la barra suma las dos cosas; repetirlo da `+25 de oro, 6 de maná`.
- Con la torre de magia y oro pero sin maná, la habilidad dice `Faltan 20 de maná` y no se aprende.
- En un móvil en horizontal los botones del HUD no se solapan con la barra.
- Tests:
  - `balance_test.dart` por recurso (oro y maná);
  - `arena_rules_test.dart`: `rewardFor` de *Tres bandidos* la primera vez 75 + 20 y repetido 25 + 6;
  - `arena_levels_test.dart` / `skills_test.dart`: niveles 1–5 sin maná, 6–10 con maná; costes exactos de las habilidades;
  - `learn_skill_use_case_test.dart`: oro sin maná → `notEnoughResources` y nada gastado;
  - `internationalize_test.dart`: `arenaReward` con `+10 de oro`, `+75 de oro, 20 de maná` y sin cantidades 0; nombre y cantidad del maná;
  - `custom_icons_test.dart` cubre `Resource.mana`;
  - `hud_overlay_test.dart`: el umbral nuevo.
