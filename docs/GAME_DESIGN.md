# Análisis del juego y brainstorming de mecánicas

> Documento de trabajo (2026-10-04, ampliado el 2026-10-06 con el modo de combate). Resume el estado actual del
> prototipo y recoge ideas para ampliar la jugabilidad. Las ideas son propuestas, no decisiones.
>
> Planes de implementación:
> - Ciudad y recursos: [`docs/boost/plans/2026-10-04-game-design/`](boost/plans/2026-10-04-game-design/README.md) (fases F0–F15).
> - Héroe y arena: [`docs/boost/plans/2026-10-06-hero-arena/`](boost/plans/2026-10-06-hero-arena/README.md) (fases C0–C7).

## 1. La idea

Un juego de **recolección y construcción** en vista cenital 3/4, inspirado en la parte económica de *Age of Empires*:
el placer está en explorar, recoger recursos, levantar edificios y ver cómo un asentamiento crece. Ritmo tranquilo,
sesiones cortas, controles de un solo toque/clic, jugable igual en web, Android e iOS.

Junto a la aldea hay un **segundo modo, la arena** (sección 3.8): el héroe mejora su equipo y sus habilidades en
edificios de la ciudad y se enfrenta a enemigos cada vez más fuertes en peleas automáticas. La aldea sigue sin
combate: las peleas sólo ocurren en la arena, y perder no castiga. Al golpear saltan unas gotas de sangre para que se
note el impacto, sin ir más allá (nada de charcos ni restos).

Pilares que se deducen de lo ya hecho:

1. **Tocar y que pase algo**: un clic sobre un árbol lleva al personaje, que se coloca y tala solo. Nada de
   micro-gestión de animaciones o rutas.
2. **Progreso visible**: el bosque se aclara, la madera sube, la casa aparece por fases.
3. **Guía ligera**: misiones encadenadas que enseñan el bucle sin tutoriales largos.
4. **Un solo núcleo de reglas**: toda la lógica en el dominio (Dart puro, sin Flutter ni Flame); la presentación sólo dibuja.
5. **Dos modos que se necesitan**: la aldea da recursos y edificios para mejorar al héroe; la arena da oro y trofeos
   que la aldea gasta. Ninguno de los dos es obligatorio para disfrutar del otro.

## 2. Qué hay hecho

### Bucle de juego actual

```
Recoger hacha ──▶ Talar árboles (+5–6 madera) ──▶ Construir casa (15 madera) ──▶ Fin de misiones
```

| Elemento | Estado |
|---|---|
| Mapa | Bosque de 1600×1200 generado con semillas fijas (mismo mapa en todas las plataformas): 70 árboles de 14 formas, decoración de suelo (hierba, hojas, setas, rocas). |
| Personaje | Uno solo, controlado directamente. Camina (110 u/s), choca con troncos y edificios, se coloca solo junto al objetivo. |
| Recursos | Sólo **madera**. Cada árbol: 5 hachazos, 5–6 de madera. Los árboles **no vuelven a crecer** (388 de madera en todo el mapa). |
| Herramientas | Hacha (se recoge del suelo). El martillo aparece al construir pero no es un objeto del inventario. |
| Edificios | Sólo **Casa**: 15 de madera, 8 martillazos. Se coloca con previsualización válida/no válida. Una vez terminada **no hace nada**. |
| Misiones | 3, lineales y permanentes: recoger hacha, tener 15 de madera, construir una casa. Después, no hay más objetivos. |
| Presentación | HUD con madera, botón *Construir*, panel *Misiones*, mensajes, partículas al talar/construir. Barra de colocación en táctil. |
| Persistencia | Ninguna: la sesión vive en memoria y se pierde al cerrar. |

### Fortalezas técnicas que facilitan crecer

- **Añadir un trabajo es barato**: una variante de `IntentEntity` + un `Work` + una rama en `workFor()`
  (`lib/layers/domain/world/work.dart`). Talar y construir ya siguen ese patrón, así que minar, pescar o cosechar
  cuestan poco.
- **`GameEventEntity`** desacopla reglas y efectos: cada nueva mecánica emite eventos y las apps los animan.
- **Misiones declarativas** (`Quests.all`): una misión es un `id`, un objetivo y una función que mide el mundo.
- **`Blueprints`** ya modela coste, martillazos y huella: añadir edificios es casi sólo datos (y arte).
- **`TreeKind`** ya existe y el generador lo decide para cada árbol; hoy sólo cambia el sprite.
- Arte LPC disponible sin usar: árboles en variantes `brown`, `orange`, `pale`, `dead` y un `terrain_atlas` con agua y
  cascada, caminos, cultivos en varias fases de crecimiento (trigo, maíz, tomates…), rocas grandes, tocones,
  vallas, puentes de madera y muros de piedra.

