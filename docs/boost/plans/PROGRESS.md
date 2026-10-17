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
| Nombre *Farming*, icono del roble, textos táctiles | ✅ ([X](2026-10-06-hero-arena/X-ios-alignment.md)), en `feature/PROJECT-X-arena` (#60) | ✅ |
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
| X Alineación con iOS | ✅ | `feature/PROJECT-X-arena` (#60, issue #55) | Nombre `Farming`, ids `com.apergas.farming`, paquete `farming`, icono, arranque `#0E150E`, textos táctiles y no reiniciar la obra en curso. 658 tests. Probada en Chrome y en el emulador Android 16 (nombre, icono adaptativo, arranque verde, textos táctiles, la obra no se para); iOS sin probar. |
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

## Arreglos y mejoras pendientes

Fallos y mejoras vistos jugando que no son de ninguna fase. Cada uno va en su rama desde la rama de integración donde está el código (`bugfix/PROJECT-X-<descripción>` para un fallo, `feature/PROJECT-X-<descripción>` para una mejora), con commits `[PROJECT-X]`.

| Arreglo | Estado | Rama de destino | Notas |
|---|---|---|---|
| Rayas negras en el suelo de la arena | ✅ | `feature/PROJECT-X-arena` (`bugfix/PROJECT-X-arena-ground-seams`) | Hecho como se propone abajo: `ArenaGroundComponent` extiende `GroundComponent` y dibuja la valla encima; `arena-grass` sale del atlas. 660 tests. Comprobado en Chrome a dos tamaños de ventana. |
| Empezar con el hacha en la mano | 📝 | `feature/PROJECT-X-town` (o `arena`) | Ver abajo. Pedido el 2026-10-17. |
| El héroe lleva puesta su armadura en la arena | 💭 | `feature/PROJECT-X-arena` | Ver abajo. Hay que bajar capas LPC nuevas y decidir cómo se combinan con las armas. |

### Rayas negras en el suelo de la arena

**Qué pasa:** el suelo de la arena se ve con rayas negras horizontales entre las baldosas de hierba.

**Por qué:** `ArenaGroundComponent.render` (`features/arena/game/components/arena_ground_component.dart`) pinta la hierba como un mosaico de sprites `arena-grass` de 32 px, uno por baldosa, sacados del atlas `arena.png`. La cámara de la arena usa un zoom de cobertura entre 1 y 3 que casi nunca es entero. Con un zoom fraccionario, los bordes de cada baldosa caen entre píxeles de la pantalla: quedan huecos de un píxel donde se ve el fondo, y el muestreo también puede coger la fila vecina del atlas.

**Cómo se arregló en la aldea** (`d6e932d`, `[PROJECT-X]: Draw the ground as one repeated tile so no seams show between tiles`): `GroundComponent` dejó de pintar baldosa a baldosa. Ahora pinta **un solo rectángulo** del tamaño del mundo con un `Paint` cuyo `shader` es un `ImageShader(tile, TileMode.repeated, TileMode.repeated, identidad, filterQuality: FilterQuality.none)`, con `isAntiAlias = false`. La GPU repite la textura sin costuras a cualquier zoom. Para eso la baldosa tiene que ser una **imagen propia** (`lpc/ground.png`, que carga `LpcAssetsLoader`), no un trozo de un atlas: el shader repetiría el atlas entero.

**Arreglo** (hecho el 2026-10-17):
- La hierba de la arena es la misma que la del bosque (`ARENA_GRASS` en `build_assets.py` toma la misma celda de `terrain_atlas.png`). `ArenaAssetsLoader` carga también `lpc/ground.png`, y `ArenaAssets` la expone como `ground` (`Image`).
- `ArenaGroundComponent` pinta la hierba con un `drawRect` del tamaño del escenario y el mismo `Paint` con `ImageShader` repetido que `GroundComponent`; la valla sigue igual. Si sale limpio, se puede compartir el `Paint` entre los dos componentes.
- Si `arena-grass` ya no se usa, sale de `ArenaSpriteNames` y del atlas (`build_assets.py` regenera `arena.png`/`arena.json`). El test del atlas de la arena y `ArenaAssetsMock` cambian con él.
- **Tests:** `arena_ground_component_test.dart` comprueba que la hierba se pinta con un solo rectángulo y shader, como `ground_component_test.dart` en el bosque.
- **Prueba manual:** la arena en Chrome con la ventana a varios tamaños (zoom no entero) y en Android: sin rayas.

### Empezar con el hacha en la mano

**Qué se quiere** (pedido por el usuario el 2026-10-17): que el personaje empiece la partida con el hacha en la mano, sin tener que recogerla y sin la misión *Recoge el hacha*.

**Por qué:** recogerla no aporta nada. Además, el aviso "¡Hacha recogida! …" se pierde, porque en el mismo tick llega "Misión completada: Recoge el hacha" y lo tapa (visto en Chrome y en Android).

**Qué cambia:**
- **Nivel:** el hacha ya no está en el suelo (`LevelLocalDatasourceImpl` deja de poner el objeto del hacha) y el jugador empieza con `ToolKind.axe`. Hay que mirar dónde nace el jugador (`StartGameUseCase` / `World`).
- **Misiones:** `QuestId.pickUpAxe` sale de `Quests.all`. F2 todavía no guarda nada, así que el valor del enum también se puede quitar. Las insignias (`0/11` hoy) bajan en uno, y las fichas de F4 (`x/16`) y F8 (`x/20`) se ajustan.
- **Textos:** fuera `forest.message.welcome` ("Hay un hacha en el suelo…"), o se cambia por una bienvenida que mande a talar. Fuera también `pickedUpAxe` / `pickedUpAxeTouch` si ya nadie los usa. F5 seguirá teniendo el pico en el suelo, con su propio aviso.
- **Tests:** los escenarios y mocks que empiezan sin hacha (`ForestScenarioMock.axeNextToPlayer`, `GameScenarioMock`…), los de misiones y el test de flujo. El test de equilibrado no cambia.
- **iOS** sigue haciendo lo que Flutter hace hoy: es un cambio nuevo, no de paridad, y el repositorio iOS no se toca.

**Cuándo:** antes de F4, que añade misiones a la aldea y cuenta la insignia. Puede ir en la rama de la aldea antes de F1, o en la de la arena si se quiere ya.

### El héroe lleva puesta su armadura en la arena

**Qué se quiere:** igual que el héroe cambia de arma en la arena (hacha → espada corta → de hierro → de acero), que cambie de aspecto al comprar armadura.

**Cómo están hoy las armas:**
- `build_assets.py` compone cada juego del héroe con sus capas LPC y su arma (`ARENA_FIGHTERS`: `hero`, `hero-short-sword`, `hero-iron-sword`, `hero-steel-sword`). Cada juego tiene 17 frames: 2 de reposo, 9 de andar y 6 de golpe.
- `ArenaBloc` lee el arma equipada (`Gear.of(GearSlot.weapon, hero.weaponTier).id`) y la pasa en `FighterRenderData.weapon`.
- `ArenaSpriteNames.heroWith(GearId?)` elige el juego.
- **La armadura no llega a la vista:** `FighterRenderData` no tiene campo para ella y el héroe lleva siempre la ropa de trabajo.
- En el bosque el jugador no muestra equipo, ni arma ni armadura. Esto no cambia.

**Armaduras del catálogo** (`Gear`, `GearSlot.armor`) **y capas LPC posibles:**

| Tier | Armadura | Capas | ¿Están en el repo? |
|---|---|---|---|
| 0 | Ropa de trabajo | La camisa de manga larga de hoy (`torso_clothes_longsleeve`) | Sí |
| 1 | Armadura de cuero | `torso_armour_leather_male` (la de los bárbaros), quizá con brazales | Sí (`sources/barbarians/`) |
| 2 | Cota de malla | Torso de malla, y hombreras si las hay | No |
| 3 | Armadura de placas | Torso, hombreras y piernas de placas, y quizá yelmo | No |

- Las capas que faltan se bajan del Universal LPC Spritesheet Character Generator, en el mismo commit que ya usan los bárbaros (`58ce1aa`), carpeta `spritesheets/`. Las rutas hay que confirmarlas en el repositorio, y cada capa trae sus animaciones `idle`, `walk` y `slash`.
- Licencias esperadas: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0. Cada capa nueva se acredita en `CREDITS.md`.

**Qué hay que decidir al planificarlo:**
- **Juegos precompuestos por combinación** (`hero-<arma>-<armadura>`):
  - es el camino de hoy y no hay que tocar Flame;
  - pero son 4 × 4 = 16 juegos, 272 frames del héroe en vez de 68, y `arena.png` crece bastante.
- **Armadura como capa aparte**, dibujada encima del héroe con su arma:
  - un juego de frames por armadura, con `FighterComponent` pintando dos sprites alineados;
  - el atlas crece poco, pero el orden de capas (el arma delante o detrás del torso según el frame) lo complica.

**Piezas, en cualquiera de los dos casos:**
- `FighterRenderData.armor` (`GearId?`), que `ArenaBloc` rellena con `Gear.of(GearSlot.armor, hero.armorTier).id` en los mismos dos sitios que el arma.
- Los nombres en `ArenaSpriteNames`, el atlas regenerado y sus tests (`arena_sprite_names_test.dart`, `ArenaAssetsMock`).

**Prueba manual:** comprar cada armadura en la Armería y ver al héroe con ella en la arena, con cada arma.

## Siguiente paso

1. **C9 → C10 → C11 → C12**, cada una desde `feature/PROJECT-X-arena`.
2. PR de `feature/PROJECT-X-arena` a `develop`, con la prueba manual completa en web, Android e iOS.
3. Empezar con el hacha (ver *Arreglos y mejoras pendientes*), antes de F4.
4. `git merge develop` en `feature/PROJECT-X-town` y **F1 → F3 → F4** (bloque 1) → **F5 → F6 → F7 → F8** (bloque 2) → **F2** (bloque 3).

**Tracker de GitHub** (al día el 2026-10-17):
- Issues nuevos en *Gameplay roadmap*: X #55, C9 #56, C10 #57, C11 #58, C12 #59, con labels y milestones `phase:C9`–`phase:C12`. El campo *Phase* del proyecto llega solo hasta C7: añadir C9–C12 a mano en la web (cambiar sus opciones por la API borra los valores de las tarjetas).
- Los issues de F2–F8 llevan la ficha nueva, su referencia iOS y el *Depende de* del nuevo orden; F2 pasa a llamarse *Guardado de la partida*.
- Los enlaces apuntan a `develop`, donde llegan las fichas cuando entre la arena.
