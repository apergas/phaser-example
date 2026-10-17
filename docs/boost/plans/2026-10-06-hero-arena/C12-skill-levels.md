# C12 · Niveles de habilidad del héroe — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-arena/C12-skill-levels.md`, con las tablas de equilibrado y de economía completas).

| | |
|---|---|
| **Rama** | `feature/PROJECT-C12-skill-levels`, desde `feature/PROJECT-X-arena` |
| **Depende de** | C9 (costes con maná) y C11 (equilibrado con las habilidades de los enemigos) |
| **Issue / milestone** | `phase:C12` · milestone `C12 Skill levels` · #59 |
| **Referencia iOS** | merge `c6a2107` (`[PROJECT-C12]: Merge the skill levels`), commits `c494924` (combate) y `6ff3310` (panel) |

## Objetivo

Cada habilidad del héroe tiene 3 niveles. Aprenderla es el nivel 1; *Mejorar* sube al siguiente, pagando más, y mejora su efecto.

## Decisiones ya tomadas

**Representación:**
- `HeroEntity.skillLevels: Map<SkillId, int>` sustituye al conjunto de habilidades. Sin entrada = no aprendida; los valores van de 1 a 3, con `assert`.
- En `HeroRules`:
  - `levelOf(skill)`;
  - `skills` (calculado, `Set<SkillId>`, para quien solo pregunta si la conoce: misiones y combate);
  - `withSkill(skill, level)`.
- Recorrer siempre `SkillId.values`, nunca el mapa.

**Catálogo:** `SkillEntity.costs` es una lista con un coste por nivel (`costs[0]` es el nivel 1), con `maxLevel` (= 3) y `costOf(level)`. Costes de oro / maná (×1,5 y ×2,25, con los .5 redondeados hacia arriba al múltiplo de 5):

| Habilidad | Nv 1 | Nv 2 | Nv 3 |
|---|---|---|---|
| *Golpe doble* | 60 / 20 | 90 / 30 | 135 / 45 |
| *Esquiva* | 90 / 30 | 135 / 45 | 205 / 70 |
| *Segundo aliento* | 130 / 45 | 195 / 70 | 295 / 100 |

**Efectos por nivel** (`Rules`):
- `doubleStrikeEvery` = 3 en todos los niveles; el segundo golpe hace `+0 / +15 / +30 %` (`doubleStrikeBonusByLevel`): el daño, ya restada la defensa, por `1 + bonificación`, redondeado y sin pasar de la vida que le queda al enemigo.
- *Esquiva* `20 / 25 / 30 %` (`dodgeChanceByLevel`).
- *Segundo aliento* cura `40 / 50 / 60 %` (`secondWindHealByLevel`).
- **Sin tiradas nuevas:** en nivel 1 el registro es idéntico al de antes, byte a byte.
- Los enemigos con habilidades (C11) usan el nivel 1 (`Rules.enemySkillLevel`) y sus probabilidades no cambian.

**Poder:** `HeroRules.power` cuenta la suma de niveles (10 % por nivel, `Rules.powerPerSkill`). En nivel 1 da lo de siempre, y mejorar se nota en la lista de la arena.

**Estados y resultados** (enums de core; aún no se guardan, así que se pueden quitar casos):
- `SkillOptionState` pasa a `available, needsBuilding, unaffordable, maxed` (sin `known`).
- `LearnSkillResult` pasa a `ok, missingBuilding, notEnoughResources, upgraded, maxed` (sin `alreadyKnown`).
- `LearnSkillUseCase` aprende el nivel 1 o sube al siguiente. Comprueba, en este orden: torre de magia, máximo, recursos.
- `SkillOptionEntity` gana `level` (0 = sin aprender), `nextLevel` y `nextCost` (`null` en el máximo).

**Equilibrado** (regla del test de balance más un techo nuevo): el héroe esperado con sus habilidades en **nivel 3** gana ≤ 95 % con las semillas 0–99 y 0–999. Victorias con 0–99 / 0–999:

| Nivel | Nv 1 | Nv 2 | Nv 3 |
|---|---|---|---|
| 7 | 73,0 / 75,1 % | 83,0 / 85,6 % | 88,0 / 91,5 % |
| 8 | 78,0 / 71,9 % | 86,0 / 83,4 % | 94,0 / 93,3 % |
| 9 | 79,0 / 74,0 % | 86,0 / 86,8 % | 93,0 / 93,7 % |
| 10 | 64,0 / 60,8 % | 80,0 / 76,8 % | 91,0 / 88,7 % |

