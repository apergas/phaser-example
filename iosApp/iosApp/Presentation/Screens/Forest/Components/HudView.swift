import SwiftUI
import Shared

struct HudView: View {
    let hud: HudState
    let isPlacing: Bool
    let message: String?
    let onBuild: (BlueprintId) -> Void
    let onConfirmPlacement: () -> Void
    let onCancelPlacement: () -> Void

    @State private var isQuestsOpen = false
    @State private var isBuildOpen = false

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    resources
                    Spacer()
                    actions
                }
                Spacer()
                if isPlacing { placementBar }
                if let message { toast(message) }
            }
            .padding(12)
        }
    }

    private var resources: some View {
        HStack(spacing: 16) {
            Text("\(ForestLabels.shared.WOOD) \(hud.wood)").foregroundStyle(.yellow)
            Text(ForestLabels.shared.AXE).opacity(hud.hasAxe ? 1 : 0.35)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
    }

    private var actions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                Button("\(ForestLabels.shared.QUESTS) \(hud.questBadge)") { isQuestsOpen.toggle(); isBuildOpen = false }
                Button(ForestLabels.shared.BUILD) { isBuildOpen.toggle(); isQuestsOpen = false }
                    .disabled(hud.isBuildLocked)
            }
            .buttonStyle(.borderedProminent)
            if isQuestsOpen {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(hud.quests, id: \.title) { quest in
                        HStack {
                            Text(quest.title).strikethrough(quest.status == .done)
                            Spacer()
                            Text(quest.progressText).foregroundStyle(.yellow)
                        }
                    }
                }
                .frame(maxWidth: 320)
                .padding(12)
                .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            }
            if isBuildOpen {
                ForEach(hud.buildItems, id: \.name) { item in
                    Button("\(item.name) · \(item.costText)\(item.missingText.map { " · \($0)" } ?? "")") {
                        isBuildOpen = false
                        onBuild(item.blueprint)
                    }
                    .disabled(!item.isEnabled)
                }
            }
        }
    }

    private var placementBar: some View {
        HStack(spacing: 12) {
            Button(ForestLabels.Placement.shared.CONFIRM, action: onConfirmPlacement).buttonStyle(.borderedProminent)
            Button(ForestLabels.Placement.shared.CANCEL, action: onCancelPlacement).buttonStyle(.bordered)
        }
    }

    private func toast(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
            .accessibilityAddTraits(.updatesFrequently)
    }
}
