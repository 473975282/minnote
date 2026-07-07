import Foundation

struct PlainNote: Identifiable, Equatable {
    let id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var fileURL: URL?
    var format: NoteFormat
    var tag: NoteTag?

    var title: String {
        guard let firstLine = firstContentLine
        else {
            return "无标题"
        }

        let cleaned = cleanTitle(firstLine)
        return cleaned.isEmpty ? "无标题" : String(cleaned.prefix(40))
    }

    var filenameTitle: String? {
        guard let firstLine = firstContentLine else {
            return nil
        }

        let cleaned = cleanTitle(firstLine)
        return cleaned.isEmpty ? nil : cleaned
    }

    var preview: String {
        let lines = text.components(separatedBy: .newlines)
        let firstContentIndex = lines.firstIndex {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        let bodyLines = lines.enumerated()
            .filter { index, line in
                index != firstContentIndex
                    && !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .map(\.element)

        let compactText = bodyLines
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !compactText.isEmpty else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "空白便笺" : "无正文"
        }

        return String(compactText.prefix(54))
    }

    var characterCount: Int {
        text.count
    }

    private var firstContentLine: String? {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }

    private func cleanTitle(_ line: String) -> String {
        var cleaned = line

        while cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
