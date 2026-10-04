import Shared

enum ForestBuilder {
    static func build() -> ForestView {
        let viewModel = ForestViewModel(shared: GameContainer.shared.makeForestViewModel())
        return ForestView(viewModel: viewModel)
    }
}