### Límites actuales (lo que más frena la jugabilidad)

1. **No hay razón para seguir jugando** después de la casa: el edificio no produce nada y no hay más metas.
2. **Una sola materia prima**: no hay decisiones (¿qué recojo primero?, ¿en qué gasto?).
3. **El mapa se agota** y no cambia con el tiempo.
4. **Sin guardado**: cualquier progreso se pierde.
5. **Un solo personaje**: falta el "sentimiento AoE" de ver a tu gente trabajar sola.
6. **Un solo modo y un personaje que no crece**: todo es talar y construir; el héroe no gana nada que se note
   (ni equipo, ni habilidades, ni retos que antes no podía superar).

## 3. Brainstorming de mecánicas

Ideas agrupadas por tema. Cada una indica una **estimación de esfuerzo** (S/M/L) y cómo encajaría en la arquitectura.

### 3.1 Más recursos y recolección

- **Piedra** (S): rocas grandes en el mapa que se pican con un **pico**. Nuevo `MineIntentEntity` + un `Work` de minería,
  `Rock` como obstáculo. La roca decorativa ya existe: podría haber una versión grande y sólida.
- **Comida** (M): arbustos de bayas (recolectar sin herramienta), pesca en un lago con **caña**, caza pasiva
  (ciervos que huyen, sin violencia explícita: "atraparlos" o simplemente recoger lo que dejan). La comida es el
  recurso natural para alimentar aldeanos (ver 3.3).
- **Árboles con personalidad** (S): usar `TreeKind` para que los robles den más madera pero tarden más, los pinos
  sean rápidos, los árboles viejos den madera "noble" para edificios especiales, y los secos (`trees-dead`) den poco.
- **Recogida desde el suelo** (S): al caer, el árbol suelta troncos que hay que recoger (o que recoge un aldeano).
  Da más vida al mapa y prepara el transporte.
- **Herramientas mejorables** (M): hacha de piedra → hierro: menos golpes por árbol. Introduce un sumidero de
  recursos y una sensación clara de progreso.
- **Capacidad de carga** (M): el personaje lleva como máximo N unidades y debe volver a un almacén. Es el núcleo del
  bucle de AoE ("ir y volver") y da sentido a dónde se colocan los edificios.

### 3.2 Construcción con función

Que cada edificio **desbloquee o produzca** algo:

| Edificio | Coste orientativo | Función |
|---|---|---|
| Casa | 15 madera | +2 de población (permite aldeanos). |
| Almacén / Campamento maderero | 20 madera | Punto de entrega; recolección cercana más rápida. |
| Granja / Huerto | 30 madera | Produce comida con el tiempo o se cosecha como un trabajo. |
| Cantera | 25 madera | Habilita la piedra o la acelera. |
| Taller / Herrería | madera + piedra | Fabrica y mejora herramientas. |
| Pozo, caminos, vallas | baratos | Decoración útil: caminos aceleran al personaje, vallas delimitan. |
| Monumento / Plaza | mucho de todo | Meta a largo plazo, "maravilla" pacífica del AoE. |

Otras ideas de construcción:

- **Edificios por etapas** (S): cimientos → estructura → tejado, con arte distinto por fase (ya existe `progress`).
- **Entrega de materiales a pie de obra** (M): pagar al colocar es simple; pagar por fases obliga a acarrear.
- **Mejorar edificios** (M): casa → casa grande, almacén → granero.
- **Demoler / mover** (S): devolver parte del coste.
- **Reglas de colocación** (S–M): granjas sólo en terreno abierto, molino junto a agua, cantera junto a roca.

### 3.3 Aldeanos (el salto a "tipo AoE")

- **Reclutar aldeanos** (L): con casas (población) y comida. Cada aldeano reutiliza el mismo motor de `ActivityEntity` /
  `IntentEntity` que el jugador; habría que pasar de un `PlayerEntity` a una lista de unidades.
- **Asignar trabajos** (L): seleccionar un aldeano y tocar un árbol/roca/granja; después repite solo hasta que se
  agota el objetivo y busca el más cercano del mismo tipo.
