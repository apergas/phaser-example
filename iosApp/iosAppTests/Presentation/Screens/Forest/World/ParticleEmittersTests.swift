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
