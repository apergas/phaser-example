# C5 · Torre de magia y habilidades — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | D (héroe) |
| **Depende de** | C3 (panel *Héroe*). Los efectos en la pelea los aplica el motor de C1; si C1 todavía no está, las habilidades se aprenden igual y empiezan a funcionar cuando llegue. |
| **Issue / milestone** | `phase:C5` · `stream:D` · milestone `C5 Mage tower` |

## Objetivo

Un tercer edificio de mejora que no da números sino **comportamientos**: golpe doble, segundo aliento y esquiva. Así aparece una decisión: ¿mejoro la espada o aprendo una habilidad?

## Decisiones ya tomadas

**Edificio:** `BlueprintId.mageTower`, *Torre de magia*.
- Coste: 30 de madera y 40 de oro. Es el primer edificio que cuesta oro: así la aldea necesita la arena. Lleva además 10 de piedra si F5 está.
- 12 martillazos; huella como la casa.

**Habilidades:**
- `SkillEntity(id: SkillId, cost: Map<Resource, int>)` en `domain/entities/hero/`.
- Catálogo `Skills.all` en `rules/skills.dart` (orientativo):

  | Habilidad | Coste | Efecto (lo aplica `Combat.resolve`, C1) |
  |---|---|---|
  | Golpe doble (`doubleStrike`) | 60 de oro | Cada tercer ataque golpea dos veces. |
  | Esquiva (`dodge`) | 90 de oro | 20 % de evitar cada golpe. |
  | Segundo aliento (`secondWind`) | 130 de oro | Una vez por pelea, al bajar del 30 % de vida recupera el 40 %. |

- Se pueden aprender en cualquier orden.
- Cada una suma un 10 % de Poder (`Rules.powerPerSkill`, C0).

**Casos de uso:**
- `LearnSkillUseCase.call({required SkillId id}) → LearnSkillResult`, con el enum de core `LearnSkillResult { ok, missingBuilding, alreadyKnown, notEnoughResources }`, comprobado en ese orden.
  - Paga con `world.spend`.
  - Si sale `ok`: `world.updateHero((hero) => hero.copyWith(skills: {...hero.skills, id}))`.
- `GetSkillOptionsUseCase → List<SkillOptionEntity(skill, state: SkillOptionState { known, available, needsBuilding, unaffordable }, missing)>`.

**UI:**
- Pestaña *Habilidades* en `HeroPanel` (C3 la dejó preparada): una `SkillTile` por habilidad, con nombre, descripción corta, coste y *Aprender*.
- Evento `ForestSkillLearnRequested(id)` y efecto `SkillLearnedEffect`: destello azul con las partículas existentes.
- En la arena (C2), los turnos `doubleStrike`, `dodge` y `secondWind` muestran el nombre de la habilidad flotando ("¡Esquiva!"). Si C2 ya lo hace con textos genéricos, aquí sólo se cambian por los nombres de `Internationalize`.

**Arte:** frame `mageTower`, montado con piezas existentes (tejado recoloreado violeta, más alto).

**Textos:** nombres y descripciones de las habilidades (`forest.skill.<id>.name` / `.description`) y el nombre del edificio.

**Persistencia:** `skills` ya está en `HeroEntity` (C0).

## Ficheros previstos

- **Dominio:**
  - `entities/hero/skill_entity.dart`, `skill_option_entity.dart` (nuevos)
  - `rules/skills.dart` (nuevo), `rules/blueprints.dart`
  - `use-cases/hero/learn_skill_use_case.dart`, `get_skill_options_use_case.dart` (nuevos)
  - Enums de core: `blueprint_id.dart`, `learn_skill_result.dart` y `skill_option_state.dart` (nuevos)
- **Presentación:** `features/forest/bloc/*`, `models/hero_panel_data.dart`, `models/skill_item_data.dart` (nuevo), `models/forest_effect.dart`, `widgets/hero_panel.dart`, `widgets/skill_tile.dart` (nuevo), `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`; y `features/arena/**` sólo para los textos de las habilidades.
- **Core:** `Internationalize`, `es.json`.
- **Arte:** `build_assets.py`.

## Cómo probarlo

- Sin la Torre, la pestaña dice "Construye la Torre de magia".
- Con la Torre y 60 de oro se aprende *Golpe doble*: el Poder sube un 10 %.
- En la arena (si C1 y C2 están), se ve "¡Golpe doble!" en el tercer ataque.
- Tests: casos de uso con cada resultado, `forest_bloc_test.dart`, `hero_panel_test.dart` (pestaña), `skills_test.dart` (el catálogo cubre todo `SkillId`).
