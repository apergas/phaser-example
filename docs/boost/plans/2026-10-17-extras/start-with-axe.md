# Empezar con el hacha en la mano — ficha

> Arreglo o mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-start-with-axe`, desde `feature/PROJECT-X-town` (o `feature/PROJECT-X-arena`) |
| **Estado** | Ficha |

**Qué se quiere** (pedido por el usuario el 2026-10-17): que el personaje empiece la partida con el hacha en la mano, sin tener que recogerla y sin la misión *Recoge el hacha*.

**Por qué:** recogerla no aporta nada. Además, el aviso "¡Hacha recogida! …" se pierde, porque en el mismo tick llega "Misión completada: Recoge el hacha" y lo tapa (visto en Chrome y en Android).

**Qué cambia:**
- **Nivel:** el hacha ya no está en el suelo (`LevelLocalDatasourceImpl` deja de poner el objeto del hacha) y el jugador empieza con `ToolKind.axe`. Hay que mirar dónde nace el jugador (`StartGameUseCase` / `World`).
- **Misiones:** `QuestId.pickUpAxe` sale de `Quests.all`. F2 todavía no guarda nada, así que el valor del enum también se puede quitar. Las insignias (`0/11` hoy) bajan en uno, y las fichas de F4 (`x/16`) y F8 (`x/20`) se ajustan.
- **Textos:** fuera `forest.message.welcome` ("Hay un hacha en el suelo…"), o se cambia por una bienvenida que mande a talar. Fuera también `pickedUpAxe` / `pickedUpAxeTouch` si ya nadie los usa. F5 seguirá teniendo el pico en el suelo, con su propio aviso.
- **Tests:** los escenarios y mocks que empiezan sin hacha (`ForestScenarioMock.axeNextToPlayer`, `GameScenarioMock`…), los de misiones y el test de flujo. El test de equilibrado no cambia.
- **iOS** sigue haciendo lo que Flutter hace hoy: es un cambio nuevo, no de paridad, y el repositorio iOS no se toca.

**Cuándo:** antes de F4, que añade misiones a la aldea y cuenta la insignia. Puede ir en la rama de la aldea antes de F1, o en la de la arena si se quiere ya.
