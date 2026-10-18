# Progreso del desarrollo

> Planes: [héroe y arena](2026-10-06-hero-arena/README.md) · [aldea](2026-10-04-game-design/README.md) · [arreglos y mejoras](2026-10-17-extras/README.md). Última actualización: 2026-10-18.

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
| [C9 Maná](2026-10-06-hero-arena/C9-mana.md) | ✅ | `develop` (#64) | Maná en los niveles 6–10 y en las habilidades. Tests hasta TC9.3 (666); TC9.4 en T1. |
| [C10 Pelea sin saltar](2026-10-06-hero-arena/C10-no-skip.md) | ✅ | `develop` (#65) | Sin *Saltar* durante la repetición. Tests en T1. |
| [C11 Habilidades de los enemigos](2026-10-06-hero-arena/C11-enemy-skills.md) | ✅ | `develop` (#66) | Probabilidades 1,5–3,5 % en los niveles 6–10. Tests en T1. |
| [C12 Niveles de habilidad](2026-10-06-hero-arena/C12-skill-levels.md) | ✅ | `develop` (#68) | Tres niveles por habilidad (×1,5 y ×2,25). Tests en T1. |
| [C13 Armadura visible del héroe](2026-10-06-hero-arena/C13-hero-armour.md) | ✅ | `develop` (#69) | Juegos precompuestos arma × armadura (cuero, malla, placas con yelmo). Tests en T1. |

## Aldea

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| F0 Generalizar recursos, herramientas y edificios | ✅ | `develop` (#6) | Incluye el arreglo de las líneas del suelo. |
| [F1 Árboles con personalidad](2026-10-04-game-design/F1-tree-kinds.md) | ✅ | `develop` (#72) | Bloque 1. Tests en T1. |
| [F3 Rebrote de árboles](2026-10-04-game-design/F3-regrowth.md) | ✅ | `develop` (#73) | Bloque 1. Tests en T1. |
| [F4 Misiones, capítulo 1](2026-10-04-game-design/F4-quests-chapter-1.md) | ✅ | `develop` (#74) | Bloque 1. Tests en T1. |
| [F5 Piedra y pico](2026-10-04-game-design/F5-stone.md) | ✅ | `develop` (#76) | Bloque 2. Tests en T1. |
| [F6 Almacén y capacidad de carga](2026-10-04-game-design/F6-storehouse.md) | ✅ | `develop` (#77) | Bloque 2. Tests en T1. |
| [F7 Cantera](2026-10-04-game-design/F7-quarry.md) | ✅ | `develop` (#78) | Bloque 2. Tests en T1. |
| [F8 Taller y mejoras de herramientas](2026-10-04-game-design/F8-workshop.md) | ✅ | `develop` (#79) | Bloque 2. Tests en T1. |
| [F2 Guardado de la partida](2026-10-04-game-design/F2-autosave.md) | ✅ | `develop` (#81) | Bloque 3. Tests en T1. |
| F9–F15 Comida, aldeanos, granja, estaciones, eras, mercader | 💭 en espera | — | Se hablan con el usuario antes de planificarlas. |

## Arreglos y mejoras

| Arreglo o mejora | Estado | Dónde está |
|---|---|---|
| [Rayas negras en el suelo de la arena](2026-10-17-extras/arena-ground-seams.md) | ✅ | `develop` (#61) |
| [Empezar con el hacha en la mano](2026-10-17-extras/start-with-axe.md) | ✅ | `develop` (#71) |
| [T1 Tests](2026-10-17-extras/T1-tests.md) | ✅ | `develop` (1206 tests, 260 en Chrome) |
| [Recursos directos al almacén, sin carga, almacén ni cantera](2026-10-17-extras/auto-stock.md) | ✅ | `develop` (1179 tests, 276 en Chrome) |
| [Botones del HUD en el móvil](2026-10-17-extras/compact-hud-buttons.md) | ✅ | `develop` |

## Siguiente paso

| Orden | Qué | Rama |
|---|---|---|
| ✅ | Arena C9–C13; prueba manual del bloque en Chrome y Android 16 (iOS sin probar; los niveles 6–10 y las mejoras sin jugar a mano) y unión a `develop` | `feature/PROJECT-X-arena` → `develop` |
| ✅ | Aldea: empezar con el hacha, F1, F3, F4 (bloque 1), F5–F8 (bloque 2) y F2 (bloque 3), unidos a `develop` | `feature/PROJECT-X-town` → `develop` |
| ✅ | Prueba manual del bloque de la aldea en Chrome (tala, carga y entrega en el campamento, autoguardado al recargar, *Partida* ▸ *Guardar* / *Nueva partida*) y arranque en Android 16; iOS sin probar | — |
| ✅ | T1 Tests | `feature/PROJECT-T1-tests` → `develop` |
| ✅ | Recursos directos al almacén | `feature/PROJECT-X-auto-stock` → `develop` |
| ✅ | Botones del HUD en el móvil | `feature/PROJECT-X-compact-hud-buttons` → `develop` |
