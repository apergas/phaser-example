# Ampliación de la jugabilidad (`docs/GAME_DESIGN.md`): hoja de ruta

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement each phase plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Start every session with the project skill `/siguiente-tarea` and finish every task with `/cerrar-tarea`.

**Goal:** Llevar el prototipo (una madera, un hacha, una casa que no hace nada) hacia un juego de gestión pacífico tipo *Age of Empires*. Cada fase añade algo **jugable y probable por separado** en web, Android e iOS.

**Architecture:**
- Una sola app Flutter. Las reglas nuevas van en `lib/layers/domain/` (Dart puro, sin Flutter ni Flame); `presentation` sólo dibuja.
- Una mecánica de trabajo nueva se compone de una subclase de `IntentEntity`, un `Work` y un caso en `workFor()` (`lib/layers/domain/world/work.dart`).
- Un edificio nuevo es un `BlueprintEntity` en `Blueprints.all` (`lib/layers/domain/rules/blueprints.dart`) más su frame en el atlas.
- Las misiones son entradas de `Quests.all` (`lib/layers/domain/quests/quests.dart`).

Ver `CLAUDE.md` → *Architecture*.

**Tech Stack:**
- Flutter 3.47.6 / Dart 3.13 (Android, iOS y web desde el mismo código).
- BLoC (`flutter_bloc`), Flame + `flame_bloc` para el mundo, `get_it` + `injectable`, `easy_localization` (sólo `es.json`).
- Tests: `flutter_test`, `mockito`, `bloc_test`, `flame_test`.
- Arte: LPC generado por `asset-packs/lpc/build_assets.py` en `lib/core/assets/images/lpc/`.

## Global Constraints

Copiadas de `CLAUDE.md`. Todas las tareas las cumplen implícitamente.

**Arquitectura:**
- Dependencias `PRESENTATION -> DOMAIN <- DATA`, `CORE` usado por todas. Lo vigila `test/architecture_test.dart`: el dominio no importa Flutter, Flame, `dart:ui` ni `dart:io`; Flame sólo en `features/forest/game/` y `forest_page.dart`; nadie fuera de `domain/world/` importa sus piezas internas (`WorldState`, `Work`, los sistemas).
- Las entidades son clases `*Entity` inmutables: campos `final`, constructor `const`, `copyWith`, `==`/`hashCode` escritos a mano, sólo *getters* calculados. Sus operaciones van en `domain/world/extensions/` (E2). `World` es el único agregado mutable.
- Los enums viven en `lib/core/config/constants/enum/` (E4); los que sólo usa la pantalla, en `enum/forest/`.
- Casos de uso: una clase `@Injectable()` por acción, con `call()` **síncrono** (E3).
- Las excepciones documentadas E1–E11 de `CLAUDE.md` se mantienen. Si una fase obliga a cambiar alguna (por ejemplo F2 con el almacenamiento), la fase actualiza `CLAUDE.md` en la misma tarea.
- Sin comentarios en `lib/`. `dart format --line-length 120` sobre lo que se escribe, **nunca** sobre `di.config.dart` ni `*.mocks.dart`.
- Tras cambiar DI o mocks: `dart run build_runner build --delete-conflicting-outputs` y commit de lo generado tal cual.

**Tests:**
- Espejo de `lib/` en `test/`. Nombres `testWhen<Action>Then<Result>`. Comentarios `// given`, `// when`, `// then`.
- Mocks con `@GenerateMocks` de mockito; BLoCs con `blocTest`. Los tests de BLoC y página usan los casos de uso reales sobre `MockLevelRepository` / `MockGameSessionRepository` (E11).
- Datos de prueba como campos `static` en `test/mocks/**/<name>_mock.dart`; **nunca** entidades, view models, efectos ni DBOs declarados dentro de un test (salvo literales `PositionEntity(x:, y:)`).
- Textos de la app en los tests a través de `Internationalize`; los tests de widgets llaman a `loadSpanishTranslations` y esperan con `pumpUntil`.

**Idioma y textos:**
- Código, identificadores y comentarios en inglés.
- Textos para el jugador en español, **sólo** en `lib/core/assets/i18n/translations/es.json`, leídos con `Internationalize`.

**Plataforma y dependencias:**
- Versiones sólo en `pubspec.yaml`, con `^`; cada dependencia nueva o subida va en su propio commit.
- Android `compileSdk`/`targetSdk` 36.
- `analysis_options.yaml`: se conservan los cuatro `exclude` que añade Flutter.

