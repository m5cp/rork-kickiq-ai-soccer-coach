import Foundation

nonisolated enum TeamRole: String, Codable, Sendable, CaseIterable, Identifiable {
    case owner = "owner"
    case coach = "coach"
    case player = "player"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .owner: "Owner"
        case .coach: "Coach"
        case .player: "Player"
        }
    }

    var icon: String {
        switch self {
        case .owner: "crown.fill"
        case .coach: "person.badge.shield.checkmark.fill"
        case .player: "figure.soccer"
        }
    }

    var isCoachOrOwner: Bool {
        self == .owner || self == .coach
    }
}

nonisolated struct TeamDTO: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let join_code: String
    let age_group: String?
    let created_by: String
    let created_at: String

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, join_code, age_group, created_by, created_at
    }
}

nonisolated struct TeamMemberDTO: Codable, Sendable, Identifiable {
    let id: String
    let team_id: String
    let user_id: String
    let role: String
    let display_name: String?
    let position: String?
    let joined_at: String

    nonisolated enum CodingKeys: String, CodingKey {
        case id, team_id, user_id, role, display_name, position, joined_at
    }
}

nonisolated struct DrillLogDTO: Codable, Sendable, Identifiable {
    let id: String
    let user_id: String
    let team_id: String?
    let drill_id: String
    let drill_name: String
    let value: Double?
    let metric_type: String?
    let completed_at: String

    nonisolated enum CodingKeys: String, CodingKey {
        case id, user_id, team_id, drill_id, drill_name, value, metric_type, completed_at
    }
}

nonisolated struct ChallengeDTO: Codable, Sendable, Identifiable {
    let id: String
    let team_id: String
    let creator_id: String
    let creator_name: String?
    let drill_id: String
    let drill_name: String
    let target_value: Double
    let metric_type: String
    let created_at: String
    let expires_at: String?
    let status: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, team_id, creator_id, creator_name, drill_id, drill_name
        case target_value, metric_type, created_at, expires_at, status
    }
}

nonisolated struct ChallengeResultDTO: Codable, Sendable, Identifiable {
    let id: String
    let challenge_id: String
    let user_id: String
    let display_name: String?
    let value: Double
    let completed_at: String

    nonisolated enum CodingKeys: String, CodingKey {
        case id, challenge_id, user_id, display_name, value, completed_at
    }
}

nonisolated struct AssignedDrillDTO: Codable, Sendable, Identifiable {
    let id: String
    let team_id: String
    let drill_id: String
    let drill_name: String
    let assigned_by: String
    let assigned_to: String?
    let assignee_name: String?
    let due_date: String?
    let completed: Bool
    let note: String?
    let created_at: String

    nonisolated enum CodingKeys: String, CodingKey {
        case id, team_id, drill_id, drill_name, assigned_by, assigned_to
        case assignee_name, due_date, completed, note, created_at
    }
}

nonisolated struct ActivityEventDTO: Codable, Sendable, Identifiable {
    let id: String
    let team_id: String
    let user_id: String
    let display_name: String?
    let event_type: String
    let title: String
    let subtitle: String?
    let icon: String?
    let created_at: String

    nonisolated enum CodingKeys: String, CodingKey {
        case id, team_id, user_id, display_name, event_type, title, subtitle, icon, created_at
    }
}

nonisolated struct UserProfileDTO: Codable, Sendable {
    let id: String
    let display_name: String?
    let position: String?
    let skill_level: String?
    let avatar_url: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, display_name, position, skill_level, avatar_url
    }
}

nonisolated struct LeaderboardEntry: Sendable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let position: String?
    let value: Double
    let rank: Int
}
