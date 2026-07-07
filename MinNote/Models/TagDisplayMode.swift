import Foundation

enum TagDisplayMode: String, CaseIterable, Identifiable, Hashable {
    case compact
    case tags

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .compact:
            return "简洁"
        case .tags:
            return "标签"
        }
    }
}
