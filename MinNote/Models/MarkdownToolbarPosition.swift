import Foundation

enum MarkdownToolbarPosition: String, CaseIterable, Identifiable, Hashable {
    case top
    case bottom

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .top:
            return "顶部"
        case .bottom:
            return "底部"
        }
    }
}
