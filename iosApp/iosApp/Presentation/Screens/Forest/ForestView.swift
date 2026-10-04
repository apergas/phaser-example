import Shared
import SpriteKit
import SwiftUI

struct ForestView: View {
    let viewModel: ForestViewModel
    @State private var scene: ForestScene?

    init(viewModel: ForestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60)
                        .ignoresSafeArea()
                        .accessibilityLabel(ForestLabels.Accessibility.shared.GAME_WORLD)
                }
                HudView(
                    hud: viewModel.state.hud,
                    isPlacing: viewModel.state.placement != nil,
                    message: viewModel.message,
                    onBuild: { viewModel.requestBuild($0) },
                    onConfirmPlacement: { viewModel.confirmPlacement() },
                    onCancelPlacement: { viewModel.cancelPlacement() }
                )
            }
            .onAppear {
                if scene == nil { scene = ForestScene(viewModel: viewModel, size: geometry.size) }
            }
        }
        .task { await viewModel.observe() }
    }
}
