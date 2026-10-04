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
        // An empty sprite node keeps a zero size when it gets a texture later.
        ghost.size = ghost.texture?.size() ?? .zero
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
