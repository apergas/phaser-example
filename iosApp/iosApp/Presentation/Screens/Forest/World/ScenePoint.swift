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