- **Automatización progresiva** (M, sobre lo anterior): el jugador empieza haciéndolo todo y poco a poco delega.
  Encaja con el tono tranquilo: el juego pasa de "acción" a "gestión".
- **Necesidades suaves** (M): los aldeanos comen; sin comida trabajan más lento (nunca mueren: sin castigo duro).

### 3.4 Mundo vivo

- **Regeneración** (S): los tocones dejan un brote que vuelve a ser árbol tras X minutos; o plantar árboles
  (un trabajo más) para que la madera sea sostenible.
- **Ciclo día/noche** (M): tinte de pantalla, de noche se trabaja más lento o sólo cerca de antorchas/casas.
- **Estaciones** (M): reutilizar los árboles `orange` (otoño), `pale` (invierno), `green` (primavera/verano).
  Las cosechas sólo en ciertas estaciones; el invierno pide reservas de madera para calentarse.
- **Fauna ambiental** (S–M): pájaros, conejos, mariposas que huyen al acercarse. Sólo ambiente, mucho encanto.
- **Niebla de guerra / exploración** (M): el mapa empieza oculto; explorar revela recursos especiales.
- **Mapas más grandes con biomas** (L): bosque, pradera, orilla de lago, colinas rocosas. El generador con semillas
  ya está preparado para crecer; el `terrain_atlas` tiene agua y caminos.

### 3.5 Progresión y metas

- **Más misiones** (S): cadenas por capítulos ("El primer invierno", "Una aldea de 5 casas"). El sistema actual lo
  soporta tal cual; sólo hay que añadir entradas y textos en `es.json` (`Internationalize`).
- **Eras** (M): como las edades de AoE, pero pacíficas: Campamento → Aldea → Pueblo. Cada era desbloquea edificios y
  cambia el arte de los existentes.
