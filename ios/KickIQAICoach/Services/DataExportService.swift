import Foundation

nonisolated struct ExportableData: Codable, Sendable {
    let exportDate: Date
    let appVersion: String
    let profile: PlayerProfile?
    let sessions: [TrainingSession]
    let streakCount: Int
    let maxStreak: Int
    let xpPoints: Int
    let analysisCount: Int
    let completedDrillIDs: [String]
    let favoriteDrillIDs: [String]
    let personalRecords: [PersonalRecord]
    let drillCompletionHistory: [DrillCompletion]
    let weeklyGoal: WeeklyGoal?
    let sessionNotes: [SessionNote]
}

@MainActor
enum DataExportService {
    static func exportData(from storage: StorageService) -> Data? {
        let exportable = ExportableData(
            exportDate: .now,
            appVersion: "2.0",
            profile: storage.profile,
            sessions: storage.sessions,
            streakCount: storage.streakCount,
            maxStreak: storage.maxStreak,
            xpPoints: storage.xpPoints,
            analysisCount: storage.analysisCount,
            completedDrillIDs: Array(storage.completedDrillIDs),
            favoriteDrillIDs: Array(storage.favoriteDrillIDs),
            personalRecords: storage.personalRecords,
            drillCompletionHistory: storage.drillCompletionHistory,
            weeklyGoal: storage.weeklyGoal,
            sessionNotes: storage.sessionNotes
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportable)
    }

    static func exportURL(from storage: StorageService) -> URL? {
        guard let data = exportData(from: storage) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("KickIQ_Backup_\(formattedDate()).json")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
}
