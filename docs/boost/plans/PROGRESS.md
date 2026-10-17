# Progreso del desarrollo

> Resumen de las dos hojas de ruta. El detalle de cada fase está en su plan o ficha:
> - Héroe y arena: [`2026-10-06-hero-arena/`](2026-10-06-hero-arena/README.md) (incluye la [alineación con iOS](2026-10-06-hero-arena/X-ios-alignment.md)).
> - Aldea: [`2026-10-04-game-design/`](2026-10-04-game-design/README.md).
>
> Última actualización: 2026-10-17. Se actualiza al terminar cada tarea (`/cerrar-tarea`) y al pasar un plan de ficha a detallado, con un commit en la misma rama de la tarea. Cada rama de integración lleva su copia al día; `develop` la recibe cuando entra la rama.

**Leyenda:**
- ✅ terminada.
- 🔨 en curso.
- 🟢 plan detallado, lista para implementar.
- 📝 ficha: hay que detallar el plan (`boost:writing-plans`) al empezar.
- 💭 esbozo: se replanifica más adelante.

## Contexto: la versión iOS (2026-10-12 → 2026-10-17)

El juego se migró a SwiftUI + SpriteKit en `/Users/axelperezgaspar/farming-ios` (en los planes, `$IOS`), a partir de este repositorio en `feature/PROJECT-X-arena` @ `a3af0e0` (C8). Allí se portó todo (M0–M7) y se siguió desarrollando. **Desde el 2026-10-17 el desarrollo vuelve aquí**: la idea es que el juego Flutter quede igual que el de iOS y seguir desde Flutter. El repositorio iOS queda como referencia (planes detallados, goldens y tablas de equilibrado); no se escribe en él.

