# Fase 8 — App iOS (SwiftUI + SpriteKit)

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Una app iOS que juega la misma partida usando el framework `Shared`: mundo en SpriteKit dentro de SwiftUI, HUD en SwiftUI, misiones y construcción táctil.

**Architecture:** Proyecto Xcode `iosApp` con la estructura de la skill de iOS: `Presentation/App`, `Presentation/Screens/Forest/` (`ForestView` + `ForestViewModel` + `ForestBuilder` + `Components/` + `World/`). El `ForestViewModel` de Swift es `@Observable` y envuelve al `ForestViewModel` compartido (Kotlin): observa `uiState`/`uiEffect` con SKIE y reenvía los intents. El `ForestBuilder` obtiene el ViewModel compartido de `GameContainer` (Kotlin), que hace de `Container`.

**Tech Stack:** Swift 5.9+, iOS 17+, SwiftUI (`@Observable`), SpriteKit (`SpriteView`), framework `Shared` (Kotlin/Native, estático) con SKIE, XCTest.

## Global Constraints

Las de [`README.md`](README.md#global-constraints) y las de la skill de iOS: `@Observable` en el ViewModel, funciones que tocan estado en una `extension` `@MainActor`, vista que recibe el ViewModel por `init`, `Builder` como única entrada para crear la pantalla, conformidad a protocolos en `extension`, `self` solo cuando hace falta, booleanos con `is`/`has`/`should`; tests XCTest con clase base (`setUp`/`tearDown`) y métodos en extensiones dentro de `Tests/`, `// given` `// when` `// then`, nombres `testWhen...Then...` sin guiones bajos.

**Notas de interoperabilidad:**
- Desde Swift, el ViewModel compartido es `Shared.ForestViewModel` (el módulo se llama `Shared`); el de la app es `ForestViewModel`. Para que no haya ambigüedad se usa `typealias SharedForestViewModel = Shared.ForestViewModel`.
- SKIE expone `StateFlow`/`SharedFlow` como `AsyncSequence` (`for await`) y las sealed como `onEnum(of:)` para `switch` exhaustivo. Los `enum class` de Kotlin llegan en minúscula (`BlueprintId.house`); los `object`/`data object` como `.shared` (`ForestIntent.PlacementCancelled.shared`).
- Coordenadas: el dominio tiene la Y hacia abajo; SpriteKit hacia arriba. Toda la conversión vive en `World/ScenePoint.swift`. El orden de pintado usa `zPosition = worldY` (más abajo en el mundo = encima).

## File Structure

```
iosApp/
  iosApp.xcodeproj
  iosApp/
    Presentation/App/RpgApp.swift
    Presentation/Screens/Forest/
      ForestView.swift            SwiftUI: SpriteView + HUD superpuesto
      ForestViewModel.swift       @Observable, envuelve SharedForestViewModel
      ForestBuilder.swift
      Components/HudView.swift    recursos, botones, paneles, barra de colocación, toast
      World/ScenePoint.swift      conversión mundo ↔ escena
      World/LpcAtlas.swift        texturas, frames del atlas y máscara alfa
      World/ForestScene.swift     SKScene: nodos, cámara, bucle, efectos, toques
      World/ParticleEmitters.swift astillas y polvo con SKEmitterNode (mismos valores que la web)
    Resources/lpc/               copiado por build_assets.py (referencia de carpeta)
  iosAppTests/
    Presentation/Screens/Forest/ForestViewModelTests.swift
    Presentation/Screens/Forest/Tests/TickForestViewModelTests.swift
    Presentation/Screens/Forest/Tests/PlacementForestViewModelTests.swift
    Presentation/Screens/Forest/World/ParticleEmittersTests.swift
asset-packs/lpc/build_assets.py   + copia a iosApp/iosApp/Resources/lpc/
```

---

### Task 1: Proyecto Xcode enlazado con `Shared`

**Files:**
- Create: `iosApp/iosApp.xcodeproj` (Xcode), `iosApp/iosApp/Presentation/App/RpgApp.swift`
- Modify: `asset-packs/lpc/build_assets.py`

**Interfaces:**
- Consumes: framework `Shared` (fase 1: `binaries.framework { baseName = "Shared"; isStatic = true }`).
- Produces: app iOS que arranca y puede `import Shared`.

- [ ] **Step 1: Crear el proyecto** — Xcode → New Project → iOS App; Product Name `iosApp`; Interface SwiftUI; Language Swift; Include Tests ✓; guardar en `phaser-example/iosApp/`. Deployment target iOS 17.0. Bundle id `com.apergas.rpg`.

- [ ] **Step 2: Compilar el framework desde Xcode** — Target `iosApp` → Build Phases → `+` New Run Script Phase, **antes** de *Compile Sources*, con:
```bash
cd "$SRCROOT/.."
./gradlew :shared:embedAndSignAppleFrameworkForXcode
```
Build Settings del target: `Framework Search Paths` += `$(SRCROOT)/../shared/build/xcode-frameworks/$(CONFIGURATION)/$(SDK_NAME)`; `Other Linker Flags` += `-framework Shared`; `User Script Sandboxing` = `No` (el script ejecuta Gradle).

- [ ] **Step 3: Assets** — en `build_assets.py`, junto a la copia de Android:
```python
    ios_out = ROOT.parent.parent / "iosApp" / "iosApp" / "Resources" / "lpc"
    shutil.copytree(OUT, ios_out, dirs_exist_ok=True)
```
Run: `cd asset-packs/lpc && python3 build_assets.py`. En Xcode: arrastrar `iosApp/Resources/lpc` al proyecto como **folder reference** (carpeta azul), target `iosApp`.

- [ ] **Step 4: Entrada de la app** (sustituye la plantilla; borrar `ContentView.swift`)

`Presentation/App/RpgApp.swift`:
```swift
import SwiftUI

@main
struct RpgApp: App {
    var body: some Scene {
        WindowGroup {
            ForestBuilder.build()
        }
    }
}
```
(`ForestBuilder` se crea en la Task 2; para este paso, temporalmente `Text(GameContainer.shared.makeGameUseCase().quests().first?.description ?? "")` con `import Shared`.)

- [ ] **Step 5: Ejecutar** — Product → Run en un simulador (iPhone, horizontal).
Expected: compila Gradle + Swift y muestra la descripción de la primera misión.

- [ ] **Step 6: Commit**

```bash
git add iosApp asset-packs/lpc/build_assets.py
git commit -m "[PROJECT-X]: Add iOS app linked to the shared Kotlin framework"
```

---

### Task 2: `ForestViewModel` (Swift) + `ForestBuilder` + tests

**Files:**
- Create: `Presentation/Screens/Forest/ForestViewModel.swift`, `ForestBuilder.swift`
- Test: `iosAppTests/Presentation/Screens/Forest/ForestViewModelTests.swift`, `Tests/TickForestViewModelTests.swift`, `Tests/PlacementForestViewModelTests.swift`

**Interfaces:**
- Consumes: `SharedForestViewModel`, `ForestState`, `ForestEffect`, `ForestIntent`, `WorldSnapshot`, `Position`, `BlueprintId`, `GameContainer` (Kotlin).
- Produces:
```swift
@Observable final class ForestViewModel {
    var state: ForestState            // para SwiftUI (HUD)
    var message: String?              // último ShowMessage, para el toast
    var currentState: ForestState { get }   // lectura síncrona para SpriteKit en cada fotograma
    var onEffect: ((ForestEffect) -> Void)? // la escena SpriteKit se registra
    func worldSnapshot() -> WorldSnapshot
}
@MainActor extension ForestViewModel {
    func observe() async
    func tick(deltaMs: Double)
    func mapClicked(at point: Position, treeId: String?)
    func pointerMoved(to point: Position)
    func requestBuild(_ blueprint: BlueprintId)
    func confirmPlacement()
    func cancelPlacement()
}
enum ForestBuilder { static func build() -> ForestView }
```

- [ ] **Step 1: Tests** (patrón de la skill: clase base + extensiones en `Tests/`)

`ForestViewModelTests.swift`:
```swift
import XCTest
import Shared
@testable import iosApp

final class ForestViewModelTests: XCTestCase {
    var sut: ForestViewModel!

    override func setUp() {
        super.setUp()
        sut = ForestViewModel(shared: GameContainer.shared.makeForestViewModel())
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }
}
```

`Tests/TickForestViewModelTests.swift`:
```swift
import XCTest
import Shared
@testable import iosApp

extension ForestViewModelTests {
    @MainActor
    func testWhenFirstTickThenWelcomeMessageIsForwarded() async {
        let expectation = XCTestExpectation(description: "testWhenFirstTickThenWelcomeMessageIsForwarded")

        // given
        let observation = Task { await sut.observe() }

        // when
        try? await Task.sleep(nanoseconds: 50_000_000)
        sut.tick(deltaMs: 16)

        // then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.message, "Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        observation.cancel()
    }

    @MainActor
    func testWhenTickingThenCurrentStateIsAvailableSynchronously() {
        // given
        let start = sut.currentState.player.position

        // when
        sut.mapClicked(at: Position(x: start.x + 50, y: start.y), treeId: nil)
        sut.tick(deltaMs: 1000)

        // then
        XCTAssertEqual(sut.currentState.player.position.x, 850)
    }
}
```

`Tests/PlacementForestViewModelTests.swift`:
```swift
import XCTest
import Shared
@testable import iosApp

extension ForestViewModelTests {
    @MainActor
    func testWhenRequestingABuildWithoutWoodThenNoPlacementStarts() {
        // given
        sut.tick(deltaMs: 16)

        // when
        sut.requestBuild(.house)

        // then
        XCTAssertNil(sut.currentState.placement)
    }

    @MainActor
    func testWhenCancellingPlacementThenPlacementIsCleared() {
        // given
        sut.requestBuild(.house)

        // when
        sut.cancelPlacement()

        // then
        XCTAssertNil(sut.currentState.placement)
    }
}
```

Nota: `GameContainer` comparte una sesión por proceso; `makeForestViewModel()` llama a `startGame()` y la reinicia, así que cada test empieza con partida nueva (posición `(800, 600)`).

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `xcodebuild test -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: FAIL — `cannot find 'ForestViewModel' in scope` (el de Swift).

- [ ] **Step 3: Implementar `ForestViewModel.swift`**

```swift
import Foundation
import Observation
import Shared

typealias SharedForestViewModel = Shared.ForestViewModel

@Observable
final class ForestViewModel {
    private let shared: SharedForestViewModel

    var state: ForestState
    var message: String?
    var onEffect: ((ForestEffect) -> Void)?

    /// Read every frame by the SpriteKit scene, without waiting for the async observation.
    var currentState: ForestState { shared.uiState.value }

    init(shared: SharedForestViewModel) {
        self.shared = shared
        state = shared.uiState.value
    }

    func worldSnapshot() -> WorldSnapshot {
        shared.worldSnapshot()
    }
}

@MainActor
extension ForestViewModel {
    /// Mirrors the shared state for SwiftUI and forwards one-off effects; runs for the screen's lifetime.
    func observe() async {
        async let states: Void = observeStates()
        async let effects: Void = observeEffects()
        _ = await (states, effects)
    }

    func tick(deltaMs: Double) {
        shared.onIntent(intent: ForestIntent.Tick(deltaMs: deltaMs))
    }

    func mapClicked(at point: Position, treeId: String?) {
        shared.onIntent(intent: ForestIntent.MapClicked(position: point, treeId: treeId, isSecondary: false))
    }

    func pointerMoved(to point: Position) {
        shared.onIntent(intent: ForestIntent.PointerMoved(position: point))
    }

    func requestBuild(_ blueprint: BlueprintId) {
        shared.onIntent(intent: ForestIntent.BuildRequested(blueprint: blueprint))
    }

    /// Touch adaptation: places the building where the preview currently is.
    func confirmPlacement() {
        guard let placement = currentState.placement else { return }
        shared.onIntent(intent: ForestIntent.MapClicked(position: placement.position, treeId: nil, isSecondary: false))
    }

    func cancelPlacement() {
        shared.onIntent(intent: ForestIntent.PlacementCancelled.shared)
    }
}

@MainActor
private extension ForestViewModel {
    func observeStates() async {
        for await newState in shared.uiState {
            state = newState
        }
    }

    func observeEffects() async {
        for await effect in shared.uiEffect {
            if case .showMessage(let show) = onEnum(of: effect) {
                message = show.text
            } else {
                onEffect?(effect)
            }
        }
    }
}
```

`ForestBuilder.swift`:
```swift
import Shared

enum ForestBuilder {
    static func build() -> ForestView {
        let viewModel = ForestViewModel(shared: GameContainer.shared.makeForestViewModel())
        return ForestView(viewModel: viewModel)
    }
}
```

`ForestView.swift` (provisional hasta la Task 3):
```swift
import SwiftUI

struct ForestView: View {
    let viewModel: ForestViewModel

    init(viewModel: ForestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("\(viewModel.state.hud.questBadge) · \(viewModel.state.hud.wood)")
            .task { await viewModel.observe() }
    }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: el mismo `xcodebuild test`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add iosApp
git commit -m "[PROJECT-X]: Add iOS forest view model wrapping the shared one"
```

---

### Task 3: Mundo en SpriteKit y HUD en SwiftUI

**Files:**
- Create: `World/ScenePoint.swift`, `World/LpcAtlas.swift`, `World/ForestScene.swift`, `Components/HudView.swift`
- Modify: `ForestView.swift` (versión final)

**Interfaces:**
- Consumes: `ForestViewModel` (Task 2); `SpriteNames` (Kotlin, `presentation/forest`); assets `Resources/lpc`.
- Produces: `ForestView` final.

Constantes de render: las mismas que la web y Android (zoom 2; personaje 64 px con origen Y 62/64; filas `up, left, down, right`; andar columnas 1–8 a 10 fps; quieto 2 columnas a 2 fps; trabajo 128 px, 6 columnas, origen Y 94/128, secuencias `[0,0,5,5,4,4,3,1]` y `[0,0,5,5,4,4,1]`; árboles y decoración: sprite que da `SpriteNames` a partir del tipo del nivel; casa 24 px por debajo del centro de su huella; obra con alfa `0.35 + 0.65·progreso`).

- [ ] **Step 1: `ScenePoint.swift`**

```swift
import CoreGraphics
import Shared

/// The domain's Y axis points down (like the web); SpriteKit's points up. Every conversion lives here.
struct ScenePoint {
    let worldHeight: Double

    func scene(_ position: Position) -> CGPoint {
        CGPoint(x: position.x, y: worldHeight - position.y)
    }

    func world(_ point: CGPoint) -> Position {
        Position(x: Double(point.x), y: worldHeight - Double(point.y))
    }
}
```

- [ ] **Step 2: `LpcAtlas.swift`**

```swift
import SpriteKit
import UIKit

struct AtlasFrame: Decodable {
    struct Rect: Decodable { let x: Int; let y: Int; let w: Int; let h: Int }
    struct Pivot: Decodable { let x: Double; let y: Double }
    let frame: Rect
    let pivot: Pivot?
}

/// LPC textures and the Phaser JSON-hash atlas generated by build_assets.py.
final class LpcAtlas {
    private struct AtlasFile: Decodable { let frames: [String: AtlasFrame] }

    private let forestImage: CGImage
    private let forestTexture: SKTexture
    private let alpha: [UInt8]
    let frames: [String: AtlasFrame]
    private(set) var textures: [String: SKTexture] = [:]

    init() {
        let url = Bundle.main.url(forResource: "forest", withExtension: "json", subdirectory: "lpc")!
        frames = try! JSONDecoder().decode(AtlasFile.self, from: Data(contentsOf: url)).frames
        forestImage = Self.image(named: "forest").cgImage!
        forestTexture = Self.texture(from: forestImage)
        alpha = Self.alphaChannel(of: forestImage)
        for (name, entry) in frames {
            textures[name] = Self.subTexture(of: forestTexture, image: forestImage, x: entry.frame.x, y: entry.frame.y, width: entry.frame.w, height: entry.frame.h)
        }
    }

    /// SpriteKit anchors from the bottom-left, the atlas pivot from the top-left.
    func anchor(of name: String) -> CGPoint {
        let pivot = frames[name]?.pivot
        return CGPoint(x: pivot?.x ?? 0.5, y: 1 - (pivot?.y ?? 0.5))
    }

    /// Same threshold as the web: the painted tree shadow does not count as the tree.
    func isOpaque(frame name: String, localX: Int, localY: Int) -> Bool {
        guard let entry = frames[name], (0..<entry.frame.w).contains(localX), (0..<entry.frame.h).contains(localY) else { return false }
        let index = (entry.frame.y + localY) * forestImage.width + entry.frame.x + localX
        return alpha[index] >= 200
    }

    static func image(named name: String) -> UIImage {
        UIImage(contentsOfFile: Bundle.main.path(forResource: name, ofType: "png", inDirectory: "lpc")!)!
    }

    static func texture(from image: CGImage) -> SKTexture {
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .nearest
        return texture
    }

    /// A cell of a sheet, given in top-left pixel coordinates.
    static func subTexture(of texture: SKTexture, image: CGImage, x: Int, y: Int, width: Int, height: Int) -> SKTexture {
        let imageWidth = Double(image.width), imageHeight = Double(image.height)
        let rect = CGRect(x: Double(x) / imageWidth, y: 1 - Double(y + height) / imageHeight, width: Double(width) / imageWidth, height: Double(height) / imageHeight)
        let cell = SKTexture(rect: rect, in: texture)
        cell.filteringMode = .nearest
        return cell
    }

    private static func alphaChannel(of image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height)
        let context = CGContext(data: &pixels, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }
}
```

- [ ] **Step 3: `ForestScene.swift`**

```swift
import SpriteKit
import Shared

private let cameraZoom: CGFloat = 2
private let houseFrontOffset = 24.0
private let facingRows: [Facing] = [.up, .left, .down, .right]
private let chopSequence = [0, 0, 5, 5, 4, 4, 3, 1]
private let hammerSequence = [0, 0, 5, 5, 4, 4, 1]

/// Passive SpriteKit view of the game: advances the view model each frame, plays its effects, draws its state.
final class ForestScene: SKScene {
    private let viewModel: ForestViewModel
    private let atlas = LpcAtlas()
    private let points: ScenePoint
    private let snapshot: WorldSnapshot
    private let player = SKSpriteNode()
    private let ghost = SKSpriteNode()
    private var trees: [String: (node: SKSpriteNode, frame: String, base: Position)] = [:]
    private var items: [String: SKSpriteNode] = [:]
    private var buildings: [String: SKSpriteNode] = [:]
    private var sheets: [String: (texture: SKTexture, image: CGImage)] = [:]
    private var lastTime: TimeInterval?

    init(viewModel: ForestViewModel, size: CGSize) {
        self.viewModel = viewModel
        snapshot = viewModel.worldSnapshot()
        points = ScenePoint(worldHeight: snapshot.height)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.055, green: 0.082, blue: 0.055, alpha: 1)
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        for name in ["hero-walk", "hero-idle", "hero-walk-axe", "hero-idle-axe", "hero-chop", "hero-hammer", "ground"] {
            let image = LpcAtlas.image(named: name).cgImage!
            sheets[name] = (LpcAtlas.texture(from: image), image)
        }
        addGround()
        // What to draw and where comes from the level (shared): no art decisions are made here.
        for decoration in snapshot.decorations {
            addDecoration(frame: SpriteNames.shared.decoration(kind: decoration.kind), position: decoration.position)
        }
        for tree in snapshot.trees {
            addTree(id: tree.id, frame: SpriteNames.shared.tree(kind: tree.kind), base: tree.position)
        }
        for item in snapshot.items { addItem(id: item.id, position: item.position) }
        for building in snapshot.buildings { addBuilding(id: building.id, center: building.position, progress: building.progress) }

        player.anchorPoint = CGPoint(x: 0.5, y: 2.0 / 64)
        addChild(player)
        ghost.texture = atlas.textures["house"]
        ghost.anchorPoint = atlas.anchor(of: "house")
        ghost.alpha = 0.6
        ghost.zPosition = 1_000_000
        ghost.isHidden = true
        addChild(ghost)

        let camera = SKCameraNode()
        camera.setScale(1 / cameraZoom)
        addChild(camera)
        self.camera = camera
        viewModel.onEffect = { [weak self] effect in self?.play(effect) }
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = (currentTime - (lastTime ?? currentTime)) * 1000
        lastTime = currentTime
        viewModel.tick(deltaMs: delta)

        let state = viewModel.currentState
        render(state.player, at: currentTime)
        renderGhost(state.placement)
        followPlayer(state.player.position)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let world = points.world(point)
        if viewModel.currentState.placement != nil {
            viewModel.pointerMoved(to: world)
        } else {
            viewModel.mapClicked(at: world, treeId: treeAt(world))
        }
    }
}

private extension ForestScene {
    func addGround() {
        let tile = 32
        let width = Int(snapshot.width), height = Int(snapshot.height)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }())
        let tileImage = UIImage(cgImage: sheets["ground"]!.image)
        let image = renderer.image { _ in
            for y in stride(from: 0, to: height, by: tile) {
                for x in stride(from: 0, to: width, by: tile) { tileImage.draw(at: CGPoint(x: x, y: y)) }
            }
        }
        let ground = SKSpriteNode(texture: LpcAtlas.texture(from: image.cgImage!))
        ground.anchorPoint = .zero
        ground.position = CGPoint(x: 0, y: 0)
        ground.zPosition = -2
        addChild(ground)
    }

    func addTree(id: String, frame: String, base: Position) {
        let node = SKSpriteNode(texture: atlas.textures[frame])
        node.anchorPoint = atlas.anchor(of: frame)
        node.position = points.scene(base)
        node.zPosition = base.y
        addChild(node)
        trees[id] = (node, frame, base)
    }

    func addDecoration(frame: String, position: Position) {
        let node = SKSpriteNode(texture: atlas.textures[frame])
        node.anchorPoint = atlas.anchor(of: frame)
        node.position = points.scene(position)
        node.zPosition = position.y
        addChild(node)
    }

    func addItem(id: String, position: Position) {
        let node = SKSpriteNode(texture: atlas.textures["axe-pickup"])
        node.position = points.scene(Position(x: position.x, y: position.y - 8))
        node.zPosition = position.y
        node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: 0.7), .moveBy(x: 0, y: -3, duration: 0.7)])))
        addChild(node)
        items[id] = node
    }

    func addBuilding(id: String, center: Position, progress: Double) {
        let front = Position(x: center.x, y: center.y + houseFrontOffset)
        let node = SKSpriteNode(texture: atlas.textures["house"])
        node.anchorPoint = atlas.anchor(of: "house")
        node.position = points.scene(front)
        node.zPosition = front.y
        node.alpha = 0.35 + 0.65 * progress
        addChild(node)
        buildings[id] = node
    }

    func play(_ effect: ForestEffect) {
        switch onEnum(of: effect) {
        case .itemPickedUp(let picked):
            items.removeValue(forKey: picked.itemId)?.run(.sequence([.group([.moveBy(x: 0, y: 16, duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        case .treeHit(let hit):
            guard let tree = trees[hit.treeId] else { return }
            let direction: CGFloat = hit.fromX < tree.base.x ? -1 : 1
            tree.node.run(.sequence([.rotate(byAngle: 0.05 * direction, duration: 0.07), .rotate(byAngle: -0.05 * direction, duration: 0.07)]))
        case .treeFelled(let felled):
            guard let tree = trees.removeValue(forKey: felled.treeId) else { return }
            let direction: CGFloat = felled.fromX < tree.base.x ? -1 : 1
            let stump = SKSpriteNode(texture: atlas.textures["stump"])
            stump.anchorPoint = atlas.anchor(of: "stump")
            stump.position = tree.node.position
            stump.zPosition = tree.base.y - 1
            addChild(stump)
            tree.node.run(.sequence([.group([.rotate(byAngle: 1.48 * direction, duration: 0.7), .fadeOut(withDuration: 0.7)]), .removeFromParent()]))
        case .buildingPlaced(let placed):
            addBuilding(id: placed.building.id, center: placed.building.position, progress: placed.building.progress)
        case .buildingHammered(let hammered):
            buildings[hammered.buildingId]?.alpha = 0.35 + 0.65 * hammered.progress
        case .buildingCompleted(let completed):
            buildings[completed.buildingId]?.alpha = 1
        case .showMessage:
            break
        }
    }

    func render(_ state: PlayerRenderState, at time: TimeInterval) {
        let row = facingRows.firstIndex(of: state.facing) ?? 2
        let sheetName: String, cell: Int, column: Int, originY: Double
        switch onEnum(of: state.pose) {
        case .work(let work):
            let sequence = work.tool == .axe ? chopSequence : hammerSequence
            let step = min(sequence.count - 1, Int(work.swingProgress * Double(sequence.count)))
            (sheetName, cell, column, originY) = (work.tool == .axe ? "hero-chop" : "hero-hammer", 128, sequence[step], 94.0 / 128)
        case .walk(let walk):
            (sheetName, cell, column, originY) = (walk.withAxe ? "hero-walk-axe" : "hero-walk", 64, 1 + Int(time * 10) % 8, 62.0 / 64)
        case .idle(let idle):
            (sheetName, cell, column, originY) = (idle.withAxe ? "hero-idle-axe" : "hero-idle", 64, Int(time * 2) % 2, 62.0 / 64)
        }
        let sheet = sheets[sheetName]!
        player.texture = LpcAtlas.subTexture(of: sheet.texture, image: sheet.image, x: column * cell, y: row * cell, width: cell, height: cell)
        player.size = CGSize(width: cell, height: cell)
        player.anchorPoint = CGPoint(x: 0.5, y: 1 - originY)
        player.position = points.scene(state.position)
        player.zPosition = state.position.y
    }

    func renderGhost(_ placement: Placement?) {
        guard let placement else { ghost.isHidden = true; return }
        ghost.isHidden = false
        ghost.position = points.scene(Position(x: placement.position.x, y: placement.position.y + houseFrontOffset))
        ghost.color = placement.isValid ? UIColor(red: 0.72, green: 1, blue: 0.72, alpha: 1) : UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
        ghost.colorBlendFactor = 1
    }

    /// Keeps the camera inside the world; a world smaller than the screen stays centred.
    func followPlayer(_ position: Position) {
        let viewWidth = size.width / cameraZoom, viewHeight = size.height / cameraZoom
        func axis(_ center: CGFloat, _ world: CGFloat, _ view: CGFloat) -> CGFloat {
            view >= world ? world / 2 : min(max(center, view / 2), world - view / 2)
        }
        let target = points.scene(position)
        camera?.position = CGPoint(x: axis(target.x, snapshot.width, viewWidth), y: axis(target.y, snapshot.height, viewHeight))
    }

    /// The front-most tree whose opaque pixels are under this world point.
    func treeAt(_ point: Position) -> String? {
        trees.sorted { $0.value.base.y > $1.value.base.y }.first { _, tree in
            guard let frame = atlas.frames[tree.frame] else { return false }
            let left = tree.base.x - Double(frame.frame.w) * (frame.pivot?.x ?? 0.5)
            let top = tree.base.y - Double(frame.frame.h) * (frame.pivot?.y ?? 0.5)
            return atlas.isOpaque(frame: tree.frame, localX: Int(point.x - left), localY: Int(point.y - top))
        }?.key
    }
}
```

- [ ] **Step 4: `HudView.swift`**

```swift
import SwiftUI
import Shared

struct HudView: View {
    let hud: HudState
    let isPlacing: Bool
    let message: String?
    let onBuild: (BlueprintId) -> Void
    let onConfirmPlacement: () -> Void
    let onCancelPlacement: () -> Void

    @State private var isQuestsOpen = false
    @State private var isBuildOpen = false

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    resources
                    Spacer()
                    actions
                }
                Spacer()
                if isPlacing { placementBar }
                if let message { toast(message) }
            }
            .padding(12)
        }
    }

    private var resources: some View {
        HStack(spacing: 16) {
            Text("\(ForestLabels.shared.WOOD) \(hud.wood)").foregroundStyle(.yellow)
            Text(ForestLabels.shared.AXE).opacity(hud.hasAxe ? 1 : 0.35)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
    }

    private var actions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                Button("\(ForestLabels.shared.QUESTS) \(hud.questBadge)") { isQuestsOpen.toggle(); isBuildOpen = false }
                Button(ForestLabels.shared.BUILD) { isBuildOpen.toggle(); isQuestsOpen = false }
                    .disabled(hud.isBuildLocked)
            }
            .buttonStyle(.borderedProminent)
            if isQuestsOpen {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(hud.quests, id: \.title) { quest in
                        HStack {
                            Text(quest.title).strikethrough(quest.status == .done)
                            Spacer()
                            Text(quest.progressText).foregroundStyle(.yellow)
                        }
                    }
                }
                .frame(maxWidth: 320)
                .padding(12)
                .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            }
            if isBuildOpen {
                ForEach(hud.buildItems, id: \.name) { item in
                    Button("\(item.name) · \(item.costText)\(item.missingText.map { " · \($0)" } ?? "")") {
                        isBuildOpen = false
                        onBuild(item.blueprint)
                    }
                    .disabled(!item.isEnabled)
                }
            }
        }
    }

    private var placementBar: some View {
        HStack(spacing: 12) {
            Button(ForestLabels.Placement.shared.CONFIRM, action: onConfirmPlacement).buttonStyle(.borderedProminent)
            Button(ForestLabels.Placement.shared.CANCEL, action: onCancelPlacement).buttonStyle(.bordered)
        }
    }

    private func toast(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
            .accessibilityAddTraits(.updatesFrequently)
    }
}
```

- [ ] **Step 5: `ForestView.swift` final**

```swift
import SpriteKit
import SwiftUI

