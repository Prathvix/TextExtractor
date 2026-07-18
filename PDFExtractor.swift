import PDFKit
import AppKit

/// Renders PDF pages one at a time so large documents (hundreds of pages)
/// don't blow up memory by holding every page's full-resolution image at once.
struct PDFExtractor {
    static func openDocument(url: URL) -> PDFDocument? {
        PDFDocument(url: url)
    }

    /// Renders a single page. Call this one page at a time for big documents
    /// instead of rendering the whole PDF into an array upfront.
    static func renderPage(_ document: PDFDocument, pageIndex: Int, dpi: CGFloat) -> NSImage? {
        guard let page = document.page(at: pageIndex) else { return nil }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = dpi / 72.0
        let scaledSize = NSSize(width: pageRect.width * scale, height: pageRect.height * scale)
        guard scaledSize.width > 0, scaledSize.height > 0 else { return nil }

        let image = NSImage(size: scaledSize)
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: scaledSize))
            context.saveGState()
            context.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()
        }
        image.unlockFocus()
        return image
    }

    /// Lower resolution automatically for documents with lots of pages,
    /// trading a bit of OCR accuracy for a lot less memory pressure.
    static func recommendedDPI(forPageCount count: Int) -> CGFloat {
        switch count {
        case 0...20: return 200
        case 21...80: return 150
        default: return 110
        }
    }
}

