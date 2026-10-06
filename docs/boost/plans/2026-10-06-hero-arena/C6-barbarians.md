# C6 · Bárbaros y jefe — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C4 |
| **Issue / milestone** | `phase:C6` · `stream:C` · milestone `C6 Barbarians` |

## Objetivo

Cerrar la arena con un final que se note: bárbaros con aspecto propio, un jefe más grande y peleas de grupo bien compuestas. Ganar al jefe por primera vez convierte al héroe en *Campeón de la arena*.

## Decisiones ya tomadas

**Arte:**
- Bárbaro: capas LPC de la *Universal LPC Spritesheet* (ropa de pieles, barba, hacha grande o maza) con animaciones `slash` e `idle`, en `asset-packs/lpc/sources/barbarians/`. El arma con capas delante y detrás, como `axe_fg` / `axe_bg`. Acreditado en `CREDITS.md`.
- Jefe: el bárbaro con casco o cuernos y otro color, escalado ×1,25.
- Si una capa no existe con licencia compatible, se recolorea el bandido y se apunta como desviación (como en C2).

**Grupos:**
- Hasta 3 enemigos en formación fija: el primero delante, en el centro; el segundo y el tercero detrás, arriba y abajo. Profundidad por la `y` de la base, como en el bosque.
- El enemigo al que apunta el héroe se resalta con un anillo bajo los pies.
- Los caídos se quedan tumbados y atenuados, sin charcos ni restos (sólo las gotas de cada impacto, de C2).
- Las posiciones van en `arena_render_constants.dart`.

**Campeón:**
- Al ganar `barbarianChief` por primera vez, el `FightPlayedEntity` lleva `isFirstChampionship: true` (o un campo equivalente que se decide en el plan, calculado en `StartFightUseCase`).
- La arena lo muestra con un `ChampionEffect` (confeti con las partículas existentes) y un panel "¡Campeón de la arena!".
- En el HUD del bosque, el panel *Héroe* muestra una insignia (si C3 está).

**Dominio:** no hay niveles nuevos. Sólo cambian, si hace falta, las estadísticas de los bárbaros en `ArenaLevels.all`, y con ellas se actualizan los tests de flujo.

## Ficheros previstos

- **Arte:** `asset-packs/lpc/sources/barbarians/**`, `build_assets.py`, `arena.{png,json}`, `CREDITS.md`.
- **Dominio:** `entities/combat/fight_result_entity.dart`, `use-cases/arena/start_fight_use_case.dart`.
- **Presentación:** `features/arena/game/**` (formación, anillo, caídos), `features/arena/models/arena_effect.dart`, `features/arena/widgets/result_panel.dart`; `features/forest/widgets/hero_panel.dart` (insignia, si existe).
- **Core:** `Internationalize`, `es.json`.

## Cómo probarlo

- La pareja de bárbaros y el jefe con su guardia se ven bien colocados, y el objetivo se resalta.
- Ganar al jefe por primera vez muestra el panel de campeón; repetirlo, no.
- Tests: `start_fight_use_case_test.dart` (primera vez y repetición), componentes con `testWithFlameGame`.