struct ForestView: View {
    let viewModel: ForestViewModel
    @State private var scene: ForestScene?

    init(viewModel: ForestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60)
                        .ignoresSafeArea()
                        .accessibilityLabel(ForestLabels.Accessibility.shared.GAME_WORLD)
                }
                HudView(
                    hud: viewModel.state.hud,
                    isPlacing: viewModel.state.placement != nil,
                    message: viewModel.message,
                    onBuild: { viewModel.requestBuild($0) },
                    onConfirmPlacement: { viewModel.confirmPlacement() },
                    onCancelPlacement: { viewModel.cancelPlacement() }
                )
            }
            .onAppear {
                if scene == nil { scene = ForestScene(viewModel: viewModel, size: geometry.size) }
            }
        }
        .task { await viewModel.observe() }
    }
}
```

- [ ] **Step 6: Partida en simulador** — Run en iPhone (horizontal) y comprobar: mismo bosque que la web; recoger el hacha → aviso; tocar árbol → se coloca al lado, hachazos con sacudida, cae y deja tocón; 3 árboles → ≥15 madera; Construir → Casa → tocar sitio (fantasma verde/rojo) → **Construir aquí** → casa construida; Misiones 3/3.

- [ ] **Step 7: Tests y commit**

Run: `xcodebuild test -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: PASS.

