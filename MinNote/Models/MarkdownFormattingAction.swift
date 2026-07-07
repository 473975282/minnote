import AppKit
import Foundation

enum MarkdownFormattingAction: String, CaseIterable, Identifiable, Hashable {
    case body
    case heading1
    case heading2
    case heading3
    case bold
    case italic
    case strikethrough
    case bulletList
    case numberedList
    case taskList
    case quote
    case inlineCode
    case codeBlock
    case table

    var id: String {
        rawValue
    }

    static let rows: [[MarkdownFormattingAction]] = [
        [.body, .heading1, .heading2, .heading3, .bold, .italic, .strikethrough],
        [.bulletList, .numberedList, .taskList, .quote, .inlineCode, .codeBlock, .table]
    ]

    var shortTitle: String {
        switch self {
        case .body:
            return "正文"
        case .heading1:
            return "H1"
        case .heading2:
            return "H2"
        case .heading3:
            return "H3"
        case .bold:
            return "B"
        case .italic:
            return "I"
        case .strikethrough:
            return "S"
        case .bulletList:
            return "•"
        case .numberedList:
            return "1."
        case .taskList:
            return "☐"
        case .quote:
            return ">"
        case .inlineCode:
            return "`"
        case .codeBlock:
            return "{}"
        case .table:
            return "表"
        }
    }

    var settingsTitle: String {
        switch self {
        case .body:
            return "正文"
        case .heading1:
            return "一级标题"
        case .heading2:
            return "二级标题"
        case .heading3:
            return "三级标题"
        case .bold:
            return "加粗"
        case .italic:
            return "斜体"
        case .strikethrough:
            return "删除线"
        case .bulletList:
            return "无序列表"
        case .numberedList:
            return "有序列表"
        case .taskList:
            return "任务列表"
        case .quote:
            return "引用"
        case .inlineCode:
            return "行内代码"
        case .codeBlock:
            return "代码块"
        case .table:
            return "表格"
        }
    }

    var help: String {
        settingsTitle
    }

    func apply(to textView: NSTextView) {
        switch self {
        case .body:
            applyLineStyle(to: textView, prefix: nil)
        case .heading1:
            applyLineStyle(to: textView, prefix: "# ")
        case .heading2:
            applyLineStyle(to: textView, prefix: "## ")
        case .heading3:
            applyLineStyle(to: textView, prefix: "### ")
        case .bold:
            toggleWrapSelection(in: textView, prefix: "**", suffix: "**", placeholder: "加粗文字")
        case .italic:
            toggleWrapSelection(in: textView, prefix: "*", suffix: "*", placeholder: "斜体文字")
        case .strikethrough:
            toggleWrapSelection(in: textView, prefix: "~~", suffix: "~~", placeholder: "删除线文字")
        case .bulletList:
            applyLineStyle(to: textView, prefix: "- ")
        case .numberedList:
            applyNumberedList(to: textView)
        case .taskList:
            applyTaskList(to: textView)
        case .quote:
            applyLineStyle(to: textView, prefix: "> ")
        case .inlineCode:
            toggleWrapSelection(in: textView, prefix: "`", suffix: "`", placeholder: "代码")
        case .codeBlock:
            insertBlock(in: textView, body: "代码", leading: "```\n", trailing: "\n```")
        case .table:
            insertTemplate(
                in: textView,
                template: "| 列一 | 列二 |\n| --- | --- |\n| 内容 | 内容 |"
            )
        }
    }

    func applying(to text: String) -> String {
        let separator = text.isEmpty || text.hasSuffix("\n") ? "" : "\n"
        return text + separator + fallbackTemplate
    }

    private var fallbackTemplate: String {
        switch self {
        case .body:
            return "正文"
        case .heading1:
            return "# 一级标题"
        case .heading2:
            return "## 二级标题"
        case .heading3:
            return "### 三级标题"
        case .bold:
            return "**加粗文字**"
        case .italic:
            return "*斜体文字*"
        case .strikethrough:
            return "~~删除线文字~~"
        case .bulletList:
            return "- 列表项"
        case .numberedList:
            return "1. 列表项"
        case .taskList:
            return "- [ ] item"
        case .quote:
            return "> 引用"
        case .inlineCode:
            return "`代码`"
        case .codeBlock:
            return "```\n代码\n```"
        case .table:
            return "| 列一 | 列二 |\n| --- | --- |\n| 内容 | 内容 |"
        }
    }

