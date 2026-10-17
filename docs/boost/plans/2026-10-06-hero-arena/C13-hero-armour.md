# C13 · Armadura visible del héroe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (arena) |
| **Rama** | `feature/PROJECT-C13-hero-armour`, desde `feature/PROJECT-X-arena` (C9–C12 dentro) |
| **Issue / milestone** | `phase:C13` · milestone `C13 Hero armour` · #67 |
| **Depende de** | C12 |
| **Referencia iOS** | Ninguna: no está en iOS. Antes era una mejora sin fase; el 2026-10-17 el usuario la convirtió en la fase C13. |

**Goal:** Igual que el héroe cambia de arma en la arena (hacha → espada corta → de hierro → de acero), cambia de aspecto al comprar armadura (ropa de trabajo → cuero → cota de malla → placas).

**Architecture:** Arte: `build_assets.py` compone 16 juegos del héroe (4 armas × 4 armaduras) con el mismo camino de las armas (`ARENA_FIGHTERS`, capas LPC precompuestas, 17 frames por juego), con capas nuevas en `asset-packs/lpc/sources/armour/`. Presentación: `FighterRenderData.armor` (`GearId?`), que `ArenaBloc` rellena junto al arma, y `ArenaSpriteNames.heroWith(weapon, armor)` elige el juego. Ni dominio, ni datos, ni DI, ni Flame (solo nombres de frames).

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame; Python 3 + Pillow para el atlas. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario, 2026-10-17):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar o cambien de resultado están listados en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque de la arena. En su lugar, el arte se revisa **mirando** recortes del atlas regenerado (Pillow en el *scratchpad* y la herramienta Read sobre el PNG).
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Mientras `test/` no compila no se usa `flutter analyze` a secas.
- `python3 build_assets.py` (desde `asset-packs/lpc/`) solo puede cambiar `arena.png` y `arena.json`: `forest.png`, `forest.json`, `ground.png` y los `hero-*.png` del bosque quedan idénticos byte a byte (`git status` lo dice).
- En el bosque el jugador sigue sin mostrar equipo.
- Arte LPC: solo capas CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0 / CC-BY 3.0 / CC-BY 4.0, bajadas de `raw.githubusercontent.com` del generador en el commit `58ce1aa479e4df32845a73a5d0afc221c3a893c2`, acreditadas en `asset-packs/lpc/sources/armour/CREDITS-armour.txt` y en `lib/core/assets/images/lpc/CREDITS.md`.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-C13]: <frase en inglés en imperativo>`.
- No se tocan `di.config.dart` ni `*.mocks.dart` (C13 no cambia DI).

## Decisiones

1. **Juegos precompuestos por combinación** (decisión del usuario): 16 juegos del héroe, cada uno con 2 frames de reposo, 9 de andar y 6 de golpe, como los de hoy. El orden de capas del arma (detrás o delante del cuerpo según el frame) sale solo, porque la armadura es parte del cuerpo y el arma se compone igual que antes (`armed_sheets`). Se valoró la armadura como capa aparte dibujada por Flame y se descartó (ver la ficha original en el historial).
2. **Nombres:** `hero[-<arma>][-<armadura>]`. La armadura de tier 0 (*Ropa de trabajo*) no lleva sufijo, así que los cuatro juegos de hoy (`hero`, `hero-short-sword`, `hero-iron-sword`, `hero-steel-sword`) **no cambian de nombre**. Sufijos de armadura: `-leather` (*Armadura de cuero*), `-chain-mail` (*Cota de malla*), `-plate` (*Armadura de placas*). Ejemplos: `hero-leather`, `hero-short-sword-chain-mail`, `hero-steel-sword-plate`.
3. **Capas por tier** (de abajo arriba, mismo orden `zPos` que el generador: piernas 20, camisa 35, malla 50, armadura de torso/brazos/hombreras 60, brazales 70, cabeza, pelo, casco):

   | Tier | Armadura | Capas sobre la ropa de trabajo | Origen |
   |---|---|---|---|
   | 0 | Ropa de trabajo | — (`CHARACTER_LAYERS` de hoy) | `sources/character/` |
   | 1 | Armadura de cuero | `torso_armour_leather_male` + `arms_bracers_male` sobre la camisa verde | `sources/barbarians/` (ya en el repo) |
   | 2 | Cota de malla | `torso_chainmail_male` sobre la camisa verde (las mangas verdes asoman en los brazos) | `sources/armour/` (nueva) |
   | 3 | Armadura de placas | `legs_armour_plate_male` **en lugar** de los pantalones, la camisa, `torso_chainmail_male` (asoma por debajo del peto), `torso_armour_plate_male`, `arms_armour_plate_male`, `shoulders_pauldrons_male` y el yelmo `hat_helmet_nasal_adult` encima del pelo | `sources/armour/` |

   - Ninguna capa nueva se recolorea: el cuero es marrón y el metal gris acero de origen.
   - **Yelmo:** se probaron `kettle` (ala ancha: tapa media cara y se lee como sombrero), `armet_simple` (cierra la cara: se pierde al héroe) y `nasal`. Se elige `nasal`: deja ver la cara, tapa el pelo sin dejar mechones raros y distingue las placas de la malla de un vistazo (las dos son grises).
4. **Capas bajadas** (`asset-packs/lpc/sources/armour/`, `<nombre>__{idle,walk,slash}.png` desde `spritesheets/<ruta>/{idle,walk,slash}.png`):

   | Nombre | Ruta en el generador | Autores | Licencias |
   |---|---|---|---|
   | `torso_chainmail_male` | `torso/chainmail/male` | Johannes Sjölund (wulax), Napsio (Vitruvian Studio), JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | `torso_armour_plate_male` | `torso/armour/plate/male` | Napsio (Vitruvian Studio), JaidynReiman, bluecarrot16, Michael Whitlock (bigbeargames), Johannes Sjölund (wulax) | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | `arms_armour_plate_male` | `arms/armour/plate/male` | Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | `shoulders_pauldrons_male` | `shoulders/pauldrons/male` | Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | `legs_armour_plate_male` | `legs/armour/plate/male` | bluecarrot16, JaidynReiman, Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax) | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
   | `hat_helmet_nasal_adult` | `hat/helmet/nasal/adult` | bluecarrot16 | CC-BY 3.0, CC-BY 4.0, OGA-BY 3.0, GPL 2.0, GPL 3.0 |

   Todas existen en el commit `58ce1aa` con `idle`, `walk` y `slash`, y todas tienen una licencia aceptada. `zPos` comprobados en `sheet_definitions/` del mismo commit (`torso_chainmail.json` 50, `torso/armour/torso_armour_plate.json` 60, `arms/arms_armour.json` 60, `arms/shoulders/shoulders_pauldrons.json` 60, `arms/wrists/arms_bracers.json` 70, `legs/legs_armour.json` 20).
5. **Tamaño del atlas:** `arena.png` pasa de 1024 × 1370 (110 KB) a 1024 × 3328 (261 KB; `arena.json` de 50 a 119 KB) (12 juegos nuevos de 11 frames de 64 px y 6 de 128 px). Sigue por debajo de 4096, el máximo seguro de textura en WebGL y en móviles; no se cambia el ancho del empaquetado.
6. **Presentación:** `FighterRenderData.armor` (`GearId?`, por defecto `null`, en `==` y `hashCode`); `ArenaBloc._heroArmor` (`GearId.workClothes` al empezar) se calcula con `Gear.of(GearSlot.armor, status.hero.armorTier).id` en `_previewFighters`, junto a `_heroWeapon`, y se pasa en los dos sitios donde se pasa el arma (`_previewFighters` y `_replayFighter`, solo al héroe). `ArenaSpriteNames.heroWith(GearId? weapon, GearId? armor)` con dos `switch` exhaustivos (uno por sufijo); `ArenaSpriteNames.fighter(kind, {weapon, armor})`; `ArenaFrames.frameName` pasa `armor: fighter.armor`.

## Reparto

| Tarea | Qué |
|---|---|
| TC13.1 | Arte: capas nuevas, 16 juegos del héroe en `arena.png`, créditos |
| TC13.2 | La arena elige el juego por arma y armadura (`FighterRenderData.armor`, `ArenaSpriteNames`, `ArenaFrames`, `ArenaBloc`) |
| TC13.3 | Cierre: T1, `PROGRESS.md`, README y `CLAUDE.md` |

---

### Task TC13.1: Juegos del héroe con armadura en el atlas de la arena

**Files:**
- Create: `asset-packs/lpc/sources/armour/` (18 PNG) y `asset-packs/lpc/sources/armour/CREDITS-armour.txt`
- Modify: `asset-packs/lpc/build_assets.py` (docstring, `ARENA_FIGHTERS` y dos constantes nuevas)
- Regenerate: `lib/core/assets/images/lpc/arena.png`, `lib/core/assets/images/lpc/arena.json`
- Modify: `lib/core/assets/images/lpc/CREDITS.md` (sección *Arena*)

**Interfaces:**
- Consumes: `CHARACTER_LAYERS`, `RECOLOURS`, `armed_sheets`, `build_arena` (sin cambios).
- Produces: frames `hero[-short-sword|-iron-sword|-steel-sword][-leather|-chain-mail|-plate]-{idle-0..1,walk-0..8,slash-0..5}` en `arena.json`, que TC13.2 nombra.

- [ ] **Step 1: Bajar las capas** (desde `asset-packs/lpc/`)

```sh
B=https://raw.githubusercontent.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator/58ce1aa479e4df32845a73a5d0afc221c3a893c2/spritesheets
mkdir -p sources/armour
for entry in torso/chainmail/male:torso_chainmail_male torso/armour/plate/male:torso_armour_plate_male \
  arms/armour/plate/male:arms_armour_plate_male shoulders/pauldrons/male:shoulders_pauldrons_male \
  legs/armour/plate/male:legs_armour_plate_male hat/helmet/nasal/adult:hat_helmet_nasal_adult; do
  path=${entry%%:*}; name=${entry##*:}
  for animation in idle walk slash; do
    curl -sfo sources/armour/${name}__${animation}.png $B/$path/$animation.png || echo "missing $path $animation"
  done
done
ls sources/armour | wc -l
```
Esperado: ningún `missing` y 18 ficheros.

- [ ] **Step 2: `sources/armour/CREDITS-armour.txt`** (mismo formato que `CREDITS-barbarians.txt`; autores, licencias y URL de `CREDITS.csv` del mismo commit)

```text
Hero armour in the arena (used by build_assets.py -> arena.png)
================================================================

Layers of the Universal LPC Spritesheet Character Generator, commit 58ce1aa479e4df32845a73a5d0afc221c3a893c2:
https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator
Each file is spritesheets/<path>/{idle,walk,slash}.png, renamed to <name>__{idle,walk,slash}.png.
The leather armour and the bracers are the barbarians' (sources/barbarians, CREDITS-barbarians.txt).

torso_chainmail_male        <- torso/chainmail/male
  Johannes Sjölund (wulax), Napsio (Vitruvian Studio), JaidynReiman
  minor edits by bluecarrot16, reduced colors by Napsio, adjusted Male colors and Idle/Sit/Emote/Climb/Run by JaidynReiman
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites

torso_armour_plate_male     <- torso/armour/plate/male
  Napsio (Vitruvian Studio), JaidynReiman, bluecarrot16, Michael Whitlock (bigbeargames), Johannes Sjölund (wulax)
  original by wulax, recolor by bigbeargames, color reduced to 7 colors and adapted to v3 bases by bluecarrot16,
  run/jump/sit/climb/revised combat by JaidynReiman, reduced colors to 6 (based on Napsio's Vitruvian)
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  https://opengameart.org/content/lpc-combat-armor-for-women

arms_armour_plate_male      <- arms/armour/plate/male
  Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman
  original by wulax, recolors by bigbeargames; adapted to v3 bases and further recolors by bluecarrot16,
  climb/emote/jump by JaidynReiman
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  http://opengameart.org/content/lpc-clothing-updates

shoulders_pauldrons_male    <- shoulders/pauldrons/male
  Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman
  adapted to female base by makrohn, adapted to v3 bases by bluecarrot16, climb/jump/sit/emote/run/revised combat by
  JaidynReiman
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  http://opengameart.org/content/lpc-clothing-updates

legs_armour_plate_male      <- legs/armour/plate/male
  bluecarrot16, JaidynReiman, Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax)
  reduced to 7 colors and adapted to v3 bases by bluecarrot16, climb/jump/sit/emote/run by JaidynReiman
  OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0
  https://opengameart.org/content/lpc-medieval-fantasy-character-sprites

hat_helmet_nasal_adult      <- hat/helmet/nasal/adult
  bluecarrot16
  CC-BY 3.0, CC-BY 4.0, OGA-BY 3.0, GPL 2.0, GPL 3.0
  https://opengameart.org/content/lpc-helmets
  https://opengameart.org/content/lpc-expanded-hats-facial-helmets
```

- [ ] **Step 3: `build_assets.py`** — sustituir el bloque de `ARENA_FIGHTERS` (y su comentario) por:

```python
# Hero armour suffix -> layers, bottom to top (same zPos order as the generator). No suffix: the work clothes of the
# forest. Leather: the barbarians' armour and bracers over the shirt. Chain mail: over the shirt. Plate: plate legs
# instead of the pants, chain mail under the breastplate, plate arms, pauldrons and the nasal helmet over the hair.
HERO_ARMOURS = {
    "": CHARACTER_LAYERS,
    "-leather": [
        *CHARACTER_LAYERS[:4],
        ("barbarians", "torso_armour_leather_male"),
        ("barbarians", "arms_bracers_male"),
        *CHARACTER_LAYERS[4:],
    ],
    "-chain-mail": [*CHARACTER_LAYERS[:4], ("armour", "torso_chainmail_male"), *CHARACTER_LAYERS[4:]],
    "-plate": [
        ("character", "body_bodies_male"),
        ("character", "feet_boots_basic_male"),
        ("armour", "legs_armour_plate_male"),
        ("character", "torso_clothes_longsleeve_longsleeve_male"),
        ("armour", "torso_chainmail_male"),
        ("armour", "torso_armour_plate_male"),
        ("armour", "arms_armour_plate_male"),
        ("armour", "shoulders_pauldrons_male"),
        ("character", "head_heads_human_male"),
        ("character", "hair_plain_adult"),
        ("armour", "hat_helmet_nasal_adult"),
    ],
}
# Hero weapon suffix -> the axe or a sword sheet in sources/tools (the LPC arming sword in bronze, iron or steel).
HERO_WEAPONS = {"": "axe", "-short-sword": "sword-bronze", "-iron-sword": "sword-iron", "-steel-sword": "sword-steel"}
# Fighter -> (recolours, LPC row, layers, weapon): the hero faces right (row 3), the enemies face left (row 1). The
# hero has one set per weapon and armour: hero[-<weapon>][-<armour>].
ARENA_FIGHTERS = {
    **{
        f"hero{weapon_suffix}{armour_suffix}": (RECOLOURS, 3, layers, weapon)
        for weapon_suffix, weapon in HERO_WEAPONS.items()
        for armour_suffix, layers in HERO_ARMOURS.items()
    },
    "bandit": (BANDIT_RECOLOURS, 1, CHARACTER_LAYERS, "axe"),
    "bandit-veteran": (VETERAN_RECOLOURS, 1, CHARACTER_LAYERS, "sword-iron"),
    "barbarian": (BARBARIAN_RECOLOURS, 1, BARBARIAN_LAYERS, "axe"),
    "barbarian-chief": (CHIEF_RECOLOURS, 1, CHIEF_LAYERS, "axe"),
}
```

Y en el docstring, la línea de `arena.png` pasa a decir "the hero (with the axe and each sword, in each armour: work clothes, leather, chain mail, plate)".

- [ ] **Step 4: Regenerar** — `cd asset-packs/lpc && python3 build_assets.py`; luego `git status --short lib/core/assets/images/lpc`.
Esperado: solo `M arena.png` y `M arena.json`. Anotar el tamaño de `arena.png` antes y después (`python3 -c "from PIL import Image; print(Image.open('lib/core/assets/images/lpc/arena.png').size)"`) y que `arena.json` tiene 16 × 17 = 272 frames `hero*`.

- [ ] **Step 5: Mirar el arte** — un script en el *scratchpad* (fuera del repo) recorta del atlas regenerado, por cada uno de los 16 juegos, `idle-0`, `walk-3` y los `slash-0..5`, los pega en una rejilla (una fila por juego, fondo verde, ×2 con `NEAREST`) y la guarda en PNG; se abre con Read. Comprobar: cada armadura se distingue de las demás; el arma queda detrás del cuerpo en los frames de preparación y delante en el golpe igual que con la ropa de trabajo; ninguna capa de armadura tapa la mano que agarra la espada; el yelmo no deja pelo por encima; los frames del juego `hero` y `hero-short-sword` (tier 0) son idénticos a los de antes (comparar con el `arena.png` de `HEAD`).

- [ ] **Step 6: `CREDITS.md`** — en *Arena*, tras *Swords*, una subsección:

```markdown
### Hero armour (`hero-*-leather-*`, `hero-*-chain-mail-*`, `hero-*-plate-*` and the same without a weapon)

The hero's leather armour is the barbarians' leather armour and bracers (see *Barbarians* below). The chain mail
and the plate armour are layers of the [Universal LPC Spritesheet Character Generator](https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator)
(commit 58ce1aa) in `asset-packs/lpc/sources/armour/` (see `CREDITS-armour.txt` there), not recoloured.

| Layer | Authors | Licences |
|---|---|---|
| Chain mail | Johannes Sjölund (wulax), Napsio (Vitruvian Studio), JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Plate breastplate | Napsio (Vitruvian Studio), JaidynReiman, bluecarrot16, Michael Whitlock (bigbeargames), Johannes Sjölund (wulax) | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Plate arms | Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Pauldrons | Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Plate legs | bluecarrot16, JaidynReiman, Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax) | OGA-BY 3.0, CC-BY-SA 3.0, GPL 3.0 |
| Nasal helmet | bluecarrot16 | CC-BY 3.0, CC-BY 4.0, OGA-BY 3.0, GPL 2.0, GPL 3.0 |

