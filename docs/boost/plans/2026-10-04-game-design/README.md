# Ampliación de la jugabilidad (`docs/GAME_DESIGN.md`): hoja de ruta

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement each phase plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Start every session with the project skill `/siguiente-tarea` and finish every task with `/cerrar-tarea`.

**Goal:** Llevar el prototipo (una madera, un hacha, una casa que no hace nada) hacia un juego de gestión pacífico tipo *Age of Empires*. Cada fase añade algo **jugable y probable por separado** en web, Android e iOS.

**Architecture:**
- Todas las reglas nuevas van en `shared` (Kotlin Multiplatform). Las tres apps sólo dibujan.
- Una mecánica de trabajo nueva se compone de una variante de `Intent`, un `Work` y una rama en `workFor()`.
- Un edificio nuevo es un `Blueprint` más su frame en el atlas.
- Las misiones son entradas de `Quests.all`.

Ver `CLAUDE.md` → *Architecture*.

**Tech Stack:**
- Kotlin Multiplatform (`commonMain`, `jsMain`) con kotlin.test.
- Web: Vite + Phaser 4 + TypeScript.
- Android: Jetpack Compose + Hilt.
- iOS: SwiftUI + SpriteKit + SKIE.
- Arte: LPC generado por `asset-packs/lpc/build_assets.py`.

## Global Constraints

Copiadas de `CLAUDE.md`. Todas las tareas las cumplen implícitamente.

**Arquitectura:**
- Dependencias `Presentation ──▶ Domain ◀── Data`. Lo vigilan `shared/src/androidHostTest/.../ArchitectureTests.kt` y `webApp/tests/architecture.test.ts`.
- Las entidades son `data class` inmutables, sin `var`. `World` es el único agregado mutable.

**Tests:**
- Comentarios `// given`, `// when`, `// then`.
- Nombres `testWhen<Action>Then<Result>`.
- Datos de prueba como `val <Entity>.Companion.mock`.
- Mocks escritos a mano, con una propiedad `error` y flags `<method>Called`.

**Idioma y textos:**
- Código, identificadores y comentarios en inglés.
- Textos para el jugador en español, **sólo** en `ForestLabels`.

**Plataformas:**
- `webApp`: tsconfig con `erasableSyntaxOnly` (ni propiedades de parámetro en constructores ni `enum`). Vite con `base: './'`.
- Versiones sólo en `gradle/libs.versions.toml`.
- `compileSdk`/`targetSdk` 36: no se pueden usar librerías AndroidX que pidan `minCompileSdk` 37.

**Arte:**
- Sólo arte LPC ya disponible en `asset-packs/lpc/sources/`.
- Cualquier pieza LPC nueva en el atlas se acredita en `shared/assets/lpc/CREDITS.md`.

**Constantes de dibujo:** las de `CLAUDE.md` (zoom 2, hojas de 64/128 px, secuencias de golpe…) son iguales en las tres apps.

**Git:**
- Commits `[PROJECT-X]: Imperative description`, o `[PROJECT-123]: …` si hay ticket.
- Ramas `feature/PROJECT-X-<descripcion>`.
- **Sin ninguna atribución a IA:** ni `Co-Authored-By` de una IA ni menciones a Claude o Anthropic. El hook de git lo rechaza.

**Cierre de fase:** una fase sólo está terminada cuando funciona en **las tres apps** y pasan:
- `./gradlew :shared:allTests`
- `./gradlew :androidApp:testDebugUnitTest`
- `xcodebuild test …`
- `npm run typecheck && npm test && npm run build`

---

## 1. Cómo retomar contexto (para la IA)

Para trabajar en una tarea **no hace falta leer el proyecto**. Lee sólo esto:

1. `CLAUDE.md`: arquitectura y comandos.
2. Este README: la sección 2 (tabla de fases) y la sección 3 (reglas de trabajo en paralelo).
3. El fichero de tu fase (`F<n>-*.md`) y, dentro de él, **sólo tu tarea**. Cada tarea lista sus *Files* e *Interfaces* (lo que consume y lo que produce).
4. Tu issue de GitHub: estado, quién la lleva y comentarios.

