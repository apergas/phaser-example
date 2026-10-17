# C10 · Pelea sin saltar — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (arena) |
| **Rama** | `feature/PROJECT-C10-no-skip`, desde `feature/PROJECT-X-arena` con C9 unida |
| **Issue / milestone** | `phase:C10` · milestone `C10 No skip` · #57 |
| **Depende de** | C9 |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-arena/C10-no-skip.md`, merge `cec553e`, commit `82e7619` |

**Goal:** La repetición de la pelea ya no se puede saltar: se ve entera, a la misma velocidad, y no hay ningún botón abajo a la derecha mientras dura.

**Architecture:** Solo presentación y el catálogo de textos. `FightButton` no pinta nada durante la repetición; `ArenaHud` y `ArenaPage` pierden `onSkip`; `ArenaBloc` pierde `ArenaReplaySkipped` y el parámetro `playTurns` de `_emitReplay`; `FightReplayData` pierde `skipped()`; `es.json` e `Internationalize` pierden `arena.skip`. Dominio, datos, escena Flame y `ArenaData` no cambian.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, easy_localization. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario, 2026-10-17):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar son esperados y están listados en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, tras C12.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Mientras `test/` no compila no se usa `flutter analyze` a secas.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-C10]: <frase en inglés en imperativo>`.
- No se tocan `di.config.dart` ni `*.mocks.dart` (C10 no cambia DI).

## Decisiones

Las de la ficha se mantienen (reglas del usuario, 2026-10-15):

1. **Sin botón durante la repetición.** `FightButton` devuelve `SizedBox.shrink()` si `isReplaying`; no se deja un botón desactivado. Al acabar vuelve *Empezar pelea*.
2. **Sin salto:** se borran `ArenaReplaySkipped` y su manejador, `FightReplayData.skipped()` (la única variante solo para el salto), `arena.skip` y `Internationalize.arenaSkip`.
3. **`_emitReplay` siempre emite** los efectos de cada turno nuevo, luego `FightEndedEffect` y, si toca, `ChampionEffect`: el parámetro `playTurns` desaparece.
4. **Misma velocidad:** `ArenaRenderConstants.leadInMs` (400) y `turnMs` (800) no cambian.
5. ***Volver*** (`ArenaClosed`) sigue sin guarda: la pelea ya está resuelta y pagada antes de verla.
6. La lista de niveles sigue desactivada y el panel de resultado oculto durante la repetición. El snackbar no tapa nada: el único aviso de la arena (`arena.message.locked`) sale de `ArenaFightRequested`, que no se puede lanzar mientras se repite (`canFight` es `false`).

## Reparto

| Tarea | Qué |
|---|---|
| TC10.1 | Sin botón durante la repetición (`FightButton`, `ArenaHud`, `ArenaPage`) |
| TC10.2 | Quitar el salto del BLoC, del modelo y del texto |
| TC10.3 | Cierre: T1, `PROGRESS.md`, README y `CLAUDE.md` |

---

### Task TC10.1: Sin botón durante la repetición

**Files:**
- Modify: `lib/layers/presentation/features/arena/widgets/fight_button.dart`
- Modify: `lib/layers/presentation/features/arena/widgets/arena_hud.dart`
- Modify: `lib/layers/presentation/features/arena/arena_page.dart` (línea ~133)

**Interfaces:**
- Produces: `FightButton({super.key, required bool isReplaying, required bool canFight, required VoidCallback onFight})`; `ArenaHud` sin `onSkip`.

- [ ] **Step 1: `fight_button.dart`** (sustituir entero)

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../forest/widgets/hud_button.dart';

class FightButton extends StatelessWidget {
  final bool isReplaying;
  final bool canFight;
  final VoidCallback onFight;

  const FightButton({super.key, required this.isReplaying, required this.canFight, required this.onFight});

  @override
  Widget build(BuildContext context) {
    if (isReplaying) return const SizedBox.shrink();
    return HudButton(label: Internationalize.arenaFight, isActive: canFight, onPressed: canFight ? onFight : null);
  }
}
```

- [ ] **Step 2: `arena_hud.dart`**: borrar el campo `final VoidCallback onSkip;` y `required this.onSkip,` del constructor, y pasar a `FightButton` tres argumentos:

```dart
child: FightButton(isReplaying: isReplaying, canFight: canFight, onFight: onFight),
```

- [ ] **Step 3: `arena_page.dart`**: borrar la línea `onSkip: () => bloc.add(const ArenaReplaySkipped()),` del `ArenaHud`.

- [ ] **Step 4: Verificar**

```sh
dart format --line-length 120 lib/layers/presentation/features/arena/widgets/fight_button.dart lib/layers/presentation/features/arena/widgets/arena_hud.dart lib/layers/presentation/features/arena/arena_page.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 5: Commit** — `git add lib/layers/presentation/features/arena` y, aparte, `git commit -m "[PROJECT-C10]: Hide the fight button while the replay plays"`.

### Task TC10.2: Quitar el salto del BLoC, del modelo y del texto

