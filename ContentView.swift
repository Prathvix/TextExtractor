import SwiftUI
import Vision
import UniformTypeIdentifiers
import AppKit
import PDFKit

struct BatchItem: Identifiable {
    let id = UUID()
    var name: String
    var image: NSImage
    var text: String = ""
    var originalText: String = ""
    var attributedText: NSAttributedString = NSAttributedString(string: "")
    var isProcessing: Bool = true
}

struct ContentView: View {
    @ObservedObject private var history = HistoryManager.shared

    @State private var items: [BatchItem] = []
    @State private var selectedItemID: BatchItem.ID?
    @State private var isDragging = false
    @State private var showConfidence = false
    @State private var showHistory = false
    @State private var capsEnabled = false
    @State private var showNoTextAlert = false
    @State private var pdfProgress: (current: Int, total: Int)? = nil
    @State private var showPDFPageLimitAlert = false
    @State private var pdfLimitMessage = ""
    @State private var copyButtonLabel = "Copy Text"

    private let maxPDFPages = 50

    private var selectedIndex: Int? {
        items.firstIndex(where: { $0.id == selectedItemID })
    }

    var body: some View {
        HSplitView {
            if showHistory {
                historyPanel
                    .frame(minWidth: 220, maxWidth: 280)
            }

            VStack(spacing: 14) {
                dropZone
                if let progress = pdfProgress {
                    VStack(spacing: 4) {
                        ProgressView(value: Double(progress.current), total: Double(progress.total))
                        Text("Processing page \(progress.current) of \(progress.total)…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                actionBar
                if items.count > 1 {
                    batchList
                }
                textPane
            }
            .padding(18)
            .frame(minWidth: 480, minHeight: 480)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showHistory.toggle()
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .alert("No Text Found", isPresented: $showNoTextAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Couldn't find any text in that image. It may be too blurry, low-contrast, or genuinely text-free — try a clearer photo.")
        }
        .alert("Large PDF", isPresented: $showPDFPageLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pdfLimitMessage)
        }
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(isDragging ? .accentColor : .gray.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragging ? Color.accentColor.opacity(0.08) : Color.clear)
                )

            if let index = selectedIndex {
                Image(nsImage: items[index].image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .cornerRadius(8)

                if items[index].isProcessing {
                    ZStack {
                        Color.black.opacity(0.35)
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Extracting text…")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .cornerRadius(12)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Drag & drop images or PDFs")
                        .foregroundColor(.secondary)
                    Text("Multiple files supported — batch mode kicks in automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 200)
        .onDrop(of: [.fileURL, .image], isTargeted: $isDragging) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Button { openFiles() } label: { Label("Open Files", systemImage: "folder") }
            Button { pasteFromClipboard() } label: { Label("Paste Image", systemImage: "doc.on.clipboard") }
            Button { resetAll() } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
                .disabled(items.isEmpty)
            Button { copySelected() } label: { Label("Copy", systemImage: "doc.on.doc") }
                .disabled(selectedIndex == nil)

            Toggle(isOn: $showConfidence) {
                Label("Confidence", systemImage: "eye")
            }
            .toggleStyle(.button)
            .disabled(selectedIndex == nil)

            Toggle(isOn: $capsEnabled) {
                Label("ALL CAPS", systemImage: "textformat.size.larger")
            }
            .toggleStyle(.button)
            .disabled(items.isEmpty)
            .onChange(of: capsEnabled) { newValue in
                for i in items.indices {
                    items[i].text = newValue ? items[i].originalText.uppercased() : items[i].originalText
                }
            }

            Spacer()

            Menu {
                Button("Copy This Text") { copySelected() }
                Button("Copy All (Combined)") { copyAll() }
                    .disabled(items.count < 2)
                Divider()
                Button("Export This as .txt") { export(combined: false, markdown: false) }
                Button("Export This as .md") { export(combined: false, markdown: true) }
                Divider()
                Button("Export All as .txt") { export(combined: true, markdown: false) }
                    .disabled(items.count < 2)
                Button("Export All as .md") { export(combined: true, markdown: true) }
                    .disabled(items.count < 2)
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(items.isEmpty)
        }
    }

    // MARK: - Batch List

    private var batchList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    Button {
                        selectedItemID = item.id
                    } label: {
                        VStack(spacing: 4) {
                            Image(nsImage: item.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(item.id == selectedItemID ? Color.accentColor : .clear, lineWidth: 2)
                                )
                            if item.isProcessing {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Text(item.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 90)
    }

    // MARK: - Text Pane

    @ViewBuilder
    private var textPane: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(showConfidence ? "Extracted Text (confidence highlighted)" : "Extracted Text")
                .font(.caption)
                .foregroundColor(.secondary)

            if let index = selectedIndex {
                if items[index].isProcessing {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            ProgressView()
                            Text("Extracting text…")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .frame(minHeight: 180)
                    .border(Color.gray.opacity(0.3))
                } else if showConfidence {
                    ConfidenceTextView(attributedText: items[index].attributedText)
                        .frame(minHeight: 180)
                } else {
                    TextEditor(text: Binding(
                        get: { items[index].text },
                        set: { items[index].text = $0 }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .border(Color.gray.opacity(0.3))
                    .frame(minHeight: 180)
                }
            } else {
                TextEditor(text: .constant(""))
                    .disabled(true)
                    .frame(minHeight: 180)
                    .border(Color.gray.opacity(0.3))
            }
        }
    }

    // MARK: - History Panel

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("History").font(.headline)
                Spacer()
                Button("Clear") { history.clear() }
                    .font(.caption)
            }
            .padding()

            List(history.entries) { entry in
                Button {
                    loadFromHistory(entry)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.sourceName).font(.caption).bold()
                        Text(entry.text)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadFromHistory(_ entry: HistoryEntry) {
        var item = BatchItem(
            name: entry.sourceName,
            image: NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) ?? NSImage()
        )
        item.originalText = entry.text
        item.text = capsEnabled ? entry.text.uppercased() : entry.text
        item.isProcessing = false
        items = [item]
        selectedItemID = item.id
    }

    private func resetAll() {
        items.removeAll()
        selectedItemID = nil
        showConfidence = false
    }

    // MARK: - Drop / Open Handling

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            // Check for file URLs first (PDFs, docx, images as files)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async { loadFile(url) }
                    }
                }
            }
            // Check for image data (clipboard pastes, inline images)
            else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data, let image = NSImage(data: data) else { return }
                    DispatchQueue.main.async { addItem(name: "Pasted Image", image: image) }
                }
            }
        }
    }

