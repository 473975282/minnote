import Carbon.HIToolbox
import Foundation

enum HotKeyError: Error, LocalizedError {
    case eventHandlerInstallFailed(OSStatus)
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .eventHandlerInstallFailed(let status):
            return "Hot key event handler install failed with status \(status)."
        case .registrationFailed(let status):
            return "Hot key registration failed with status \(status)."
        }
    }
}

final class HotKeyManager {
    private let handler: @MainActor () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(handler: @escaping @MainActor () -> Void) {
        self.handler = handler
    }

    func register(configuration: HotKeyConfiguration) throws {
        unregister()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let eventStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard eventStatus == noErr else {
            throw HotKeyError.eventHandlerInstallFailed(eventStatus)
        }

        let hotKeyID = EventHotKeyID(signature: Self.fourCharCode("FNT1"), id: 1)
        let registerStatus = RegisterEventHotKey(
            configuration.keyCode,
            configuration.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            unregister()
            throw HotKeyError.registrationFailed(registerStatus)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }

    private static let eventHandler: EventHandlerUPP = { _, _, userData in
        guard let userData else {
            return noErr
        }

        let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
            manager.handler()
        }

        return noErr
    }

    private static func fourCharCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}
