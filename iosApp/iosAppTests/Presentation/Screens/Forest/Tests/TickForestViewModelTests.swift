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