**Arte:**
- Sólo arte LPC ya disponible en `asset-packs/lpc/sources/`.
- Cualquier pieza LPC nueva en el atlas se acredita en `lib/core/assets/images/lpc/CREDITS.md`.
- Los iconos del HUD son SVG propios en `lib/core/assets/images/icons/`, registrados en `CustomIcons`.

**Constantes de dibujo:** las de `CLAUDE.md` (zoom 2, hojas de 64/128 px, secuencias de golpe…), en `features/forest/game/render/render_constants.dart`.

**Git:**
- Commits `[PROJECT-X]: Imperative description`, o `[PROJECT-123]: …` si hay ticket.
- Ramas `feature/PROJECT-X-<descripcion>`.
- **Sin ninguna atribución a IA:** ni `Co-Authored-By` de una IA ni menciones a Claude o Anthropic. El hook de git lo rechaza.

**Cierre de fase:** una fase sólo está terminada cuando pasan:
- `dart run build_runner build --delete-conflicting-outputs && git diff --exit-code`
- `flutter analyze` (debe terminar en `No issues found!`)
- `flutter test`
- `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart`

y la prueba manual de la fase funciona en Chrome, en el emulador Android y en el simulador iOS.

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
| **F0** Generalizar recursos, herramientas y edificios | 🟢 [F0-generalize.md](F0-generalize.md) | A + B | — | Inventario por `Resource`, coste por recursos, HUD de recursos genérico, sprites de edificios e ítems elegidos por tipo. **Sin cambios de jugabilidad.** |
| **F1** Árboles con personalidad | 📝 [F1-tree-kinds.md](F1-tree-kinds.md) | A | F0 | Cada `TreeKind` da distinta madera y pide distintos golpes. Texto "+N" flotante. |
| **F2** Guardado automático | 📝 [F2-autosave.md](F2-autosave.md) | B | F0 | La partida sobrevive a cerrar la app. Botón "Nueva partida". |
| **F3** Rebrote de árboles | 📝 [F3-regrowth.md](F3-regrowth.md) | A | F1 | Tocón → brote → árbol: la madera es sostenible. |
| **F4** Misiones, capítulo 1 | 📝 [F4-quests-chapter-1.md](F4-quests-chapter-1.md) | A | F3 | `StatsEntity` y 5 misiones nuevas. |
| **F5** Piedra y pico | 📝 [F5-stone.md](F5-stone.md) | A | F0 | Segundo recurso: rocas, pico y el trabajo de picar. |
| **F6** Almacén y capacidad de carga | 📝 [F6-storehouse.md](F6-storehouse.md) | B | F2 | Bucle "ir y volver": carga máxima, entregar en almacén, campamento inicial. |
| **F7** Cantera | 📝 [F7-quarry.md](F7-quarry.md) | A | F5, F6 | Primera regla de colocación (junto a roca) y entrega de piedra. |
| **F8** Taller y mejoras de herramientas | 📝 [F8-workshop.md](F8-workshop.md) | B | F5, F6 | Coste en varios recursos, hacha/pico de hierro, misiones del capítulo 2. |
| **F9** Comida y población | 💭 | — | F8 | `Resource.food`, bayas. Cada casa da +2 de población. |
| **F10** Reclutar aldeanos | 💭 | — | F9 | `PlayerEntity` pasa a ser una lista de unidades; reclutar en casa a cambio de comida. |
| **F11** Asignar trabajos | 💭 | — | F10 | El aldeano repite el ciclo: recoger → entregar → siguiente del mismo tipo. |
| **F12** Granja | 💭 | — | F11 | Cultivos de `terrain_atlas` por fases; producen comida. |
| **F13** Estaciones | 💭 | — | F12 | Árboles `orange`/`pale`/`green` según la estación; cosecha estacional. |
| **F14** Eras y monumento | 💭 | — | F13 | Campamento → Aldea → Pueblo; maravilla pacífica. |
| **F15** Mercader y pedidos | 💭 | — | F14 | Comercio y encargos con recompensa. |

F9–F15 dan por hecho que el juego evoluciona hacia **gestión** (aldeanos). Es la primera pregunta abierta de `docs/GAME_DESIGN.md` (sección 5): se confirma con el equipo antes de planificar F9.

### Flujos de trabajo (dos desarrolladores)

```
T0.1 dominio ─▶ T0.2 presentación
                       │
     ┌─────────────────┴──────────────────────────────────┐
Flujo A (mundo y recursos)                  Flujo B (persistencia y economía)
F1 ─▶ F3 ─▶ F4 ─▶ F5 ──────┐                F2 ─▶ F6 ──────┐
                           ├─▶ F7 (A)                     ├─▶ F8 (B)
                 F6 (B) ───┘                    F5 (A) ───┘
```

