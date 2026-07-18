import SwiftUI

/// Small toast-style popup shown after a quick capture completes, confirming
/// text was extracted and copied.
struct QuickCaptureResultView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 4) {
                Text("Text copied to clipboard")
                    .font(.system(size: 13, weight: .semibold))
                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
        }
        .padding(14)
        .frame(width: 320, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
