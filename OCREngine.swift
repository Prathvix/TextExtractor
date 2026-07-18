import Vision
import AppKit

/// Shared OCR logic used by both the main window (drag/drop/open/paste) and
/// the quick-capture hotkey flow, so recognition behavior stays consistent.
struct OCREngine {
    struct Result {
        let plainText: String
        let attributedText: NSAttributedString
    }

    /// Runs Vision text recognition on a CGImage. Completion is always called on the main thread.
    static func recognize(cgImage: CGImage, completion: @escaping (Result) -> Void) {
        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(Result(plainText: "No text found.", attributedText: NSAttributedString(string: "No text found.")))
                }
                return
            }

            var lines: [String] = []
            let attributed = NSMutableAttributedString()

            for (index, observation) in observations.enumerated() {
                guard let candidate = observation.topCandidates(1).first else { continue }
                lines.append(candidate.string)

                // Confidence is per recognized line/segment, not per individual word.
                let color: NSColor
                switch candidate.confidence {
                case 0.85...: color = .labelColor
                case 0.5..<0.85: color = .systemOrange
                default: color = .systemRed
                }

                let isLast = index == observations.count - 1
                let lineText = candidate.string + (isLast ? "" : "\n")
                let lineAttr = NSAttributedString(
                    string: lineText,
                    attributes: [
                        .foregroundColor: color,
                        .backgroundColor: candidate.confidence < 0.85 ? color.withAlphaComponent(0.15) : NSColor.clear
                    ]
                )
                attributed.append(lineAttr)
            }

            let plainText = lines.joined(separator: "\n")
            let finalText = plainText.isEmpty ? "No text found." : plainText

            DispatchQueue.main.async {
                completion(Result(plainText: finalText, attributedText: attributed))
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}
