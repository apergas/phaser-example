# Arena · cambios y mejoras pendientes

> Lista de ajustes de la arena que se aplicarán **cuando el plan *Héroe y arena* esté completo** (después de C7), en una fase propia de pulido. No es un plan detallado: cada punto se convierte en tarea cuando se planifique esa fase.
>
> Abierta el 2026-10-07, tras probar C2 y C3 juntas.

## 1. Arte de los luchadores

### 1.1 Bandido novato y bandido veterano se ven iguales

Los dos son `EnemyKind.bandit` y usan los mismos frames `bandit-*` del atlas de la arena (camisa granate, pantalón gris oscuro, pelo negro y hacha).

**Qué hacer:** que el veterano se distinga a simple vista. Opciones, de menos a más trabajo:
- otro color de camisa (y quizá de pantalón) con `recolour()` en `build_assets.py`;
- un sombrero o una capucha LPC encima de la cabeza;
- que lleve una **espada** en lugar del hacha (ver 1.3).

Hace falta un `EnemyKind` nuevo (por ejemplo `banditVeteran`, añadido al final del enum) o un campo de aspecto en `EnemyEntity`. Los `switch` exhaustivos de `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale` e `Internationalize.arenaEnemy` avisan de todo lo que hay que tocar.

### 1.2 El héroe pelea con el arma que lleva equipada

Hoy el héroe de la arena siempre pelea con el hacha, aunque haya comprado la espada corta (o una mejor).

**Qué hacer:** que el sprite del héroe en la arena use el arma equipada:
- `woodcutterAxe` → hacha (como ahora);
- `shortSword`, `ironSword`, `steelSword` → espada.

La escena ya recibe el héroe por `FighterRenderData`; habría que añadirle el arma (o una variante de aspecto) y generar en `arena.png` los frames `hero-*-sword`.

### 1.3 Espadas en el atlas

Ahora no hay espadas en `asset-packs/lpc/sources/`: por eso todos los luchadores golpean con el hacha (desviación de C2). Antes de 1.1 y 1.2 hay que traer una espada LPC con licencia compatible (CC-BY-SA 3.0, GPL 3.0 u OGA-BY 3.0), acreditarla en `CREDITS.md` y añadir sus capas a `body_sheet`. Comprobar antes si C6 ya la ha traído.

## 2. Mejoras del héroe sólo con oro

Hoy cada pieza de equipo cuesta madera **y** oro (`Gear.all`):

| Pieza | Coste actual |
|---|---|
| Espada corta | 20 madera + 10 oro |
| Espada de hierro | 30 madera + 40 oro |
| Espada de acero | 40 madera + 120 oro |
| Armadura de cuero | 15 madera + 15 oro |
| Cota de malla | 30 madera + 50 oro |
| Armadura de placas | 40 madera + 150 oro |

**Qué hacer:** que las mejoras del héroe cuesten **sólo oro**. Los recursos de la aldea se siguen gastando en construir la Herrería y la Armería, pero comprar armas y armaduras se paga con lo que se gana en la arena.

- Quitar `Resource.wood` del coste en `Gear.all` y subir el oro para compensar (a revisar con el test de equilibrado de C7).
- **Cruce con F5 (piedra):** el README (3.2) dice que F5 añade 15 de piedra a `steelSword` y `plateArmor`. Si se aplica este cambio, esa piedra pasa sólo a los edificios (Herrería, Armería, Torre de magia) y no al equipo. Actualizar la tabla de cruces.
- Ajustar `GearOptionEntity.missing`, los textos de "Faltan…" y los mocks (`FundsMock`, `GearScenarioMock`) que hoy cuentan madera.

## 3. Los luchadores se acercan para golpear

Hoy cada luchador se queda en su sitio (héroe en x = 190, enemigos en x = 300/340) y golpea al aire: el golpe "llega" aunque estén a más de 100 px.

