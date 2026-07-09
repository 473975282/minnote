import SwiftUI

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        IconButtonChrome(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct IconButtonChrome<Label: View>: View {
    let isPressed: Bool
    private let label: Label

    init(isPressed: Bool, @ViewBuilder label: () -> Label) {
        self.isPressed = isPressed
        self.label = label()
    }

    var body: some View {
        label
            .foregroundStyle(.primary.opacity(isPressed ? 0.62 : 0.86))
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.primary.opacity(isPressed ? 0.12 : 0.055))
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
