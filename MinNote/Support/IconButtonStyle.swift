import SwiftUI

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary.opacity(configuration.isPressed ? 0.62 : 0.86))
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.primary.opacity(configuration.isPressed ? 0.12 : 0.055))
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
