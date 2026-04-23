import Foundation

@Observable
@MainActor
class CoachStorageService {
    var sessions: [CoachSession] = []
    var blocks: [TrainingBlock] = []
    var evaluations: [PlayerEvaluation] = []
    var campaigns: [Campaign] = []

    private let sessionsKey = "coach_sessions"
    private let blocksKey = "coach_blocks"
    private let evaluationsKey = "coach_evaluations"
    private let campaignsKey = "coach_campaigns"

    init() {
        load()
        if sessions.isEmpty {
            sessions = CoachSessionTemplates.defaultSessions
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
        if let data = try? JSONEncoder().encode(blocks) {
            UserDefaults.standard.set(data, forKey: blocksKey)
        }
        if let data = try? JSONEncoder().encode(evaluations) {
            UserDefaults.standard.set(data, forKey: evaluationsKey)
        }
        if let data = try? JSONEncoder().encode(campaigns) {
            UserDefaults.standard.set(data, forKey: campaignsKey)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([CoachSession].self, from: data) {
            sessions = decoded
        }
        if let data = UserDefaults.standard.data(forKey: blocksKey),
           let decoded = try? JSONDecoder().decode([TrainingBlock].self, from: data) {
            blocks = decoded
        }
        if let data = UserDefaults.standard.data(forKey: evaluationsKey),
           let decoded = try? JSONDecoder().decode([PlayerEvaluation].self, from: data) {
            evaluations = decoded
        }
        if let data = UserDefaults.standard.data(forKey: campaignsKey),
           let decoded = try? JSONDecoder().decode([Campaign].self, from: data) {
            campaigns = decoded
        }
    }

    func addCampaign(_ campaign: Campaign) {
        campaigns.append(campaign)
        save()
    }

    func updateCampaign(_ campaign: Campaign) {
        if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[index] = campaign
            save()
        }
    }

    func deleteCampaign(_ campaign: Campaign) {
        campaigns.removeAll { $0.id == campaign.id }
        save()
    }

    func resolveSession(id: UUID, in campaign: Campaign) -> CoachSession? {
        campaign.embeddedSessions.first { $0.id == id } ?? sessions.first { $0.id == id }
    }

    func addSession(_ session: CoachSession) {
        sessions.append(session)
        save()
    }

    func updateSession(_ session: CoachSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            save()
        }
    }

    func deleteSession(_ session: CoachSession) {
        sessions.removeAll { $0.id == session.id }
        save()
    }

    func duplicateSession(_ session: CoachSession) {
        var copy = session
        copy.id = UUID()
        copy.title = session.displayTitle + " (Copy)"
        copy.customTitle = nil
        copy.createdAt = Date()
        sessions.append(copy)
        save()
    }

    func addBlock(_ block: TrainingBlock) {
        blocks.append(block)
        save()
    }

    func updateBlock(_ block: TrainingBlock) {
        if let index = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[index] = block
            save()
        }
    }

    func deleteBlock(_ block: TrainingBlock) {
        blocks.removeAll { $0.id == block.id }
        save()
    }

    func addEvaluation(_ evaluation: PlayerEvaluation) {
        evaluations.append(evaluation)
        save()
    }

    func updateEvaluation(_ evaluation: PlayerEvaluation) {
        if let index = evaluations.firstIndex(where: { $0.id == evaluation.id }) {
            evaluations[index] = evaluation
            save()
        }
    }

    func deleteEvaluation(_ evaluation: PlayerEvaluation) {
        evaluations.removeAll { $0.id == evaluation.id }
        save()
    }

    func sessionsByMoment() -> [(moment: GameMoment, sessions: [CoachSession])] {
        GameMoment.allCases.compactMap { moment in
            let filtered = sessions.filter { $0.gameMoment == moment }
            guard !filtered.isEmpty else { return nil }
            return (moment: moment, sessions: filtered)
        }
    }
}
