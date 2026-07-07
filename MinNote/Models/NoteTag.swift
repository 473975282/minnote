import SwiftUI

enum NoteTag: String, CaseIterable, Codable, Identifiable, Hashable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .red:
            return "红色"
        case .orange:
            return "橙色"
        case .yellow:
            return "黄色"
        case .green:
            return "绿色"
        case .blue:
            return "蓝色"
        case .purple:
            return "紫色"
        }
    }

    var color: Color {
        switch self {
        case .red:
            return Color(red: 0.925, green: 0.245, blue: 0.275)
        case .orange:
            return Color(red: 0.945, green: 0.560, blue: 0.165)
        case .yellow:
            return Color(red: 0.915, green: 0.735, blue: 0.180)
        case .green:
            return Color(red: 0.260, green: 0.650, blue: 0.335)
        case .blue:
            return Color(red: 0.275, green: 0.480, blue: 0.925)
        case .purple:
            return Color(red: 0.560, green: 0.395, blue: 0.875)
        }
    }
}
