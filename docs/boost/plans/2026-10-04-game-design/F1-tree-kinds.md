# F1 · Árboles con personalidad — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha, cambia este aviso por la cabecera *For agentic workers*, divide el trabajo en tareas T1.x y crea sus issues en GitHub.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F0 |
| **Issue / milestone** | `phase:F1` · milestone `F1 Tree kinds` |

## Objetivo

Que el tipo de árbol (`TreeKind`, que el generador ya decide) cambie cuánto cuesta talarlo y cuánta madera da. Así aparece la primera decisión: ¿talo el roble grande o tres pinos rápidos? Además, la madera ganada se ve flotar sobre el árbol.

## Decisiones ya tomadas

- **Tabla en `Rules`:** `TREE_KIND_STATS: Map<TreeKind, TreeStats(woodYield, hitsToFell)>`, donde `TreeStats` es una `data class` del dominio. Valores orientativos:

  | Tipos | Madera | Golpes |
  |---|---|---|
  | `Oak`, `Old`, `Big` | 8–9 | 7–8 |
  | `Pine`, `Slim` | 4 | 3 |
  | Resto | 5–6 (como hoy) | 5 |

  Los números finales se fijan en el plan y se apuntan como decisión.
- **`TreeDto.wood` deja de usarse.**
  - `LevelMappers` calcula la madera y los golpes con la tabla a partir de `kind`.
  - El generador no cambia: el mapa y los tests dorados de posición y tipo (`LevelLocalDataSourceImplTests`) siguen iguales.
  - Sí cambia el total de madera, hoy `388` en `LevelLocalDataSourceImplTests` y `GameContainerTests`. El nuevo total se calcula y se fija en el test.
- **Feedback "+N":**
  - `ForestEffect.TreeFelled` añade `wood: Int`.
  - Las tres apps muestran un texto que sube y se desvanece sobre la base del tronco:
    - web: un `Text` con tween;
    - Android: una partícula de texto o un estado temporal;
    - iOS: `SKLabelNode` + `SKAction`.
  - El texto sale de `ForestLabels.Messages.woodGained(n)`.
- **Persistencia:** no añade estado nuevo.

## Ficheros previstos

**`shared`:**
- `shared/.../domain/rules/Rules.kt`
- `shared/.../domain/entities/tree/TreeStats.kt` (nuevo)
- `shared/.../data/repositories/level/LevelMappers.kt`
- `shared/.../presentation/forest/ForestContract.kt`
- `shared/.../presentation/forest/ForestViewModel.kt`
- `shared/src/jsMain/.../web/WebMappers.kt`: el efecto `tree-felled` lleva el texto en `text`.

**Apps:**
- Web: `webApp/src/presentation/screens/forest/world/TreeView.ts`, o un `FloatingText.ts` nuevo.
- Android: `androidApp/.../world/WorldSceneState.kt` y `WorldCanvas.kt`.
- iOS: `iosApp/.../World/ForestScene.swift`.

## Cómo probarlo

- Un roble pide más golpes y da más madera que un pino. Al caer sale "+8" en uno y "+4" en el otro.
- La misión de 15 de madera se sigue completando.
- Tests: `LevelRepositoryImplTests` y `World*Tests`, con un caso por cada tipo de árbol representativo.
