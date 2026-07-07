import AppKit
import SwiftUI

struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var configuration: HotKeyConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator(configuration: $configuration)
    }

    func makeNSView(context: Context) -> HotKeyRecorderButton {
        let button = HotKeyRecorderButton()
        button.configuration = configuration
        button.onCapture = { configuration in
            context.coordinator.capture(configuration)
        }
        return button
    }

    func updateNSView(_ nsView: HotKeyRecorderButton, context: Context) {
        nsView.configuration = configuration
    }

    final class Coordinator {
        private var configuration: Binding<HotKeyConfiguration>

        init(configuration: Binding<HotKeyConfiguration>) {
            self.configuration = configuration
        }

        func capture(_ configuration: HotKeyConfiguration) {
            self.configuration.wrappedValue = configuration
        }
    }
}

final class HotKeyRecorderButton: NSButton {
    var configuration: HotKeyConfiguration = .default {
        didSet {
            if !isRecording {
                updateTitle()
            }
        }
    }

    var onCapture: ((HotKeyConfiguration) -> Void)?

    private var isRecording = false {
        didSet {
            updateTitle()
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        isBordered = true
        focusRingType = .default
        setButtonType(.momentaryPushIn)
        updateTitle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateTitle()
    }

    override func mouseDown(with event: NSEvent) {
        startRecording()
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode != 53 else {
            stopRecording()
            return
        }

        guard let configuration = HotKeyConfiguration(event: event) else {
            NSSound.beep()
            return
        }

        self.configuration = configuration
        onCapture?(configuration)
        stopRecording()
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            stopRecording()
        }

        return super.resignFirstResponder()
    }

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    private func stopRecording() {
        isRecording = false
    }

    private func updateTitle() {
        title = isRecording ? "录入中..." : configuration.displayString
    }
}
