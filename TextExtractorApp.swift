import SwiftUI

@main
struct TextExtractorApp: App {
    @StateObject private var quickCapture = QuickCaptureManager()
    private let hotkeyManager = HotkeyManager()

    init() {
        // Wiring is done in a separate step below since `hotkeyManager` and
        // `quickCapture` can't both be captured in this init directly.
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, minHeight: 500)
                .onAppear {
                    hotkeyManager.onTrigger = { [weak quickCapture] in
                        quickCapture?.startCapture()
                    }
                    hotkeyManager.start()
                }
        }
        .windowResizability(.contentSize)

        // Menu bar icon: quick access to capture, and a reminder of the shortcut
        MenuBarExtra("Text Extractor", systemImage: "text.viewfinder") {
            Button("Capture Screen Region (⌘⇧2)") {
                quickCapture.startCapture()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
