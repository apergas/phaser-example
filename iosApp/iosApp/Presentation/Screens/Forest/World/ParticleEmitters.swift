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
