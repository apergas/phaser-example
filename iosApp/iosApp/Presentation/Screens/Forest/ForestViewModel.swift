import Foundation
import Observation
import Shared

typealias SharedForestViewModel = Shared.ForestViewModel

@Observable
final class ForestViewModel {
    private let shared: SharedForestViewModel

    var state: ForestState
    var message: String?
    var onEffect: ((ForestEffect) -> Void)?

    /// Read every frame by the SpriteKit scene, without waiting for the async observation.
    var currentState: ForestState { shared.uiState.value }

    init(shared: SharedForestViewModel) {
        self.shared = shared
        state = shared.uiState.value
    }

    func worldSnapshot() -> WorldSnapshot {
        shared.worldSnapshot()
    }
}

@MainActor
extension ForestViewModel {
    /// Mirrors the shared state for SwiftUI and forwards one-off effects; runs for the screen's lifetime.
    func observe() async {
        async let states: Void = observeStates()
        async let effects: Void = observeEffects()
        _ = await (states, effects)
    }

    func tick(deltaMs: Double) {
        shared.onIntent(intent: ForestIntentTick(deltaMs: deltaMs))
    }

    func mapClicked(at point: Position, treeId: String?) {
        shared.onIntent(intent: ForestIntentMapClicked(position: point, treeId: treeId, isSecondary: false))
    }

    func pointerMoved(to point: Position) {
        shared.onIntent(intent: ForestIntentPointerMoved(position: point))
    }

    func requestBuild(_ blueprint: BlueprintId) {
        shared.onIntent(intent: ForestIntentBuildRequested(blueprint: blueprint))
    }

    /// Touch adaptation: places the building where the preview currently is.
    func confirmPlacement() {
        guard let placement = currentState.placement else { return }
        shared.onIntent(intent: ForestIntentMapClicked(position: placement.position, treeId: nil, isSecondary: false))
    }

    func cancelPlacement() {
        shared.onIntent(intent: ForestIntentPlacementCancelled.shared)
    }
}

@MainActor
private extension ForestViewModel {
    func observeStates() async {
        for await newState in shared.uiState {
            state = newState
        }
    }

    func observeEffects() async {
        for await effect in shared.uiEffect {
            if case .showMessage(let show) = onEnum(of: effect) {
                message = show.text
            } else {
                onEffect?(effect)
            }
        }
    }
}
