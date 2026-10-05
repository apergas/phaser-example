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

- **Tabla en `Rules`:** `static const Map<TreeKind, TreeStatsEntity> treeKindStats`, donde `TreeStatsEntity(woodYield, hitsToFell)` es una entidad nueva en `domain/entities/tree/`. `Rules.hitsToFellTree` desaparece. Valores orientativos:

  | Tipos | Madera | Golpes |
  |---|---|---|
  | `oak`, `old`, `big` | 8–9 | 7–8 |
  | `pine`, `slim` | 4 | 3 |
  | Resto | 5–6 (como hoy) | 5 |

  Los números finales se fijan en el plan y se apuntan como decisión. El mapa tiene que cubrir todos los valores de `TreeKind` (un test lo comprueba).
- **`TreeDBO.wood` deja de usarse para la jugabilidad.**
  - `TreeMapperDBO` toma la madera y los golpes de la tabla a partir de `kind`.
  - El generador (`LevelLocalDatasourceImpl`) **no cambia**: sigue sacando `wood` de la semilla, porque quitar esa llamada movería todos los números aleatorios siguientes y con ellos las posiciones. El mapa y los tests dorados de posición y tipo (`level_local_datasource_impl_test.dart`, también en Chrome) siguen iguales, incluido el total de `TreeDBO.wood` (388).
  - Sí cambia el total de madera de las entidades, hoy `388` en `test/core/config/di/di_test.dart`. El nuevo total se calcula y se fija en el test.
- **Feedback "+N":**
  - `TreeFelledEffect` (`models/forest_effect.dart`) añade `final int wood;`. `ForestBloc._react` lo rellena con el `wood` de `TreeFelledEventEntity`, que ya existe.
  - Nuevo componente Flame `FloatingTextComponent` en `features/forest/game/components/`: un `TextComponent` que sube y se desvanece sobre la base del tronco; lo añade `ForestSceneComponent._onTreeFelled`.
  - El texto sale de una clave nueva `forest.floating.woodGained: "+{wood}"` con `Internationalize.forestFloatingWoodGained(wood:)`. El mensaje del *snackbar* (`forestMessageWoodGained`, "+6 de madera") se mantiene.
- **Persistencia:** no añade estado nuevo.

## Ficheros previstos

**Dominio:**
- `lib/layers/domain/entities/tree/tree_stats_entity.dart` (nuevo)
- `lib/layers/domain/rules/rules.dart`

**Datos:** `lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart`.

**Presentación:**
- `lib/layers/presentation/features/forest/models/forest_effect.dart`
- `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
- `lib/layers/presentation/features/forest/game/components/floating_text_component.dart` (nuevo)
- `lib/layers/presentation/features/forest/game/forest_scene_component.dart`
- `lib/core/assets/i18n/internationalize.dart` y `es.json`

## Cómo probarlo

- Un roble pide más golpes y da más madera que un pino. Al caer sale "+8" en uno y "+4" en el otro.
- La misión de 15 de madera se sigue completando.
- Tests: `tree_mapper_dbo_test.dart`, `level_repository_impl_test.dart` y `world_chopping_test.dart`, con un caso por cada tipo de árbol representativo; `forest_bloc_test.dart` (el efecto lleva la madera) y un test de `FloatingTextComponent` con `testWithFlameGame`.