- La columna *Nv 1* es la de C11. Un paso por detrás con nivel 3 sigue < 50 %.
- Subir a nivel 3 las dos habilidades del héroe esperado cuesta unas 10 repeticiones del jefe. Flutter debe dar las mismas cifras (mismo dominio y mismo `SeededRandom`).
- Comprobación cruzada opcional, como en C11, contra `$IOS/build/c12-parity/out-final/m2-combat.txt` (22766 líneas; las 19970 primeras son las de C11).

**Panel *Héroe*, pestaña *Habilidades*** (`SkillTile`, `SkillItemData` con `levelText`, `nextText` y `buttonText`). La ficha de cada habilidad enseña:
- el nombre con "Nv 2/3" al lado, solo si está aprendida;
- la descripción del nivel actual (la del 1 si no está aprendida);
- "Nv 3: <efecto>", solo si está aprendida y no está al máximo;
- el coste del **siguiente** nivel y el motivo si no se puede;
- el botón *Aprender* (nivel 0) o *Mejorar* (1–2), o el texto *Máximo* (nivel 3) en el color de "hecho".

Al mejorar sale el *snackbar* "Has mejorado: Esquiva (Nv 2)" y las mismas chispas azules que al aprender (`SkillLearnedEffect`).

**Textos nuevos** (los de iOS):
- `forest.hero.skillLevel` "Nv {level}/{max}"
- `forest.hero.skillMax` "Máximo"
- `forest.hero.skillNext` "Nv {level}: {effect}"
- `forest.hero.upgrade` "Mejorar"
- `forest.message.skillMaxLevel` "Esa habilidad ya está al nivel máximo."
- `forest.message.skillUpgraded` "Has mejorado: {name} (Nv {level})"
- `forest.skill.<habilidad>.description.level2` / `level3`, para las tres habilidades:
  - *Esquiva*: "Un 25 % / 30 % de posibilidades de esquivar cada golpe."
  - *Golpe doble*: "Cada tercer ataque golpea dos veces y el segundo golpe hace un 15 % / 30 % más de daño."
  - *Segundo aliento*: "Una vez por pelea, por debajo del 30 % de vida recupera el 50 % / 60 %."

Se quita `forest.message.skillAlreadyKnown`. `forest.hero.known` deja de usarse y se queda.

**Guardado:** F2 guarda `skillLevels` desde su versión 1 (y valida al cargar que cada nivel esté entre 1 y el máximo).

## Ficheros previstos

- **Dominio:** `entities/hero/hero_entity.dart`, `skill_entity.dart`, `skill_option_entity.dart`, `world/extensions/hero_rules.dart`, `rules/skills.dart`, `rules/rules.dart`, `combat/combat.dart`, `use-cases/hero/learn_skill_use_case.dart`, `get_skill_options_use_case.dart`, misiones que miren las habilidades (`quests/quests.dart`).
- **Core:** `skill_option_state.dart`, `learn_skill_result.dart`, `es.json`, `internationalize.dart`.
- **Presentación:** `features/forest/models/skill_item_data.dart`, `widgets/skill_tile.dart`, `bloc/forest_bloc.dart`.
- **Docs:** `docs/GAME_DESIGN.md` 3.8, `CLAUDE.md`.

## Cómo probarlo

- Aprender *Golpe doble* y mejorarlo dos veces: la ficha pasa por Nv 1/3, 2/3 y 3/3 (*Máximo*), cada vez cobra el coste de la tabla y la lista de la arena sube el poder.
- Una pelea con *Esquiva* en nivel 3 esquiva más a menudo.
- Tests:
  - `combat_test.dart`:
    - goldens en niveles 2 y 3 (daño extra, esquiva 25/30 %, curación 50/60 %);
    - el nivel 1 es igual al registro de antes;
  - `learn_skill_use_case_test.dart`: aprender, mejorar, máximo, sin recursos y sin torre, con ese orden de comprobación;
  - `hero_rules_test.dart`: `levelOf`, `skills`, `withSkill` y `power` con niveles;
  - `skills_test.dart`: costes por nivel;
  - `skill_tile_test.dart` y `forest_bloc_test.dart`: textos por nivel y estado, y el *snackbar* al mejorar;
  - `balance_test.dart` con el techo del nivel 3 (≤ 95 %).
