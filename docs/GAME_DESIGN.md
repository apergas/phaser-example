# Análisis del juego y brainstorming de mecánicas

> Documento de trabajo (2026-10-04). Resume el estado actual del prototipo y recoge ideas para ampliar la
> jugabilidad. Las ideas son propuestas, no decisiones.

## 1. La idea

Un juego de **recolección y construcción** en vista cenital 3/4, inspirado en la parte económica de *Age of Empires*
pero **sin combate**: el placer está en explorar, recoger recursos, levantar edificios y ver cómo un asentamiento
crece. Ritmo tranquilo, sesiones cortas, controles de un solo toque/clic, jugable igual en web, Android e iOS.

Pilares que se deducen de lo ya hecho:

1. **Tocar y que pase algo**: un clic sobre un árbol lleva al personaje, que se coloca y tala solo. Nada de
   micro-gestión de animaciones o rutas.
2. **Progreso visible**: el bosque se aclara, la madera sube, la casa aparece por fases.
3. **Guía ligera**: misiones encadenadas que enseñan el bucle sin tutoriales largos.
4. **Un solo núcleo de reglas**: toda la lógica en el dominio (Dart puro, sin Flutter ni Flame); la presentación sólo dibuja.

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

## 5. Preguntas abiertas para el equipo

- ¿Queremos que el juego evolucione hacia **gestión** (aldeanos, automatización) o mantenerlo como **un solo
  personaje** al estilo *cozy* (tipo *Stardew* / *Animal Crossing*)? Condiciona casi toda la hoja de ruta.
- ¿Hay **fin de partida** (monumento, eras) o es un sandbox infinito?
- ¿Sesiones cortas en móvil (minutos) o partidas largas en escritorio?
- ¿Mapa fijo con semilla (igual para todos, comparables) o mapas aleatorios por partida?
- ¿Cuánto arte nuevo estamos dispuestos a buscar/generar? Las mecánicas con arte LPC ya disponible
  (estaciones, piedra, agua, cultivos) son las más baratas.