El **"qué y cómo"** está en estos Markdown. El **"quién y por dónde va"** está en GitHub Issues/Projects (sección 4). No se duplica el plan dentro de los issues.

## 2. Fases

**Leyenda:**
- 🟢 plan detallado listo para ejecutar.
- 📝 ficha: hay que escribir su plan detallado con `boost:writing-plans` al empezar la fase.
- 💭 esbozo: se replanifica al terminar la etapa anterior.

| Fase | Plan | Flujo | Depende de | Qué añade |
|---|---|---|---|---|
| **F0** Generalizar recursos, herramientas y edificios | 🟢 [F0-generalize.md](F0-generalize.md) | A + B | — | Inventario por `Resource`, coste por recursos, HUD de recursos genérico, sprites de edificios e ítems elegidos en `shared`. **Sin cambios de jugabilidad.** |
| **F1** Árboles con personalidad | 📝 [F1-tree-kinds.md](F1-tree-kinds.md) | A | F0 | Cada `TreeKind` da distinta madera y pide distintos golpes. Texto "+N" flotante. |
| **F2** Guardado automático | 📝 [F2-autosave.md](F2-autosave.md) | B | F0 | La partida sobrevive a cerrar la app. Botón "Nueva partida". |
| **F3** Rebrote de árboles | 📝 [F3-regrowth.md](F3-regrowth.md) | A | F1 | Tocón → brote → árbol: la madera es sostenible. |
| **F4** Misiones, capítulo 1 | 📝 [F4-quests-chapter-1.md](F4-quests-chapter-1.md) | A | F3 | `Stats` y 4–6 misiones nuevas. |
| **F5** Piedra y pico | 📝 [F5-stone.md](F5-stone.md) | A | F0 | Segundo recurso: rocas, pico y el trabajo de picar. |
| **F6** Almacén y capacidad de carga | 📝 [F6-storehouse.md](F6-storehouse.md) | B | F2 | Bucle "ir y volver": carga máxima, entregar en almacén, campamento inicial. |
| **F7** Cantera | 📝 [F7-quarry.md](F7-quarry.md) | A | F5, F6 | Primera regla de colocación (junto a roca) y entrega de piedra. |
| **F8** Taller y mejoras de herramientas | 📝 [F8-workshop.md](F8-workshop.md) | B | F5, F6 | Coste en varios recursos, hacha/pico de hierro, misiones del capítulo 2. |
| **F9** Comida y población | 💭 | — | F8 | `Resource.Food`, bayas. Cada casa da +2 de población. |
| **F10** Reclutar aldeanos | 💭 | — | F9 | `Player` pasa a ser `units`; reclutar en casa a cambio de comida. |
| **F11** Asignar trabajos | 💭 | — | F10 | El aldeano repite el ciclo: recoger → entregar → siguiente del mismo tipo. |
| **F12** Granja | 💭 | — | F11 | Cultivos de `terrain_atlas` por fases; producen comida. |
| **F13** Estaciones | 💭 | — | F12 | Árboles `orange`/`pale`/`green` según la estación; cosecha estacional. |
| **F14** Eras y monumento | 💭 | — | F13 | Campamento → Aldea → Pueblo; maravilla pacífica. |
| **F15** Mercader y pedidos | 💭 | — | F14 | Comercio y encargos con recompensa. |

### Flujos de trabajo (dos desarrolladores)

```
            ┌─ T0.2 web ─────┐
T0.1 shared ┼─ T0.3 android ─┼─ T0.5 cleanup
            └─ T0.4 iOS ─────┘
                                │
     ┌──────────────────────────┴──────────────────────────┐
Flujo A (mundo y recursos)                  Flujo B (persistencia y economía)
F1 ─▶ F3 ─▶ F4 ─▶ F5 ──────┐                F2 ─▶ F6 ──────┐
                           ├─▶ F7 (A)                     ├─▶ F8 (B)
                 F6 (B) ───┘                    F5 (A) ───┘
```

