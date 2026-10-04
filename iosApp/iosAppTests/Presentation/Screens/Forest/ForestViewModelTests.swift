import XCTest
import Shared
@testable import iosApp

final class ForestViewModelTests: XCTestCase {
    var sut: iosApp.ForestViewModel!

    override func setUp() {
        super.setUp()
        sut = iosApp.ForestViewModel(shared: GameContainer.shared.makeForestViewModel())
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }
}