Sources: <https://opengameart.org/content/lpc-medieval-fantasy-character-sprites>,
<https://opengameart.org/content/lpc-combat-armor-for-women>,
<http://opengameart.org/content/lpc-clothing-updates>, <https://opengameart.org/content/lpc-helmets>,
<https://opengameart.org/content/lpc-expanded-hats-facial-helmets>
```

Y en el párrafo de *Arena*, "the hero's swords and the veteran's sword are the arming sword (see *Swords* below)" pasa a añadir "and the hero's armour is described in *Hero armour* below".

- [ ] **Step 7: Commit** — `git add asset-packs/lpc lib/core/assets/images/lpc` y, aparte, `git commit -m "[PROJECT-C13]: Compose the hero armour frames"`.

### Task TC13.2: La arena elige el juego por arma y armadura

**Files:**
- Modify: `lib/layers/presentation/features/arena/models/fighter_render_data.dart`
- Modify: `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
- Modify: `lib/layers/presentation/features/arena/game/render/arena_frames.dart:16`
- Modify: `lib/layers/presentation/features/arena/bloc/arena_bloc.dart:49, 277, 287, 351`

**Interfaces:**
- Consumes: los nombres de frames de TC13.1; `Gear.of(GearSlot, int)`, `HeroEntity.armorTier`.
- Produces: `FighterRenderData({..., GearId? weapon, GearId? armor})`; `ArenaSpriteNames.heroWith(GearId? weapon, GearId? armor)`; `ArenaSpriteNames.fighter(EnemyKind? kind, {GearId? weapon, GearId? armor})`.

