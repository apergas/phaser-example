# T1 · Tests — ficha

> **Plan detallado: pendiente.** Al empezar, `boost:writing-plans` sobre esta ficha. Commits `[PROJECT-T1]: …`.

| | |
|---|---|
| **Rama** | `feature/PROJECT-T1-tests`, desde `develop` con todo lo anterior unido |
| **Depende de** | Todo lo demás: C9–C12, los arreglos y mejoras, F1, F3–F8 y F2. Va **la última**. |

## Objetivo

Desde el 2026-10-17 (a mitad de C9, tras TC9.3) el desarrollo sigue **sin tests**: ni se escriben tests nuevos ni se arreglan los que se rompan por un cambio. Lo decidió el usuario, igual que se hizo en la versión iOS. T1 deja la batería entera en verde al final.

## Qué hace

- **Arreglar** los tests existentes que hayan dejado de compilar o de pasar (firmas nuevas, catálogos con maná, misiones, recursos, etc.).
- **Escribir** los tests de lo que se hizo sin ellos. Cada plan o ficha implementado sin tests lleva su sección *Para T1* con lo que hay que cubrir; esta fase los recoge todos.
- Volver a medir los umbrales del HUD con el test de `hud_overlay_test.dart` (fuente Roboto) si han cambiado los recursos o los botones.
- Comprobar las cifras exactas que ya están en los planes: goldens de combate y tablas de equilibrado (`balance_test.dart`).
- Mantener las convenciones de `CLAUDE.md` (nombres `testWhen…Then…`, *given/when/then*, mocks centralizados).

## Hecho cuando

`build_runner` sin cambios, `flutter analyze` sin avisos (incluido `test/`), `flutter test` y los tests en Chrome en verde.

## Para T1 (se va rellenando)

- **C9** (TC9.1–TC9.3 sí tienen tests; TC9.4 no, y rompe la compilación de estos tests porque `arenaReward(amount:)` pasa a `arenaReward(amounts:)`). El código exacto está en la tarea TC9.4 de [C9-mana.md](../2026-10-06-hero-arena/C9-mana.md):
  - `test/mocks/domain/world/funds_mock.dart`: `barbarianChiefReward`, `barbarianChiefRepeatReward`, `thirtyGold`, `tenGoldAndZeroMana`, `sixManaBeforeTwentyFiveGold`;
  - `test/mocks/presentation/features/arena/arena_result_data_mock.dart`: `amounts:` con `FundsMock`, y renombrar a `championWithTheChiefReward` / `victoryWithTheChiefRepeatReward`;
  - `test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`: `amounts:` con `FundsMock`;
  - `test/core/assets/i18n/internationalize_test.dart`: `arenaReward` con `+75 de oro, 20 de maná`, `+10 de oro`, `+25 de oro, 6 de maná` y sin cantidades 0;
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`, `arena_page_test.dart` y `widgets/result_panel_test.dart`: los nombres nuevos y los textos con maná.
- **C10** (sin tests; rompe la compilación de estos). Detalle en la sección *Para T1* de [C10-no-skip.md](../2026-10-06-hero-arena/C10-no-skip.md):
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`: quitar `ArenaReplaySkipped` (varios tests), rehacerlos con `ArenaReplayTicked` hasta el final; test nuevo de que se emiten los efectos de todos los turnos, `FightEndedEffect` y `ChampionEffect`;
  - `test/layers/presentation/features/arena/models/fight_replay_data_test.dart`: borrar el test de `skipped()`;
  - `test/mocks/presentation/features/arena/arena_data_mock.dart`: `.skipped()` por `.advanced(durationMs)`;
  - `widgets/fight_button_test.dart` y `widgets/arena_hud_test.dart`: sin `onSkip` ni `Internationalize.arenaSkip`; sin botón durante la repetición y *Empezar pelea* al acabar;
  - `arena_page_test.dart`: quitar lo que use el salto; `internationalize_test.dart`: sin `arena.skip`.
- **C11** (sin tests; rompe la compilación de estos y puede cambiar resultados). Detalle, semillas y cifras en la sección *Para T1* de [C11-enemy-skills.md](../2026-10-06-hero-arena/C11-enemy-skills.md):
  - `test/mocks/presentation/features/arena/arena_effect_mock.dart`: `SkillUsedEffect` con `side` e `index` (héroe: `FightSide.hero, 0`) y variantes de enemigo; arregla la compilación de `arena_bloc_test.dart`;
  - revisar resultados de los tests que pelean con los niveles reales 6–10: `arena_flow_test.dart`, `start_fight_use_case_test.dart` (jefe), `arena_bloc_test.dart` (`banditTrio`, `wolfPack`, `barbarianChief`);
  - `arena_levels_test.dart`: `enemySkillChance` 0 en 1–5 y 0,015 / 0,02 / 0,025 / 0,03 / 0,035 en 6–10; `arena_level_entity_test.dart`: valor por defecto, `copyWith`, `==`, `hashCode`; mocks de nivel con probabilidad;
  - `enemy_kind_rules_test.dart` (nuevo): habilidades de cada `EnemyKind`;
  - `combat_test.dart`: goldens de los niveles 6–10 (semillas 0, 25, 1, 8 y 1), probabilidad 0 da el registro de antes, *Segundo aliento* del jefe una sola vez, `adviceFor` sin los `dodge` del héroe;
  - `balance_test.dart`: sigue en verde con las probabilidades; añadir ≥ 60 % con las semillas 0–999 (89,0/86,6, 73,0/75,1, 78,0/71,9, 79,0/74,0, 64,0/60,8 %);
  - `arena_bloc_test.dart`: `SkillUsedEffect` de enemigo (bando e índice); `arena_scene_component_test.dart`: el nombre flota sobre el enemigo.
