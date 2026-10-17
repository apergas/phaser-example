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

- **C9:** TC9.4 (recompensa con varios recursos: `Internationalize.arenaReward(amounts:)` con `+10 de oro` / `+75 de oro, 20 de maná` y sin cantidades 0; `ArenaBloc` pasa el mapa entero; mocks de resultados de la arena con maná) y el resto de la sección de tests del plan de C9.
