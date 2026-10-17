# C10 · Pelea sin saltar — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-arena/C10-no-skip.md`).

| | |
|---|---|
| **Rama** | `feature/PROJECT-C10-no-skip`, desde `feature/PROJECT-X-arena` |
| **Depende de** | C9 (en iOS fue antes que C9; aquí el orden es numérico y no se pisan) |
| **Issue / milestone** | `phase:C10` · milestone `C10 No skip` · #57 |
| **Referencia iOS** | merge `cec553e` (`[PROJECT-C10]: Merge the fight without skip`), commit `82e7619` |

## Objetivo

La repetición de la pelea ya no se puede saltar: se ve entera, a la misma velocidad.

## Decisiones ya tomadas

Reglas del usuario (2026-10-15):
- **Sin ningún botón abajo a la derecha durante la repetición.** *Empezar pelea* desaparece mientras dura y vuelve al acabar. No se deja un botón desactivado.
- **Sin funcionalidad de salto:**
  - se borra el evento `ArenaReplaySkipped` y su manejador en `ArenaBloc`;
  - el manejador de `ArenaReplayTicked` siempre emite los efectos de cada turno nuevo, después `FightEndedEffect` y, si toca, `ChampionEffect`;
  - si `FightReplayData` tiene una variante o *factory* solo para el salto, se borra;
  - se borran la clave `arena.skip` (*Saltar*) de `es.json` y su getter de `Internationalize`.
- **Misma velocidad:** 400 ms de entrada y 800 ms por turno.
- ***Volver* sigue funcionando** durante la repetición (`ArenaClosed`): la pelea ya está resuelta y pagada antes de empezar a verla.
- La lista de niveles sigue desactivada y el panel de resultado oculto durante la repetición.
- El *snackbar* no tiene nada que tapar durante la repetición: el único aviso de la arena (`arena.message.locked`) sale de pedir pelea, que no se puede hacer mientras se repite.

## Ficheros previstos

- `features/arena/bloc/arena_event.dart`, `arena_bloc.dart`, `models/fight_replay_data.dart` (si tenía el salto).
- `features/arena/widgets/fight_button.dart`, `arena_hud.dart`, `arena_page.dart` (lo que conecte el salto).
- `es.json`, `internationalize.dart`.
- Mocks y tests que usen `ArenaReplaySkipped`.

## Cómo probarlo

- Empezar una pelea: no hay botón abajo a la derecha hasta que acaba y la pelea se ve entera.
- *Volver* a media pelea cierra la arena con el oro ya cobrado.
- Tests:
  - `arena_bloc_test.dart`: la repetición emite los efectos de todos los turnos; ya no hay evento de salto;
  - `fight_button_test.dart` / `arena_hud_test.dart`: sin botón durante la repetición y con *Empezar pelea* al acabar;
  - `internationalize_test.dart` sin `arena.skip`.
