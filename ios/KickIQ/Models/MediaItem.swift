import Foundation

nonisolated enum MediaType: String, Codable, Sendable {
    case photo
    case video
}

nonisolated enum MediaTag: String, Codable, CaseIterable, Sendable, Identifiable {
    case training = "Training"
    case match = "Match"
    case technique = "Technique"
    case team = "Team"
    case highlight = "Highlight"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .training: "figure.soccer"
        case .match: "sportscourt.fill"
        case .technique: "scope"
        case .team: "person.3.fill"
        case .highlight: "star.fill"
        case .other: "photo.fill"
        }
    }
}

nonisolated struct MediaItem: Codable, Sendable, Identifiable {
    let id: String
    let type: MediaType
    let fileName: String
    var tag: MediaTag
    var caption: String
    let createdAt: Date
    var playerName: String?
    var sessionID: String?
    var isEdited: Bool

    init(
        id: String = UUID().uuidString,
        type: MediaType,
        fileName: String,
        tag: MediaTag = .training,
        caption: String = "",
        createdAt: Date = .now,
        playerName: String? = nil,
        sessionID: String? = nil,
        isEdited: Bool = false
    ) {
        self.id = id
        self.type = type
        self.fileName = fileName
        self.tag = tag
        self.caption = caption
        self.createdAt = createdAt
        self.playerName = playerName
        self.sessionID = sessionID
        self.isEdited = isEdited
    }
}
