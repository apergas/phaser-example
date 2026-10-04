import SwiftUI

@main
struct RpgApp: App {
    var body: some Scene {
        WindowGroup {
            ForestBuilder.build()
        }
    }
}
