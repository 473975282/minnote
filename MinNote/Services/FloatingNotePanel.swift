import AppKit

final class FloatingNotePanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func cancelOperation(_ sender: Any?) {
        if let event = NSApp.currentEvent,
           event.type == .keyDown {
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if modifiers.contains(.command),
               event.charactersIgnoringModifiers == "." || event.keyCode == 47 {
                return
            }
        }

        onCancel?()
    }
}
