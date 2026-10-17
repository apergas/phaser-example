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
| C8 Pulido de la arena | ✅ | `feature/PROJECT-X-arena` | 649 tests. |
| Reanudar obras | ✅ | `feature/PROJECT-X-arena` (#54) | 655 tests. |
| [X Alineación con iOS](2026-10-06-hero-arena/X-ios-alignment.md) | ✅ | `feature/PROJECT-X-arena` (#60) | *Farming*, `com.apergas.farming`, icono, textos táctiles. 658 tests. Probada en Chrome y Android; iOS sin probar. |
| [C9 Maná](2026-10-06-hero-arena/C9-mana.md) | 🟢 plan listo | `feature/PROJECT-C9-mana` | Maná en los niveles 6–10 y en las habilidades. |
| [C10 Pelea sin saltar](2026-10-06-hero-arena/C10-no-skip.md) | 📝 ficha | — | Sin *Saltar* durante la repetición. |
| [C11 Habilidades de los enemigos](2026-10-06-hero-arena/C11-enemy-skills.md) | 📝 ficha | — | Probabilidades 1,5–3,5 % en los niveles 6–10. |
| [C12 Niveles de habilidad](2026-10-06-hero-arena/C12-skill-levels.md) | 📝 ficha | — | Tres niveles por habilidad. |

## Aldea

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| F0 Generalizar recursos, herramientas y edificios | ✅ | `develop` (#6) | Incluye el arreglo de las líneas del suelo. |
| [F1 Árboles con personalidad](2026-10-04-game-design/F1-tree-kinds.md) | 🟢 plan listo | — | Bloque 1. |
| [F3 Rebrote de árboles](2026-10-04-game-design/F3-regrowth.md) | 📝 ficha | — | Bloque 1. |
| [F4 Misiones, capítulo 1](2026-10-04-game-design/F4-quests-chapter-1.md) | 📝 ficha | — | Bloque 1. |
| [F5 Piedra y pico](2026-10-04-game-design/F5-stone.md) | 📝 ficha | — | Bloque 2. |
| [F6 Almacén y capacidad de carga](2026-10-04-game-design/F6-storehouse.md) | 📝 ficha | — | Bloque 2. |
| [F7 Cantera](2026-10-04-game-design/F7-quarry.md) | 📝 ficha | — | Bloque 2. |
| [F8 Taller y mejoras de herramientas](2026-10-04-game-design/F8-workshop.md) | 📝 ficha | — | Bloque 2. |
| [F2 Guardado de la partida](2026-10-04-game-design/F2-autosave.md) | 📝 ficha | — | Bloque 3: va la última. |
| F9–F15 Comida, aldeanos, granja, estaciones, eras, mercader | 💭 esbozo | — | Se replanifican al terminar F2. |

## Arreglos y mejoras

| Arreglo o mejora | Estado | Dónde está |
|---|---|---|
| [Rayas negras en el suelo de la arena](2026-10-17-extras/arena-ground-seams.md) | ✅ | `feature/PROJECT-X-arena` (#61) |
| [Empezar con el hacha en la mano](2026-10-17-extras/start-with-axe.md) | 📝 ficha | — |
| [Armadura visible en la arena](2026-10-17-extras/hero-armour.md) | 💭 esbozo | — |
| [T1 Tests](2026-10-17-extras/T1-tests.md) | 📝 ficha | — (la última; desde TC9.4 no se escriben tests) |

## Siguiente paso

| Orden | Qué | Rama |
|---|---|---|
| 1 | C9 → C10 → C11 → C12 | desde `feature/PROJECT-X-arena` |
| 2 | Unir la arena a `develop`, con prueba manual en web, Android e iOS | `feature/PROJECT-X-arena` → `develop` |
| 3 | Empezar con el hacha (antes de F4) | desde `feature/PROJECT-X-town` |
| 4 | F1 → F3 → F4 (bloque 1) → F5 → F6 → F7 → F8 (bloque 2) → F2 (bloque 3) | desde `feature/PROJECT-X-town`, tras `git merge develop` |
| 5 | T1 Tests | desde `develop`, con todo unido |
