# C4 · Lobos y oso — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C2 |
| **Issue / milestone** | `phase:C4` · `stream:C` · milestone `C4 Beasts` |

## Objetivo

Que la arena tenga animales entre los humanos: un lobo, una pareja de lobos, un oso y una manada. Es la fase que trae **arte nuevo**.

## Decisiones ya tomadas

**Arte (la primera tarea de la fase, antes de tocar código):**
- Buscar en OpenGameArt animales de estilo LPC (lobo y oso, vistos de lado o en 4 direcciones, con animación de ataque).
- Comprobar que la licencia es compatible (CC-BY-SA 3.0, GPL 3.0 u OGA-BY 3.0) y anotar autor, enlace y licencia.
- Copiarlos a `asset-packs/lpc/sources/creatures/` y procesarlos con `build_assets.py` hacia el atlas `arena`.
- Acreditarlos en `lib/core/assets/images/lpc/CREDITS.md`.
- **Si no hay oso compatible:** el oso es el lobo recoloreado marrón oscuro y escalado ×1,5 (`EnemyKind.bear` sigue existiendo). Se apunta como desviación.

**Dominio:**
- `EnemyKind.wolf`, `EnemyKind.bear` y `ArenaLevelId.wolf`, `wolfPair`, `bear`, `wolfPack`, siempre **al final** de sus enums.
- Se insertan en `ArenaLevels.all`, **en medio** de la lista (orientativo, C7 equilibra):

  | Después de | Nivel | Enemigos (ataque / defensa / vida) | Poder | Oro |
  |---|---|---|---|---|
  | `banditRookie` | `wolf` | wolf 5/1/22 | 30 | 15 |
  | `banditVeteran` | `wolfPair` | 2 × wolf 5/1/22 | 60 | 25 |
  | `wolfPair` | `bear` | bear 9/3/40 | 59 | 35 |
  | `barbarian` | `wolfPack` | 3 × wolf 5/1/18 | 84 | 55 |

- Una partida guardada no pierde nada: los niveles ganados siguen en `clearedLevels`, y el desbloqueo mira el nivel anterior de la lista. Un nivel nuevo que queda detrás de uno ya ganado aparece desbloqueado.
- Los tests dorados de `combat_test.dart` no cambian (el motor es el mismo). `arena_flow_test.dart` y `arena_levels_test.dart` se amplían.

**Presentación:**
- `FighterComponent` gana la animación de animal: un salto corto hacia el objetivo y vuelta, en lugar de la hoja `slash`. Se elige por `EnemyKind` en un `switch` exhaustivo.
- Frames nuevos en `ArenaSpriteNames`.
- Textos: nombres de los 4 niveles y de los 2 enemigos en `es.json`.

**Persistencia:** nada nuevo.

## Ficheros previstos

- **Arte:** `asset-packs/lpc/sources/creatures/**`, `build_assets.py`, `arena.{png,json}`, `CREDITS.md`.
- **Dominio:** enums `enemy_kind.dart`, `arena_level_id.dart`; `rules/arena_levels.dart`.
- **Presentación:** `features/arena/game/components/fighter_component.dart`, `features/arena/game/atlas/arena_sprite_names.dart`, `Internationalize`, `es.json`.

## Cómo probarlo

- Tras ganar al bandido novato, se desbloquea el lobo. La pelea muestra al lobo atacando con un salto.
- La manada de 3 lobos se ve bien colocada (la colocación de grupos es provisional hasta C6).
- Una partida guardada antes de C4 conserva sus niveles ganados.
- Tests: niveles, flujo, componente del animal con `testWithFlameGame`.
