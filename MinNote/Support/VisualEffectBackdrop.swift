import AppKit
import SwiftUI

struct VisualEffectBackdrop: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    var isEmphasized = false

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = isEmphasized
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = isEmphasized
    }
}

struct TransparentLiquidBackground: View {
    var material: NSVisualEffectView.Material = .popover
    var tint: Color
    var sheen: Color
    var reflection: Color
    var topGlow: Color

    var body: some View {
        ZStack {
            VisualEffectBackdrop(material: material)

            Rectangle()
                .fill(tint)

            LinearGradient(
                colors: [
                    sheen,
                    .clear,
                    reflection
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    topGlow,
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.screen)
        }
    }
}