- **F0** la hace un único desarrollador: T0.1 y T0.2 son secuenciales y tocan los mismos ficheros calientes. Mientras tanto, el otro puede escribir el plan detallado de F1 o de F2.
- **Flujo A** desarrollador 1; **flujo B** desarrollador 2. Si un flujo se queda bloqueado esperando una dependencia (F7 espera a F6, F8 espera a F5), ese desarrollador escribe el plan detallado de su siguiente fase o ayuda en la otra.

## 3. Reglas de trabajo en paralelo

- **Rama por tarea:** `feature/PROJECT-X-<fase>-<tarea>`, por ejemplo `feature/PROJECT-X-f0-domain`. Sale de `develop`; PR a `develop`. Antes de abrir el PR, *rebase* sobre `develop`.
- **Cada tarea deja `develop` en verde:** al ser una sola app, una tarea que cambia una API del dominio adapta en el mismo PR todo lo que la usa (BLoC, widgets, componentes y tests). No se dejan APIs `@Deprecated` a medias.
- **Persistencia (a partir de F2):**
  - Cada fase que añade estado lo añade también al guardado y sube `SaveDBO.currentVersion`.
  - Si una fase de un flujo se fusiona antes que F2, quien hace F2 incluye ese estado.
  - Si se fusiona después, lo añade la propia fase.
- **Ficheros calientes:** `rules.dart`, `blueprints.dart`, `world.dart`, `world_state.dart`, `work.dart`, `game_event_entity.dart`, `quests.dart`, `forest_bloc.dart`, `forest_event.dart`, `forest_effect.dart`, `hud_data.dart`, `forest_scene_component.dart`, `internationalize.dart`, `es.json` y los enums de `lib/core/config/constants/enum/`.
  - Cambios **aditivos**: se añaden entradas nuevas al final de su bloque, sin reordenar ni reformatear lo existente.
  - Los casos de los `switch` exhaustivos van en el orden de declaración del `enum` o de la jerarquía `sealed`.
- **Ficheros generados** (`lib/core/config/di/di.config.dart`, `test/**/*.mocks.dart`):
  - Nunca se resuelve un conflicto a mano: se acepta cualquiera de las dos versiones, se ejecuta `dart run build_runner build --delete-conflicting-outputs` y se hace commit del resultado.
- **Atlas binario** `lib/core/assets/images/lpc/forest.{png,json}`:
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
  - `blocked`.
- **Milestones:** uno por fase (`F0 Generalize`, `F1 Tree kinds`, …).
- **Issues:**
  - F0 tiene uno por tarea (T0.1 y T0.2).
  - F1–F8 tienen un issue por fase, que se divide en tareas cuando se escribe su plan detallado.
  - El cuerpo de cada issue lleva: enlace al plan, `Depende de: #n`, "Cómo probarlo".
- **Project** *Gameplay roadmap*:
  - columnas *Todo*, *In progress*, *Review*, *Done*;
  - campos *Stream* y *Phase*.
- **Ciclo de vida de una tarea:**
  1. `/siguiente-tarea` la asigna y la mueve a *In progress*.
  2. `/cerrar-tarea` abre el PR con `Closes #n` y la mueve a *Review*.
  3. Al fusionar, pasa a *Done*.

El tracker todavía no existe: quien empiece F0 crea labels, milestones, issues y el Project con estas reglas.

## 5. Desviaciones registradas

Aquí se apunta todo lo que se haga distinto de lo que dicen los planes: qué, por qué y en qué fase/tarea.

- **Traducción a Flutter (2026-10-05):** la hoja de ruta se escribió para el proyecto KMP + Compose + SwiftUI + Phaser y se ha reescrito tras la migración a Flutter.
  - F0 pasa de 5 tareas (dominio compartido, una por app y limpieza) a 2 secuenciales (dominio y presentación): con una sola app ya no hace falta *expandir y contraer* ni dejar API `@Deprecated`.
  - Desaparecen las etiquetas `platform:*`.
  - F2 guarda con `shared_preferences` en un único datasource, en lugar de que cada app inyecte su almacenamiento.
  - Los textos del jugador pasan de `ForestLabels` a `es.json` + `Internationalize`, y los del contrato MVI (`ForestState`/`ForestIntent`/`ForestEffect`, `HudState`) a `ForestBloc`, `ForestEvent`, `ForestEffect` y `HudData`.
