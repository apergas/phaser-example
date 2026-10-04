import Shared
import SwiftUI

@main
struct RpgApp: App {
    var body: some Scene {
        WindowGroup {
            // Temporary: proves the Kotlin framework links. Replaced by ForestBuilder.build() in Task 2.
            Text(firstQuestDescription())
        }
    }

    private func firstQuestDescription() -> String {
        let gameUseCase = GameContainer.shared.makeGameUseCase()
        gameUseCase.startGame()
        return gameUseCase.quests().first?.description ?? ""
    }
}