**Files:**
- Modify: `lib/layers/presentation/features/arena/bloc/arena_event.dart`
- Modify: `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
- Modify: `lib/layers/presentation/features/arena/models/fight_replay_data.dart`
- Modify: `lib/core/assets/i18n/translations/es.json` (borrar `"skip": "Saltar",` del grupo `arena`)
- Modify: `lib/core/assets/i18n/internationalize.dart` (borrar `arenaSkip`)

**Interfaces:**
- Consumes: TC10.1 (nadie usa ya `ArenaReplaySkipped`).
- Produces: `ArenaEvent` sin `ArenaReplaySkipped`; `FightReplayData` sin `skipped()`.

- [ ] **Step 1: `arena_event.dart`**: borrar

```dart
final class ArenaReplaySkipped extends ArenaEvent {
  const ArenaReplaySkipped();
}
```

- [ ] **Step 2: `arena_bloc.dart`**: borrar la línea `ArenaReplaySkipped() => _onReplaySkipped(event, emit),` del `switch`, borrar `_onReplaySkipped` entero y reemplazar la cabecera de `_emitReplay` (hasta la lista `effects`) por

```dart
  void _emitReplay(FightReplayData previous, FightReplayData next, Emitter<ArenaState> emit) {
    final effects = <ArenaEffect>[
      for (var turn = previous.turnIndex + 1; turn <= next.turnIndex; turn++) ..._effectsFor(next, turn),
      if (next.isFinished) FightEndedEffect(isVictory: next.log.isVictory),
      if (next.isFinished && _isFirstChampionship) const ChampionEffect(),
    ];
```
El resto del método (desde `var data = …`) no cambia. `_onReplayTicked` ya llama `_emitReplay(replay, replay.advanced(event.deltaMs), emit)`.

- [ ] **Step 3: `fight_replay_data.dart`**: borrar `FightReplayData skipped() => advanced(durationMs);`.

- [ ] **Step 4: textos**: borrar `"skip": "Saltar",` de `es.json` y `static String get arenaSkip => '$_arena.skip'.tr();` de `internationalize.dart`.

- [ ] **Step 5: Verificar**

```sh
dart format --line-length 120 lib/layers/presentation/features/arena/bloc/arena_event.dart lib/layers/presentation/features/arena/bloc/arena_bloc.dart lib/layers/presentation/features/arena/models/fight_replay_data.dart lib/core/assets/i18n/internationalize.dart
flutter analyze lib
grep -rni "skip" lib
```
Esperado: `No issues found!` y `grep` sin coincidencias.

- [ ] **Step 6: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-C10]: Remove the replay skip"`.

### Task TC10.3: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-06-hero-arena/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **C10** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila C10 → `✅`, `feature/PROJECT-C10-no-skip`, nota "Sin tests (T1)"; `README.md`: icono de C10 → ✅.
- [ ] **Step 3:** `CLAUDE.md`: quitar `ArenaReplaySkipped` de los eventos de `ArenaBloc` y anotar que la repetición no se puede saltar y que `FightButton` no pinta nada mientras dura.
- [ ] **Step 4: Commit** — `git add docs/boost/plans`; `git add CLAUDE.md` (comando aparte); `git commit -m "[PROJECT-C10]: Close the no-skip phase"` (comando aparte).

## Prueba manual

Se hace una vez tras C12 (comprobación por bloque), en Chrome y Android:

1. Empezar una pelea: no hay botón abajo a la derecha hasta que acaba; la pelea se ve entera, con 400 ms de entrada y 800 ms por turno.
2. Al acabar vuelve *Empezar pelea* y aparece el panel de resultado.
3. *Volver* a media pelea cierra la arena y, en el bosque, el oro ya está cobrado.
4. Durante la repetición la lista de niveles no responde.
5. No queda ningún texto *Saltar* en ninguna pantalla.

## Para T1

Tests que dejan de compilar o fallan por C10 (no se ha tocado `test/`):

- `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`: quitar todo uso de `ArenaReplaySkipped` (líneas ~324–577, varios tests) y rehacerlos avanzando con `ArenaReplayTicked` hasta el final; test nuevo: la repetición emite los efectos de todos los turnos, luego `FightEndedEffect` y, en el primer campeonato, `ChampionEffect`.
- `test/layers/presentation/features/arena/models/fight_replay_data_test.dart`: borrar `testWhenSkippedThenItIsTheSameAsAdvancingToTheEnd` (`skipped()` ya no existe).
- `test/mocks/presentation/features/arena/arena_data_mock.dart` (línea ~38): sustituir `.skipped()` por `.advanced(<durationMs>)`.
- `test/layers/presentation/features/arena/widgets/fight_button_test.dart` y `arena_hud_test.dart`: quitar `onSkip` y el toque en `Internationalize.arenaSkip`; casos nuevos: sin ningún botón mientras `isReplaying` y con *Empezar pelea* al acabar.
- `test/layers/presentation/features/arena/arena_page_test.dart`: quitar lo que use el salto.
- `test/core/assets/i18n/internationalize_test.dart`: sin `arena.skip`.