- **F0** la empieza un desarrollador con T0.1, que bloquea al resto. Las tareas T0.2–T0.4 se reparten en cuanto T0.1 está fusionada. T0.5 la hace quien termine el último.
- **Flujo A** desarrollador 1; **flujo B** desarrollador 2. Si un flujo se queda bloqueado esperando una dependencia (F7 espera a F6, F8 espera a F5), ese desarrollador escribe el plan detallado de su siguiente fase o ayuda en la otra.

## 3. Reglas de trabajo en paralelo

- **Rama por tarea:** `feature/PROJECT-X-<fase>-<tarea>`, por ejemplo `feature/PROJECT-X-f0-shared`. Sale de `develop`; PR a `develop`. Antes de abrir el PR, *rebase* sobre `develop`.
- **Expandir y luego contraer:**
  - Cuando una tarea de `shared` cambia una API que usan las apps, **añade** lo nuevo y deja lo viejo marcado `@Deprecated` para que `develop` siga compilando en las tres apps.
  - Una tarea de limpieza posterior quita lo viejo.
  - `develop` **nunca** queda roto para la otra persona.
- **Persistencia (a partir de F2):**
  - Cada fase que añade estado lo añade también al guardado y sube `SAVE_VERSION`.
  - Si una fase de un flujo se fusiona antes que F2, quien hace F2 incluye ese estado.
  - Si se fusiona después, lo añade la propia fase.
- **Ficheros calientes:** `ForestLabels.kt`, `ForestContract.kt`, `Rules.kt`, `World.kt`, `WebModels.kt`.
  - Cambios **aditivos**: se añaden entradas nuevas al final de su bloque, sin reordenar ni reformatear lo existente.
  - Las ramas de los `when` exhaustivos van en el orden de declaración del `enum`.
- **Atlas binario** `shared/assets/lpc/forest.{png,json}`:
  - Nunca se resuelve un conflicto a mano.
  - Se acepta la versión de `develop`, se ejecuta `cd asset-packs/lpc && python3 build_assets.py` y se hace commit del resultado.
  - Cada fase añade sus piezas a `build_assets.py`, que es la fuente.
- **Plan vivo:**
  - Al terminar una tarea se marcan sus checkboxes en el `F<n>-*.md`.
  - Cualquier desviación se apunta en la sección 5 de este README.
  - El estado de la tarea se lleva en GitHub, no aquí.

## 4. Tracker en GitHub

- **Repositorio:** `apergas/phaser-example`. Desde la terminal se usa `gh`, que hay que instalar y autenticar (`gh auth login`).
- **Labels:**
  - fase: `phase:F0` … `phase:F8`;
  - flujo: `stream:A`, `stream:B`;
  - plataforma: `platform:shared`, `platform:web`, `platform:android`, `platform:ios`;
  - `blocked`.
- **Milestones:** uno por fase (`F0 Generalize`, `F1 Tree kinds`, …).
- **Issues:**
  - F0 tiene uno por tarea (T0.1–T0.5).
  - F1–F8 tienen un issue por fase, que se divide en tareas cuando se escribe su plan detallado.
  - El cuerpo de cada issue lleva: enlace al plan, `Depende de: #n`, "Cómo probarlo".
- **Project** *Gameplay roadmap*:
  - columnas *Todo*, *In progress*, *Review*, *Done*;
  - campos *Stream* y *Phase*.
- **Ciclo de vida de una tarea:**
  1. `/siguiente-tarea` la asigna y la mueve a *In progress*.
  2. `/cerrar-tarea` abre el PR con `Closes #n` y la mueve a *Review*.
  3. Al fusionar, pasa a *Done*.

## 5. Desviaciones registradas

Aquí se apunta todo lo que se haga distinto de lo que dicen los planes: qué, por qué y en qué fase/tarea.

- *(vacío)*