**Qué hacer:** que en cada turno el atacante **avance hasta el objetivo**, golpee y **vuelva** a su sitio:
- dentro de los 600 ms del turno: avanzar (por ejemplo el primer 35 %), golpe con el impacto a mitad (como ahora), retroceder al final;
- la posición de impacto, a unos 28–32 px del objetivo, del lado del atacante;
- mientras avanza y vuelve, la animación de andar (`walk`, columnas 1–8) mirando al objetivo;
- en una esquiva, el enemigo avanza y falla; en el segundo aliento nadie se mueve;
- *Saltar* deja a todos en su sitio.

Todo esto es de la escena (`FighterComponent`, `ArenaSceneComponent`) y de `FightReplayData` (fase del turno); el dominio no cambia. Puede que haga falta alargar `turnMs` (por ejemplo a 800 ms) para que se lea bien.

## 4. Daño: ¿fijo o aleatorio?

### Cómo funciona ahora

El daño de cada golpe ya tiene una parte aleatoria (`Combat._damage`):

```
daño = max(1, redondeo((ataque − defensa) × (1 ± 0,15)))
```

- `Rules.damageSpread = 0.15`: el daño varía un ±15 % alrededor de `ataque − defensa`.
- Es **determinista**: la semilla es `hero.fightsFought`, así que la misma pelea sale siempre igual, pero cada pelea nueva cambia.
- Nunca baja de 1 ni pasa de la vida que le queda al objetivo.

**El problema** es que con los números bajos del principio el ±15 % casi no se nota, porque al redondear sale siempre lo mismo:

| Golpe | Base (ataque − defensa) | Rango con ±15 % | Lo que se ve |
|---|---|---|---|
| Bandido novato (3) → héroe nuevo (defensa 1) | 2 | 1,7–2,3 | siempre **2** |
| Héroe nuevo (4) → bandido novato (defensa 0) | 4 | 3,4–4,6 | 3, 4 o 5 |
| Héroe con espada de hierro (10) → bárbaro (defensa 4) | 6 | 5,1–6,9 | 5, 6 o 7 |
| Bárbaro (12) → héroe con cota (defensa 5) | 7 | 5,95–8,05 | 6, 7 u 8 |

Por eso en la prueba el bandido quitaba siempre "−2".

### Qué hacer

**Decidido (2026-10-07):** el ataque pasa a ser un **rango "de tanto a tanto"**, que sube con cada arma: hacha 3–5, espada corta 5–7, y así sucesivamente.
- Cada arma (`GearEntity`) lleva `attackMin` / `attackMax` en lugar de un `attack` fijo. Los enemigos (`CombatStatsEntity`), lo mismo. Los números exactos de cada pieza y enemigo se fijan al planificar, con el test de equilibrado de C7.
- En cada golpe se elige un valor del rango con la semilla y se le resta la defensa: `daño = max(1, valor − defensa)`. Desaparece el ±15 % (`Rules.damageSpread`).
- El panel *Héroe* y la lista de equipo muestran el rango ("Ataque 3–5"), y cada opción de compra (`GearOptionTile`) el rango de la pieza nueva.

Además:
- se mantiene la semilla (`SeededRandom(hero.fightsFought)`) y el orden de las llamadas a `next()`, que es parte del contrato del motor;
- hay que recalcular los resultados exactos de `combat_test.dart` y de los mocks de peleas, y el test de equilibrado de C7;
- el Poder (`HeroRules.power`) usa el ataque medio del rango.

## 5. Pendientes que ya estaban apuntados

Del cierre de C2 y C3 (sección 5 del README):
- **Decisiones provisionales de C2**, a revisar con este pulido: la pausa con `RouteObserver`, el panel de victoria sin botón y el umbral ámbar del Poder (×1,25). La de "todos con hacha" la resuelven 1.2 y 1.3.
- `ArenaBloc._emitReplay` llama a `GetArenaUseCase` sin `try/catch`; hay que capturarlo si F2 trae errores de almacenamiento.
- Un golpe de 0 de daño enseña "−0" (no debería pasar con `max(1, …)`, pero la escena no lo filtra).
- La pose `hurt` dibuja lo mismo que `idle`: el parpadeo lo pone el efecto. Se podría dar un frame propio de "recibir el golpe".
- En un móvil de 844 × 390, el panel de derrota (con *Reintentar*) puede tapar al enemigo de arriba en los niveles de tres enemigos. Revisar en la prueba manual.
