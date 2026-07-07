import Foundation

enum NoteFormat: String, CaseIterable, Identifiable, Hashable {
    case text
    case markdown

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .text:
            return "TXT"
        case .markdown:
            return "Markdown"
        }
    }

    var shortTitle: String {
        fileExtension.uppercased()
    }

    var fileExtension: String {
        switch self {
        case .text:
            return "txt"
        case .markdown:
            return "md"
        }
    }

    static func from(fileExtension: String) -> NoteFormat? {
        switch fileExtension.lowercased() {
        case "txt":
            return .text
        case "md", "markdown":
            return .markdown
        default:
            return nil
        }
    }
}