- [ ] **Step 1: `fighter_render_data.dart`** — campo `final GearId? armor;` tras `weapon`, parámetro `this.armor,` tras `this.weapon,`, `&& other.armor == armor` en `==` y `armor` al final de `Object.hash(...)`:

```dart
  @override
  int get hashCode =>
      Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress, targetIndex, isTargeted, weapon, armor);
```

- [ ] **Step 2: `arena_sprite_names.dart`** — sustituir `heroWith` y `fighter` por:

```dart
  static String heroWith(GearId? weapon, GearId? armor) => '$hero${_weaponSuffix(weapon)}${_armorSuffix(armor)}';

  static String fighter(EnemyKind? kind, {GearId? weapon, GearId? armor}) =>
      kind == null ? heroWith(weapon, armor) : enemy(kind);

  static String _weaponSuffix(GearId? weapon) => switch (weapon) {
    GearId.shortSword => '-short-sword',
    GearId.ironSword => '-iron-sword',
    GearId.steelSword => '-steel-sword',
    null ||
    GearId.woodcutterAxe ||
    GearId.workClothes ||
    GearId.leatherArmor ||
    GearId.chainMail ||
    GearId.plateArmor => '',
  };

  static String _armorSuffix(GearId? armor) => switch (armor) {
    GearId.leatherArmor => '-leather',
    GearId.chainMail => '-chain-mail',
    GearId.plateArmor => '-plate',
    null ||
    GearId.woodcutterAxe ||
    GearId.shortSword ||
    GearId.ironSword ||
    GearId.steelSword ||
    GearId.workClothes => '',
  };
```