    private func openFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff, .bmp, .gif, .pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            for url in panel.urls { loadFile(url) }
        }
    }

    private func loadFile(_ url: URL) {
        if url.pathExtension.lowercased() == "pdf" {
            loadPDF(url)
        } else if let image = NSImage(contentsOf: url) {
            addItem(name: url.lastPathComponent, image: image)
        }
    }

    private func loadPDF(_ url: URL) {
        guard let document = PDFExtractor.openDocument(url: url) else { return }
        let totalPages = document.pageCount
        guard totalPages > 0 else { return }

        let pagesToProcess = min(totalPages, maxPDFPages)
        let dpi = PDFExtractor.recommendedDPI(forPageCount: totalPages)
        let baseName = url.deletingPathExtension().lastPathComponent

        if totalPages > maxPDFPages {
            pdfLimitMessage = "This PDF has \(totalPages) pages. To keep the app responsive and avoid running out of memory, only the first \(maxPDFPages) pages will be processed."
            showPDFPageLimitAlert = true
        }

        processPDFPage(document: document, pageIndex: 0, totalToProcess: pagesToProcess, baseName: baseName, dpi: dpi)
    }

    /// Processes one PDF page at a time — renders it, waits for OCR to finish,
    /// discards the full-res render, then moves to the next page. This keeps
    /// memory bounded to roughly one page in flight instead of the whole book.
    private func processPDFPage(document: PDFDocument, pageIndex: Int, totalToProcess: Int, baseName: String, dpi: CGFloat) {
        guard pageIndex < totalToProcess else {
            pdfProgress = nil
            return
        }
        pdfProgress = (pageIndex + 1, totalToProcess)

        DispatchQueue.global(qos: .userInitiated).async {
            let image = PDFExtractor.renderPage(document, pageIndex: pageIndex, dpi: dpi)
            DispatchQueue.main.async {
                guard let image else {
                    processPDFPage(document: document, pageIndex: pageIndex + 1, totalToProcess: totalToProcess, baseName: baseName, dpi: dpi)
                    return
                }
                addItem(name: "\(baseName) — p\(pageIndex + 1)", image: image) {
                    processPDFPage(document: document, pageIndex: pageIndex + 1, totalToProcess: totalToProcess, baseName: baseName, dpi: dpi)
                }
            }
        }
    }

    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Try multiple image formats in order
        if let data = pasteboard.data(forType: .tiff) ??
                      pasteboard.data(forType: .png) ??
                      pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: "public.tiff")) ??
                      pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: "public.png")) {
            if let image = NSImage(data: data) {
                addItem(name: "Pasted Image", image: image)
                return
            }
        }
        
        // If no data formats worked, try getting an NSImage directly
        if let image = NSImage(pasteboard: pasteboard) {
            addItem(name: "Pasted Image", image: image)
            return
        }
    }

    private func addItem(name: String, image: NSImage, completion: (() -> Void)? = nil) {
        // Run OCR on the full-resolution image for accuracy, but only ever
        // store a small thumbnail on the item — this is what stops a
        // multi-hundred-page PDF from accumulating gigabytes of full-size
        // page images in memory as batch mode fills up.
        let thumbnail = downscaled(image, maxDimension: 300)
        let newItem = BatchItem(name: name, image: thumbnail)
        items.append(newItem)
        let itemID = newItem.id
        selectedItemID = itemID

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion?()
            return
        }

        OCREngine.recognize(cgImage: cgImage) { result in
            guard let index = items.firstIndex(where: { $0.id == itemID }) else {
                completion?()
                return
            }
            items[index].originalText = result.plainText
            items[index].text = capsEnabled ? result.plainText.uppercased() : result.plainText
            items[index].attributedText = result.attributedText
            items[index].isProcessing = false
            history.add(sourceName: name, text: result.plainText)

            if result.plainText == "No text found." {
                showNoTextAlert = true
            }
            completion?()
        }
    }

    /// Shrinks an image to fit within maxDimension on its longest side.
    /// Used to keep batch-mode thumbnails small in memory.
    private func downscaled(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        guard ratio < 1.0 else { return image }

        let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    // MARK: - Copy / Export

    private func copySelected() {
        guard let index = selectedIndex else { return }
        setClipboard(items[index].text)
    }

    private func copyAll() {
        let combined = items.map { "## \($0.name)\n\($0.text)" }.joined(separator: "\n\n")
        setClipboard(combined)
    }

    private func setClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func export(combined: Bool, markdown: Bool) {
        let text: String
        let defaultName: String

        if combined {
            text = items.map { "## \($0.name)\n\($0.text)" }.joined(separator: "\n\n")
            defaultName = "extracted-text-batch"
        } else {
            guard let index = selectedIndex else { return }
            text = items[index].text
            defaultName = (items[index].name as NSString).deletingPathExtension
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [markdown ? (UTType(filenameExtension: "md") ?? .plainText) : .plainText]
        panel.nameFieldStringValue = defaultName + (markdown ? ".md" : ".txt")

        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

#Preview {
    ContentView()
}