    private func applyLineStyle(to textView: NSTextView, prefix: String?) {
        let nsString = textView.string as NSString
        let selectedRange = textView.selectedRange()
        let lineRange = nsString.lineRange(for: selectedRange)
        let original = nsString.substring(with: lineRange)
        let hasTrailingNewline = original.hasSuffix("\n")
        var lines = original.components(separatedBy: "\n")

        if hasTrailingNewline {
            lines.removeLast()
        }

        let shouldRemove = prefix.map { marker in
            lines
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .allSatisfy { $0.trimmingCharacters(in: .whitespaces).hasPrefix(marker) }
        } ?? true

        let transformed = lines
            .map { line -> String in
                let stripped = stripLeadingMarkdownMarker(from: line)

                guard let prefix,
                      !shouldRemove,
                      !stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return stripped
                }

                return prefix + stripped
            }
            .joined(separator: "\n") + (hasTrailingNewline ? "\n" : "")

        replace(
            in: textView,
            range: lineRange,
            with: transformed,
            selectedRange: NSRange(location: lineRange.location, length: (transformed as NSString).length)
        )
    }

    private func applyNumberedList(to textView: NSTextView) {
        let nsString = textView.string as NSString
        let selectedRange = textView.selectedRange()
        let lineRange = nsString.lineRange(for: selectedRange)
        let original = nsString.substring(with: lineRange)
        let hasTrailingNewline = original.hasSuffix("\n")
        var lines = original.components(separatedBy: "\n")

        if hasTrailingNewline {
            lines.removeLast()
        }

        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let shouldRemove = !nonEmptyLines.isEmpty && nonEmptyLines.allSatisfy {
            $0.trimmingCharacters(in: .whitespaces).range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil
        }

        let transformed = lines.enumerated()
            .map { index, line -> String in
                let stripped = stripLeadingMarkdownMarker(from: line)

                guard !shouldRemove,
                      !stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return stripped
                }

                return "\(index + 1). \(stripped)"
            }
            .joined(separator: "\n") + (hasTrailingNewline ? "\n" : "")

        replace(
            in: textView,
            range: lineRange,
            with: transformed,
            selectedRange: NSRange(location: lineRange.location, length: (transformed as NSString).length)
        )
    }

    private func applyTaskList(to textView: NSTextView) {
        let nsString = textView.string as NSString
        let selectedRange = textView.selectedRange()
        let lineRange = nsString.lineRange(for: selectedRange)
        let original = nsString.substring(with: lineRange)
        let hasTrailingNewline = original.hasSuffix("\n")
        var lines = original.components(separatedBy: "\n")

        if hasTrailingNewline {
            lines.removeLast()
        }

        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let shouldRemove = !nonEmptyLines.isEmpty && nonEmptyLines.allSatisfy {
            $0.trimmingCharacters(in: .whitespaces).range(of: #"^- \[[ xX]\]\s+"#, options: .regularExpression) != nil
        }

        let transformed = lines
            .map { line -> String in
                let stripped = stripLeadingMarkdownMarker(from: line)

                guard !shouldRemove,
                      !stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return stripped
                }

                return "- [ ] \(stripped)"
            }
            .joined(separator: "\n") + (hasTrailingNewline ? "\n" : "")

        replace(
            in: textView,
            range: lineRange,
            with: transformed,
            selectedRange: NSRange(location: lineRange.location, length: (transformed as NSString).length)
        )
    }

    private func toggleWrapSelection(
        in textView: NSTextView,
        prefix: String,
        suffix: String,
        placeholder: String
    ) {
        let nsString = textView.string as NSString
        let selectedRange = textView.selectedRange()
        let selectedText = nsString.substring(with: selectedRange)

        if selectedText.hasPrefix(prefix),
           selectedText.hasSuffix(suffix),
           selectedText.count >= prefix.count + suffix.count {
            let innerStart = (prefix as NSString).length
            let innerLength = (selectedText as NSString).length - innerStart - (suffix as NSString).length
            let inner = (selectedText as NSString).substring(with: NSRange(location: innerStart, length: innerLength))
            replace(
                in: textView,
                range: selectedRange,
                with: inner,
                selectedRange: NSRange(location: selectedRange.location, length: (inner as NSString).length)
            )
            return
        }

        let prefixLength = (prefix as NSString).length
        let suffixLength = (suffix as NSString).length
        let beforeLocation = selectedRange.location - prefixLength
        let afterLocation = selectedRange.location + selectedRange.length

        if beforeLocation >= 0,
           afterLocation + suffixLength <= nsString.length,
           nsString.substring(with: NSRange(location: beforeLocation, length: prefixLength)) == prefix,
           nsString.substring(with: NSRange(location: afterLocation, length: suffixLength)) == suffix,
           !isAmbiguousSingleAsteriskToggle(prefix: prefix, in: nsString, beforeLocation: beforeLocation, afterLocation: afterLocation) {
            let replacementRange = NSRange(
                location: beforeLocation,
                length: prefixLength + selectedRange.length + suffixLength
            )
            replace(
                in: textView,
                range: replacementRange,
                with: selectedText,
                selectedRange: NSRange(location: beforeLocation, length: selectedRange.length)
            )
            return
        }

        let inner = selectedText.isEmpty ? placeholder : selectedText
        let replacement = prefix + inner + suffix
        let innerLocation = selectedRange.location + prefixLength

        replace(
            in: textView,
            range: selectedRange,
            with: replacement,
            selectedRange: NSRange(location: innerLocation, length: (inner as NSString).length)
        )
    }

    private func isAmbiguousSingleAsteriskToggle(
        prefix: String,
        in string: NSString,
        beforeLocation: Int,
        afterLocation: Int
    ) -> Bool {
        guard prefix == "*" else {
            return false
        }

        let previousIsAsterisk = beforeLocation > 0
            && string.substring(with: NSRange(location: beforeLocation - 1, length: 1)) == "*"
        let nextIsAsterisk = afterLocation + 1 < string.length
            && string.substring(with: NSRange(location: afterLocation + 1, length: 1)) == "*"

        return previousIsAsterisk || nextIsAsterisk
    }

    private func insertBlock(
        in textView: NSTextView,
        body: String,
        leading: String,
        trailing: String
    ) {
        let nsString = textView.string as NSString
        let selectedRange = textView.selectedRange()
        let selectedText = nsString.substring(with: selectedRange)
        let inner = selectedText.isEmpty ? body : selectedText
        let before = needsLeadingNewline(in: nsString, at: selectedRange.location) ? "\n" : ""
        let after = needsTrailingNewline(in: nsString, after: selectedRange.location + selectedRange.length) ? "\n" : ""
        let replacement = before + leading + inner + trailing + after
        let innerLocation = selectedRange.location + (before + leading as NSString).length

        replace(
            in: textView,
            range: selectedRange,
            with: replacement,
            selectedRange: NSRange(location: innerLocation, length: (inner as NSString).length)
        )
    }

    private func insertTemplate(in textView: NSTextView, template: String) {
        let nsString = textView.string as NSString
        let selectedRange = textView.selectedRange()
        let before = needsLeadingNewline(in: nsString, at: selectedRange.location) ? "\n" : ""
        let after = needsTrailingNewline(in: nsString, after: selectedRange.location + selectedRange.length) ? "\n" : ""
        let replacement = before + template + after

        replace(
            in: textView,
            range: selectedRange,
            with: replacement,
            selectedRange: NSRange(location: selectedRange.location, length: (replacement as NSString).length)
        )
    }

    private func stripLeadingMarkdownMarker(from line: String) -> String {
        var trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("#") {
            while trimmed.hasPrefix("#") {
                trimmed.removeFirst()
            }
            return trimmed.trimmingCharacters(in: .whitespaces)
        }

        if let range = trimmed.range(of: #"^- \[[ xX]\]\s+"#, options: .regularExpression) {
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        for marker in ["- ", "* ", "+ ", "> "] where trimmed.hasPrefix(marker) {
            return String(trimmed.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }

        if let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        return trimmed
    }

    private func replace(
        in textView: NSTextView,
        range: NSRange,
        with replacement: String,
        selectedRange: NSRange
    ) {
        guard textView.shouldChangeText(in: range, replacementString: replacement) else {
            return
        }

        textView.textStorage?.replaceCharacters(in: range, with: replacement)
        textView.didChangeText()
        textView.setSelectedRange(selectedRange)
        textView.scrollRangeToVisible(selectedRange)
    }

    private func needsLeadingNewline(in string: NSString, at location: Int) -> Bool {
        guard location > 0 else {
            return false
        }

        return string.substring(with: NSRange(location: location - 1, length: 1)) != "\n"
    }

    private func needsTrailingNewline(in string: NSString, after location: Int) -> Bool {
        guard location < string.length else {
            return false
        }

        return string.substring(with: NSRange(location: location, length: 1)) != "\n"
    }
}
