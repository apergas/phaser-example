# Empezar con el hacha en la mano — ficha

> Arreglo o mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-start-with-axe`, desde `feature/PROJECT-X-town` (o `feature/PROJECT-X-arena`) |
| **Estado** | Plan detallado |

**Qué se quiere** (pedido por el usuario el 2026-10-17): que el personaje empiece la partida con el hacha en la mano, sin tener que recogerla y sin la misión *Recoge el hacha*.

**Por qué:** recogerla no aporta nada. Además, el aviso "¡Hacha recogida! …" se pierde, porque en el mismo tick llega "Misión completada: Recoge el hacha" y lo tapa (visto en Chrome y en Android).

**Qué cambia:**
- **Nivel:** el hacha ya no está en el suelo (`LevelLocalDatasourceImpl` deja de poner el objeto del hacha) y el jugador empieza con `ToolKind.axe`. Hay que mirar dónde nace el jugador (`StartGameUseCase` / `World`).
- **Misiones:** `QuestId.pickUpAxe` sale de `Quests.all`. F2 todavía no guarda nada, así que el valor del enum también se puede quitar. Las insignias (`0/11` hoy) bajan en uno, y las fichas de F4 (`x/16`) y F8 (`x/20`) se ajustan.
- **Textos:** fuera `forest.message.welcome` ("Hay un hacha en el suelo…"), o se cambia por una bienvenida que mande a talar. Fuera también `pickedUpAxe` / `pickedUpAxeTouch` si ya nadie los usa. F5 seguirá teniendo el pico en el suelo, con su propio aviso.
- **Tests:** los escenarios y mocks que empiezan sin hacha (`ForestScenarioMock.axeNextToPlayer`, `GameScenarioMock`…), los de misiones y el test de flujo. El test de equilibrado no cambia.
- **iOS** sigue haciendo lo que Flutter hace hoy: es un cambio nuevo, no de paridad, y el repositorio iOS no se toca.

**Cuándo:** antes de F4, que añade misiones a la aldea y cuenta la insignia. Puede ir en la rama de la aldea antes de F1, o en la de la arena si se quiere ya.

---

# Empezar con el hacha en la mano — plan de implementación

> **Para agentes:** `boost:subagent-driven-development` o `boost:executing-plans`. Sin pasos de test: el usuario no quiere tests en esta mejora (ver *Para T1*).

**Objetivo:** el jugador nace con `ToolKind.axe` en el inventario, sin hacha en el suelo ni misión *Recoge el hacha*, y la bienvenida le manda a talar.

**Arquitectura:** el nivel deja de generar el objeto del hacha; el mapper del nivel crea el `PlayerEntity` con el hacha en `InventoryEntity.tools`. El sistema genérico de objetos del suelo (`pickUpItems`, `GroundItemEntity`, `ItemPickedUpEventEntity`, `SpriteNames.item`) no se toca: F5 pondrá el pico en el suelo.

**Verificación:** `flutter analyze lib` termina en "No issues found!", `dart format --line-length 120` sobre lo escrito y `dart run build_runner build --delete-conflicting-outputs` solo si cambia la DI (no se espera).

## Decisiones

- **Dónde nace con el hacha:** `LevelMapperDBO.toEntity` (`lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart`) pasa `inventory: const InventoryEntity(tools: {ToolKind.axe})` a `PlayerEntity`. El dominio y `StartGameUseCase` no cambian.
- **`QuestId.pickUpAxe` sale del enum**, además de `Quests.all`: F2 no guarda nada todavía, así que no hay índices guardados que romper. Los valores restantes se desplazan.
- **Bienvenida nueva:** "Tala árboles para reunir madera y construir tu aldea." (misma clave `forest.message.welcome`; la versión touch es la misma, no habla de clic).
- **Textos `pickedUpAxe` / `pickedUpAxeTouch` se quedan:** el `switch` de `ForestBloc._react` sobre `ToolKind` es exhaustivo y sigue el sistema de recogida, que ya no recoge el hacha pero F5 reescribirá ese `switch` al añadir el pico. Se anota en la ficha de F5 al cerrar si hace falta.
- **Conteos:** la línea de la aldea baja de 3 a 2 misiones y el total de 11 a 10. En F4 la aldea pasa a 7 y el total a 15 (`x/15`); en F8 el total pasa a 19 (`x/19`).

## Tarea 1: nivel, jugador y misión

**Archivos:**
- Modificar: `lib/layers/data/datasources/level/local/level_local_datasource_impl.dart`
- Modificar: `lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart`
- Modificar: `lib/core/config/constants/enum/quest_id.dart`, `lib/layers/domain/quests/quests.dart`

- [ ] **Paso 1:** en el datasource, quitar la constante `_axe`, usar `items: const []` en `fetch()` y quitar `onAxe` de `isFree` (queda `return !underTree && !onSpawn && !crowded;`).
- [ ] **Paso 2:** en el mapper, importar `InventoryEntity` y `ToolKind` (imports relativos) y dar al jugador el inventario inicial:

```dart
player: PlayerEntity(
  position: _positionMapperDBO.toEntity(playerStart),
  speed: Rules.playerSpeed,
  radius: Rules.playerRadius,
  inventory: const InventoryEntity(tools: {ToolKind.axe}),
),
```

- [ ] **Paso 3:** quitar `pickUpAxe` de `QuestId`, borrar su `_MeasuredQuest` en `Quests.all` y el import de `tool_kind.dart` si queda sin uso.

## Tarea 2: textos y bienvenida

**Archivos:**
- Modificar: `lib/core/assets/i18n/translations/es.json`
- Modificar: `lib/core/assets/i18n/internationalize.dart`

- [ ] **Paso 1:** en `es.json`, borrar `quest.pickUpAxe` y cambiar `message.welcome` a "Tala árboles para reunir madera y construir tu aldea.".
- [ ] **Paso 2:** en `Internationalize`, borrar el caso `QuestId.pickUpAxe` del `switch` de misiones.
- [ ] **Paso 3:** `flutter analyze lib`, `dart format --line-length 120` sobre los archivos tocados (no sobre generados) y commit `[PROJECT-X]: Start the game holding the axe`.

## Tarea 3: fichas posteriores

- [ ] En `F4-quests-chapter-1.md`: "la línea de la aldea pasa a 7 misiones y el total a 15", insignia `0/15` y `x/15` (líneas 37, 44, 62, 67).
- [ ] En `F8-workshop.md`: la insignia pasa a `x/19` (líneas 62 y 102, "llega a 19/19").
- [ ] Commit `git add docs/boost/plans` y aparte `[PROJECT-X]: Plan starting with the axe` (este commit va antes de implementar).

## Prueba manual

Empezar partida: el héroe lleva el hacha (sprite con hacha) y no hay ninguna en el suelo; sale el aviso de bienvenida nuevo; clic en un árbol tala sin recoger nada; el panel de misiones empieza en *Reúne 15 de madera* y la insignia en `0/10`.

## Para T1

Los tests que empezaban sin hacha (`ForestScenarioMock.axeNextToPlayer`, `GameScenarioMock`, mocks de nivel/DBO con el objeto del hacha), los de misiones (`quests_test`, `quest_log_test`, recuento 11 → 10), los de `ForestBloc` (bienvenida, aviso de recogida), `internationalize_test` (clave `pickUpAxe`) y el test de flujo.