- **Árbol de mejoras** (M): investigar en el taller (talar +20 % más rápido, caminar más rápido, más carga).
- **Logros** (S): talar 100 árboles, construir sin chocar, etc.
- **Modos de juego** (M): campaña con objetivos, **sandbox** sin límites, **contrarreloj** ("construye el monumento
  en 15 minutos"), mapa del día con semilla compartida.

### 3.6 Economía y decisiones

- **Comercio** (M): un mercader que visita la aldea cada cierto tiempo y cambia madera por piedra/herramientas.
- **Pedidos** (S–M): carteles con encargos ("entrega 30 de madera al pueblo vecino") que dan recompensas.
- **Precios dinámicos** (M): cuanto más vendes de algo, menos vale.
- **Recursos escasos** (S): pocos árboles "nobles", vetas de piedra limitadas; obliga a planificar.

### 3.7 Calidad de vida y presentación

- **Guardado automático** (M): serializar la `GameSessionEntity` a un DBO y guardarla con `shared_preferences`
  (o Hive) en un datasource local; funciona igual en web, Android e iOS. Prerrequisito para casi todo lo demás.
- **Cola de órdenes** (S): mantener pulsado/Shift+clic para encadenar árboles.
- **Minimapa** (M) y **zoom** con pellizco/rueda (S).
- **Sonido** (M): hachazos, martillazos, ambiente de bosque; refuerza mucho la sensación de "jugoso".
- **Feedback de números** (S): "+6" flotando sobre el árbol, contador de madera que "late".
- **Tutorial contextual** (S): resaltar el árbol más cercano mientras la primera misión está activa.

### 3.8 Héroe y arena: un segundo modo de juego

La aldea por sí sola acaba siendo "talar y construir". Se propone un segundo modo, corto y fácil de entender, en el que
**el héroe se hace más fuerte gracias a la aldea** y lo demuestra en peleas por niveles. Plan de implementación en
[`docs/boost/plans/2026-10-06-hero-arena/`](boost/plans/2026-10-06-hero-arena/README.md).

#### Propuesta elegida: arena por niveles con combate automático (M–L)

**El bucle que une los dos modos.** Es la clave para que no sean dos juegos pegados:

```
Aldea: madera / piedra ──▶ Herrería, Armería, Torre de magia ──▶ equipo y habilidades ──▶ más Poder
  ▲                                                                                        │
  └──────────────── oro (y más adelante trofeos) ◀──────────── Arena: ganar niveles ◀──────┘
```

- El **oro** sólo se gana en la arena; el equipo y las habilidades sólo se compran en la aldea.
- Ningún modo bloquea al otro: la aldea se juega igual sin pisar la arena, y la arena se puede repetir para conseguir
  oro aunque no se avance.

**El héroe.** Es el mismo personaje que tala y construye. Tiene sólo tres atributos y un número resumen:

| Atributo | Para qué sirve |
|---|---|
| **Ataque** | Un rango "de tanto a tanto" (hacha 3–5): cada golpe elige un valor del rango. |
| **Defensa** | Se resta al daño recibido (cada golpe hace al menos 1). |
| **Vida** | Golpes que aguanta. Se recupera entera al terminar cada pelea. |
| **Poder** | Resumen que se ve en el HUD y junto a cada nivel: `ataque medio × 3 + defensa × 4 + vida / 2`, +10 % por habilidad. Sirve para orientarse; quien decide la pelea es la simulación. |

Valores de partida: Ataque 3–5, Defensa 1, Vida 30 (Poder 31). Con todo el equipo y las tres habilidades, Ataque
12–16, Defensa 8, Vida 75 (Poder 144). Las cifras son las del equilibrado de la fase C7, protegidas por
`test/layers/domain/combat/balance_test.dart`.

**Edificios de mejora** (se construyen con recursos de la aldea; lo que venden se paga **sólo con oro** de la arena):

| Edificio | Qué vende | Niveles |
|---|---|---|
| **Herrería** | Armas (+Ataque) | Hacha de leñador (la de talar, nivel inicial) → Espada corta → Espada de hierro → Espada de acero |
| **Armería** | Armaduras (+Defensa, +Vida) | Ropa de trabajo (inicial) → Cuero → Cota de malla → Placas |
| **Torre de magia** | Habilidades pasivas | *Golpe doble* (cada tercer ataque golpea dos veces), *Segundo aliento* (una vez por pelea, al bajar del 30 % de vida recupera el 40 %), *Esquiva* (20 % de evitar un golpe) |

Se llama *Torre de magia* y no "taller mágico" para no confundirla con el *Taller* de herramientas (sección 3.2).
Si existe la piedra, la piden los edificios, no el equipo.

| Pieza | Ataque / Defensa · Vida | Precio |
|---|---|---|
| Hacha de leñador (inicial) | Ataque 3–5 | — |
| Espada corta | Ataque 6–8 | 30 de oro |
| Espada de hierro | Ataque 9–11 | 60 de oro |
| Espada de acero | Ataque 12–16 | 110 de oro |
| Ropa de trabajo (inicial) | Defensa 1 · Vida 30 | — |
| Armadura de cuero | Defensa 3 · Vida 40 | 40 de oro |
| Cota de malla | Defensa 5 · Vida 55 | 70 de oro |
| Armadura de placas | Defensa 8 · Vida 75 | 120 de oro |
| *Golpe doble* / *Esquiva* / *Segundo aliento* | — | 60 / 90 / 130 de oro (con la Torre de magia: 30 de madera y 40 de oro) |

**Niveles de la arena** (equilibrados en la fase C7; cada enemigo: Ataque / Defensa / Vida):

| Nivel | Enemigos | Poder | Recompensa (primera vez) | Héroe esperado | Gana con él | Con un escalón menos |
|---|---|---|---|---|---|---|
| 1 | Bandido novato (2–4 / 0 / 20) | 19 | 10 de oro | Inicial | casi siempre | — |
| 2 | Lobo (4–6 / 1 / 20) | 29 | 20 de oro | Inicial | 60–95 % | — |
| 3 | Bandido veterano (4–6 / 2 / 36) | 41 | 30 de oro | Espada corta | 60–95 % | < 50 % |
| 4 | Dos lobos (6–8 / 1 / 18) | 68 | 40 de oro | + Armadura de cuero | 60–95 % | < 50 % |
| 5 | Oso (8–12 / 3 / 40) | 62 | 55 de oro | + Espada de hierro | 60–95 % | < 50 % |
| 6 | Tres bandidos (7–9 / 1 / 26) | 123 | 75 de oro | + Cota de malla | 60–95 % | < 50 % |
| 7 | Bárbaro (10–14 / 4 / 58) | 81 | 90 de oro | + *Golpe doble* | 60–95 % | < 50 % |
| 8 | Manada de tres lobos (8–12 / 1 / 22) | 135 | 100 de oro | + *Esquiva* | 60–95 % | < 50 % |
| 9 | Dos bárbaros (8–12 / 4 / 52) | 144 | 120 de oro | + Espada de acero | 60–95 % | < 50 % |
| 10 | Jefe bárbaro (16–20 / 5 / 72) y dos guardias (7–11 / 2 / 31) | 210 | 150 de oro | + Armadura de placas | 60–95 % | < 50 % |

- "Gana con él" y "con un escalón menos" son el porcentaje de victorias en 100 peleas (semillas 0–99). El Poder del
  nivel no sube siempre: el oso pega fuerte pero es uno solo, y los grupos cuentan a todos sus miembros.
- Con el oro de la primera victoria de cada nivel anterior, más repetir como mucho tres veces el último, se paga el
  héroe esperado del nivel siguiente. *Segundo aliento* queda como mejora opcional para el final.

- Un nivel se desbloquea al ganar el anterior. Repetir un nivel ganado da un tercio del oro.
- Perder no quita nada: se vuelve a la aldea con un consejo ("Te falta Defensa", "Prueba con la Cota de malla").

**La pelea.**
1. En la pantalla de la arena se elige un nivel desbloqueado y se pulsa **"Empezar pelea"**.
2. El dominio simula la pelea entera **de golpe** y devuelve un registro: quién golpea a quién, daño, esquivas,
   habilidades y resultado. Es una simulación por turnos con semilla:
   - el héroe golpea primero, siempre al primer enemigo que queda en pie;
   - después golpea cada enemigo vivo;
   - daño = `max(1, valor − defensa)`, con un valor al azar del rango de ataque del atacante;
   - como mucho 30 rondas; si nadie cae, cuenta como derrota.
3. La pantalla **reproduce** ese registro en 5–8 segundos: el héroe y los enemigos frente a frente, la animación
   `slash` que ya existe, unas gotas de sangre en cada impacto, barras de vida, números de daño flotando, y al final
   victoria o derrota con la recompensa.

Con el azar, una pelea igualada no se sabe de antemano, pero con un Poder claramente mayor casi siempre se gana.
Como la semilla sale del número de peleas jugadas, la misma partida guardada da siempre el mismo resultado y los tests
son deterministas.

**Arte.**
- **Héroe**: el que ya existe, con la hoja `slash` (la de talar) y el hacha como primera arma. Las espadas y armaduras
  pueden empezar como recoloreados (`recolour()` en `build_assets.py`) y cambiarse por piezas LPC reales más adelante.
- **Bandidos**: las mismas capas LPC del héroe con otra ropa y otro color. No hace falta arte nuevo.
- **Lobos y oso**: hace falta arte nuevo. Hay animales de estilo LPC en OpenGameArt; hay que confirmar la licencia y
  acreditarlos en `CREDITS.md`. Por eso los niveles con animales van en una fase propia.
- **Bárbaros**: capas LPC con pieles, barba y hacha grande, si se encuentran; si no, bandidos recoloreados.
- **Escenario**: un claro de hierba con vallas o muros de piedra del `terrain_atlas` (ya disponible).

**Cómo encaja en la arquitectura.**
- Dominio:
  - `HeroEntity` (equipo, habilidades, niveles ganados, peleas jugadas) vive dentro del `World`, que sigue siendo el
    único agregado mutable, así que el guardado y las misiones lo ven sin hacer nada especial.
  - El motor de combate es una función pura en `domain/combat/`, fuera de `world/`.
  - Catálogos `Gear`, `Skills`, `Enemies` y `ArenaLevels` en `domain/rules/`, como `Blueprints`.
- Pagos y cobros: pasan por dos métodos del `World` (`earn` / `spend`). Así, cuando la aldea pase a tener almacén
  (stock común), el combate no se entera.
- Presentación: una pantalla nueva `features/arena/` con su BLoC y su escena Flame. Se entra desde un botón del HUD del
  bosque y se navega con `NavigationService`.

#### Alternativas que también encajan

| Idea | Esfuerzo | Cómo sería | Pros / contras |
|---|---|---|---|
| **Expediciones** | S | Un *Puesto de guardia* en la aldea manda al héroe a una expedición de 30–60 s; el Poder decide la probabilidad de éxito y el botín. | Lo más barato: sólo un panel y un temporizador. Sin espectáculo. Buen primer paso o "modo idle" complementario de la arena. |
| **Caza en el bosque** | M | Lobos que deambulan por el mapa actual; al tocarlos, el héroe va y ataca como si fuera un árbol. | Reutiliza el patrón `IntentEntity` + `Work` + `workFor()` (un lobo es "un árbol que se mueve y devuelve golpes"). No hay otra pantalla, pero mete peligro en la aldea, que debía ser tranquila. |
| **Defensa de la aldea** | L | De noche llegan oleadas de lobos y luego de bandidos; se construyen vallas y torres. | La más "AoE". Necesita IA de enemigos, rutas y daño a edificios. Encaja tras los aldeanos (que podrían hacer de guardias). |
| **Torre / mazmorra por pisos** | M | Igual que la arena, pero en una secuencia de pisos sin volver a la aldea entre medias (la vida no se recupera). | Variante de la arena con más tensión; reutiliza el mismo motor. |

#### Ideas para más adelante

- **Trofeos** (S): pieles de lobo y garras de oso como recurso que piden las armaduras de nivel alto. Une aún más los
  dos modos.
- **Postura antes de pelear** (S): *Agresiva* (+Ataque, −Defensa) o *Prudente*. Es una sola decisión, sin
  micro-gestión.
- **Equipo visible en el bosque** (S–M): el héroe tala con la espada o la armadura que lleva puestas.
- **Misiones de héroe** (S): "Gana el nivel 3", "Compra la Cota de malla", "Aprende una habilidad".
- **Torneo / jefe del día** (M): un nivel con semilla diaria, como el "mapa del día" de la sección 3.5.
- **Guardias** (L): con aldeanos (sección 3.3), reclutar guardias que suman Poder en la arena o defienden la aldea.

## 4. Propuesta de hoja de ruta

Orden pensado para que cada paso aporte jugabilidad visible y prepare el siguiente.

1. **Cerrar el bucle básico** (corto)
   - Guardado automático.
   - Árboles que rebrotan o se plantan.
   - `TreeKind` con efecto en madera y golpes.
   - 4–6 misiones más.
2. **Segundo recurso y edificios útiles**
   - Piedra + pico + cantera.
   - Almacén con capacidad de carga del personaje.
   - Taller con mejora de herramientas.
3. **Aldeanos**
   - Casa = población, comida = coste.
   - Aldeanos que trabajan en bucle sobre un tipo de recurso.
   - Granja/bayas para la comida.
4. **Mundo vivo y metas largas**
   - Estaciones con el arte ya disponible.
   - Eras y monumento final.
   - Mercader / pedidos.

**En paralelo, el héroe y la arena** (sección 3.8). Sólo depende de que existan los recursos genéricos (fase F0 del plan
de la aldea), así que puede ir a la vez que las etapas 1–4 o después:

- **Contrato común**: el héroe dentro del `World`, el oro y los métodos `earn` / `spend`. Lo hace un único desarrollador.
- **Flujo "arena"**: el motor de combate, la pantalla de la arena, los animales y los bárbaros.
- **Flujo "héroe"**: Herrería y Armería, Torre de magia y habilidades, misiones y equilibrado.

Cómo se combinan los dos planes y qué pasa en cada cruce (guardado, almacén, piedra, misiones, HUD): sección 3 del
[README del plan de la arena](boost/plans/2026-10-06-hero-arena/README.md) y sección 6 del
[README del plan de la aldea](boost/plans/2026-10-04-game-design/README.md).

## 5. Preguntas abiertas para el equipo

- ¿Queremos que el juego evolucione hacia **gestión** (aldeanos, automatización) o mantenerlo como **un solo
  personaje** al estilo *cozy* (tipo *Stardew* / *Animal Crossing*)? Condiciona casi toda la hoja de ruta.
- ¿Hay **fin de partida** (monumento, eras) o es un sandbox infinito?
- ¿Sesiones cortas en móvil (minutos) o partidas largas en escritorio?
- ¿Mapa fijo con semilla (igual para todos, comparables) o mapas aleatorios por partida?
- ¿Cuánto arte nuevo estamos dispuestos a buscar/generar? Las mecánicas con arte LPC ya disponible
  (estaciones, piedra, agua, cultivos) son las más baratas.

**Decidido para la arena (2026-10-06):**
- **Derrota sin castigo:** se vuelve a la aldea con un consejo y no se pierde nada.
- **La arena tiene final:** 10 niveles hasta el jefe bárbaro; ganarlo convierte al héroe en *Campeón*. Los niveles
  infinitos con semilla quedan como idea futura.
- **Pelea 100 % automática.** La postura antes de pelear queda como idea futura.
- **Sangre, sólo unas gotas:** cada golpe que acierta hace saltar unas pocas gotas (partículas) para que se note el
  impacto. Nada de charcos, restos ni cuerpos ensangrentados.
- **Se permite arte LPC nuevo** (animales, bárbaros, armas) con licencia compatible, acreditado en `CREDITS.md`.
