import Combine
import Foundation

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let sourceName: String
    let text: String

    init(sourceName: String, text: String) {
        self.id = UUID()
        self.date = Date()
        self.sourceName = sourceName
        self.text = text
    }
}

/// Persists the last N extractions to a JSON file in Application Support.
/// Shared as a singleton so both the main window and the quick-capture flow
/// write to the same history.
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published private(set) var entries: [HistoryEntry] = []
    private let maxEntries = 25
    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("TextExtractor", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("history.json")
        load()
    }

    func add(sourceName: String, text: String) {
        guard !text.isEmpty, text != "No text found." else { return }
        let entry = HistoryEntry(sourceName: sourceName, text: text)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL)
    }
}
