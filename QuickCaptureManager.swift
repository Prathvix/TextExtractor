import AppKit
import Combine
import SwiftUI
import Vision

/// Orchestrates the "quick capture" flow:
/// 1. Shells out to macOS's built-in `screencapture` for interactive region selection
/// 2. Reads the captured image from the clipboard
/// 3. Runs on-device Vision OCR
/// 4. Puts the extracted text on the clipboard and shows a small result popup
final class QuickCaptureManager: ObservableObject {
    @Published var lastExtractedText: String = ""
    @Published var isCapturing: Bool = false

    private var toastPanel: NSPanel?

    func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -i = interactive region select, -c = copy result to clipboard (no file saved)
        task.arguments = ["-i", "-c"]

        task.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isCapturing = false
                self?.processClipboardImage()
            }
        }

        do {
            try task.run()
        } catch {
            isCapturing = false
            print("Failed to launch screencapture: \(error)")
        }
    }

    private func processClipboardImage() {
        let pasteboard = NSPasteboard.general
        guard let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
              let image = NSImage(data: data),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            // User likely pressed Esc to cancel the capture — do nothing.
            return
        }

        OCREngine.recognize(cgImage: cgImage) { [weak self] result in
            if result.plainText == "No text found." {
                self?.showNoTextAlert()
                return
            }
            self?.lastExtractedText = result.plainText
            self?.copyToClipboard(result.plainText)
            self?.showToast(text: result.plainText)
            HistoryManager.shared.add(sourceName: "Quick Capture", text: result.plainText)
        }
    }

    private func showNoTextAlert() {
        let alert = NSAlert()
        alert.messageText = "No Text Found"
        alert.informativeText = "That capture didn't contain any recognizable text. Try again with a clearer, less blurry region."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - Toast Popup

    private func showToast(text: String) {
        hideToast()

        let hostingView = NSHostingView(rootView: QuickCaptureResultView(text: text))
        let size = CGSize(width: 320, height: 90)
        hostingView.frame = CGRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: hostingView.frame,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]

        // Position in the top-right corner of the main screen
        if let screen = NSScreen.main {
            let margin: CGFloat = 20
            let x = screen.visibleFrame.maxX - size.width - margin
            let y = screen.visibleFrame.maxY - size.height - margin
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
        toastPanel = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.hideToast()
        }
    }

    private func hideToast() {
        toastPanel?.orderOut(nil)
        toastPanel = nil
    }
}