| | Flutter (este repo) | iOS (`$IOS`, `develop` @ `ad3be22` + `feature/PROJECT-F8-workshop` @ `0234537`) |
|---|---|---|
| Base (bosque, construcción, héroe, arena C0–C8) | ✅ | ✅ portada (M0–M7) |
| Reanudar una obra a medias | ✅ `a16317c`, en `feature/PROJECT-X-arena` (#54) | ✅ (D18), con la guarda de no reiniciar la obra en curso |
| Nombre *Farming*, icono del roble, textos táctiles | — ([X](2026-10-06-hero-arena/X-ios-alignment.md)) | ✅ |
| C9 Maná | — | ✅ |
| C10 Pelea sin saltar | — | ✅ |
| C11 Habilidades de los enemigos | — | ✅ |
| C12 Niveles de habilidad | — | ✅ |
| F1 Árboles con personalidad | 🟢 plan | ✅ |
| F3 Rebrote | — | ✅ |
| F4 Misiones, capítulo 1 | — | ✅ |
| F5 Piedra y pico | — | ✅ |
| F6 Almacén y carga | — | ✅ |
| F7 Cantera | — | ✅ |
| F8 Taller y mejoras | — | 🔨 tarea 1 de 6 |
| F2 Guardado | — | 📝 ficha |
| Tests | En cada fase (TDD, regla de `CLAUDE.md`) | Ninguno todavía (los dejó para una fase T1) |

Lo que **no** se trae de iOS: lo propio de Swift/SpriteKit (cambio de eje Y, aislamiento de actores, símbolos del String Catalog, profundidades de `Float`, `Router`/`Navigator`) y la eliminación de la web (D17): Flutter sigue publicando en GitHub Pages, con ratón, Esc y clic derecho.

## Ramas

| Rama | Contenido | Destino |
|---|---|---|
| `main` | Lo publicado en GitHub Pages. | — |
| `develop` | Lo integrado (hoy, C0–C7, #53) y todos los planes. | `main`, cuando lo decida el usuario |
| `feature/PROJECT-X-arena` | Integración de la arena: C8 y el arreglo de las obras (#54). Recibe la alineación X y C9–C12. | `develop`, una vez, al terminar C12 |
| `feature/PROJECT-X-town` | Integración de la aldea (hoy en `d7cb944`, por detrás de `develop`). Antes de F1, `git merge develop` (con la arena dentro). | `develop`, por bloques |
| `feature/PROJECT-X-ios-alignment` | Estos planes y la fase X. | `feature/PROJECT-X-arena` |

**Bloques de la aldea** (cada uno pasa a `develop` cuando está completo):
- **Bloque 1:** F1, F3, F4 (árboles, rebrote y misiones del capítulo 1).
- **Bloque 2:** F5–F8 (piedra, almacén, cantera y taller).
- **Bloque 3:** F2 (guardado de todo lo anterior).
- **Después:** F9–F15, cuando se replanifiquen.

**Normas de git** (de `CLAUDE.md` y de los README; un hook las hace cumplir):
- Ramas de trabajo `feature/PROJECT-<código>-<descripción-en-inglés>` (con `-`, nunca `_`), desde su rama de integración. Las fases C salen de `feature/PROJECT-X-arena` y las F de `feature/PROJECT-X-town`; su PR va a esa rama, no a `develop`.
- Títulos de commit y de PR `[PROJECT-<código>]: <frase en inglés en imperativo>`: `[PROJECT-C9]: Add mana as an arena reward`. La frase no repite el código. `[PROJECT-X]` solo para lo que no es de una fase: la alineación X, unir ramas y tareas del repositorio.
- Nada de atribución a IA: ni `Co-Authored-By`, ni menciones a Claude o Anthropic, ni el emoji del robot. `CLAUDE.md` se añade al índice en un comando aparte del `git commit`.
- La documentación va con el código: planes, casillas, desviaciones y este fichero se actualizan en la rama de la tarea, en un commit propio.
- Siempre `git merge`, nunca `rebase`. Conflictos en `di.config.dart`, `*.mocks.dart` o el atlas: nunca a mano; se regenera.
- Antes de unir una rama, la batería de cierre (el CI solo corre en `main`):
  - `build_runner` + `git diff --exit-code`;
  - `flutter analyze`;
  - `flutter test`;
  - los tests en Chrome.
- Los PR hacia una rama de integración no cierran sus issues solos: se cierran y se mueven las tarjetas a mano.

## Arena

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| C0 Contrato común | ✅ | `develop` (#9) | Oro, caja del `World`, héroe y entidades de combate. |
| C1 Motor y niveles | ✅ | `develop` (#10) | Lógica sin pantalla. |
| C2 Pantalla de la arena | ✅ | `develop` (#42) | Lleva unida C3; HUD con botones bajo la barra en pantallas estrechas. |
| C3 Herrería y Armería | ✅ | `develop` (#41) | Herrería, Armería y panel *Héroe*. |
| C4 Lobos y oso | ✅ | `develop` | Lobo de Redshrike y oso de tapatilorenzo (CC-BY / OGA-BY); salto hacia el objetivo. |
| C5 Torre de magia | ✅ | `develop` | Torre de magia, catálogo `Skills`, pestaña *Habilidades*. |
| C6 Bárbaros y jefe | ✅ | `develop` (#51) | Bárbaros y jefe con capas LPC, anillo bajo el objetivo, *Campeón de la arena*. |
| C7 Misiones y equilibrado | ✅ | `develop` (#52, #53) | Daño por rangos, línea *Héroe*, equipo solo con oro, test de equilibrado. 639 tests. |
| C8 Pulido de la arena | ✅ | `feature/PROJECT-X-arena` (sin PR) | Lo de `ARENA-FIXES.md`. 649 tests. |
| Reanudar obras | ✅ | `feature/PROJECT-X-arena` (#54) | Tocar una obra a medias vuelve a martillearla sin pagar. 655 tests. |
| X Alineación con iOS | 🟢 plan listo | `feature/PROJECT-X-ios-alignment` (#55) | Nombre `Farming`, ids `com.apergas.farming`, paquete `farming`, icono, arranque `#0E150E`, textos táctiles y no reiniciar la obra en curso. |
| C9 Maná | 📝 ficha | — | Hecha en iOS (`f8f7792`). Maná en los niveles 6–10 (20/25/30/35/50) y en las habilidades (20/30/45); balance por recurso. |
| C10 Pelea sin saltar | 📝 ficha | — | Hecha en iOS (`cec553e`). Sin *Saltar* ni botón durante la repetición. |
| C11 Habilidades de los enemigos | 📝 ficha | — | Hecha en iOS (`283d176`). Probabilidades 1,5/2/2,5/3/3,5 % en los niveles 6–10; orden de tiradas fijo. |
| C12 Niveles de habilidad | 📝 ficha | — | Hecha en iOS (`c6a2107`). Tres niveles, costes ×1,5 / ×2,25, techo del 95 % en nivel 3. |

## Aldea

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| F0 Generalizar recursos, herramientas y edificios | ✅ | `develop` (#6) | Incluye el arreglo de las líneas del suelo. |
| F1 Árboles con personalidad | 🟢 plan listo | — | Hecha en iOS (`078f228`) con las mismas cifras; el plan lleva una nota con lo que cambia (rama, arena ya presente, sin `!`). |
| F3 Rebrote de árboles | 📝 ficha | — | Hecha en iOS (`80de0c2`). 60 s a brote, 180 s a árbol; mismo id; espera al jugador; construir borra el tocón. |
| F4 Misiones, capítulo 1 | 📝 ficha | — | Hecha en iOS (`3e60655`). `StatsEntity`, 5 misiones, filas plegadas "N hechas", insignia `x/16`. |
| F5 Piedra y pico | 📝 ficha | — | Hecha en iOS (`b26be1c`). 12 rocas (semilla 2026), pico en (1012, 812), piedra en los edificios del héroe. |
| F6 Almacén y capacidad de carga | 📝 ficha | — | Hecha en iOS (`020d442`). Carga de 10, campamento en el nivel, almacén que paga todo. |
| F7 Cantera | 📝 ficha | — | Hecha en iOS (`ad3be22`). Junto a una roca (< 120), solo piedra, picado a 525 ms. |
| F8 Taller y mejoras de herramientas | 📝 ficha | — | A medias en iOS (tarea 1 de 6). Hacha y pico de hierro (−40 % de golpes), botón *Taller*, misiones del capítulo 2 (`x/20`). |
| F2 Guardado de la partida | 📝 ficha | — | Va la última. `shared_preferences`, versión 1 con todo, autoguardado, menú *Partida* con *Guardar* y *Nueva partida*. |
| F9–F15 Comida, aldeanos, granja, estaciones, eras, mercader | 💭 esbozo | — | Se replanifican al terminar F2, si el equipo confirma el giro a la gestión con aldeanos (`GAME_DESIGN.md` §5). |

## Siguiente paso

1. **X** Alineación con iOS (#55), en `feature/PROJECT-X-ios-alignment` (ya creada, con estos planes y el arreglo de #54).
2. **C9 → C10 → C11 → C12**, cada una desde `feature/PROJECT-X-arena`.
3. PR de `feature/PROJECT-X-arena` a `develop`, con la prueba manual completa en web, Android e iOS.
4. `git merge develop` en `feature/PROJECT-X-town` y **F1 → F3 → F4** (bloque 1) → **F5 → F6 → F7 → F8** (bloque 2) → **F2** (bloque 3).

**Tracker de GitHub** (al día el 2026-10-17):
- Issues nuevos en *Gameplay roadmap*: X #55, C9 #56, C10 #57, C11 #58, C12 #59, con labels y milestones `phase:C9`–`phase:C12`. El campo *Phase* del proyecto llega solo hasta C7: añadir C9–C12 a mano en la web (cambiar sus opciones por la API borra los valores de las tarjetas).
- Los issues de F2–F8 llevan la ficha nueva, su referencia iOS y el *Depende de* del nuevo orden; F2 pasa a llamarse *Guardado de la partida*.
- Los enlaces apuntan a `develop`, donde llegan las fichas cuando entre la arena.
