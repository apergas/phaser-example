# Fase 6 — Mundo con Flame: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dibujar el bosque con Flame exactamente como la web Phaser actual: suelo, decoración, árboles con toque por píxel y animaciones de golpe/caída, hacha flotante, casas por fases con barra de progreso, jugador animado con las hojas LPC, fantasma de colocación, partículas y cámara, todo alimentado por el `ForestBloc` de la fase 5.

**Architecture:** Todo vive en `lib/layers/presentation/features/forest/game/`. La lógica pura (nombres de sprites, atlas, máscara alfa, curvas de animación, selección de fotogramas, encuadre de cámara, partículas de forma cerrada) se separa en clases sin estado para poder testearla sin motor. Los componentes Flame solo pintan. `ForestSceneComponent` recibe `ForestData` (`show(data)`): reproduce `data.effects`, reconcilia los componentes por id con `data.world` y coloca jugador y fantasma. `ForestStateListener` (con `FlameBlocListenable`) le pasa cada estado del BLoC. `ForestWorld` (un `World` de Flame) traduce la entrada a eventos del BLoC, y `ForestGame` envía `ForestTicked` en cada `update` y mueve la cámara.

**Tech Stack:** flame, flame_bloc, flutter_bloc, flame_test, bloc (todos añadidos en la fase 1).

## Global Constraints

- Todas las restricciones del [README](README.md) (sección *Global Constraints*) aplican a cada tarea.
- Port 1:1 de la web publicada (`webApp/src/presentation/**`): mismos valores, tiempos, curvas, colores y orden de pintado. Las diferencias encontradas entre las tres apps actuales y la decisión tomada están en la sección «Desajustes entre apps» al final.
- Prioridad de pintado (`priority`) = `RenderDepth.bySortY(y de la base)`; suelo `RenderDepth.ground`, sombras `RenderDepth.shadow`, fantasma `RenderDepth.overlay`.
- Todos los sprites con `FilterQuality.none`.
- Sin comentarios en `lib/`. Imports relativos en `lib/`; los tests importan `package:rpg/...`.
- `SpriteNames` reutiliza `extension KebabCase on String { String toKebabCase() }` de `lib/core/utils/kebab_case.dart` (fase 3).
- El `ForestBloc` no está en DI: lo crea la `ForestPage` en `BlocProvider.create` (README D4). En esta fase se crea una `ForestPage` mínima (solo `GameWidget`) para ver el mundo; la fase 7 reescribe ese fichero añadiendo HUD, snackbars y Esc.
- Al final de cada tarea: `flutter analyze` → `No issues found!`.

## Contratos que consume (fases 1–5)

