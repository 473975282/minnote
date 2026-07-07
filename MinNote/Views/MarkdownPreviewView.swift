import SwiftUI

struct MarkdownPreviewView: View {
    let text: String
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0
    var onTaskToggle: ((Int) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("暂无 Markdown 内容")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(parseBlocks(text)) { block in
                        markdownBlock(block)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20 + topInset)
            .padding(.bottom, 20 + bottomInset)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.clear)
    }

    @ViewBuilder
    private func markdownBlock(_ block: MarkdownBlock) -> some View {
        switch block.kind {
        case .line(let line, let sourceLine):
            markdownLine(line, sourceLine: sourceLine)
        case .table(let rows):
            markdownTable(rows)
        }
    }

    @ViewBuilder
    private func markdownLine(_ line: String, sourceLine: Int) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            Spacer()
                .frame(height: 4)
        } else if trimmed.hasPrefix("### ") {
            Text(inlineMarkdown(String(trimmed.dropFirst(4))))
                .font(.system(size: 16, weight: .semibold))
        } else if trimmed.hasPrefix("## ") {
            Text(inlineMarkdown(String(trimmed.dropFirst(3))))
                .font(.system(size: 19, weight: .semibold))
        } else if trimmed.hasPrefix("# ") {
            Text(inlineMarkdown(String(trimmed.dropFirst(2))))
                .font(.system(size: 24, weight: .bold))
        } else if trimmed.hasPrefix("> ") {
            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(.secondary.opacity(0.35))
                    .frame(width: 3)

                Text(inlineMarkdown(String(trimmed.dropFirst(2))))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if let task = taskItem(from: trimmed) {
            Button {
                onTaskToggle?(sourceLine)
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: task.isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(task.isChecked ? .secondary : .tertiary)
                        .padding(.top, 2)

                    Text(inlineMarkdown(task.text))
                        .strikethrough(task.isChecked, color: .secondary)
                        .foregroundStyle(task.isChecked ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onTaskToggle == nil)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(.secondary)

                Text(inlineMarkdown(String(trimmed.dropFirst(2))))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if trimmed.hasPrefix("```") {
            Text(trimmed)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 6))
        } else {
            Text(inlineMarkdown(trimmed))
                .font(.system(size: 14))
                .lineSpacing(3)
        }
    }

    private func markdownTable(_ rows: [[String]]) -> some View {
        let columnCount = rows.map(\.count).max() ?? 0
        let columnWidths = tableColumnWidths(rows: rows, columnCount: columnCount)

        return ScrollView(.horizontal) {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<columnCount, id: \.self) { columnIndex in
                            Text(inlineMarkdown(cell(in: row, at: columnIndex)))
                                .font(.system(size: 13, weight: rowIndex == 0 ? .semibold : .regular))
                                .foregroundStyle(rowIndex == 0 ? .primary : .secondary)
                                .lineSpacing(3)
                                .frame(width: columnWidths[columnIndex], alignment: .leading)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 7)
                        }
                    }
                    .background(tableCellBackground(rowIndex: rowIndex))
                    .overlay(alignment: .topLeading) {
                        tableColumnDividers(columnWidths: columnWidths)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(.primary.opacity(0.07))
                            .frame(height: rowIndex == rows.count - 1 ? 0 : 1)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.visible)
    }

    private func tableColumnWidths(rows: [[String]], columnCount: Int) -> [CGFloat] {
        guard columnCount > 0 else {
            return []
        }

        return (0..<columnCount).map { columnIndex in
            let maxLength = rows
                .map { cell(in: $0, at: columnIndex).count }
                .max() ?? 0
            let contentWidth = CGFloat(maxLength) * 7.2 + 28

            return min(max(contentWidth, 112), 340)
        }
    }

    private func tableCellBackground(rowIndex: Int) -> Color {
        if rowIndex == 0 {
            return Color.primary.opacity(0.07)
        }

        return Color.primary.opacity(rowIndex.isMultiple(of: 2) ? 0.025 : 0)
    }

    @ViewBuilder
    private func tableColumnDividers(columnWidths: [CGFloat]) -> some View {
        if columnWidths.count > 1 {
            HStack(spacing: 0) {
                ForEach(0..<(columnWidths.count - 1), id: \.self) { columnIndex in
                    Color.clear
                        .frame(width: columnWidths[columnIndex] + 18)

                    Rectangle()
                        .fill(.primary.opacity(0.07))
                        .frame(width: 1)
                }

                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        }
    }

    private func inlineMarkdown(_ source: String) -> AttributedString {
        let pattern = #"~~(.+?)~~"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (try? AttributedString(markdown: source)) ?? AttributedString(source)
        }

        let nsSource = source as NSString
        let matches = regex.matches(
            in: source,
            range: NSRange(location: 0, length: nsSource.length)
        )

        guard !matches.isEmpty else {
            return (try? AttributedString(markdown: source)) ?? AttributedString(source)
        }

        var result = AttributedString()
        var location = 0

        for match in matches {
            if match.range.location > location {
                let plainRange = NSRange(location: location, length: match.range.location - location)
                let chunk = nsSource.substring(with: plainRange)
                result += (try? AttributedString(markdown: chunk)) ?? AttributedString(chunk)
            }

            let inner = nsSource.substring(with: match.range(at: 1))
            var struck = (try? AttributedString(markdown: inner)) ?? AttributedString(inner)
            struck.strikethroughStyle = .single
            result += struck
            location = match.range.location + match.range.length
        }

        if location < nsSource.length {
            let chunk = nsSource.substring(from: location)
            result += (try? AttributedString(markdown: chunk)) ?? AttributedString(chunk)
        }

        return result
    }

    private func taskItem(from trimmed: String) -> (isChecked: Bool, text: String)? {
        let uncheckedPrefix = "- [ ] "
        let checkedPrefixes = ["- [x] ", "- [X] "]

        if trimmed.hasPrefix(uncheckedPrefix) {
            return (false, String(trimmed.dropFirst(uncheckedPrefix.count)))
        }

        for prefix in checkedPrefixes where trimmed.hasPrefix(prefix) {
            return (true, String(trimmed.dropFirst(prefix.count)))
        }

        return nil
    }

    private func parseBlocks(_ source: String) -> [MarkdownBlock] {
        let lines = source.components(separatedBy: .newlines)
        var blocks: [MarkdownBlock] = []
        var index = 0
        var blockID = 0

        while index < lines.count {
            if index + 1 < lines.count,
               isTableRow(lines[index]),
               isSeparatorRow(lines[index + 1]) {
                var rows = [parseTableRow(lines[index])]
                index += 2

                while index < lines.count,
                      isTableRow(lines[index]),
                      !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                    rows.append(parseTableRow(lines[index]))
                    index += 1
                }

                blocks.append(MarkdownBlock(id: blockID, kind: .table(rows)))
            } else {
                blocks.append(MarkdownBlock(id: blockID, kind: .line(lines[index], sourceLine: index)))
                index += 1
            }

            blockID += 1
        }

        return blocks
    }

    private func isTableRow(_ line: String) -> Bool {
        line.contains("|") && parseTableRow(line).count > 1
    }

    private func isSeparatorRow(_ line: String) -> Bool {
        let cells = parseTableRow(line)

        return cells.count > 1 && cells.allSatisfy { cell in
            let trimmed = cell.trimmingCharacters(in: .whitespaces)

            guard trimmed.count >= 3, trimmed.contains("-") else {
                return false
            }

            return trimmed.allSatisfy { character in
                character == "-" || character == ":"
            }
        }
    }

    private func parseTableRow(_ line: String) -> [String] {
        var row = line.trimmingCharacters(in: .whitespaces)

        if row.hasPrefix("|") {
            row.removeFirst()
        }

        if row.hasSuffix("|") {
            row.removeLast()
        }

        return row
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func cell(in row: [String], at index: Int) -> String {
        guard index < row.count else {
            return ""
        }

        return row[index]
    }
}

private struct MarkdownBlock: Identifiable {
    enum Kind {
        case line(String, sourceLine: Int)
        case table([[String]])
    }

    let id: Int
    let kind: Kind
}