```bash
git add iosApp
git commit -m "[PROJECT-X]: Add SpriteKit forest world and SwiftUI HUD on iOS"
```

### Task 4: Partículas (astillas y polvo)

**Files:**
- Create: `iosApp/iosApp/Presentation/Screens/Forest/World/ParticleEmitters.swift`
- Modify: `World/ForestScene.swift` (ramas `treeHit` y `buildingHammered` de `play`, y un `emit`)
- Test: `iosApp/iosAppTests/Presentation/Screens/Forest/World/ParticleEmittersTests.swift`

**Interfaces:**
- Consumes: `ForestScene.play(_:)`, `ScenePoint` (Task 3).
- Produces: `ParticleEmitters.woodChips(playerOnLeft:) -> SKEmitterNode`, `ParticleEmitters.dust() -> SKEmitterNode`.

SpriteKit ya trae sistema de partículas (`SKEmitterNode`): basta configurarlo con los valores de la web (`TreeView.hit`, `BuildingView.hammered`, `PreloadScene.generateParticleTextures`). Dos diferencias de convención: SpriteKit mide los ángulos en sentido antihorario con la Y hacia arriba (el ángulo web `a` pasa a ser `360 − a`), y sus rangos son el ancho total alrededor de un valor central (30–80 → `55` ± `50/2`).

