import Shared
import XCTest

final class SharedFrameworkTests: XCTestCase {
    func testWhenStartingAGameThenTheSharedForestIsLoaded() {
        // given
        let gameUseCase = GameContainer.shared.makeGameUseCase()

        // when
        gameUseCase.startGame()

        // then
        XCTAssertEqual(gameUseCase.worldSnapshot().trees.count, 70)
    }
}
