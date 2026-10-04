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