- `RenderConstants` (`lib/core/config/constants/render_constants.dart`, fase 1): `cameraZoom`, `tileSize`, `characterFrameSize`, `characterAnchorY`, `rowUp/rowLeft/rowDown/rowRight`, `walkFirstStep`, `walkLastStep`, `walkFps`, `idleColumns`, `idleFps`, `workFrameSize`, `workAnchorY`, `chopSequence`, `hammerSequence`, `houseFrontOffset`. Esta fase **añade** `cameraLerp`, `maxFrameSeconds`, `backgroundColor` y `solidAlpha`.
- Enums `TreeKind`, `DecorationKind`, `Facing`, `WorkTool` (`lib/core/config/constants/enum/`).
- Entidades (README §3.2) con constructores con nombre: `PositionEntity(x:, y:)`, `TreeEntity(id:, kind:, position:, trunkRadius:, woodYield:, hitsToFell:)`, `GroundItemEntity(id:, kind:, position:)`, `DecorationEntity(id:, kind:, position:)`, `BuildingEntity(id:, blueprint:, position:, hitsDone:)` con `progress`, `WorldSnapshotEntity(width:, height:, trees:, items:, decorations:, buildings:)`; `Blueprints.house` (`lib/layers/domain/rules/blueprints.dart`).
- BLoC (fase 5, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart` con `part` de eventos y estado): `ForestTicked(deltaMs:)`, `ForestMapClicked(position:, treeId:, isSecondary:)`, `ForestPointerMoved(position:)`, `ForestStarted()`; `ForestInitial()`, `ForestSuccess(data:)`, `ForestInProgress(data:)`, `ForestFailure(data:, exception:)`; `ForestData(world:, player:, hud:, placement:, effects:)` con `effects` por defecto `const []`.
- Modelos (fase 5, `features/forest/models/`): `PlayerRenderData(position:, facing:, pose:)`, `IdlePose(withAxe:)`, `WalkPose(withAxe:)`, `WorkPose(tool:, swingProgress:)`, `PlacementData(blueprint:, position:, isValid:)`, `ItemPickedUpEffect(itemId:)`, `TreeHitEffect(treeId:, fromX:)`, `TreeFelledEffect(treeId:, fromX:)`, `BuildingPlacedEffect(building:)`, `BuildingHammeredEffect(buildingId:, progress:)`, `BuildingCompletedEffect(buildingId:)`.
- Arte en `lib/core/assets/images/lpc/` declarado en `pubspec.yaml` (fase 1).

## Mapa de ficheros

| Fichero | Responsabilidad |
|---|---|
| `lib/core/config/constants/render_constants.dart` (modificar) | + `cameraLerp`, `maxFrameSeconds`, `backgroundColor`, `solidAlpha` |
| `lib/core/config/constants/enum/forest/player_sheet.dart` | `enum PlayerSheet { walk, idle, walkAxe, idleAxe, chop, hammer }` |
| `lib/core/config/constants/enum/forest/particle_kind.dart` | `enum ParticleKind { woodChip, dust }` |
| `game/atlas/sprite_names.dart` | nombre de fotograma del atlas por tipo |
| `game/atlas/atlas_frame.dart`, `lpc_atlas.dart` | modelo y parser del JSON-hash con `pivot` |
| `game/atlas/alpha_mask.dart` | alfa por píxel de `forest.png` |
| `game/atlas/lpc_assets.dart`, `lpc_assets_loader.dart` | texturas cargadas y su carga |
| `game/render/render_depth.dart` | prioridades |
| `game/render/position_conversion.dart` | `PositionEntity` ⇄ `Vector2` |
| `game/render/easing.dart`, `tree_motion.dart` | curvas de Phaser y animación de árbol |
| `game/render/player_frame.dart`, `player_frames.dart` | fotograma del jugador |
| `game/render/camera_framing.dart` | seguimiento y límites de cámara |
| `game/particles/particle.dart`, `particle_bursts.dart`, `particle_burst_component.dart` | partículas de forma cerrada |
| `game/components/*.dart` | suelo, sprite de atlas, sombra, árbol, objeto, edificio, fantasma, jugador |
| `game/forest_scene_component.dart`, `forest_state_listener.dart`, `forest_world.dart`, `forest_game.dart` | escena, puente con el BLoC, entrada, bucle y cámara |
| `features/forest/forest_page.dart` | página mínima (la reescribe la fase 7) |
| `test/layers/presentation/features/forest/game/**` | tests espejo |
| `test/mocks/presentation/features/forest/game/*`, `test/mocks/presentation/features/forest/forest_bloc_fake.dart` | datos y dobles de test |

(`game/` = `lib/layers/presentation/features/forest/game/`.)

---

### Task 1: Constantes, enums, `SpriteNames`, `RenderDepth` y conversión de posiciones

**Files:**
- Modify: `lib/core/config/constants/render_constants.dart`
- Create: `lib/core/config/constants/enum/forest/player_sheet.dart`, `lib/core/config/constants/enum/forest/particle_kind.dart`
- Create: `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`
- Create: `lib/layers/presentation/features/forest/game/render/render_depth.dart`
- Create: `lib/layers/presentation/features/forest/game/render/position_conversion.dart`
- Test: `test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`, `test/layers/presentation/features/forest/game/render/render_depth_test.dart`

**Interfaces:**
- Consumes: `KebabCase.toKebabCase()` (fase 3), `TreeKind`, `DecorationKind`, `PositionEntity`.
- Produces: `SpriteNames.house|stump|axePickup`, `SpriteNames.tree(TreeKind)`, `SpriteNames.decoration(DecorationKind)`; `RenderDepth.ground|shadow|overlay`, `RenderDepth.bySortY(double)`; `PositionEntity.toVector2()`, `Vector2.toPositionEntity()`; `PlayerSheet`, `ParticleKind`; `RenderConstants.cameraLerp|maxFrameSeconds|backgroundColor|solidAlpha`.

- [ ] **Step 1: Comprobar las dependencias de Flame**

```bash
flutter pub deps --style=compact | grep -E "^- (flame|flame_bloc|flame_test) "
```

Expected: las tres líneas. Si falta alguna: `flutter pub add flame flame_bloc` / `flutter pub add --dev flame_test` y commit aparte `[PROJECT-X]: Add Flame dependencies`.

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart` (port de `SpriteNamesTests.kt`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

void main() {
  test('testWhenNamingSpritesThenFollowsTheAtlasFrameNames', () {
    // given
    const tree = TreeKind.broad;
    const decoration = DecorationKind.tallGrass;

    // when
    final treeName = SpriteNames.tree(tree);
    final decorationName = SpriteNames.decoration(decoration);

    // then
    expect(treeName, 'tree-broad');
    expect(decorationName, 'decor-tall-grass');
  });
}
```

`test/layers/presentation/features/forest/game/render/render_depth_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

void main() {
  test('testWhenSortingByBaseThenLowerOnScreenIsDrawnInFront', () {
    // given
    const behind = 120.0;
    const front = 120.5;

    // when
    final behindPriority = RenderDepth.bySortY(behind);
    final frontPriority = RenderDepth.bySortY(front);

    // then
    expect(behindPriority, 12000);
    expect(frontPriority, 12050);
    expect(RenderDepth.ground < RenderDepth.shadow, isTrue);
    expect(RenderDepth.shadow < RenderDepth.bySortY(0), isTrue);
    expect(RenderDepth.overlay > RenderDepth.bySortY(100000), isTrue);
  });
}
```

- [ ] **Step 3: Ejecutarlos y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart test/layers/presentation/features/forest/game/render/render_depth_test.dart`
Expected: FAIL, `Error when reading 'lib/layers/presentation/features/forest/game/atlas/sprite_names.dart': No such file or directory`.

- [ ] **Step 4: Implementar**

Añadir al final de la clase `RenderConstants` (`lib/core/config/constants/render_constants.dart`), sin tocar lo que creó la fase 1:

```dart
  static const double cameraLerp = 0.1;
  static const double maxFrameSeconds = 0.1;
  static const int backgroundColor = 0xFF0E150E;
  static const int solidAlpha = 200;
```

`lib/core/config/constants/enum/forest/player_sheet.dart`:

```dart
enum PlayerSheet { walk, idle, walkAxe, idleAxe, chop, hammer }
```

`lib/core/config/constants/enum/forest/particle_kind.dart`:

```dart
enum ParticleKind { woodChip, dust }
```

`lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`:

```dart
import '../../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../../core/utils/kebab_case.dart';

abstract final class SpriteNames {
  static const String house = 'house';
  static const String stump = 'stump';
  static const String axePickup = 'axe-pickup';

  static String tree(TreeKind kind) => 'tree-${kind.name.toKebabCase()}';

  static String decoration(DecorationKind kind) => 'decor-${kind.name.toKebabCase()}';
}
```

`lib/layers/presentation/features/forest/game/render/render_depth.dart`:

```dart
abstract final class RenderDepth {
  static const int ground = -2000000;
  static const int shadow = -1000000;
  static const int overlay = 1000000000;

  static int bySortY(double baseY) => (baseY * 100).round();
}
```

`lib/layers/presentation/features/forest/game/render/position_conversion.dart`:

```dart
import 'package:flame/extensions.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';

extension PositionEntityVector on PositionEntity {
  Vector2 toVector2() => Vector2(x, y);
}

extension Vector2PositionEntity on Vector2 {
  PositionEntity toPositionEntity() => PositionEntity(x: x, y: y);
}
```

- [ ] **Step 5: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/config/constants lib/layers/presentation/features/forest/game test/layers/presentation/features/forest/game
git commit -m "[PROJECT-X]: Add sprite names, render depth and world render constants"
```

---

### Task 2: Atlas LPC, máscara alfa y carga de texturas

**Files:**
- Create: `game/atlas/atlas_frame.dart`, `game/atlas/lpc_atlas.dart`, `game/atlas/alpha_mask.dart`, `game/atlas/lpc_assets.dart`, `game/atlas/lpc_assets_loader.dart`
- Create: `test/mocks/presentation/features/forest/game/lpc_assets_mock.dart`, `test/mocks/presentation/features/forest/game/lpc_assets_loader_fake.dart`
- Test: `test/layers/presentation/features/forest/game/atlas/lpc_atlas_test.dart`, `test/layers/presentation/features/forest/game/atlas/alpha_mask_test.dart`, `test/layers/presentation/features/forest/game/atlas/lpc_assets_test.dart`

**Interfaces:**
- Consumes: `SpriteNames`, `RenderConstants.solidAlpha`, `PlayerSheet`.
- Produces:
  - `AtlasFrame({required String name, required int x, required int y, required int width, required int height, required double pivotX, required double pivotY})`
  - `LpcAtlas.parse(String source) → Map<String, AtlasFrame>`
  - `AlphaMask({required int width, required int height, required Uint8List rgba})`, `int alphaAt(int x, int y)`, `static Future<AlphaMask> fromImage(Image)`
  - `LpcAssets({forest, frames, forestMask, ground, heroWalk, heroIdle, heroWalkAxe, heroIdleAxe, heroChop, heroHammer})`, `AtlasFrame frame(String)`, `Sprite sprite(String)`, `bool isOpaque(AtlasFrame, int localX, int localY)`, `Image sheet(PlayerSheet)`
  - `LpcAssetsLoader({AssetBundle? bundle})`, `Future<LpcAssets> load()`
  - Test: `LpcAssetsMock.create()` (fotogramas de 8×8 en (0,0), pivote (0.5, 1) salvo `axe-pickup` (0.5, 0.5); mitad izquierda transparente, mitad derecha opaca), `LpcAssetsLoaderFake(LpcAssets)` con `loadCalled`.

- [ ] **Step 1: Escribir los dobles de test**

`test/mocks/presentation/features/forest/game/lpc_assets_mock.dart`:

```dart
import 'dart:typed_data';
import 'dart:ui';

import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/alpha_mask.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

abstract final class LpcAssetsMock {
  static const int frameSize = 8;

  static final List<String> frameNames = [
    SpriteNames.house,
    SpriteNames.stump,
    SpriteNames.axePickup,
    for (final kind in TreeKind.values) SpriteNames.tree(kind),
    for (final kind in DecorationKind.values) SpriteNames.decoration(kind),
  ];

  static LpcAssets create() {
    final image = _image(frameSize, frameSize);
    return LpcAssets(
      forest: image,
      frames: {
        for (final name in frameNames)
          name: AtlasFrame(
            name: name,
            x: 0,
            y: 0,
            width: frameSize,
            height: frameSize,
            pivotX: 0.5,
            pivotY: name == SpriteNames.axePickup ? 0.5 : 1,
          ),
      },
      forestMask: AlphaMask(width: frameSize, height: frameSize, rgba: _rightHalfOpaque()),
      ground: image,
      heroWalk: image,
      heroIdle: image,
      heroWalkAxe: image,
      heroIdleAxe: image,
      heroChop: image,
      heroHammer: image,
    );
  }

  static Uint8List _rightHalfOpaque() {
    final bytes = Uint8List(frameSize * frameSize * 4);
    for (var y = 0; y < frameSize; y++) {
      for (var x = frameSize ~/ 2; x < frameSize; x++) {
        bytes[(y * frameSize + x) * 4 + 3] = 255;
      }
    }
    return bytes;
  }

  static Image _image(int width, int height) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    return recorder.endRecording().toImageSync(width, height);
  }
}
```

`test/mocks/presentation/features/forest/game/lpc_assets_loader_fake.dart`:

```dart
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets_loader.dart';

class LpcAssetsLoaderFake implements LpcAssetsLoader {
  LpcAssetsLoaderFake(this.assets);

  final LpcAssets assets;
  bool loadCalled = false;

  @override
  Future<LpcAssets> load() async {
    loadCalled = true;
    return assets;
  }
}
```

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/presentation/features/forest/game/atlas/lpc_atlas_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_atlas.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

const _fixture = '''
{
 "frames": {
  "house": {"frame": {"x": 0, "y": 0, "w": 120, "h": 191}, "rotated": false, "pivot": {"x": 0.5, "y": 1}},
  "tree-old": {"frame": {"x": 122, "y": 0, "w": 150, "h": 169}, "pivot": {"x": 0.4067, "y": 0.9941}},
  "no-pivot": {"frame": {"x": 1, "y": 2, "w": 3, "h": 4}}
 },
 "meta": {"image": "forest.png"}
}
''';

void main() {
  test('testWhenParsingTheAtlasThenReadsRectanglesAndPivots', () {
    // given
    const source = _fixture;

    // when
    final frames = LpcAtlas.parse(source);

    // then
    expect(frames['house'], const AtlasFrame(name: 'house', x: 0, y: 0, width: 120, height: 191, pivotX: 0.5, pivotY: 1));
    expect(
      frames['tree-old'],
      const AtlasFrame(name: 'tree-old', x: 122, y: 0, width: 150, height: 169, pivotX: 0.4067, pivotY: 0.9941),
    );
  });

  test('testWhenAFrameHasNoPivotThenUsesTheCentre', () {
    // given
    const source = _fixture;

    // when
    final frame = LpcAtlas.parse(source)['no-pivot'];

    // then
    expect(frame, const AtlasFrame(name: 'no-pivot', x: 1, y: 2, width: 3, height: 4, pivotX: 0.5, pivotY: 0.5));
  });

  test('testWhenParsingTheGeneratedAtlasThenEveryLevelSpriteExists', () {
    // given
    final source = File('lib/core/assets/images/lpc/forest.json').readAsStringSync();
    final expected = [
      SpriteNames.house,
      SpriteNames.stump,
      SpriteNames.axePickup,
      for (final kind in TreeKind.values) SpriteNames.tree(kind),
      for (final kind in DecorationKind.values) SpriteNames.decoration(kind),
    ];

    // when
    final frames = LpcAtlas.parse(source);

    // then
    expect(frames.keys, containsAll(expected));
  });
}
```

`test/layers/presentation/features/forest/game/atlas/alpha_mask_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/alpha_mask.dart';

void main() {
  test('testWhenReadingAlphaThenReturnsTheFourthByteOfThePixel', () {
    // given
    final mask = AlphaMask(width: 2, height: 1, rgba: Uint8List.fromList([10, 20, 30, 0, 40, 50, 60, 255]));

    // when
    final transparent = mask.alphaAt(0, 0);
    final opaque = mask.alphaAt(1, 0);

    // then
    expect(transparent, 0);
    expect(opaque, 255);
  });

  test('testWhenReadingOutsideTheImageThenIsTransparent', () {
    // given
    final mask = AlphaMask(width: 2, height: 1, rgba: Uint8List.fromList([0, 0, 0, 255, 0, 0, 0, 255]));

    // when
    final outside = [mask.alphaAt(-1, 0), mask.alphaAt(2, 0), mask.alphaAt(0, 1)];

    // then
    expect(outside, [0, 0, 0]);
  });
}
```

`test/layers/presentation/features/forest/game/atlas/lpc_assets_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/player_sheet.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('testWhenCheckingAFramePixelThenUsesTheSolidAlphaThreshold', () {
    // given
    final assets = LpcAssetsMock.create();
    final frame = assets.frame(SpriteNames.house);

    // when
    final left = assets.isOpaque(frame, 1, 3);
    final right = assets.isOpaque(frame, 6, 3);
    final outside = assets.isOpaque(frame, 8, 3);

    // then
    expect(left, isFalse);
    expect(right, isTrue);
    expect(outside, isFalse);
  });

  test('testWhenAskingForAnUnknownFrameThenThrows', () {
    // given
    final assets = LpcAssetsMock.create();

    // when
    void lookUp() => assets.frame('tree-palm');

    // then
    expect(lookUp, throwsArgumentError);
  });

  test('testWhenAskingForASpriteThenCutsTheFrameRectangle', () {
    // given
    final assets = LpcAssetsMock.create();

    // when
    final sprite = assets.sprite(SpriteNames.stump);

    // then
    expect(sprite.srcSize.x, 8);
    expect(sprite.srcSize.y, 8);
    expect(assets.sheet(PlayerSheet.chop), same(assets.heroChop));
  });
}
```

- [ ] **Step 3: Ejecutarlos y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/game/atlas`
Expected: FAIL, `No such file or directory` en `atlas_frame.dart`.

- [ ] **Step 4: Implementar**

`game/atlas/atlas_frame.dart`:

```dart
class AtlasFrame {
  final String name;
  final int x;
  final int y;
  final int width;
  final int height;
  final double pivotX;
  final double pivotY;

  const AtlasFrame({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pivotX,
    required this.pivotY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtlasFrame &&
          other.name == name &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height &&
          other.pivotX == pivotX &&
          other.pivotY == pivotY;

  @override
  int get hashCode => Object.hash(name, x, y, width, height, pivotX, pivotY);
}
```

`game/atlas/lpc_atlas.dart`:

```dart
import 'dart:convert';

import 'atlas_frame.dart';

abstract final class LpcAtlas {
  static const double _defaultPivot = 0.5;

  static Map<String, AtlasFrame> parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final frames = json['frames'] as Map<String, dynamic>;
    return frames.map((name, value) {
      final entry = value as Map<String, dynamic>;
      final rect = entry['frame'] as Map<String, dynamic>;
      final pivot = entry['pivot'] as Map<String, dynamic>?;
      return MapEntry(
        name,
        AtlasFrame(
          name: name,
          x: (rect['x'] as num).toInt(),
          y: (rect['y'] as num).toInt(),
          width: (rect['w'] as num).toInt(),
          height: (rect['h'] as num).toInt(),
          pivotX: (pivot?['x'] as num?)?.toDouble() ?? _defaultPivot,
          pivotY: (pivot?['y'] as num?)?.toDouble() ?? _defaultPivot,
        ),
      );
    });
  }
}
```

`game/atlas/alpha_mask.dart`:

```dart
import 'dart:typed_data';
import 'dart:ui';

class AlphaMask {
  final int width;
  final int height;
  final Uint8List _rgba;

  AlphaMask({required this.width, required this.height, required Uint8List rgba}) : _rgba = rgba;

  int alphaAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return _rgba[(y * width + x) * 4 + 3];
  }

  static Future<AlphaMask> fromImage(Image image) async {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    return AlphaMask(width: image.width, height: image.height, rgba: data!.buffer.asUint8List());
  }
}
```

`game/atlas/lpc_assets.dart`:

```dart
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../../../../../../core/config/constants/enum/forest/player_sheet.dart';
import '../../../../../../core/config/constants/render_constants.dart';
import 'alpha_mask.dart';
import 'atlas_frame.dart';

class LpcAssets {
  final Image forest;
  final Map<String, AtlasFrame> frames;
  final AlphaMask forestMask;
  final Image ground;
  final Image heroWalk;
  final Image heroIdle;
  final Image heroWalkAxe;
  final Image heroIdleAxe;
  final Image heroChop;
  final Image heroHammer;

  const LpcAssets({
    required this.forest,
    required this.frames,
    required this.forestMask,
    required this.ground,
    required this.heroWalk,
    required this.heroIdle,
    required this.heroWalkAxe,
    required this.heroIdleAxe,
    required this.heroChop,
    required this.heroHammer,
  });

  AtlasFrame frame(String name) {
    final atlasFrame = frames[name];
    if (atlasFrame == null) throw ArgumentError.value(name, 'name', 'Unknown atlas frame');
    return atlasFrame;
  }

  Sprite sprite(String name) {
    final atlasFrame = frame(name);
    return Sprite(
      forest,
      srcPosition: Vector2(atlasFrame.x.toDouble(), atlasFrame.y.toDouble()),
      srcSize: Vector2(atlasFrame.width.toDouble(), atlasFrame.height.toDouble()),
    );
  }

  bool isOpaque(AtlasFrame atlasFrame, int localX, int localY) {
    if (localX < 0 || localY < 0 || localX >= atlasFrame.width || localY >= atlasFrame.height) return false;
    return forestMask.alphaAt(atlasFrame.x + localX, atlasFrame.y + localY) >= RenderConstants.solidAlpha;
  }

  Image sheet(PlayerSheet sheet) {
    return switch (sheet) {
      PlayerSheet.walk => heroWalk,
      PlayerSheet.idle => heroIdle,
      PlayerSheet.walkAxe => heroWalkAxe,
      PlayerSheet.idleAxe => heroIdleAxe,
      PlayerSheet.chop => heroChop,
      PlayerSheet.hammer => heroHammer,
    };
  }
}
```

`game/atlas/lpc_assets_loader.dart`:

```dart
import 'package:flame/cache.dart';
import 'package:flutter/services.dart';

import 'alpha_mask.dart';
import 'lpc_assets.dart';
import 'lpc_atlas.dart';

class LpcAssetsLoader {
  static const String prefix = 'lib/core/assets/images/';
  static const String atlasPath = 'lpc/forest.json';

  final AssetBundle _bundle;

  LpcAssetsLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<LpcAssets> load() async {
    final images = Images(prefix: prefix, bundle: _bundle);
    final forest = await images.load('lpc/forest.png');
    final atlasSource = await _bundle.loadString('$prefix$atlasPath');
    return LpcAssets(
      forest: forest,
      frames: LpcAtlas.parse(atlasSource),
      forestMask: await AlphaMask.fromImage(forest),
      ground: await images.load('lpc/ground.png'),
      heroWalk: await images.load('lpc/hero-walk.png'),
      heroIdle: await images.load('lpc/hero-idle.png'),
      heroWalkAxe: await images.load('lpc/hero-walk-axe.png'),
      heroIdleAxe: await images.load('lpc/hero-idle-axe.png'),
      heroChop: await images.load('lpc/hero-chop.png'),
      heroHammer: await images.load('lpc/hero-hammer.png'),
    );
  }
}
```

- [ ] **Step 5: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/atlas && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/features/forest/game/atlas test/layers/presentation/features/forest/game/atlas test/mocks/presentation/features/forest/game
git commit -m "[PROJECT-X]: Load the LPC atlas, alpha mask and character sheets"
```

---

### Task 3: Curvas de animación, fotogramas del jugador y encuadre de cámara

**Files:**
- Create: `game/render/easing.dart`, `game/render/tree_motion.dart`, `game/render/player_frame.dart`, `game/render/player_frames.dart`, `game/render/camera_framing.dart`
- Test: `test/layers/presentation/features/forest/game/render/easing_test.dart`, `tree_motion_test.dart`, `player_frames_test.dart`, `camera_framing_test.dart`

**Interfaces:**
- Consumes: `RenderConstants`, `Facing`, `WorkTool`, `PlayerSheet`, `PlayerRenderData`, `PlayerPose` (`IdlePose`, `WalkPose`, `WorkPose`).
- Produces:
  - `Easing.sineOut|sineInOut|quadIn|backOut(double t) → double` (las de Phaser)
  - `TreeMotion.direction({required double fromX, required double baseX})`, `shakeAngle({required double elapsedMs, required double direction})`, `fallAngle({...})`, `fallOpacity(double elapsedMs)`, `hasFallen(double elapsedMs)`, `shakeMs`; ángulos en radianes
  - `PlayerFrame({required PlayerSheet sheet, required int column, required int row, required double cellSize, required double anchorY})`
  - `PlayerFrames.row(Facing)`, `walkColumn(double seconds)`, `idleColumn(double seconds)`, `workColumn(WorkTool, double swingProgress)`, `sheet(PlayerPose)`, `animationKey(PlayerRenderData)`, `frame(PlayerRenderData, double animationSeconds)`
  - `CameraFraming.center({required Vector2 current, required Vector2 target, required Vector2 world, required Vector2 view, required double lerp}) → Vector2`, `CameraFraming.snap(Vector2 center, double zoom) → Vector2`

- [ ] **Step 1: Escribir los tests que fallan**

`test/layers/presentation/features/forest/game/render/easing_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/easing.dart';

void main() {
  test('testWhenEasingTheEndsThenStartsAtZeroAndEndsAtOne', () {
    // given
    final curves = [Easing.sineOut, Easing.sineInOut, Easing.quadIn, Easing.backOut];

    // when
    final starts = curves.map((curve) => curve(0)).toList();
    final ends = curves.map((curve) => curve(1)).toList();

    // then
    for (final start in starts) {
      expect(start, closeTo(0, 1e-9));
    }
    for (final end in ends) {
      expect(end, closeTo(1, 1e-9));
    }
  });

  test('testWhenEasingHalfwayThenMatchesPhaserFormulas', () {
    // given
    const half = 0.5;

    // when
    final values = [Easing.sineOut(half), Easing.sineInOut(half), Easing.quadIn(half), Easing.backOut(half)];

    // then
    expect(values[0], closeTo(0.7071067811865476, 1e-9));
    expect(values[1], closeTo(0.5, 1e-9));
    expect(values[2], closeTo(0.25, 1e-9));
    expect(values[3], closeTo(1.0876975, 1e-6));
  });
}
```

`test/layers/presentation/features/forest/game/render/tree_motion_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/tree_motion.dart';

double _degrees(double value) => value * math.pi / 180;

void main() {
  test('testWhenThePlayerIsOnTheLeftThenTheTreeMovesRight', () {
    // given
    const baseX = 100.0;

    // when
    final fromLeft = TreeMotion.direction(fromX: 90, baseX: baseX);
    final fromRight = TreeMotion.direction(fromX: 110, baseX: baseX);

    // then
    expect(fromLeft, 1);
    expect(fromRight, -1);
  });

  test('testWhenShakingThenPeaksAtThreeDegreesAndComesBack', () {
    // given
    const direction = 1.0;

    // when
    final start = TreeMotion.shakeAngle(elapsedMs: 0, direction: direction);
    final quarter = TreeMotion.shakeAngle(elapsedMs: 35, direction: direction);
    final peak = TreeMotion.shakeAngle(elapsedMs: 70, direction: direction);
    final end = TreeMotion.shakeAngle(elapsedMs: 140, direction: direction);

    // then
    expect(start, closeTo(0, 1e-9));
    expect(quarter, closeTo(_degrees(3 * math.sin(math.pi / 4)), 1e-9));
    expect(peak, closeTo(_degrees(3), 1e-9));
    expect(end, 0);
  });

  test('testWhenFallingThenRotatesAwayAndFadesWithQuadIn', () {
    // given
    const direction = -1.0;

    // when
    final angle = TreeMotion.fallAngle(elapsedMs: 350, direction: direction);
    final opacity = TreeMotion.fallOpacity(350);

    // then
    expect(angle, closeTo(_degrees(-85 * 0.25), 1e-9));
    expect(opacity, closeTo(0.75, 1e-9));
    expect(TreeMotion.hasFallen(699), isFalse);
    expect(TreeMotion.hasFallen(700), isTrue);
  });
}
```

`test/layers/presentation/features/forest/game/render/player_frames_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/forest/player_sheet.dart';
import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/player_frame.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/player_frames.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_render_data.dart';

void main() {
  test('testWhenChoosingTheRowThenFollowsUpLeftDownRight', () {
    // given
    const facings = [Facing.up, Facing.left, Facing.down, Facing.right];

    // when
    final rows = facings.map(PlayerFrames.row).toList();

    // then
    expect(rows, [0, 1, 2, 3]);
  });

  test('testWhenWalkingThenCyclesColumnsOneToEightAtTenFps', () {
    // given
    const times = [0.0, 0.1, 0.79, 0.8];

    // when
    final columns = times.map(PlayerFrames.walkColumn).toList();

    // then
    expect(columns, [1, 2, 8, 1]);
  });

  test('testWhenIdleThenAlternatesTwoColumnsAtTwoFps', () {
    // given
    const times = [0.0, 0.49, 0.5, 1.0];

    // when
    final columns = times.map(PlayerFrames.idleColumn).toList();

    // then
    expect(columns, [0, 0, 1, 0]);
  });

  test('testWhenWorkingThenTheSwingProgressPicksTheSequenceStep', () {
    // given
    const progress = [0.0, 0.3, 0.99, 1.0];

    // when
    final chop = progress.map((value) => PlayerFrames.workColumn(WorkTool.axe, value)).toList();
    final hammer = progress.map((value) => PlayerFrames.workColumn(WorkTool.hammer, value)).toList();

    // then
    expect(chop, [0, 5, 1, 1]);
    expect(hammer, [0, 5, 1, 1]);
  });

  test('testWhenBuildingTheFrameThenUsesTheSheetOfThePose', () {
    // given
    final chopping = PlayerRenderData(
      position: const PositionEntity(x: 0, y: 0),
      facing: Facing.left,
      pose: const WorkPose(tool: WorkTool.axe, swingProgress: 0.3),
    );
    final walking = PlayerRenderData(
      position: const PositionEntity(x: 0, y: 0),
      facing: Facing.right,
      pose: const WalkPose(withAxe: true),
    );

    // when
    final workFrame = PlayerFrames.frame(chopping, 0);
    final walkFrame = PlayerFrames.frame(walking, 0.1);

    // then
    expect(workFrame, const PlayerFrame(sheet: PlayerSheet.chop, column: 5, row: 1, cellSize: 128, anchorY: 94 / 128));
    expect(walkFrame, const PlayerFrame(sheet: PlayerSheet.walkAxe, column: 2, row: 3, cellSize: 64, anchorY: 62 / 64));
    expect(PlayerFrames.animationKey(walking), 'walkAxe-right');
    expect(PlayerFrames.sheet(const IdlePose(withAxe: false)), PlayerSheet.idle);
  });
}
```

`test/layers/presentation/features/forest/game/render/camera_framing_test.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/camera_framing.dart';

void main() {
  final world = Vector2(1600, 1200);
  final view = Vector2(400, 300);

  test('testWhenFollowingWithFullLerpThenCentresOnThePlayer', () {
    // given
    final player = Vector2(800, 600);

    // when
    final center = CameraFraming.center(current: Vector2.zero(), target: player, world: world, view: view, lerp: 1);

    // then
    expect(center, Vector2(800, 600));
  });

  test('testWhenThePlayerIsNearACornerThenTheCameraStaysInsideTheWorld', () {
    // given
    final player = Vector2(10, 1190);

    // when
    final center = CameraFraming.center(current: player, target: player, world: world, view: view, lerp: 1);

    // then
    expect(center, Vector2(200, 1050));
  });

  test('testWhenTheWorldIsSmallerThanTheViewThenItIsCentred', () {
    // given
    final small = Vector2(300, 200);

    // when
    final center = CameraFraming.center(current: Vector2.zero(), target: Vector2(10, 10), world: small, view: view, lerp: 1);

    // then
    expect(center, Vector2(150, 100));
  });

  test('testWhenLerpingThenMovesATenthOfTheWayEachFrame', () {
    // given
    final current = Vector2(800, 600);

    // when
    final center = CameraFraming.center(current: current, target: Vector2(900, 600), world: world, view: view, lerp: 0.1);

    // then
    expect(center.x, closeTo(810, 1e-9));
    expect(center.y, closeTo(600, 1e-9));
  });

  test('testWhenSnappingThenRoundsToWholeScreenPixels', () {
    // given
    final center = Vector2(10.3, 20.2);

    // when
    final snapped = CameraFraming.snap(center, 2);

    // then
    expect(snapped, Vector2(10.5, 20));
  });
}
```

- [ ] **Step 2: Ejecutarlos y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/game/render`
Expected: FAIL, `No such file or directory` en `easing.dart`.

- [ ] **Step 3: Implementar**

`game/render/easing.dart`:

```dart
import 'dart:math' as math;

abstract final class Easing {
  static const double _backOvershoot = 1.70158;

  static double sineOut(double t) => math.sin(t * math.pi / 2);

  static double sineInOut(double t) => (1 - math.cos(math.pi * t)) / 2;

  static double quadIn(double t) => t * t;

  static double backOut(double t) {
    final shifted = t - 1;
    return shifted * shifted * ((_backOvershoot + 1) * shifted + _backOvershoot) + 1;
  }
}
```

`game/render/tree_motion.dart`:

```dart
import 'dart:math' as math;

import 'easing.dart';

abstract final class TreeMotion {
  static const double shakeDegrees = 3;
  static const double shakeHalfMs = 70;
  static const double shakeMs = shakeHalfMs * 2;
  static const double fallDegrees = 85;
  static const double fallMs = 700;

  static double direction({required double fromX, required double baseX}) => fromX < baseX ? 1 : -1;

  static double shakeAngle({required double elapsedMs, required double direction}) {
    if (elapsedMs < 0 || elapsedMs >= shakeMs) return 0;
    final leg = elapsedMs < shakeHalfMs ? elapsedMs / shakeHalfMs : (shakeMs - elapsedMs) / shakeHalfMs;
    return _radians(shakeDegrees * direction * Easing.sineOut(leg));
  }

  static double fallAngle({required double elapsedMs, required double direction}) {
    return _radians(fallDegrees * direction * _fallProgress(elapsedMs));
  }

  static double fallOpacity(double elapsedMs) => 1 - _fallProgress(elapsedMs);

  static bool hasFallen(double elapsedMs) => elapsedMs >= fallMs;

  static double _fallProgress(double elapsedMs) => Easing.quadIn((elapsedMs / fallMs).clamp(0, 1).toDouble());

  static double _radians(double degrees) => degrees * math.pi / 180;
}
```

`game/render/player_frame.dart`:

```dart
import '../../../../../../core/config/constants/enum/forest/player_sheet.dart';

class PlayerFrame {
  final PlayerSheet sheet;
  final int column;
  final int row;
  final double cellSize;
  final double anchorY;

  const PlayerFrame({
    required this.sheet,
    required this.column,
    required this.row,
    required this.cellSize,
    required this.anchorY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerFrame &&
          other.sheet == sheet &&
          other.column == column &&
          other.row == row &&
          other.cellSize == cellSize &&
          other.anchorY == anchorY;

  @override
  int get hashCode => Object.hash(sheet, column, row, cellSize, anchorY);
}
```

`game/render/player_frames.dart`:

```dart
import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../../../core/config/constants/enum/forest/player_sheet.dart';
import '../../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../../core/config/constants/render_constants.dart';
import '../../models/player_pose.dart';
import '../../models/player_render_data.dart';
import 'player_frame.dart';

abstract final class PlayerFrames {
  static int row(Facing facing) {
    return switch (facing) {
      Facing.up => RenderConstants.rowUp,
      Facing.left => RenderConstants.rowLeft,
      Facing.down => RenderConstants.rowDown,
      Facing.right => RenderConstants.rowRight,
    };
  }

  static int walkColumn(double seconds) {
    final steps = RenderConstants.walkLastStep - RenderConstants.walkFirstStep + 1;
    return RenderConstants.walkFirstStep + (seconds * RenderConstants.walkFps).floor() % steps;
  }

  static int idleColumn(double seconds) => (seconds * RenderConstants.idleFps).floor() % RenderConstants.idleColumns;

  static int workColumn(WorkTool tool, double swingProgress) {
    final sequence = tool == WorkTool.axe ? RenderConstants.chopSequence : RenderConstants.hammerSequence;
    final step = math.min(sequence.length - 1, (swingProgress * sequence.length).floor());
    return sequence[math.max(0, step)];
  }

  static PlayerSheet sheet(PlayerPose pose) {
    return switch (pose) {
      IdlePose(:final withAxe) => withAxe ? PlayerSheet.idleAxe : PlayerSheet.idle,
      WalkPose(:final withAxe) => withAxe ? PlayerSheet.walkAxe : PlayerSheet.walk,
      WorkPose(:final tool) => tool == WorkTool.axe ? PlayerSheet.chop : PlayerSheet.hammer,
    };
  }

  static String animationKey(PlayerRenderData player) => '${sheet(player.pose).name}-${player.facing.name}';

  static PlayerFrame frame(PlayerRenderData player, double animationSeconds) {
    final pose = player.pose;
    final playerRow = row(player.facing);
    return switch (pose) {
      WorkPose(:final tool, :final swingProgress) => PlayerFrame(
        sheet: sheet(pose),
        column: workColumn(tool, swingProgress),
        row: playerRow,
        cellSize: RenderConstants.workFrameSize,
        anchorY: RenderConstants.workAnchorY,
      ),
      WalkPose() => PlayerFrame(
        sheet: sheet(pose),
        column: walkColumn(animationSeconds),
        row: playerRow,
        cellSize: RenderConstants.characterFrameSize,
        anchorY: RenderConstants.characterAnchorY,
      ),
      IdlePose() => PlayerFrame(
        sheet: sheet(pose),
        column: idleColumn(animationSeconds),
        row: playerRow,
        cellSize: RenderConstants.characterFrameSize,
        anchorY: RenderConstants.characterAnchorY,
      ),
    };
  }
}
```

`game/render/camera_framing.dart`:

```dart
import 'package:flame/extensions.dart';

abstract final class CameraFraming {
  static Vector2 center({
    required Vector2 current,
    required Vector2 target,
    required Vector2 world,
    required Vector2 view,
    required double lerp,
  }) {
    return Vector2(
      _axis(current: current.x, target: target.x, world: world.x, view: view.x, lerp: lerp),
      _axis(current: current.y, target: target.y, world: world.y, view: view.y, lerp: lerp),
    );
  }

  static Vector2 snap(Vector2 center, double zoom) {
    return Vector2((center.x * zoom).roundToDouble() / zoom, (center.y * zoom).roundToDouble() / zoom);
  }

  static double _axis({
    required double current,
    required double target,
    required double world,
    required double view,
    required double lerp,
  }) {
    if (view >= world) return world / 2;
    final next = current + (target - current) * lerp;
    return next.clamp(view / 2, world - view / 2).toDouble();
  }
}
```

- [ ] **Step 4: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/render && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/layers/presentation/features/forest/game/render test/layers/presentation/features/forest/game/render
git commit -m "[PROJECT-X]: Port the world animation curves, player frames and camera framing"
```

---

### Task 4: Partículas

**Files:**
- Create: `game/particles/particle.dart`, `game/particles/particle_bursts.dart`, `game/particles/particle_burst_component.dart`
- Test: `test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`, `particle_burst_component_test.dart`

**Interfaces:**
- Consumes: `PositionEntity`, `ParticleKind`, `RenderConstants.houseFrontOffset`, `RenderDepth`.
- Produces:
  - `Particle(kind:, origin:, velocityX:, velocityY:, gravity:, rotationDegrees:, lifespanSeconds:, alphaStart:, alphaEnd:, scaleStart:, scaleEnd:)`, `isAlive(double age)`, `position(double age)`, `alpha(double age)`, `scale(double age)`
  - `ParticleBursts.woodChips({required PositionEntity trunkBase, required bool playerOnLeft, required math.Random random})`, `ParticleBursts.dust({required PositionEntity buildingCenter, required math.Random random})`, `chipsSortY(PositionEntity)`, `dustSortY(PositionEntity)`
  - `ParticleBurstComponent({required List<Particle> particles, required double sortY})` con `priority = RenderDepth.bySortY(sortY) + 1`, `aliveCount`

- [ ] **Step 1: Escribir los tests que fallan**

`test/layers/presentation/features/forest/game/particles/particle_bursts_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/particle_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_bursts.dart';

double _angleDegrees(double x, double y) {
  final degrees = math.atan2(y, x) * 180 / math.pi;
  return degrees < 0 ? degrees + 360 : degrees;
}

void main() {
  const trunk = PositionEntity(x: 100, y: 120);

  test('testWhenTheAxeHitsFromTheLeftThenEightChipsFlyUpAndLeft', () {
    // given
    final random = math.Random(7);

    // when
    final chips = ParticleBursts.woodChips(trunkBase: trunk, playerOnLeft: true, random: random);

    // then
    expect(chips, hasLength(8));
    for (final chip in chips) {
      final speed = math.sqrt(chip.velocityX * chip.velocityX + chip.velocityY * chip.velocityY);
      expect(chip.kind, ParticleKind.woodChip);
      expect(chip.origin, const PositionEntity(x: 100, y: 110));
      expect(speed, inInclusiveRange(30, 80));
      expect(_angleDegrees(chip.velocityX, chip.velocityY), inInclusiveRange(200, 290));
      expect(chip.gravity, 220);
      expect(chip.lifespanSeconds, 0.5);
    }
  });

  test('testWhenTheAxeHitsFromTheRightThenChipsFlyUpAndRight', () {
    // given
    final random = math.Random(7);

    // when
    final chips = ParticleBursts.woodChips(trunkBase: trunk, playerOnLeft: false, random: random);

    // then
    for (final chip in chips) {
      expect(_angleDegrees(chip.velocityX, chip.velocityY), inInclusiveRange(250, 340));
    }
  });

  test('testWhenHammeringThenSixDustPuffsRiseFromTheFrontWall', () {
    // given
    const center = PositionEntity(x: 200, y: 180);

    // when
    final dust = ParticleBursts.dust(buildingCenter: center, random: math.Random(3));

    // then
    expect(dust, hasLength(6));
    expect(dust.first.origin, const PositionEntity(x: 200, y: 200));
    expect(dust.first.lifespanSeconds, 0.45);
    expect(ParticleBursts.dustSortY(center), 205);
    expect(ParticleBursts.chipsSortY(trunk), 121);
  });

  test('testWhenAParticleAgesThenFollowsAClosedFormTrajectory', () {
    // given
    final chip = ParticleBursts.woodChips(trunkBase: trunk, playerOnLeft: true, random: math.Random(1)).first;

    // when
    final position = chip.position(0.2);

    // then
    expect(position.x, closeTo(100 + chip.velocityX * 0.2, 1e-9));
    expect(position.y, closeTo(110 + chip.velocityY * 0.2 + 0.5 * 220 * 0.04, 1e-9));
    expect(chip.alpha(0.25), closeTo(0.5, 1e-9));
    expect(chip.isAlive(0.49), isTrue);
    expect(chip.isAlive(0.5), isFalse);
  });
}
```

`test/layers/presentation/features/forest/game/particles/particle_burst_component_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_bursts.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

void main() {
  testWithFlameGame('testWhenEveryParticleFadesThenTheBurstRemovesItself', (game) async {
    // given
    const trunk = PositionEntity(x: 100, y: 120);
    final burst = ParticleBurstComponent(
      particles: ParticleBursts.woodChips(trunkBase: trunk, playerOnLeft: true, random: math.Random(1)),
      sortY: ParticleBursts.chipsSortY(trunk),
    );
    await game.ensureAdd(burst);

    // when
    game.update(0.3);
    final aliveHalfway = burst.aliveCount;
    game.update(0.25);
    await game.ready();

    // then
    expect(burst.priority, RenderDepth.bySortY(121) + 1);
    expect(aliveHalfway, 8);
    expect(burst.isMounted, isFalse);
  });
}
```

- [ ] **Step 2: Ejecutarlos y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/game/particles`
Expected: FAIL, `No such file or directory` en `particle_bursts.dart`.

- [ ] **Step 3: Implementar**

`game/particles/particle.dart`:

```dart
import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';

class Particle {
  final ParticleKind kind;
  final PositionEntity origin;
  final double velocityX;
  final double velocityY;
  final double gravity;
  final double rotationDegrees;
  final double lifespanSeconds;
  final double alphaStart;
  final double alphaEnd;
  final double scaleStart;
  final double scaleEnd;

  const Particle({
    required this.kind,
    required this.origin,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.rotationDegrees,
    required this.lifespanSeconds,
    required this.alphaStart,
    required this.alphaEnd,
    required this.scaleStart,
    required this.scaleEnd,
  });

  bool isAlive(double ageSeconds) => ageSeconds < lifespanSeconds;

  PositionEntity position(double ageSeconds) {
    return PositionEntity(
      x: origin.x + velocityX * ageSeconds,
      y: origin.y + velocityY * ageSeconds + 0.5 * gravity * ageSeconds * ageSeconds,
    );
  }

  double alpha(double ageSeconds) => alphaStart + (alphaEnd - alphaStart) * _progress(ageSeconds);

  double scale(double ageSeconds) => scaleStart + (scaleEnd - scaleStart) * _progress(ageSeconds);

  double _progress(double ageSeconds) => (ageSeconds / lifespanSeconds).clamp(0, 1).toDouble();
}
```

`game/particles/particle_bursts.dart`:

```dart
import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../../../../../../core/config/constants/render_constants.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import 'particle.dart';

abstract final class ParticleBursts {
  static const int chipsPerHit = 8;
  static const double impactHeight = 10;
  static const int dustPerHammer = 6;
  static const double dustLift = 4;

  static List<Particle> woodChips({
    required PositionEntity trunkBase,
    required bool playerOnLeft,
    required math.Random random,
  }) {
    final minAngle = playerOnLeft ? 200.0 : 250.0;
    final maxAngle = playerOnLeft ? 290.0 : 340.0;
    return List.generate(chipsPerHit, (_) {
      final speed = _between(random, 30, 80);
      final angle = _between(random, minAngle, maxAngle) * math.pi / 180;
      return Particle(
        kind: ParticleKind.woodChip,
        origin: PositionEntity(x: trunkBase.x, y: trunkBase.y - impactHeight),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 220,
        rotationDegrees: _between(random, 0, 360),
        lifespanSeconds: 0.5,
        alphaStart: 1,
        alphaEnd: 0,
        scaleStart: 1,
        scaleEnd: 1,
      );
    });
  }

  static List<Particle> dust({required PositionEntity buildingCenter, required math.Random random}) {
    final front = buildingCenter.y + RenderConstants.houseFrontOffset;
    return List.generate(dustPerHammer, (_) {
      final speed = _between(random, 10, 35);
      final angle = _between(random, 180, 360) * math.pi / 180;
      return Particle(
        kind: ParticleKind.dust,
        origin: PositionEntity(x: buildingCenter.x, y: front - dustLift),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 0,
        rotationDegrees: 0,
        lifespanSeconds: 0.45,
        alphaStart: 0.7,
        alphaEnd: 0,
        scaleStart: 0.8,
        scaleEnd: 0.2,
      );
    });
  }

  static double chipsSortY(PositionEntity trunkBase) => trunkBase.y + 1;

  static double dustSortY(PositionEntity buildingCenter) => buildingCenter.y + RenderConstants.houseFrontOffset + 1;

  static double _between(math.Random random, double min, double max) => min + random.nextDouble() * (max - min);
}
```

`game/particles/particle_burst_component.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../render/render_depth.dart';
import 'particle.dart';

class ParticleBurstComponent extends Component {
  static const Color chipDark = Color(0xFF8A5A2B);
  static const Color chipLight = Color(0xFFC89A5E);
  static const Color dustColor = Color(0xFFD8CDB0);
  static const double dustRadius = 3;

  final List<Particle> _particles;
  final Paint _paint = Paint();
  double _ageSeconds = 0;

  ParticleBurstComponent({required List<Particle> particles, required double sortY})
    : _particles = particles,
      super(priority: RenderDepth.bySortY(sortY) + 1);

  int get aliveCount => _particles.where((particle) => particle.isAlive(_ageSeconds)).length;

  @override
  void update(double dt) {
    super.update(dt);
    _ageSeconds += dt;
    if (aliveCount == 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      if (!particle.isAlive(_ageSeconds)) continue;
      final at = particle.position(_ageSeconds);
      final alpha = particle.alpha(_ageSeconds);
      switch (particle.kind) {
        case ParticleKind.woodChip:
          _renderChip(canvas, at, particle.rotationDegrees, alpha);
        case ParticleKind.dust:
          _paint.color = dustColor.withValues(alpha: alpha);
          canvas.drawCircle(Offset(at.x, at.y), dustRadius * particle.scale(_ageSeconds), _paint);
      }
    }
  }

  void _renderChip(Canvas canvas, PositionEntity at, double rotationDegrees, double alpha) {
    canvas.save();
    canvas.translate(at.x, at.y);
    canvas.rotate(rotationDegrees * math.pi / 180);
    _paint.color = chipDark.withValues(alpha: alpha);
    canvas.drawRect(const Rect.fromLTWH(-1.5, -1, 3, 2), _paint);
    _paint.color = chipLight.withValues(alpha: alpha);
    canvas.drawRect(const Rect.fromLTWH(-1.5, -1, 2, 1), _paint);
    canvas.restore();
  }
}
```

- [ ] **Step 4: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/particles && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/layers/presentation/features/forest/game/particles test/layers/presentation/features/forest/game/particles
git commit -m "[PROJECT-X]: Add wood chip and dust particle bursts"
```

---

### Task 5: Suelo, sprite de atlas, sombra y hacha en el suelo

**Files:**
- Create: `game/components/ground_component.dart`, `game/components/atlas_sprite_component.dart`, `game/components/shadow_component.dart`, `game/components/ground_item_component.dart`
- Test: `test/layers/presentation/features/forest/game/components/ground_component_test.dart`, `atlas_sprite_component_test.dart`, `ground_item_component_test.dart`

**Interfaces:**
- Consumes: `LpcAssets`, `AtlasFrame`, `SpriteNames`, `RenderDepth`, `RenderConstants.tileSize`, `Easing`, `GroundItemEntity`, `PositionEntity`.
- Produces:
  - `GroundComponent({required Image tile, required double worldWidth, required double worldHeight})`, `static int columnsFor(double)`, `static int rowsFor(double)`
  - `AtlasSpriteComponent({required LpcAssets assets, required String frameName, required PositionEntity at, required int priority})` (factoría) y `AtlasSpriteComponent.fromFrame({required AtlasFrame frame, required Sprite sprite, required Vector2 position, required int priority})` (generativo, para subclases); `frame`, `bounds` (`Rect`), `boundsContain(Vector2)` (bordes incluidos, como `Phaser.Geom.Rectangle.contains`)
  - `ShadowComponent({required Vector2 center, required Vector2 size})` (elipse negra al 30 %, `priority = RenderDepth.shadow`)
  - `GroundItemComponent({required LpcAssets assets, required GroundItemEntity item})`: `itemId`, `shadow`, `isPickingUp`, `pickUp()`, `static double bobOffset(double elapsedMs)`

- [ ] **Step 1: Escribir los tests que fallan**

`test/layers/presentation/features/forest/game/components/ground_component_test.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  test('testWhenTilingTheForestThenCoversItWithWholeTiles', () {
    // given
    const width = 1600.0;
    const height = 1200.0;

    // when
    final columns = GroundComponent.columnsFor(width);
    final rows = GroundComponent.rowsFor(height);

    // then
    expect(columns, 50);
    expect(rows, 38);
  });

  testWithFlameGame('testWhenMountingTheGroundThenItSitsUnderEverything', (game) async {
    // given
    final ground = GroundComponent(tile: LpcAssetsMock.create().ground, worldWidth: 400, worldHeight: 300);

    // when
    await game.ensureAdd(ground);

    // then
    expect(ground.size, Vector2(400, 300));
    expect(ground.priority, RenderDepth.ground);
  });
}
```

`test/layers/presentation/features/forest/game/components/atlas_sprite_component_test.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/atlas_sprite_component.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenPlacingAnAtlasSpriteThenItsPivotSitsOnThePoint', (game) async {
    // given
    final sprite = AtlasSpriteComponent(
      assets: LpcAssetsMock.create(),
      frameName: SpriteNames.stump,
      at: const PositionEntity(x: 100, y: 120),
      priority: 7,
    );

    // when
    await game.ensureAdd(sprite);

    // then
    expect(sprite.bounds, const Rect.fromLTWH(96, 112, 8, 8));
    expect(sprite.boundsContain(Vector2(104, 120)), isTrue);
    expect(sprite.boundsContain(Vector2(104.5, 120)), isFalse);
    expect(sprite.priority, 7);
    expect(sprite.paint.filterQuality, FilterQuality.none);
  });
}
```

`test/layers/presentation/features/forest/game/components/ground_item_component_test.dart`:

```dart
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_item_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  test('testWhenBobbingThenFloatsBetweenEightAndElevenPixelsUp', () {
    // given
    const times = [0.0, 700.0, 1400.0];

    // when
    final offsets = times.map(GroundItemComponent.bobOffset).toList();

    // then
    expect(offsets[0], closeTo(-8, 1e-9));
    expect(offsets[1], closeTo(-11, 1e-9));
    expect(offsets[2], closeTo(-8, 1e-9));
  });

  testWithFlameGame('testWhenPickedUpThenRisesFadesAndDisappearsWithItsShadow', (game) async {
    // given
    final item = GroundItemComponent(assets: LpcAssetsMock.create(), item: ForestDataMock.axe);
    await game.ensureAdd(item.shadow);
    await game.ensureAdd(item);

    // when
    item.pickUp();
    game.update(0.15);
    final halfwayOpacity = item.opacity;
    game.update(0.16);
    await game.ready();

    // then
    expect(item.priority, RenderDepth.bySortY(ForestDataMock.axe.position.y));
    expect(halfwayOpacity, closeTo(0.5, 0.01));
    expect(item.isMounted, isFalse);
    expect(item.shadow.isMounted, isFalse);
  });
}
```

Estos tests usan `ForestDataMock`, que se crea en el Step 2.

- [ ] **Step 2: Crear los datos de test de la escena**

`test/mocks/presentation/features/forest/game/forest_data_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/entities/building/building_entity.dart';
import 'package:rpg/layers/domain/entities/decoration/decoration_entity.dart';
import 'package:rpg/layers/domain/entities/game/world_snapshot_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/item/ground_item_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_render_data.dart';

abstract final class ForestDataMock {
  static final TreeEntity tree = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: const PositionEntity(x: 100, y: 120),
    trunkRadius: 12,
    woodYield: 5,
    hitsToFell: 5,
  );

  static final TreeEntity frontTree = TreeEntity(
    id: 'tree-2',
    kind: TreeKind.pine,
    position: const PositionEntity(x: 102, y: 122),
    trunkRadius: 12,
    woodYield: 6,
    hitsToFell: 5,
  );

  static final GroundItemEntity axe = GroundItemEntity(
    id: 'axe',
    kind: ToolKind.axe,
    position: const PositionEntity(x: 60, y: 60),
  );

  static final DecorationEntity grass = DecorationEntity(
    id: 'decoration-1',
    kind: DecorationKind.tallGrass,
    position: const PositionEntity(x: 200, y: 200),
  );

  static final BuildingEntity house = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: const PositionEntity(x: 200, y: 180),
    hitsDone: 0,
  );

  static final BuildingEntity halfBuiltHouse = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: const PositionEntity(x: 200, y: 180),
    hitsDone: 4,
  );

  static final WorldSnapshotEntity world = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: [axe],
    decorations: [grass],
    buildings: const [],
  );

  static final WorldSnapshotEntity worldWithoutFirstTree = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [frontTree],
    items: [axe],
    decorations: [grass],
    buildings: const [],
  );

  static final WorldSnapshotEntity worldWithoutAxe = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: const [],
    decorations: [grass],
    buildings: const [],
  );

  static final WorldSnapshotEntity worldWithHouse = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: [axe],
    decorations: [grass],
    buildings: [house],
  );

  static final WorldSnapshotEntity worldWithHalfBuiltHouse = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: [axe],
    decorations: [grass],
    buildings: [halfBuiltHouse],
  );

  static final PlayerRenderData player = PlayerRenderData(
    position: const PositionEntity(x: 150, y: 150),
    facing: Facing.down,
    pose: const IdlePose(withAxe: false),
  );

  static final PlacementData validPlacement = PlacementData(
    blueprint: BlueprintId.house,
    position: const PositionEntity(x: 300, y: 200),
    isValid: true,
  );

  static final ForestData initial = ForestData(world: world, player: player);

  static final ForestData treeHit = ForestData(
    world: world,
    player: player,
    effects: const [TreeHitEffect(treeId: 'tree-1', fromX: 90)],
  );

  static final ForestData treeFelled = ForestData(
    world: worldWithoutFirstTree,
    player: player,
    effects: const [TreeFelledEffect(treeId: 'tree-1', fromX: 90)],
  );

  static final ForestData axePickedUp = ForestData(
    world: worldWithoutAxe,
    player: player,
    effects: const [ItemPickedUpEffect(itemId: 'axe')],
  );

  static final ForestData axeGone = ForestData(world: worldWithoutAxe, player: player);

  static final ForestData housePlaced = ForestData(
    world: worldWithHouse,
    player: player,
    effects: [BuildingPlacedEffect(building: house)],
  );

  static final ForestData houseHammered = ForestData(
    world: worldWithHalfBuiltHouse,
    player: player,
    effects: const [BuildingHammeredEffect(buildingId: 'building-1', progress: 0.5)],
  );

  static final ForestData placing = ForestData(world: world, player: player, placement: validPlacement);
}
```


- [ ] **Step 3: Ejecutar los tests y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/game/components`
Expected: FAIL, `No such file or directory` en `ground_component.dart`.

- [ ] **Step 4: Implementar**

`game/components/ground_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/render_constants.dart';
import '../render/render_depth.dart';

class GroundComponent extends PositionComponent {
  final Image _tile;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  Picture? _picture;

  GroundComponent({required Image tile, required double worldWidth, required double worldHeight})
    : _tile = tile,
      super(size: Vector2(worldWidth, worldHeight), priority: RenderDepth.ground);

  static int columnsFor(double width) => (width / RenderConstants.tileSize).ceil();

  static int rowsFor(double height) => (height / RenderConstants.tileSize).ceil();

  @override
  Future<void> onLoad() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const tile = RenderConstants.tileSize;
    const source = Rect.fromLTWH(0, 0, tile, tile);
    for (var row = 0; row < rowsFor(size.y); row++) {
      for (var column = 0; column < columnsFor(size.x); column++) {
        canvas.drawImageRect(_tile, source, Rect.fromLTWH(column * tile, row * tile, tile, tile), _paint);
      }
    }
    _picture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final picture = _picture;
    if (picture != null) canvas.drawPicture(picture);
  }
}
```

`game/components/atlas_sprite_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../atlas/atlas_frame.dart';
import '../atlas/lpc_assets.dart';

class AtlasSpriteComponent extends SpriteComponent {
  final AtlasFrame frame;

  AtlasSpriteComponent.fromFrame({
    required this.frame,
    required Sprite sprite,
    required Vector2 position,
    required int priority,
  }) : super(
         sprite: sprite,
         position: position,
         size: Vector2(frame.width.toDouble(), frame.height.toDouble()),
         anchor: Anchor(frame.pivotX, frame.pivotY),
         priority: priority,
         paint: Paint()..filterQuality = FilterQuality.none,
       );

  factory AtlasSpriteComponent({
    required LpcAssets assets,
    required String frameName,
    required PositionEntity at,
    required int priority,
  }) {
    return AtlasSpriteComponent.fromFrame(
      frame: assets.frame(frameName),
      sprite: assets.sprite(frameName),
      position: Vector2(at.x, at.y),
      priority: priority,
    );
  }

  Rect get bounds => Rect.fromLTWH(
    position.x - frame.width * frame.pivotX,
    position.y - frame.height * frame.pivotY,
    frame.width.toDouble(),
    frame.height.toDouble(),
  );

  bool boundsContain(Vector2 point) {
    final area = bounds;
    return point.x >= area.left && point.x <= area.right && point.y >= area.top && point.y <= area.bottom;
  }
}
```

`game/components/shadow_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../render/render_depth.dart';

class ShadowComponent extends PositionComponent {
  static final Paint _paint = Paint()..color = const Color(0x4D000000);

  ShadowComponent({required Vector2 center, required Vector2 size})
    : super(position: center, size: size, anchor: Anchor.center, priority: RenderDepth.shadow);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), _paint);
  }
}
```

`game/components/ground_item_component.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../../domain/entities/item/ground_item_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/easing.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';
import 'shadow_component.dart';

class GroundItemComponent extends AtlasSpriteComponent {
  static const double floatHeight = 8;
  static const double bobHeight = 3;
  static const double bobMs = 700;
  static const double pickUpRise = 16;
  static const double pickUpMs = 300;

  final String itemId;
  final PositionEntity ground;
  final ShadowComponent shadow;
  double _elapsedMs = 0;
  double? _pickUpElapsedMs;
  double _pickUpStartY = 0;

  GroundItemComponent({required LpcAssets assets, required GroundItemEntity item})
    : itemId = item.id,
      ground = item.position,
      shadow = ShadowComponent(center: Vector2(item.position.x, item.position.y), size: Vector2(16, 5)),
      super.fromFrame(
        frame: assets.frame(SpriteNames.axePickup),
        sprite: assets.sprite(SpriteNames.axePickup),
        position: Vector2(item.position.x, item.position.y - floatHeight),
        priority: RenderDepth.bySortY(item.position.y),
      );

  bool get isPickingUp => _pickUpElapsedMs != null;

  static double bobOffset(double elapsedMs) {
    final phase = (elapsedMs % (bobMs * 2)) / bobMs;
    final leg = phase <= 1 ? phase : 2 - phase;
    return -floatHeight - bobHeight * Easing.sineInOut(leg);
  }

  void pickUp() {
    shadow.removeFromParent();
    _pickUpElapsedMs = 0;
    _pickUpStartY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsedMs = dt * 1000;
    final pickUpElapsed = _pickUpElapsedMs;
    if (pickUpElapsed != null) {
      final total = pickUpElapsed + elapsedMs;
      _pickUpElapsedMs = total;
      final progress = math.min(1.0, total / pickUpMs);
      position.y = _pickUpStartY - pickUpRise * progress;
      opacity = 1 - progress;
      if (progress >= 1) removeFromParent();
      return;
    }
    _elapsedMs += elapsedMs;
    position.y = ground.y + bobOffset(_elapsedMs);
  }
}
```

- [ ] **Step 5: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/components && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/features/forest/game/components test/layers/presentation/features/forest/game/components test/mocks/presentation/features/forest/game/forest_data_mock.dart
git commit -m "[PROJECT-X]: Draw the ground, atlas sprites, shadows and the axe pickup"
```

---

### Task 6: Árbol con toque por píxel, sacudida y caída

**Files:**
- Create: `game/components/tree_component.dart`
- Test: `test/layers/presentation/features/forest/game/components/tree_component_test.dart`

**Interfaces:**
- Consumes: `AtlasSpriteComponent.fromFrame`, `LpcAssets.isOpaque`, `TreeMotion`, `SpriteNames.tree`, `RenderDepth`, `TreeEntity`.
- Produces: `TreeComponent({required LpcAssets assets, required TreeEntity tree})`: `treeId`, `base` (`PositionEntity`), `isFalling`, `containsPoint(Vector2)`, `hit(double fromX)`, `fell(double fromX)` (se quita sola a los 700 ms).

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/features/forest/game/components/tree_component_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/tree_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

double _degrees(double value) => value * math.pi / 180;

void main() {
  testWithFlameGame('testWhenTappingATreeThenOnlyOpaquePixelsCount', (game) async {
    // given
    final tree = TreeComponent(assets: LpcAssetsMock.create(), tree: ForestDataMock.tree);
    await game.ensureAdd(tree);

    // when
    final onOpaque = tree.containsPoint(Vector2(101, 113));
    final onTransparent = tree.containsPoint(Vector2(97, 113));
    final outside = tree.containsPoint(Vector2(110, 113));

    // then
    expect(tree.priority, RenderDepth.bySortY(120));
    expect(onOpaque, isTrue);
    expect(onTransparent, isFalse);
    expect(outside, isFalse);
  });

  testWithFlameGame('testWhenHitFromTheLeftThenShakesRightAndSettles', (game) async {
    // given
    final tree = TreeComponent(assets: LpcAssetsMock.create(), tree: ForestDataMock.tree);
    await game.ensureAdd(tree);

    // when
    tree.hit(90);
    game.update(0.07);
    final peak = tree.angle;
    game.update(0.08);

    // then
    expect(peak, closeTo(_degrees(3), 1e-9));
    expect(tree.angle, 0);
  });

  testWithFlameGame('testWhenFelledFromTheRightThenFallsLeftFadesAndIsRemoved', (game) async {
    // given
    final tree = TreeComponent(assets: LpcAssetsMock.create(), tree: ForestDataMock.tree);
    await game.ensureAdd(tree);

    // when
    tree.fell(110);
    game.update(0.35);
    final halfwayAngle = tree.angle;
    final halfwayOpacity = tree.opacity;
    final tappableWhileFalling = tree.containsPoint(Vector2(101, 113));
    game.update(0.36);
    await game.ready();

    // then
    expect(halfwayAngle, closeTo(_degrees(-85 * 0.25), 1e-9));
    expect(halfwayOpacity, closeTo(0.75, 0.01));
    expect(tappableWhileFalling, isFalse);
    expect(tree.isMounted, isFalse);
  });
}
```

- [ ] **Step 2: Ejecutarlo y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/game/components/tree_component_test.dart`
Expected: FAIL, `No such file or directory` en `tree_component.dart`.

- [ ] **Step 3: Implementar**

`game/components/tree_component.dart`:

```dart
import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../../domain/entities/tree/tree_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/render_depth.dart';
import '../render/tree_motion.dart';
import 'atlas_sprite_component.dart';

class TreeComponent extends AtlasSpriteComponent {
  final String treeId;
  final PositionEntity base;
  final LpcAssets _assets;
  double _direction = 1;
  double? _hitElapsedMs;
  double? _fallElapsedMs;

  TreeComponent({required LpcAssets assets, required TreeEntity tree})
    : treeId = tree.id,
      base = tree.position,
      _assets = assets,
      super.fromFrame(
        frame: assets.frame(SpriteNames.tree(tree.kind)),
        sprite: assets.sprite(SpriteNames.tree(tree.kind)),
        position: Vector2(tree.position.x, tree.position.y),
        priority: RenderDepth.bySortY(tree.position.y),
      );

  bool get isFalling => _fallElapsedMs != null;

  @override
  bool containsPoint(Vector2 point) {
    if (isFalling || !boundsContain(point)) return false;
    final area = bounds;
    return _assets.isOpaque(frame, (point.x - area.left).floor(), (point.y - area.top).floor());
  }

  void hit(double fromX) {
    _direction = TreeMotion.direction(fromX: fromX, baseX: base.x);
    _hitElapsedMs = 0;
  }

  void fell(double fromX) {
    _direction = TreeMotion.direction(fromX: fromX, baseX: base.x);
    _hitElapsedMs = null;
    _fallElapsedMs = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsedMs = dt * 1000;
    final fallElapsed = _fallElapsedMs;
    if (fallElapsed != null) {
      final total = fallElapsed + elapsedMs;
      _fallElapsedMs = total;
      angle = TreeMotion.fallAngle(elapsedMs: total, direction: _direction);
      opacity = TreeMotion.fallOpacity(total);
      if (TreeMotion.hasFallen(total)) removeFromParent();
      return;
    }
    final hitElapsed = _hitElapsedMs;
    if (hitElapsed == null) return;
    final total = hitElapsed + elapsedMs;
    angle = TreeMotion.shakeAngle(elapsedMs: total, direction: _direction);
    _hitElapsedMs = total >= TreeMotion.shakeMs ? null : total;
  }
}
```

- [ ] **Step 4: Ejecutar el test y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/components/tree_component_test.dart && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/layers/presentation/features/forest/game/components/tree_component.dart test/layers/presentation/features/forest/game/components/tree_component_test.dart
git commit -m "[PROJECT-X]: Draw trees with pixel-accurate taps and hit and fall animations"
```

---

### Task 7: Casa en construcción y fantasma de colocación

**Files:**
- Create: `game/components/building_component.dart`, `game/components/placement_ghost_component.dart`
- Test: `test/layers/presentation/features/forest/game/components/building_component_test.dart`, `placement_ghost_component_test.dart`

**Interfaces:**
- Consumes: `AtlasSpriteComponent.fromFrame`, `SpriteNames.house`, `RenderConstants.houseFrontOffset`, `RenderDepth`, `Easing.backOut`, `BuildingEntity`, `PlacementData`.
- Produces:
  - `BuildingComponent({required LpcAssets assets, required BuildingEntity building})`: `buildingId`, `center`, `progress` (get/set, opacidad `0.35 + 0.65 * progress`), `isComplete`, `hammered(double)`, `complete()` (rebote `scale.y` 0.92 → 1 en 350 ms con Back.easeOut; la barra desaparece)
  - `PlacementGhostComponent({required LpcAssets assets})`: `show(PlacementData)`, `isValid`, `validTint`, `invalidTint`; opacidad 0.6, `priority = RenderDepth.overlay`

- [ ] **Step 1: Escribir los tests que fallan**

`test/layers/presentation/features/forest/game/components/building_component_test.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/building_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenASiteIsPlacedThenIsDrawnBelowItsFootprintAndTranslucent', (game) async {
    // given
    final building = BuildingComponent(assets: LpcAssetsMock.create(), building: ForestDataMock.house);

    // when
    await game.ensureAdd(building);

    // then
    expect(building.position, Vector2(200, 204));
    expect(building.priority, RenderDepth.bySortY(204));
    expect(building.opacity, closeTo(0.35, 0.01));
  });

  testWithFlameGame('testWhenHammeredThenBecomesMoreSolid', (game) async {
    // given
    final building = BuildingComponent(assets: LpcAssetsMock.create(), building: ForestDataMock.house);
    await game.ensureAdd(building);

    // when
    building.hammered(0.5);

    // then
    expect(building.progress, 0.5);
    expect(building.opacity, closeTo(0.675, 0.01));
  });

  testWithFlameGame('testWhenCompletedThenSettlesWithABounce', (game) async {
    // given
    final building = BuildingComponent(assets: LpcAssetsMock.create(), building: ForestDataMock.house);
    await game.ensureAdd(building);

    // when
    building.complete();
    final squashed = building.scale.y;
    game.update(0.35);

    // then
    expect(squashed, closeTo(0.92, 1e-9));
    expect(building.isComplete, isTrue);
    expect(building.opacity, closeTo(1, 0.01));
    expect(building.scale.y, closeTo(1, 1e-9));
  });
}
```

`test/layers/presentation/features/forest/game/components/placement_ghost_component_test.dart`:

```dart
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/placement_ghost_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenPlacingOnAFreeSpotThenTheGhostIsGreen', (game) async {
    // given
    final ghost = PlacementGhostComponent(assets: LpcAssetsMock.create());
    await game.ensureAdd(ghost);

    // when
    ghost.show(ForestDataMock.validPlacement);

    // then
    expect(ghost.position, Vector2(300, 224));
    expect(ghost.priority, RenderDepth.overlay);
    expect(ghost.opacity, closeTo(0.6, 0.01));
    expect(ghost.paint.colorFilter, const ColorFilter.mode(PlacementGhostComponent.validTint, BlendMode.modulate));
  });

  testWithFlameGame('testWhenPlacingOnABlockedSpotThenTheGhostIsRed', (game) async {
    // given
    final ghost = PlacementGhostComponent(assets: LpcAssetsMock.create());
    await game.ensureAdd(ghost);
    final blocked = PlacementData(
      blueprint: BlueprintId.house,
      position: const PositionEntity(x: 100, y: 100),
      isValid: false,
    );

    // when
    ghost.show(blocked);

    // then
    expect(ghost.isValid, isFalse);
    expect(ghost.paint.colorFilter, const ColorFilter.mode(PlacementGhostComponent.invalidTint, BlendMode.modulate));
  });
}
```

- [ ] **Step 2: Ejecutarlos y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/game/components/building_component_test.dart test/layers/presentation/features/forest/game/components/placement_ghost_component_test.dart`
Expected: FAIL, `No such file or directory` en `building_component.dart`.

- [ ] **Step 3: Implementar**

`game/components/building_component.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/render_constants.dart';
import '../../../../../domain/entities/building/building_entity.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/easing.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';

class BuildingComponent extends AtlasSpriteComponent {
  static const double siteOpacity = 0.35;
  static const double barWidth = 60;
  static const double barHeight = 5;
  static const double barMargin = 6;
  static const double bounceMs = 350;
  static const double bounceFrom = 0.92;

  final String buildingId;
  final PositionEntity center;
  final Paint _barBackground = Paint()..color = const Color(0x99000000);
  final Paint _barFill = Paint()..color = const Color(0xFFE8C05A);
  double _progress = 0;
  bool _isComplete = false;
  double? _bounceElapsedMs;

  BuildingComponent({required LpcAssets assets, required BuildingEntity building})
    : buildingId = building.id,
      center = building.position,
      super.fromFrame(
        frame: assets.frame(SpriteNames.house),
        sprite: assets.sprite(SpriteNames.house),
        position: Vector2(building.position.x, building.position.y + RenderConstants.houseFrontOffset),
        priority: RenderDepth.bySortY(building.position.y + RenderConstants.houseFrontOffset),
      ) {
    progress = building.progress;
  }

  double get progress => _progress;

  bool get isComplete => _isComplete;

  set progress(double value) {
    _progress = value;
    opacity = siteOpacity + (1 - siteOpacity) * value;
  }

  void hammered(double value) {
    progress = value;
  }

  void complete() {
    progress = 1;
    _isComplete = true;
    _bounceElapsedMs = 0;
    scale.y = bounceFrom;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final bounceElapsed = _bounceElapsedMs;
    if (bounceElapsed == null) return;
    final total = bounceElapsed + dt * 1000;
    final bounce = math.min(1.0, total / bounceMs);
    scale.y = bounce >= 1 ? 1 : bounceFrom + (1 - bounceFrom) * Easing.backOut(bounce);
    _bounceElapsedMs = bounce >= 1 ? null : total;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_isComplete) return;
    final left = size.x / 2 - barWidth / 2;
    const top = -barMargin - barHeight;
    canvas.drawRect(Rect.fromLTWH(left - 1, top - 1, barWidth + 2, barHeight + 2), _barBackground);
    canvas.drawRect(Rect.fromLTWH(left, top, barWidth * _progress, barHeight), _barFill);
  }
}
```

`game/components/placement_ghost_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/render_constants.dart';
import '../../models/placement_data.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';

class PlacementGhostComponent extends AtlasSpriteComponent {
  static const double ghostOpacity = 0.6;
  static const Color validTint = Color(0xFFB8FFB8);
  static const Color invalidTint = Color(0xFFFF8080);

  bool _isValid = false;

  PlacementGhostComponent({required LpcAssets assets})
    : super.fromFrame(
        frame: assets.frame(SpriteNames.house),
        sprite: assets.sprite(SpriteNames.house),
        position: Vector2.zero(),
        priority: RenderDepth.overlay,
      ) {
    opacity = ghostOpacity;
  }

  bool get isValid => _isValid;

  void show(PlacementData placement) {
    position.setValues(placement.position.x, placement.position.y + RenderConstants.houseFrontOffset);
    _isValid = placement.isValid;
    paint.colorFilter = ColorFilter.mode(placement.isValid ? validTint : invalidTint, BlendMode.modulate);
  }
}
```

- [ ] **Step 4: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/components && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/layers/presentation/features/forest/game/components test/layers/presentation/features/forest/game/components
git commit -m "[PROJECT-X]: Draw construction sites, their progress bar and the placement ghost"
```

---

### Task 8: Jugador animado

**Files:**
- Create: `game/components/player_component.dart`
- Test: `test/layers/presentation/features/forest/game/components/player_component_test.dart`

**Interfaces:**
- Consumes: `LpcAssets.sheet`, `PlayerFrames`, `PlayerFrame`, `ShadowComponent`, `RenderDepth`, `PlayerRenderData`.
- Produces: `PlayerComponent({required LpcAssets assets, required PlayerRenderData player})`: `shadow` (22×7 en `(x, y - 1)`), `show(PlayerRenderData)`, `currentFrame` (`PlayerFrame`). La animación vuelve al primer fotograma cuando cambia la clave hoja + orientación, como `anims.play(key, true)` en Phaser.

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/features/forest/game/components/player_component_test.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/forest/player_sheet.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/player_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_render_data.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenIdleThenBreathesAtTwoFramesPerSecond', (game) async {
    // given
    final player = PlayerComponent(assets: LpcAssetsMock.create(), player: ForestDataMock.player);
    await game.ensureAdd(player.shadow);
    await game.ensureAdd(player);

    // when
    game.update(0.5);

    // then
    expect(player.currentFrame.sheet, PlayerSheet.idle);
    expect(player.currentFrame.column, 1);
    expect(player.currentFrame.row, 2);
    expect(player.priority, RenderDepth.bySortY(150));
    expect(player.shadow.position, Vector2(150, 149));
  });

  testWithFlameGame('testWhenThePoseChangesThenTheAnimationRestarts', (game) async {
    // given
    final player = PlayerComponent(assets: LpcAssetsMock.create(), player: ForestDataMock.player);
    await game.ensureAdd(player);
    game.update(0.5);
    final walking = PlayerRenderData(
      position: const PositionEntity(x: 160, y: 155),
      facing: Facing.right,
      pose: const WalkPose(withAxe: true),
    );

    // when
    player.show(walking);

    // then
    expect(player.currentFrame.sheet, PlayerSheet.walkAxe);
    expect(player.currentFrame.column, 1);
    expect(player.currentFrame.row, 3);
    expect(player.position, Vector2(160, 155));
    expect(player.priority, RenderDepth.bySortY(155));
  });
}
```

- [ ] **Step 2: Ejecutarlo y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/game/components/player_component_test.dart`
Expected: FAIL, `No such file or directory` en `player_component.dart`.

- [ ] **Step 3: Implementar**

`game/components/player_component.dart`:

```dart
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/player_render_data.dart';
import '../atlas/lpc_assets.dart';
import '../render/player_frame.dart';
import '../render/player_frames.dart';
import '../render/render_depth.dart';
import 'shadow_component.dart';

class PlayerComponent extends PositionComponent {
  final LpcAssets _assets;
  final ShadowComponent shadow;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  PlayerRenderData _player;
  String _animationKey;
  double _animationSeconds = 0;

  PlayerComponent({required LpcAssets assets, required PlayerRenderData player})
    : _assets = assets,
      _player = player,
      _animationKey = PlayerFrames.animationKey(player),
      shadow = ShadowComponent(center: Vector2(player.position.x, player.position.y - 1), size: Vector2(22, 7)),
      super(position: Vector2(player.position.x, player.position.y), priority: RenderDepth.bySortY(player.position.y));

  PlayerFrame get currentFrame => PlayerFrames.frame(_player, _animationSeconds);

  void show(PlayerRenderData player) {
    final key = PlayerFrames.animationKey(player);
    if (key != _animationKey) {
      _animationKey = key;
      _animationSeconds = 0;
    }
    _player = player;
    position.setValues(player.position.x, player.position.y);
    priority = RenderDepth.bySortY(player.position.y);
    shadow.position.setValues(player.position.x, player.position.y - 1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationSeconds += dt;
  }

  @override
  void render(Canvas canvas) {
    final frame = currentFrame;
    final cell = frame.cellSize;
    canvas.drawImageRect(
      _assets.sheet(frame.sheet),
      Rect.fromLTWH(frame.column * cell, frame.row * cell, cell, cell),
      Rect.fromLTWH(-cell / 2, -cell * frame.anchorY, cell, cell),
      _paint,
    );
  }
}
```

- [ ] **Step 4: Ejecutar el test y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/components/player_component_test.dart && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/layers/presentation/features/forest/game/components/player_component.dart test/layers/presentation/features/forest/game/components/player_component_test.dart
git commit -m "[PROJECT-X]: Animate the player with the LPC walk, idle and work sheets"
```

---

### Task 9: Escena: reconciliación por id, efectos y árbol bajo el puntero

**Files:**
- Create: `game/forest_scene_component.dart`
- Test: `test/layers/presentation/features/forest/game/forest_scene_component_test.dart`

**Interfaces:**
- Consumes: todos los componentes, `ParticleBursts`, `ParticleBurstComponent`, `ForestData`, `ForestEffect` y subtipos, `WorldSnapshotEntity`.
- Produces: `ForestSceneComponent({required LpcAssets assets, math.Random? random})`:
  - `void show(ForestData data)`: construye la escena con el primer `world`, reproduce `data.effects` **antes** de reconciliar (así el árbol talado empieza a caer antes de que la instantánea lo quite), reconcilia árboles/objetos/edificios por id, actualiza el jugador y el fantasma.
  - `String? treeAt(Vector2 point)`: el árbol pintado encima (mayor `priority`) cuyo píxel es opaco.
  - Getters de solo lectura para tests: `trees`, `items`, `buildings`, `clutter`, `player`, `ghost`.
  - Al colocar una casa (`BuildingPlacedEffect`) se quitan la decoración y los tocones cuyo punto cae dentro del rectángulo del sprite de la casa (bordes incluidos), como `clearClutterUnder` de la web.

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/features/forest/game/forest_scene_component_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/tree_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_scene_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';

import '../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

Future<ForestSceneComponent> _mountedScene(FlameGame game) async {
  final scene = ForestSceneComponent(assets: LpcAssetsMock.create(), random: math.Random(1));
  await game.ensureAdd(scene);
  scene.show(ForestDataMock.initial);
  await game.ready();
  return scene;
}

void main() {
  testWithFlameGame('testWhenShowingTheFirstStateThenBuildsTheWorldFromTheLevel', (game) async {
    // given
    final scene = ForestSceneComponent(assets: LpcAssetsMock.create(), random: math.Random(1));
    await game.ensureAdd(scene);

    // when
    scene.show(ForestDataMock.initial);
    await game.ready();

    // then
    expect(scene.trees.keys, ['tree-1', 'tree-2']);
    expect(scene.items.keys, ['axe']);
    expect(scene.clutter, hasLength(1));
    expect(scene.children.whereType<GroundComponent>(), hasLength(1));
    expect(scene.player, isNotNull);
    expect(scene.ghost, isNull);
  });

  testWithFlameGame('testWhenCanopiesOverlapThenTheFrontTreeIsTapped', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    final overlap = scene.treeAt(Vector2(103, 117));
    final backOnly = scene.treeAt(Vector2(101, 113));
    final gap = scene.treeAt(Vector2(97, 115));

    // then
    expect(overlap, 'tree-2');
    expect(backOnly, 'tree-1');
    expect(gap, isNull);
  });

  testWithFlameGame('testWhenATreeIsHitThenWoodChipsFly', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.treeHit);
    await game.ready();

    // then
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
  });

  testWithFlameGame('testWhenATreeIsFelledThenFallsLeavesAStumpAndIsNoLongerTappable', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.treeFelled);
    await game.ready();
    final fallingTrees = scene.children.whereType<TreeComponent>().length;
    game.update(0.71);
    await game.ready();

    // then
    expect(scene.trees.keys, ['tree-2']);
    expect(fallingTrees, 2);
    expect(scene.children.whereType<TreeComponent>(), hasLength(1));
    expect(scene.clutter, hasLength(2));
    expect(scene.treeAt(Vector2(101, 113)), isNull);
  });

  testWithFlameGame('testWhenTheAxeIsPickedUpThenItPopsAndVanishes', (game) async {
    // given
    final scene = await _mountedScene(game);
    final axe = scene.items['axe']!;

    // when
    scene.show(ForestDataMock.axePickedUp);
    game.update(0.31);
    await game.ready();

    // then
    expect(scene.items, isEmpty);
    expect(axe.isMounted, isFalse);
  });

  testWithFlameGame('testWhenAnItemLeavesTheWorldWithoutEffectThenIsRemoved', (game) async {
    // given
    final scene = await _mountedScene(game);
    final axe = scene.items['axe']!;

    // when
    scene.show(ForestDataMock.axeGone);
    await game.ready();

    // then
    expect(scene.items, isEmpty);
    expect(axe.isMounted, isFalse);
  });

  testWithFlameGame('testWhenAHouseIsPlacedThenAppearsAndClearsTheDecorationUnderIt', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.housePlaced);
    await game.ready();

    // then
    expect(scene.buildings.keys, ['building-1']);
    expect(scene.clutter, isEmpty);
  });

  testWithFlameGame('testWhenAHouseIsHammeredThenRaisesDustAndProgresses', (game) async {
    // given
    final scene = await _mountedScene(game);
    scene.show(ForestDataMock.housePlaced);
    await game.ready();

    // when
    scene.show(ForestDataMock.houseHammered);
    await game.ready();

    // then
    expect(scene.buildings['building-1']!.progress, 0.5);
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
  });

  testWithFlameGame('testWhenPlacementStartsAndEndsThenTheGhostComesAndGoes', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.placing);
    await game.ready();
    final ghostWhilePlacing = scene.ghost;
    scene.show(ForestDataMock.initial);
    await game.ready();

    // then
    expect(ghostWhilePlacing, isNotNull);
    expect(ghostWhilePlacing!.isValid, isTrue);
    expect(scene.ghost, isNull);
    expect(ghostWhilePlacing.isMounted, isFalse);
  });
}
```

- [ ] **Step 2: Ejecutarlo y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/game/forest_scene_component_test.dart`
Expected: FAIL, `No such file or directory` en `forest_scene_component.dart`.

- [ ] **Step 3: Implementar**

`game/forest_scene_component.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../../domain/entities/game/world_snapshot_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../bloc/forest_bloc.dart';
import '../models/forest_effect.dart';
import '../models/placement_data.dart';
import '../models/player_render_data.dart';
import 'atlas/lpc_assets.dart';
import 'atlas/sprite_names.dart';
import 'components/atlas_sprite_component.dart';
import 'components/building_component.dart';
import 'components/ground_component.dart';
import 'components/ground_item_component.dart';
import 'components/placement_ghost_component.dart';
import 'components/player_component.dart';
import 'components/tree_component.dart';
import 'particles/particle_burst_component.dart';
import 'particles/particle_bursts.dart';
import 'render/render_depth.dart';

class ForestSceneComponent extends Component {
  final LpcAssets _assets;
  final math.Random _random;
  final Map<String, TreeComponent> _trees = {};
  final Map<String, GroundItemComponent> _items = {};
  final Map<String, BuildingComponent> _buildings = {};
  final List<AtlasSpriteComponent> _clutter = [];
  PlayerComponent? _player;
  PlacementGhostComponent? _ghost;
  bool _isBuilt = false;

  ForestSceneComponent({required LpcAssets assets, math.Random? random})
    : _assets = assets,
      _random = random ?? math.Random();

  Map<String, TreeComponent> get trees => Map.unmodifiable(_trees);

  Map<String, GroundItemComponent> get items => Map.unmodifiable(_items);

  Map<String, BuildingComponent> get buildings => Map.unmodifiable(_buildings);

  List<AtlasSpriteComponent> get clutter => List.unmodifiable(_clutter);

  PlayerComponent? get player => _player;

  PlacementGhostComponent? get ghost => _ghost;

  void show(ForestData data) {
    final world = data.world;
    if (world == null) return;
    if (!_isBuilt) _build(world);
    for (final effect in data.effects) {
      _play(effect);
    }
    _reconcile(world);
    final player = data.player;
    if (player != null) _showPlayer(player);
    _showGhost(data.placement);
  }

  String? treeAt(Vector2 point) {
    TreeComponent? best;
    for (final tree in _trees.values) {
      if (!tree.containsPoint(point)) continue;
      if (best == null || tree.priority > best.priority) best = tree;
    }
    return best?.treeId;
  }

  void _build(WorldSnapshotEntity world) {
    _isBuilt = true;
    add(GroundComponent(tile: _assets.ground, worldWidth: world.width, worldHeight: world.height));
    for (final decoration in world.decorations) {
      _addClutter(SpriteNames.decoration(decoration.kind), decoration.position, decoration.position.y);
    }
  }

  void _play(ForestEffect effect) {
    switch (effect) {
      case ItemPickedUpEffect(:final itemId):
        _items.remove(itemId)?.pickUp();
      case TreeHitEffect(:final treeId, :final fromX):
        final tree = _trees[treeId];
        if (tree == null) return;
        tree.hit(fromX);
        add(
          ParticleBurstComponent(
            particles: ParticleBursts.woodChips(
              trunkBase: tree.base,
              playerOnLeft: fromX < tree.base.x,
              random: _random,
            ),
            sortY: ParticleBursts.chipsSortY(tree.base),
          ),
        );
      case TreeFelledEffect(:final treeId, :final fromX):
        final tree = _trees.remove(treeId);
        if (tree == null) return;
        tree.fell(fromX);
        _addClutter(SpriteNames.stump, tree.base, tree.base.y - 1);
      case BuildingPlacedEffect(:final building):
        final component = _buildings.putIfAbsent(
          building.id,
          () => _added(BuildingComponent(assets: _assets, building: building)),
        );
        _clearClutterUnder(component);
      case BuildingHammeredEffect(:final buildingId, :final progress):
        final building = _buildings[buildingId];
        if (building == null) return;
        building.hammered(progress);
        add(
          ParticleBurstComponent(
            particles: ParticleBursts.dust(buildingCenter: building.center, random: _random),
            sortY: ParticleBursts.dustSortY(building.center),
          ),
        );
      case BuildingCompletedEffect(:final buildingId):
        _buildings[buildingId]?.complete();
    }
  }

  void _reconcile(WorldSnapshotEntity world) {
    final treeIds = {for (final tree in world.trees) tree.id};
    for (final id in _trees.keys.where((id) => !treeIds.contains(id)).toList()) {
      _trees.remove(id)!.removeFromParent();
    }
    for (final tree in world.trees) {
      _trees.putIfAbsent(tree.id, () => _added(TreeComponent(assets: _assets, tree: tree)));
    }

    final itemIds = {for (final item in world.items) item.id};
    for (final id in _items.keys.where((id) => !itemIds.contains(id)).toList()) {
      final item = _items.remove(id)!;
      item.shadow.removeFromParent();
      item.removeFromParent();
    }
    for (final item in world.items) {
      _items.putIfAbsent(item.id, () {
        final component = GroundItemComponent(assets: _assets, item: item);
        add(component.shadow);
        return _added(component);
      });
    }

    for (final building in world.buildings) {
      final existing = _buildings[building.id];
      if (existing == null) {
        _buildings[building.id] = _added(BuildingComponent(assets: _assets, building: building));
      } else if (!existing.isComplete && existing.progress != building.progress) {
        existing.progress = building.progress;
      }
    }
  }

  void _showPlayer(PlayerRenderData player) {
    final current = _player;
    if (current != null) {
      current.show(player);
      return;
    }
    final component = PlayerComponent(assets: _assets, player: player);
    _player = component;
    add(component.shadow);
    add(component);
  }

  void _showGhost(PlacementData? placement) {
    if (placement == null) {
      _ghost?.removeFromParent();
      _ghost = null;
      return;
    }
    final ghost = _ghost ?? _added(PlacementGhostComponent(assets: _assets));
    _ghost = ghost;
    ghost.show(placement);
  }

  void _addClutter(String frameName, PositionEntity at, double sortY) {
    _clutter.add(
      _added(AtlasSpriteComponent(assets: _assets, frameName: frameName, at: at, priority: RenderDepth.bySortY(sortY))),
    );
  }

  void _clearClutterUnder(BuildingComponent building) {
    _clutter.removeWhere((sprite) {
      if (!building.boundsContain(sprite.position)) return false;
      sprite.removeFromParent();
      return true;
    });
  }

  T _added<T extends Component>(T component) {
    add(component);
    return component;
  }
}
```

- [ ] **Step 4: Ejecutar el test y analizar**

Run: `flutter test test/layers/presentation/features/forest/game/forest_scene_component_test.dart && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/layers/presentation/features/forest/game/forest_scene_component.dart test/layers/presentation/features/forest/game/forest_scene_component_test.dart
git commit -m "[PROJECT-X]: Reconcile the forest scene with the bloc state and play its effects"
```

---

### Task 10: Puente con el BLoC, entrada, bucle y cámara

**Files:**
- Create: `game/forest_state_listener.dart`, `game/forest_world.dart`, `game/forest_game.dart`
- Create: `test/mocks/presentation/features/forest/forest_bloc_fake.dart`
- Test: `test/layers/presentation/features/forest/game/forest_game_test.dart`

**Interfaces:**
- Consumes: `ForestSceneComponent`, `LpcAssetsLoader`, `CameraFraming`, `RenderConstants`, `ForestBloc`, eventos `ForestTicked`, `ForestMapClicked`, `ForestPointerMoved`, estados `ForestSuccess`, `ForestInitial`.
- Produces:
  - `ForestStateListener({required ForestSceneComponent scene})` (`FlameBlocListenable<ForestBloc, ForestState>`: `onInitialState` y `onNewState` → `scene.show(state.data)`)
  - `ForestWorld({required ForestBloc bloc, required LpcAssetsLoader assetsLoader, math.Random? random})`: `isReady`, `scene`, `clickAt(Vector2 point, {required bool isMouse, bool isSecondary = false})`, `mouseMovedTo(Vector2 canvasPosition)`, `dragTo(Vector2 point)`, `mousePosition(CameraComponent camera) → PositionEntity?`
  - `ForestGame({required ForestBloc bloc, LpcAssetsLoader? assetsLoader, math.Random? random})`: `update(dt)` envía `ForestPointerMoved` (ratón con colocación activa, recalculado cada fotograma como `pointerInWorld()` de la web) y después `ForestTicked(deltaMs: min(dt, 0.1) * 1000)` cuando el estado es `ForestSuccess`; la cámara sigue al jugador con lerp 0,1 por fotograma (salto inmediato la primera vez), limitada al mundo y ajustada a píxeles de pantalla; fondo `#0E150E`.
  - Test: `ForestBlocFake(ForestState initial)` con `events` y `push(ForestState)`.

Entrada (en `ForestWorld`, un `World` de Flame, que contiene cualquier punto):
- Clic izquierdo con ratón → `ForestMapClicked(position, treeId: scene.treeAt(point), isSecondary: false)`.
- Clic derecho → `ForestMapClicked(position, treeId: scene.treeAt(point), isSecondary: true)` (la web también pasa el árbol; el BLoC lo ignora).
- Toque mientras se coloca → `ForestPointerMoved(position)` (como Android: el toque mueve el fantasma y se confirma con la barra de la fase 7). Arrastre táctil mientras se coloca → `ForestPointerMoved` en cada actualización.
- Movimiento del ratón → se guarda la posición en el canvas; `ForestGame` la convierte a mundo cada fotograma (la cámara se mueve).
- Esc lo gestiona la fase 7.

- [ ] **Step 1: Escribir el doble del BLoC**

`test/mocks/presentation/features/forest/forest_bloc_fake.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';

class ForestBlocFake extends Bloc<ForestEvent, ForestState> implements ForestBloc {
  final List<ForestEvent> events = [];

  ForestBlocFake(super.initialState) {
    on<ForestEvent>((event, emit) => events.add(event));
  }

  void push(ForestState state) => emit(state);
}
```

(Si la fase 7 crea otro doble con el mismo propósito, se queda uno solo en este fichero.)

- [ ] **Step 2: Escribir el test que falla**

`test/layers/presentation/features/forest/game/forest_game_test.dart`:

```dart
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_game.dart';

import '../../../../../mocks/presentation/features/forest/forest_bloc_fake.dart';
import '../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/lpc_assets_loader_fake.dart';
import '../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ForestBlocFake bloc;
  late LpcAssetsLoaderFake loader;

  ForestGame createGame() => ForestGame(bloc: bloc, assetsLoader: loader);

  setUp(() {
    bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.initial));
    loader = LpcAssetsLoaderFake(LpcAssetsMock.create());
  });

  testWithGame<ForestGame>('testWhenLoadedThenBuildsTheSceneFromTheBlocState', createGame, (game) async {
    // given
    await game.ready();

    // when
    final scene = game.world.scene;

    // then
    expect(loader.loadCalled, isTrue);
    expect(game.world.isReady, isTrue);
    expect(scene!.trees.keys, ['tree-1', 'tree-2']);
  });

  testWithGame<ForestGame>('testWhenUpdatingThenTicksTheBlocWithTheFrameTime', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.update(0.016);
    game.update(0.5);
    await _settle();

    // then
    final ticks = bloc.events.whereType<ForestTicked>().map((event) => event.deltaMs);
    expect(ticks, contains(closeTo(16, 1e-9)));
    expect(ticks, contains(closeTo(100, 1e-9)));
  });

  testWithGame<ForestGame>(
    'testWhenTheGameHasNotStartedThenDoesNotTick',
    () => ForestGame(bloc: bloc = ForestBlocFake(ForestInitial()), assetsLoader: loader),
    (game) async {
      // given
      await game.ready();

      // when
      game.update(0.016);
      await _settle();

      // then
      expect(bloc.events.whereType<ForestTicked>(), isEmpty);
    },
  );

  testWithGame<ForestGame>('testWhenUpdatingThenTheCameraFramesTheWorldAtZoomTwo', createGame, (game) async {
    // given
    await game.ready();
    game.onGameResize(Vector2(800, 600));

    // when
    game.update(0.016);

    // then
    expect(game.camera.viewfinder.zoom, 2);
    expect(game.camera.viewfinder.position, Vector2(200, 150));
  });

  testWithGame<ForestGame>('testWhenClickingATreeWithTheMouseThenOrdersTheBlocToChopIt', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.world.clickAt(Vector2(101, 113), isMouse: true);
    await _settle();

    // then
    final click = bloc.events.whereType<ForestMapClicked>().single;
    expect(click.treeId, 'tree-1');
    expect(click.isSecondary, isFalse);
    expect(click.position.x, 101);
    expect(click.position.y, 113);
  });

  testWithGame<ForestGame>('testWhenRightClickingThenTheClickIsSecondary', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.world.clickAt(Vector2(300, 250), isMouse: true, isSecondary: true);
    await _settle();

    // then
    final click = bloc.events.whereType<ForestMapClicked>().single;
    expect(click.isSecondary, isTrue);
    expect(click.treeId, isNull);
  });

  testWithGame<ForestGame>(
    'testWhenTappingWhilePlacingThenMovesTheGhostInsteadOfBuilding',
    () => ForestGame(bloc: bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.placing)), assetsLoader: loader),
    (game) async {
      // given
      await game.ready();

      // when
      game.world.clickAt(Vector2(250, 200), isMouse: false);
      await _settle();

      // then
      expect(bloc.events.whereType<ForestMapClicked>(), isEmpty);
      final moved = bloc.events.whereType<ForestPointerMoved>().single;
      expect(moved.position.x, 250);
      expect(moved.position.y, 200);
    },
  );

  testWithGame<ForestGame>(
    'testWhenTheMouseHoversWhilePlacingThenTheGhostFollowsItEveryFrame',
    () => ForestGame(bloc: bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.placing)), assetsLoader: loader),
    (game) async {
      // given
      await game.ready();
      game.onGameResize(Vector2(800, 600));
      game.update(0.016);

      // when
      game.world.mouseMovedTo(Vector2(400, 300));
      game.update(0.016);
      await _settle();

      // then
      final moved = bloc.events.whereType<ForestPointerMoved>().last;
      expect(moved.position.x, closeTo(200, 1e-9));
      expect(moved.position.y, closeTo(150, 1e-9));
    },
  );
}
```

- [ ] **Step 3: Ejecutarlo y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/game/forest_game_test.dart`
Expected: FAIL, `No such file or directory` en `forest_game.dart`.

- [ ] **Step 4: Implementar**

`game/forest_state_listener.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/forest_bloc.dart';
import 'forest_scene_component.dart';

class ForestStateListener extends Component with FlameBlocListenable<ForestBloc, ForestState> {
  final ForestSceneComponent _scene;

  ForestStateListener({required ForestSceneComponent scene}) : _scene = scene;

  @override
  void onInitialState(ForestState state) {
    _scene.show(state.data);
  }

  @override
  void onNewState(ForestState state) {
    _scene.show(state.data);
  }
}
```

`game/forest_world.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;

import '../../../../domain/entities/geometry/position_entity.dart';
import '../bloc/forest_bloc.dart';
import 'atlas/lpc_assets_loader.dart';
import 'forest_scene_component.dart';
import 'forest_state_listener.dart';
import 'render/position_conversion.dart';

class ForestWorld extends World with TapCallbacks, SecondaryTapCallbacks, PointerMoveCallbacks, DragCallbacks {
  final ForestBloc _bloc;
  final LpcAssetsLoader _assetsLoader;
  final math.Random? _random;
  ForestSceneComponent? _scene;
  Vector2? _mouseCanvasPosition;
  PointerDeviceKind _dragDeviceKind = PointerDeviceKind.unknown;

  ForestWorld({required ForestBloc bloc, required LpcAssetsLoader assetsLoader, math.Random? random})
    : _bloc = bloc,
      _assetsLoader = assetsLoader,
      _random = random;

  ForestSceneComponent? get scene => _scene;

  bool get isReady => _scene != null;

  @override
  Future<void> onLoad() async {
    final scene = ForestSceneComponent(assets: await _assetsLoader.load(), random: _random);
    await add(
      FlameBlocProvider<ForestBloc, ForestState>.value(
        value: _bloc,
        children: [scene, ForestStateListener(scene: scene)],
      ),
    );
    _scene = scene;
  }

  void clickAt(Vector2 point, {required bool isMouse, bool isSecondary = false}) {
    final scene = _scene;
    final state = _bloc.state;
    if (scene == null || state is! ForestSuccess) return;
    final position = point.toPositionEntity();
    if (!isMouse && !isSecondary && state.data.placement != null) {
      _bloc.add(ForestPointerMoved(position: position));
      return;
    }
    _bloc.add(ForestMapClicked(position: position, treeId: scene.treeAt(point), isSecondary: isSecondary));
  }

  void mouseMovedTo(Vector2 canvasPosition) {
    _mouseCanvasPosition = canvasPosition.clone();
  }

  void dragTo(Vector2 point) {
    final state = _bloc.state;
    if (state is! ForestSuccess || state.data.placement == null) return;
    _bloc.add(ForestPointerMoved(position: point.toPositionEntity()));
  }

  PositionEntity? mousePosition(CameraComponent camera) {
    final canvasPosition = _mouseCanvasPosition;
    if (canvasPosition == null) return null;
    return camera.globalToLocal(canvasPosition).toPositionEntity();
  }

  @override
  void onTapDown(TapDownEvent event) {
    clickAt(event.localPosition, isMouse: event.deviceKind == PointerDeviceKind.mouse);
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    clickAt(event.localPosition, isMouse: true, isSecondary: true);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    if (event.deviceKind == PointerDeviceKind.mouse) mouseMovedTo(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragDeviceKind = event.deviceKind;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragDeviceKind != PointerDeviceKind.mouse) dragTo(event.localEndPosition);
  }
}
```

`game/forest_game.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../../../../core/config/constants/render_constants.dart';
import '../bloc/forest_bloc.dart';
import 'atlas/lpc_assets_loader.dart';
import 'forest_world.dart';
import 'render/camera_framing.dart';
import 'render/position_conversion.dart';

class ForestGame extends FlameGame<ForestWorld> {
  final ForestBloc _bloc;
  Vector2? _cameraCenter;

  ForestGame({required ForestBloc bloc, LpcAssetsLoader? assetsLoader, math.Random? random})
    : _bloc = bloc,
      super(
        world: ForestWorld(bloc: bloc, assetsLoader: assetsLoader ?? LpcAssetsLoader(), random: random),
      );

  @override
  Color backgroundColor() => const Color(RenderConstants.backgroundColor);

  @override
  Future<void> onLoad() async {
    camera.viewfinder
      ..zoom = RenderConstants.cameraZoom
      ..anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    _dispatchFrame(dt);
    super.update(dt);
    _followPlayer();
  }

  void _dispatchFrame(double dt) {
    final state = _bloc.state;
    if (state is! ForestSuccess || !world.isReady) return;
    if (state.data.placement != null) {
      final pointer = world.mousePosition(camera);
      if (pointer != null) _bloc.add(ForestPointerMoved(position: pointer));
    }
    _bloc.add(ForestTicked(deltaMs: math.min(dt, RenderConstants.maxFrameSeconds) * 1000));
  }

  void _followPlayer() {
    final data = _bloc.state.data;
    final player = data.player;
    final snapshot = data.world;
    if (player == null || snapshot == null) return;
    final zoom = camera.viewfinder.zoom;
    final target = player.position.toVector2();
    final previous = _cameraCenter;
    final center = CameraFraming.center(
      current: previous ?? target,
      target: target,
      world: Vector2(snapshot.width, snapshot.height),
      view: size / zoom,
      lerp: previous == null ? 1 : RenderConstants.cameraLerp,
    );
    _cameraCenter = center;
    camera.viewfinder.position = CameraFraming.snap(center, zoom);
  }
}
```

El import de `package:flutter/gestures.dart` lleva `show PointerDeviceKind` porque `package:flame/events.dart` también exporta un `PointerMoveEvent`; sin el `show` el nombre es ambiguo y no compila. El tipo de dispositivo del arrastre se guarda en `onDragStart` porque `DragStartEvent` lo expone y `DragUpdateEvent` no siempre.

Si la versión de Flame instalada no tiene `SecondaryTapCallbacks` o no expone `deviceKind` en `TapDownEvent` / `PointerMoveEvent` / `DragStartEvent`, se usa el mismo dato desde el evento original de Flutter (`event.raw.kind`). Si no existe ninguna de las dos cosas, la página envuelve el `GameWidget` en un `Listener` que llama a `world.clickAt(..., isSecondary: true)` cuando `event.buttons == kSecondaryMouseButton`, convirtiendo el punto con `game.camera.globalToLocal`. La desviación se anota en el README §7.

- [ ] **Step 5: Ejecutar los tests y analizar**

Run: `flutter test test/layers/presentation/features/forest/game && flutter analyze`
Expected: `All tests passed!` y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/features/forest/game test/layers/presentation/features/forest/game test/mocks/presentation/features/forest/forest_bloc_fake.dart
git commit -m "[PROJECT-X]: Drive the Flame world from the forest bloc with input, ticks and camera"
```

---

### Task 11: Montar el juego en una página mínima y verificar en Chrome

**Files:**
- Create: `lib/layers/presentation/features/forest/forest_page.dart` (mínima; la fase 7 la reescribe)
- Modify: `lib/layers/presentation/app/container_app.dart` (fase 1: `_emptyBody()` de `ContainerAppView`)

**Interfaces:**
- Consumes: `ForestGame`, `ForestBloc` y su constructor (README §3.7), los 10 casos de uso y `NavigationService` desde `locator`, `ForestStarted`.
- Produces: `ForestPage` (Page/View). La fase 7 conserva el nombre, la ruta y la creación del BLoC, y añade HUD, barra de colocación, snackbars y Esc.

- [ ] **Step 1: Crear la página mínima**

`lib/layers/presentation/features/forest/forest_page.dart`:

```dart
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/di/locator.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../../domain/use-cases/game/advance_game_use_case.dart';
import '../../../domain/use-cases/game/can_place_building_use_case.dart';
import '../../../domain/use-cases/game/chop_tree_use_case.dart';
import '../../../domain/use-cases/game/construct_building_use_case.dart';
import '../../../domain/use-cases/game/get_build_options_use_case.dart';
import '../../../domain/use-cases/game/get_player_status_use_case.dart';
import '../../../domain/use-cases/game/get_quests_use_case.dart';
import '../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
import '../../../domain/use-cases/game/move_player_use_case.dart';
import '../../../domain/use-cases/game/start_game_use_case.dart';
import 'bloc/forest_bloc.dart';
import 'game/forest_game.dart';

class ForestPage extends StatelessWidget {
  const ForestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForestBloc>(
      create: (_) => ForestBloc(
        startGameUseCase: locator.get<StartGameUseCase>(),
        movePlayerUseCase: locator.get<MovePlayerUseCase>(),
        chopTreeUseCase: locator.get<ChopTreeUseCase>(),
        canPlaceBuildingUseCase: locator.get<CanPlaceBuildingUseCase>(),
        constructBuildingUseCase: locator.get<ConstructBuildingUseCase>(),
        advanceGameUseCase: locator.get<AdvanceGameUseCase>(),
        getPlayerStatusUseCase: locator.get<GetPlayerStatusUseCase>(),
        getWorldSnapshotUseCase: locator.get<GetWorldSnapshotUseCase>(),
        getBuildOptionsUseCase: locator.get<GetBuildOptionsUseCase>(),
        getQuestsUseCase: locator.get<GetQuestsUseCase>(),
        navigationService: locator.get<NavigationService>(),
      )..add(ForestStarted()),
      child: const _ForestView(),
    );
  }
}

class _ForestView extends StatefulWidget {
  const _ForestView();

  @override
  State<_ForestView> createState() => _ForestViewState();
}

class _ForestViewState extends State<_ForestView> {
  late final ForestGame _game = ForestGame(bloc: context.read<ForestBloc>());

  @override
  void initState() {
    super.initState();
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<ForestGame>(game: _game);
  }
}
```

(Los nombres de los parámetros con nombre del constructor de `ForestBloc` son los de la fase 5. Si allí difieren, se usan los suyos.)

- [ ] **Step 2: Mostrar la página cuando arranca la app**

En `lib/layers/presentation/app/container_app.dart`, sustituir el cuerpo de `_emptyBody()`:

```dart
  Widget _emptyBody() {
    return const ForestPage();
  }
```

y añadir el import `import '../features/forest/forest_page.dart';`.

- [ ] **Step 3: Pasar todos los tests y el análisis**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `All tests passed!` (incluido `test/architecture_test.dart`: `game/` importa `flame` y `flame_bloc`, permitido en presentación; dominio y datos siguen sin importarlos).

- [ ] **Step 4: Verificación manual en Chrome (con ratón)**

```bash
flutter run -d chrome
```

Comprobar, en este orden:
1. El bosque aparece con el fondo `#0E150E` alrededor si la ventana es mayor que el mundo, los sprites sin desenfoque (píxel nítido) y la cámara centrada en el personaje, sin costuras entre losetas de hierba.
2. El hacha flota junto al personaje con su sombra. Al pasar por encima sube y se desvanece.
3. Clic en el suelo: el personaje camina (andar a 10 fps) y la cámara le sigue con suavidad sin salirse del mundo. Al parar: respiración a 2 fps.
4. Clic en un hueco entre hojas o en la sombra pintada de un árbol: el personaje camina allí, no tala. Clic en dos copas que se solapan: se tala la de delante.
5. Al talar, cada golpe coincide con el fotograma de impacto, el árbol se sacude alejándose del personaje y saltan astillas por delante de él. Al quinto golpe cae hacia el lado contrario, se desvanece en 0,7 s y queda un tocón.
6. Sin HUD todavía, hay que forzar la colocación desde la consola de DevTools de Flutter: hacer hot restart con un `ForestBuildRequested(blueprint: BlueprintId.house)` temporal en la página tras `ForestStarted()`, y **no** hacer commit de ese cambio. El fantasma sigue al ratón, verde donde cabe y rojo donde no. Clic: aparece la obra translúcida con barra amarilla, desaparece la decoración bajo la casa, cada martillazo levanta polvo y vuelve la casa más opaca, y al terminar hace un pequeño rebote y se va la barra.
7. Clic derecho durante la colocación la cancela (sin menú contextual del navegador).

- [ ] **Step 5: Comparar con la web Phaser actual (todavía presente hasta la fase 8)**

```bash
./gradlew :shared:jsBrowserProductionLibraryDistribution
cd webApp && npm ci && npm run dev
```

Abrir ambas apps con la misma ventana (p. ej. 1280×800) y comparar capturas en el arranque, con el personaje junto al hacha y tras talar el árbol más cercano: mismas posiciones de árboles y decoración, mismos tipos de árbol, mismo orden de pintado (el personaje detrás de una copa cuando está por encima del tronco), mismo encuadre. Cualquier diferencia se corrige o se anota en el README §7 con su motivo.

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/features/forest/forest_page.dart lib/layers/presentation/app/container_app.dart
git commit -m "[PROJECT-X]: Show the Flame forest when the app starts"
```

---

## Desajustes entre apps (y decisión)

La referencia es la web publicada. Diferencias encontradas al leer las tres implementaciones:

| Aspecto | Web (Phaser) | Android (Compose) | iOS (SpriteKit) | Flutter |
|---|---|---|---|---|
| Barra de progreso de la obra | sí (60×5, `#E8C05A`) | no | no | sí (web) |
| Rebote al terminar la casa | sí (`scaleY` 0.92→1, Back.easeOut 350 ms) | no | no (solo alpha = 1) | sí (web) |
| Hacha flotando y sombra | sí (±3 px, 700 ms, Sine.easeInOut) | no (sprite fijo, sin sombra) | flota, sin curva Sine | sí (web) |
| Recoger hacha | sube 16 px y se desvanece en 300 ms | desaparece al instante | sube y se desvanece | web |
| Sacudida al golpear | yoyo 70+70 ms, Sine.easeOut, 3° | `3·sin·exp` aproximado, 140 ms | rotación lineal ±0,05 rad | web |
| Caída del árbol | ángulo **y** alpha con Quad.easeIn | ángulo t², alpha lineal | lineal | web |
| Limpieza de decoración al construir | puntos dentro del rectángulo del sprite de la casa | círculo de radio `footprintRadius + 24` | no limpia | web |
| Cámara | lerp 0,1 por fotograma, límites centrados | sigue sin lerp | sigue sin lerp | web |
| Toque en colocación | clic coloca; el fantasma sigue al ratón cada fotograma | el toque mueve el fantasma y la barra confirma | — | ratón como la web, táctil como Android (+ arrastre) |
| Δt por fotograma | sin tope explícito (Phaser suaviza el delta) | sin tope | sin tope | tope de 100 ms para que una pestaña en segundo plano no atraviese obstáculos al volver |