- [ ] **Step 3: `arena_frames.dart`** — la primera línea de `frameName`:

```dart
    final name = ArenaSpriteNames.fighter(fighter.enemyKind, weapon: fighter.weapon, armor: fighter.armor);
```

- [ ] **Step 4: `arena_bloc.dart`**
  - Junto a `GearId _heroWeapon = GearId.woodcutterAxe;`: `GearId _heroArmor = GearId.workClothes;`
  - En `_previewFighters`, tras la línea de `_heroWeapon`: `_heroArmor = Gear.of(GearSlot.armor, status.hero.armorTier).id;`
  - En el `FighterRenderData` del héroe de `_previewFighters`, tras `weapon: _heroWeapon,`: `armor: _heroArmor,`
  - En `_replayFighter`, tras `weapon: side == FightSide.hero ? _heroWeapon : null,`: `armor: side == FightSide.hero ? _heroArmor : null,`

- [ ] **Step 5: Verificar**

```sh
dart format --line-length 120 lib/layers/presentation/features/arena/models/fighter_render_data.dart lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart lib/layers/presentation/features/arena/game/render/arena_frames.dart lib/layers/presentation/features/arena/bloc/arena_bloc.dart
flutter analyze lib
```
Esperado: `No issues found!`. Y que los 16 nombres que da `heroWith` existen en `arena.json`: un script en el *scratchpad* comprueba `hero{w}{a}-idle-0` para `w` en `"", -short-sword, -iron-sword, -steel-sword` y `a` en `"", -leather, -chain-mail, -plate`.

