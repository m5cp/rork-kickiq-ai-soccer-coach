import Foundation

nonisolated enum JournalEntryType: String, Codable, Sendable {
    case postGameDebrief = "Post-Game Debrief"
    case chatSession = "AI Coach Chat"
    case analysis = "Video Analysis"
}

nonisolated struct JournalEntry: Codable, Sendable, Identifiable {
    let id: String
    let type: JournalEntryType
    let date: Date
    let title: String
    let summary: String
    let fullContent: String
    let gameRating: Int?
    let tags: [String]

    init(
        id: String = UUID().uuidString,
        type: JournalEntryType,
        date: Date = .now,
        title: String,
        summary: String,
        fullContent: String,
        gameRating: Int? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.title = title
        self.summary = summary
        self.fullContent = fullContent
        self.gameRating = gameRating
        self.tags = tags
    }
}