| Efecto | Origen (mundo) | Cantidad | Velocidad | Ángulo web → SpriteKit | Gravedad | Vida | Alfa | Escala | Aspecto |
|---|---|---|---|---|---|---|---|---|---|
| Astillas (`treeHit`) | base del tronco − 10 en Y | 8 | 55 ± 25 | 200–290 → 115° ± 45° si el jugador está a la izquierda; 250–340 → 65° ± 45° si a la derecha | `yAcceleration = −220` | 0.5 s | 1 → 0 | 1 | textura 3×2 `#8A5A2B` con brillo 2×1 `#C89A5E`, giro al azar |
| Polvo (`buildingHammered`) | frente de la casa − 4 en Y | 6 | 22.5 ± 12.5 | 180–360 → 90° ± 90° | 0 | 0.45 s | 0.7 → 0 | 0.8 → 0.2 | círculo de 6 px `#D8CDB0` |

- [ ] **Step 1: Test**

`ParticleEmittersTests.swift`:
```swift
import XCTest
import SpriteKit
@testable import iosApp

final class ParticleEmittersTests: XCTestCase {
    func testWhenPlayerIsOnTheLeftThenChipsAimUpAndLeft() {
        // given
        let playerOnLeft = true

        // when
        let emitter = ParticleEmitters.woodChips(playerOnLeft: playerOnLeft)

        // then
        XCTAssertEqual(emitter.numParticlesToEmit, 8)
        XCTAssertEqual(emitter.emissionAngle, 115 * .pi / 180, accuracy: 0.0001)
        XCTAssertEqual(emitter.emissionAngleRange, 90 * .pi / 180, accuracy: 0.0001)
        XCTAssertEqual(emitter.yAcceleration, -220)
    }

    func testWhenPlayerIsOnTheRightThenChipsAimUpAndRight() {
        // given
        let playerOnLeft = false

        // when
        let emitter = ParticleEmitters.woodChips(playerOnLeft: playerOnLeft)

        // then
        XCTAssertEqual(emitter.emissionAngle, 65 * .pi / 180, accuracy: 0.0001)
    }

    func testWhenHammeringThenDustRisesAndShrinksOverItsLifetime() {
        // given / when
        let emitter = ParticleEmitters.dust()

        // then
        XCTAssertEqual(emitter.numParticlesToEmit, 6)
        XCTAssertEqual(emitter.emissionAngle, .pi / 2, accuracy: 0.0001)
        XCTAssertEqual(emitter.particleScale + emitter.particleScaleSpeed * emitter.particleLifetime, 0.2, accuracy: 0.0001)
        XCTAssertEqual(emitter.particleAlpha + emitter.particleAlphaSpeed * emitter.particleLifetime, 0, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `xcodebuild test -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:iosAppTests/ParticleEmittersTests`
Expected: FAIL (`Cannot find 'ParticleEmitters' in scope`).

- [ ] **Step 3: `ParticleEmitters.swift`**

```swift
import SpriteKit
import UIKit