- [ ] **Step 6: Commit** — `git add lib/layers/presentation/features/arena` y, aparte, `git commit -m "[PROJECT-C13]: Show the hero armour in the arena"`.

### Task TC13.3: Cierre de la fase

**Files:** `docs/boost/plans/2026-10-17-extras/T1-tests.md`, `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-06-hero-arena/README.md`, `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **C13** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila C13 → `✅`, nota "Sin tests (T1)"; `README.md`: icono de C13 → ✅.
- [ ] **Step 3:** `CLAUDE.md`: en la descripción del renderizado de la arena, el héroe lleva su arma **y su armadura** (`FighterRenderData.armor`, `ArenaSpriteNames.heroWith(weapon, armor)`: juegos precompuestos `hero[-<arma>][-<armadura>]`, cuero, malla, placas con yelmo nasal); en `asset-packs/` y créditos, `sources/armour/`. Sin repetir menciones.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); `git commit -m "[PROJECT-C13]: Close the hero armour phase"` (comando aparte).

## Prueba manual

Se hace una vez con el bloque de la arena, en Chrome y Android:

1. Partida nueva, arena: el héroe con hacha y ropa de trabajo, como antes.
2. Con la Armería y oro: comprar *Armadura de cuero*, abrir la arena: peto de cuero y brazales sobre la camisa verde, en reposo, al andar y al golpear.
3. Comprar *Cota de malla* y *Armadura de placas*: malla gris con mangas verdes; placas con hombreras, grebas y yelmo nasal.
4. Con cada armadura, comprar las espadas en la Herrería: el arma se ve igual que con la ropa de trabajo (detrás del cuerpo al preparar el golpe, delante al golpear).
5. En el bosque el jugador sigue sin equipo.

## Para T1

Tests que dejan de compilar o cambian de resultado por C13 (no se ha tocado `test/`):

- **No compila:** `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart` llama a `ArenaSpriteNames.heroWith(weapon)` con un argumento: pasa a `heroWith(weapon, armor)` recorriendo las 4 armas × 4 armaduras (`GearId.workClothes`, `leatherArmor`, `chainMail`, `plateArmor` y `null`), comprobando que los 17 frames de cada juego existen en `arena.json` y que los nombres son distintos entre sí; `fighter(null)` sigue siendo `hero` y `heroWith(null, null)` también.
- **Cambian de resultado:** `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart` compara con `FighterRenderDataMock.heroIdle`, `heroAfterBeatingTheRookie` y `heroSwinging(...)` (y `ArenaDataMock`, que los usa), que no tienen `armor`; el bloc ahora da `armor: GearId.workClothes`. Añadir `armor: GearId.workClothes` a los mocks del héroe en `test/mocks/presentation/features/arena/fighter_render_data_mock.dart` (y a `heroWithSteelSwordIdle`).
- **Nuevos:**
  - `arena_sprite_names_test.dart`: `heroWith(GearId.steelSword, GearId.plateArmor)` → `hero-steel-sword-plate`; `heroWith(null, GearId.leatherArmor)` → `hero-leather`; con `workClothes` o `null` de armadura, los nombres de antes.
  - `fighter_render_data_test.dart` (si existe; si no, en el test del modelo): `armor` en `==` y `hashCode`.
  - `arena_frames_test.dart`: `frameName` de un héroe con armadura usa su juego (mock nuevo `FighterRenderDataMock.heroInPlateIdle` con `weapon: GearId.steelSword, armor: GearId.plateArmor` → `hero-steel-sword-plate-idle-0`).
  - `arena_bloc_test.dart`: con un héroe de `armorTier: 2` (mock de sesión), el héroe de la vista previa y de la repetición lleva `armor: GearId.chainMail`; los enemigos, `null`.
  - `arena_assets_test.dart` / `ArenaAssetsMock`: el mock solo construye frames de `ArenaSpriteNames.hero` y los enemigos; si algún test pinta un héroe con armadura, añadir sus frames al mock.
