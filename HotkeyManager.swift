import AppKit
import Carbon.HIToolbox

/// Listens for a global keyboard shortcut (default: Cmd+Shift+2) even when the app
/// is not focused, and fires a callback when triggered.
///
/// NOTE: Global event monitoring requires the user to grant "Accessibility" or
/// "Input Monitoring" permission in System Settings > Privacy & Security.
/// The first time this runs, macOS will prompt automatically.
final class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    var onTrigger: (() -> Void)?

    // Default shortcut: Cmd+Shift+2
    private let requiredKeyCode: UInt16 = 19 // '2' key
    private let requiredModifiers: NSEvent.ModifierFlags = [.command, .shift]

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
        // Local monitor so the shortcut also works while the app itself is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == requiredKeyCode && flags == requiredModifiers {
            onTrigger?()
        }
    }
}
