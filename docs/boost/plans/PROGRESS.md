# Progreso del desarrollo

> Planes: [héroe y arena](2026-10-06-hero-arena/README.md) · [aldea](2026-10-04-game-design/README.md) · [arreglos y mejoras](2026-10-17-extras/README.md). Última actualización: 2026-10-17.

| Icono | Estado |
|---|---|
| ✅ | terminada |
| 🔨 | en curso |
| 🟢 | plan detallado, lista para implementar |
| 📝 | ficha: hay que detallar el plan al empezar |
| 💭 | esbozo: se replanifica más adelante |

## Arena

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| C0 Contrato común | ✅ | `develop` (#9) | Oro, caja del `World`, héroe y entidades de combate. |
| C1 Motor y niveles | ✅ | `develop` (#10) | Lógica sin pantalla. |
| C2 Pantalla de la arena | ✅ | `develop` (#42) | HUD con botones bajo la barra en pantallas estrechas. |
| C3 Herrería y Armería | ✅ | `develop` (#41) | Herrería, Armería y panel *Héroe*. |
| C4 Lobos y oso | ✅ | `develop` | Salto hacia el objetivo. |
| C5 Torre de magia | ✅ | `develop` | Catálogo `Skills`, pestaña *Habilidades*. |
| C6 Bárbaros y jefe | ✅ | `develop` (#51) | Anillo bajo el objetivo, *Campeón de la arena*. |
| C7 Misiones y equilibrado | ✅ | `develop` (#52, #53) | Daño por rangos, línea *Héroe*, test de equilibrado. 639 tests. |
| C8 Pulido de la arena | ✅ | `develop` | 649 tests. |
| Reanudar obras | ✅ | `develop` (#54) | 655 tests. |
| [X Alineación con iOS](2026-10-06-hero-arena/X-ios-alignment.md) | ✅ | `develop` (#60) | *Farming*, `com.apergas.farming`, icono, textos táctiles. 658 tests. Probada en Chrome y Android; iOS sin probar. |
| [C9 Maná](2026-10-06-hero-arena/C9-mana.md) | ✅ | `develop` (#64) | Maná en los niveles 6–10 y en las habilidades. Tests hasta TC9.3 (666); TC9.4 sin tests (ver T1). |
| [C10 Pelea sin saltar](2026-10-06-hero-arena/C10-no-skip.md) | ✅ | `develop` (#65) | Sin *Saltar* durante la repetición. Sin tests (T1). |
| [C11 Habilidades de los enemigos](2026-10-06-hero-arena/C11-enemy-skills.md) | ✅ | `develop` (#66) | Probabilidades 1,5–3,5 % en los niveles 6–10. Sin tests (T1). |
| [C12 Niveles de habilidad](2026-10-06-hero-arena/C12-skill-levels.md) | ✅ | `develop` (#68) | Tres niveles por habilidad (×1,5 y ×2,25). Sin tests (T1). |
| [C13 Armadura visible del héroe](2026-10-06-hero-arena/C13-hero-armour.md) | ✅ | `develop` (#69) | Juegos precompuestos arma × armadura (cuero, malla, placas con yelmo). Sin tests (T1). |

## Aldea

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| F0 Generalizar recursos, herramientas y edificios | ✅ | `develop` (#6) | Incluye el arreglo de las líneas del suelo. |
| [F1 Árboles con personalidad](2026-10-04-game-design/F1-tree-kinds.md) | ✅ | `feature/PROJECT-F1-tree-kinds` | Bloque 1. Sin tests (T1). |
| [F3 Rebrote de árboles](2026-10-04-game-design/F3-regrowth.md) | ✅ | `feature/PROJECT-F3-regrowth` | Bloque 1. Sin tests (T1). |
| [F4 Misiones, capítulo 1](2026-10-04-game-design/F4-quests-chapter-1.md) | ✅ | `feature/PROJECT-F4-quests-chapter-1` | Bloque 1. Sin tests (T1). |
| [F5 Piedra y pico](2026-10-04-game-design/F5-stone.md) | ✅ | `feature/PROJECT-F5-stone` | Bloque 2. Sin tests (T1). |
| [F6 Almacén y capacidad de carga](2026-10-04-game-design/F6-storehouse.md) | ✅ | `feature/PROJECT-F6-storehouse` | Bloque 2. Sin tests (T1). |
| [F7 Cantera](2026-10-04-game-design/F7-quarry.md) | ✅ | `feature/PROJECT-F7-quarry` | Bloque 2. Sin tests (T1). |
| [F8 Taller y mejoras de herramientas](2026-10-04-game-design/F8-workshop.md) | 🟢 plan listo | `feature/PROJECT-F8-workshop` | Bloque 2. |
| [F2 Guardado de la partida](2026-10-04-game-design/F2-autosave.md) | 📝 ficha | — | Bloque 3: va la última. |
| F9–F15 Comida, aldeanos, granja, estaciones, eras, mercader | 💭 en espera | — | No se planifican hasta terminar todo, T1 incluida; se hablan entonces. |

## Arreglos y mejoras

| Arreglo o mejora | Estado | Dónde está |
|---|---|---|
| [Rayas negras en el suelo de la arena](2026-10-17-extras/arena-ground-seams.md) | ✅ | `develop` (#61) |
| [Empezar con el hacha en la mano](2026-10-17-extras/start-with-axe.md) | ✅ | `feature/PROJECT-X-start-with-axe` |
| [T1 Tests](2026-10-17-extras/T1-tests.md) | 📝 ficha | — (la última; desde TC9.4 no se escriben tests) |

## Siguiente paso

| Orden | Qué | Rama |
|---|---|---|
| ✅ | Arena C9–C13; prueba manual del bloque en Chrome y Android 16 (iOS sin probar; los niveles 6–10 y las mejoras sin jugar a mano) y unión a `develop` | `feature/PROJECT-X-arena` → `develop` |
| 1 | Empezar con el hacha (antes de F4) | desde `feature/PROJECT-X-town` |
| 2 | F1 → F3 → F4 (bloque 1) → F5 → F6 → F7 → F8 (bloque 2) → F2 (bloque 3) | desde `feature/PROJECT-X-town`, tras `git merge develop` |
| 3 | Prueba manual del bloque de la aldea (web, Android e iOS; las *Prueba manual* de F1–F8, F2 y los arreglos) | `feature/PROJECT-X-town` |
| 4 | T1 Tests | desde `develop`, con todo unido |
