import Foundation

enum PanelAttachment: String, CaseIterable, Identifiable, Hashable {
    case left
    case right
    case bottom

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .left:
            return "左侧"
        case .right:
            return "右侧"
        case .bottom:
            return "底部"
        }
    }
}