/// The web's bursts (TreeView.hit, BuildingView.hammered) with the same Phaser emitter values.
/// SpriteKit angles are counter-clockwise with Y up, so a web angle `a` becomes `360 − a`;
/// its ranges are total widths around a centre value.
enum ParticleEmitters {
    static func woodChips(playerOnLeft: Bool) -> SKEmitterNode {
        let emitter = burst(texture: woodChip, count: 8, lifetime: 0.5)
        emitter.particleSpeed = 55
        emitter.particleSpeedRange = 50
        emitter.emissionAngle = degrees(playerOnLeft ? 115 : 65)
        emitter.emissionAngleRange = degrees(90)
        emitter.yAcceleration = -220
        emitter.particleRotationRange = 2 * .pi
        emitter.particleAlpha = 1
        emitter.particleAlphaSpeed = -1 / 0.5
        return emitter
    }

    static func dust() -> SKEmitterNode {
        let emitter = burst(texture: dustPuff, count: 6, lifetime: 0.45)
        emitter.particleSpeed = 22.5
        emitter.particleSpeedRange = 25
        emitter.emissionAngle = degrees(90)
        emitter.emissionAngleRange = degrees(180)
        emitter.particleScale = 0.8
        emitter.particleScaleSpeed = (0.2 - 0.8) / 0.45
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.7 / 0.45
        return emitter
    }

