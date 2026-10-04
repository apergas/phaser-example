import SwiftUI

struct ForestView: View {
    let viewModel: ForestViewModel

    init(viewModel: ForestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("\(viewModel.state.hud.questBadge) · \(viewModel.state.hud.wood)")
            .task { await viewModel.observe() }
    }
}
