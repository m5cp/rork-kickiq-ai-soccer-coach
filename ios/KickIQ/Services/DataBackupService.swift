import Foundation
import UniformTypeIdentifiers

nonisolated struct KickIQBackup: Codable, Sendable {
    let version: Int
    let exportDate: Date
    let profile: PlayerProfile?
    let sessions: [TrainingSession]
    let streakCount: Int
    let maxStreak: Int
    let xpPoints: Int
    let analysisCount: Int
    let completedDrillIDs: [String]
    let sessionDates: [String]
    let weeklyGoal: WeeklyGoal?
    let sessionNotes: [SessionNote]
    let favoriteDrillIDs: [String]
    let personalRecords: [String: PersonalRecord]
}

@MainActor
struct DataBackupService {
    static func exportData(from storage: StorageService) -> Data? {
        let backup = KickIQBackup(
            version: 1,
            exportDate: .now,
            profile: storage.profile,
            sessions: storage.sessions,
            streakCount: storage.streakCount,
            maxStreak: storage.maxStreak,
            xpPoints: storage.xpPoints,
            analysisCount: storage.analysisCount,
            completedDrillIDs: Array(storage.completedDrillIDs),
            sessionDates: Array(storage.sessionDates),
            weeklyGoal: storage.weeklyGoal,
            sessionNotes: storage.sessionNotes,
            favoriteDrillIDs: Array(storage.favoriteDrillIDs),
            personalRecords: storage.personalRecords
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(backup)
    }

    static func importData(from data: Data, into storage: StorageService) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(KickIQBackup.self, from: data)

        if let profile = backup.profile {
            storage.saveProfile(profile)
        }

        for session in backup.sessions.reversed() {
            if !storage.sessions.contains(where: { $0.id == session.id }) {
                storage.addSession(session)
            }
        }

        if backup.xpPoints > storage.xpPoints {
            storage.xpPoints = backup.xpPoints
            UserDefaults.standard.set(backup.xpPoints, forKey: "kickiq_xp")
        }

        if backup.maxStreak > storage.maxStreak {
            storage.maxStreak = backup.maxStreak
            UserDefaults.standard.set(backup.maxStreak, forKey: "kickiq_max_streak")
        }

        for drillID in backup.completedDrillIDs {
            storage.completedDrillIDs.insert(drillID)
        }
        UserDefaults.standard.set(Array(storage.completedDrillIDs), forKey: "kickiq_completed_drills")

        for id in backup.favoriteDrillIDs {
            storage.favoriteDrillIDs.insert(id)
        }
        UserDefaults.standard.set(Array(storage.favoriteDrillIDs), forKey: "kickiq_favorite_drills")

        for (key, record) in backup.personalRecords {
            if storage.personalRecords[key] == nil || record.value > (storage.personalRecords[key]?.value ?? 0) {
                storage.personalRecords[key] = record
            }
        }
        if let data = try? JSONEncoder().encode(storage.personalRecords) {
            UserDefaults.standard.set(data, forKey: "kickiq_personal_records")
        }

        if let goal = backup.weeklyGoal, storage.weeklyGoal == nil {
            storage.saveWeeklyGoal(goal)
        }

        for note in backup.sessionNotes {
            if !storage.sessionNotes.contains(where: { $0.id == note.id }) {
                storage.sessionNotes.append(note)
            }
        }
        if let data = try? JSONEncoder().encode(storage.sessionNotes) {
            UserDefaults.standard.set(data, forKey: "kickiq_session_notes")
        }
    }
}