    /// All particles at once, like Phaser's `explode()`.
    private static func burst(texture: SKTexture, count: Int, lifetime: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.numParticlesToEmit = count
        emitter.particleBirthRate = 10_000
        emitter.particleLifetime = lifetime
        return emitter
    }

    private static let woodChip = texture(width: 3, height: 2) { context in
        context.setFillColor(color(0x8A5A2B))
        context.fill(CGRect(x: 0, y: 0, width: 3, height: 2))
        context.setFillColor(color(0xC89A5E))
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 1))
    }

    private static let dustPuff = texture(width: 6, height: 6) { context in
        context.setFillColor(color(0xD8CDB0))
        context.fillEllipse(in: CGRect(x: 0, y: 0, width: 6, height: 6))
    }

    private static func texture(width: Int, height: Int, draw: (CGContext) -> Void) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .image { draw($0.cgContext) }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    private static func color(_ hex: UInt32) -> CGColor {
        CGColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func degrees(_ value: CGFloat) -> CGFloat { value * .pi / 180 }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: el mismo comando del Step 2.
Expected: PASS.

- [ ] **Step 5: Emitir desde `ForestScene.swift`** — sustituir las ramas `treeHit` y `buildingHammered` de `play(_:)`:

```swift
        case .treeHit(let hit):
            guard let tree = trees[hit.treeId] else { return }
            let direction: CGFloat = hit.fromX < tree.base.x ? -1 : 1
            tree.node.run(.sequence([.rotate(byAngle: 0.05 * direction, duration: 0.07), .rotate(byAngle: -0.05 * direction, duration: 0.07)]))
            emit(ParticleEmitters.woodChips(playerOnLeft: hit.fromX < tree.base.x),
                 at: Position(x: tree.base.x, y: tree.base.y - 10), zPosition: tree.base.y + 0.5)
```
```swift
        case .buildingHammered(let hammered):
            guard let building = buildings[hammered.buildingId] else { return }
            building.alpha = 0.35 + 0.65 * hammered.progress
            let front = points.world(building.position)
            emit(ParticleEmitters.dust(), at: Position(x: front.x, y: front.y - 4), zPosition: front.y + 1)
```

y añadir, junto a `addItem`:

```swift
    /// Plays a one-shot emitter in world coordinates and removes it once its particles have faded.
    func emit(_ emitter: SKEmitterNode, at position: Position, zPosition: Double) {
        emitter.position = points.scene(position)
        emitter.zPosition = zPosition
        emitter.targetNode = self
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.6), .removeFromParent()]))
    }
```

- [ ] **Step 6: Comprobar en simulador** — talar un árbol y construir la casa: en cada hachazo saltan 8 astillas hacia el jugador y caen; en cada martillazo sube polvo del frente de la casa. Comparar a ojo con la web abierta al lado.

- [ ] **Step 7: Commit**

```bash
git add iosApp
git commit -m "[PROJECT-X]: Add wood chip and dust particles to the iOS forest"
```

---

## Self-review de la fase

- [ ] Se prueba en local: `xcodebuild test ...` (Tasks 2 y 4) y la partida en simulador (Task 3, Step 6, y Task 4, Step 6). No hay CI para iOS (alcance acordado).
- [ ] El código Swift no reimplementa reglas: todo cambio de juego pasa por `onIntent` del ViewModel compartido.
- [ ] La única conversión de coordenadas está en `ScenePoint`.
- [ ] Mismos tipos de árbol y misma decoración que la web y Android: vienen del nivel compartido; ninguna lista de sprites ni `SeededRandom` en Swift.
- [ ] Astillas y polvo con los mismos valores que los emisores de Phaser (tabla de la Task 4), traducidos a la convención de SpriteKit.
- [ ] Todos los textos salen de `ForestLabels` (shared), también la barra táctil y la accesibilidad: ningún literal en español en Swift salvo en los tests que comprueban mensajes. El nombre de la app va en `Info.plist`.
