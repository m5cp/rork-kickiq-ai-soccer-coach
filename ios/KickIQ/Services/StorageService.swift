import Foundation
import UserNotifications

@Observable
@MainActor
class StorageService {
    var profile: PlayerProfile?
    var sessions: [TrainingSession] = []
    var hasCompletedOnboarding: Bool = false
    var streakCount: Int = 0
    var lastSessionDate: Date?
    var completedDrillIDs: Set<String> = []
    var xpPoints: Int = 0
    var analysisCount: Int = 0
    var maxStreak: Int = 0
    var lastReviewPromptDate: Date?
    var reviewPromptCount: Int = 0
    var sessionDates: Set<String> = []
    var lastStreakBrokenDate: Date?
    var pendingMilestones: [MilestoneBadge] = []
    var lastMonthlyReassessment: Date?
    var dailyDrillSeed: Int = 0
    var weeklyGoal: WeeklyGoal?
    var sessionNotes: [SessionNote] = []
    var trainingPlan: TrainingPlan?
    var smartTrainingPlan: SmartTrainingPlan?

    private let profileKey = "kickiq_profile"
    private let sessionsKey = "kickiq_sessions"
    private let onboardingKey = "kickiq_onboarding"
    private let streakKey = "kickiq_streak"
    private let lastSessionKey = "kickiq_last_session"
    private let drillsKey = "kickiq_completed_drills"
    private let xpKey = "kickiq_xp"
    private let analysisCountKey = "kickiq_analysis_count"
    private let maxStreakKey = "kickiq_max_streak"
    private let reviewDateKey = "kickiq_review_date"
    private let reviewCountKey = "kickiq_review_count"
    private let sessionDatesKey = "kickiq_session_dates"
    private let lastStreakBrokenKey = "kickiq_last_streak_broken"
    private let lastReassessmentKey = "kickiq_last_reassessment"
    private let dailyDrillSeedKey = "kickiq_daily_drill_seed"
    private let weeklyGoalKey = "kickiq_weekly_goal"
    private let sessionNotesKey = "kickiq_session_notes"
    private let trainingPlanKey = "kickiq_training_plan"
    private let smartPlanKey = "kickiq_smart_plan"

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        loadAll()
    }

    func loadAll() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = decoded
        }
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            sessions = decoded
        }
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        streakCount = UserDefaults.standard.integer(forKey: streakKey)
        maxStreak = UserDefaults.standard.integer(forKey: maxStreakKey)
        analysisCount = UserDefaults.standard.integer(forKey: analysisCountKey)
        xpPoints = UserDefaults.standard.integer(forKey: xpKey)
        reviewPromptCount = UserDefaults.standard.integer(forKey: reviewCountKey)

        if let interval = UserDefaults.standard.object(forKey: lastSessionKey) as? TimeInterval {
            lastSessionDate = Date(timeIntervalSince1970: interval)
        }
        if let interval = UserDefaults.standard.object(forKey: reviewDateKey) as? TimeInterval {
            lastReviewPromptDate = Date(timeIntervalSince1970: interval)
        }
        if let arr = UserDefaults.standard.array(forKey: drillsKey) as? [String] {
            completedDrillIDs = Set(arr)
        }
        if let arr = UserDefaults.standard.array(forKey: sessionDatesKey) as? [String] {
            sessionDates = Set(arr)
        }
        if let interval = UserDefaults.standard.object(forKey: lastStreakBrokenKey) as? TimeInterval {
            lastStreakBrokenDate = Date(timeIntervalSince1970: interval)
        }
        if let interval = UserDefaults.standard.object(forKey: lastReassessmentKey) as? TimeInterval {
            lastMonthlyReassessment = Date(timeIntervalSince1970: interval)
        }

        if let data = UserDefaults.standard.data(forKey: weeklyGoalKey),
           let decoded = try? JSONDecoder().decode(WeeklyGoal.self, from: data) {
            weeklyGoal = decoded
        }
        if let data = UserDefaults.standard.data(forKey: sessionNotesKey),
           let decoded = try? JSONDecoder().decode([SessionNote].self, from: data) {
            sessionNotes = decoded
        }
        if let data = UserDefaults.standard.data(forKey: trainingPlanKey),
           let decoded = try? JSONDecoder().decode(TrainingPlan.self, from: data) {
            trainingPlan = decoded
        }
        if let data = UserDefaults.standard.data(forKey: smartPlanKey),
           let decoded = try? JSONDecoder().decode(SmartTrainingPlan.self, from: data) {
            smartTrainingPlan = decoded
        }

        updateDailyDrillSeed()
        updateStreak()
    }

    func saveProfile(_ newProfile: PlayerProfile) {
        profile = newProfile
        if let data = try? JSONEncoder().encode(newProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func addSession(_ session: TrainingSession) {
        sessions.insert(session, at: 0)
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
        analysisCount += 1
        UserDefaults.standard.set(analysisCount, forKey: analysisCountKey)

        let dateStr = dateFormatter.string(from: session.date)
        sessionDates.insert(dateStr)
        UserDefaults.standard.set(Array(sessionDates), forKey: sessionDatesKey)

        recordSessionDate()
    }

    func completeDrill(_ drill: Drill) {
        completedDrillIDs.insert(drill.id)
        UserDefaults.standard.set(Array(completedDrillIDs), forKey: drillsKey)
        xpPoints += 25
        UserDefaults.standard.set(xpPoints, forKey: xpKey)
        recordSessionDate()
    }

    func saveWeeklyGoal(_ goal: WeeklyGoal) {
        weeklyGoal = goal
        if let data = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(data, forKey: weeklyGoalKey)
        }
    }

    func addSessionNote(_ note: SessionNote) {
        sessionNotes.insert(note, at: 0)
        if let data = try? JSONEncoder().encode(sessionNotes) {
            UserDefaults.standard.set(data, forKey: sessionNotesKey)
        }
    }

    func notesForSession(_ sessionID: String) -> [SessionNote] {
        sessionNotes.filter { $0.sessionID == sessionID }
    }

    func saveTrainingPlan(_ plan: TrainingPlan) {
        trainingPlan = plan
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: trainingPlanKey)
        }
    }

    func saveSmartTrainingPlan(_ plan: SmartTrainingPlan) {
        smartTrainingPlan = plan
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: smartPlanKey)
        }
    }

    var weeklySessionsCompleted: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        return sessions.filter { $0.date >= startOfWeek }.count + completedDrillsThisWeek
    }

    private var completedDrillsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        return sessionDates.filter { dateStr in
            guard let date = dateFormatter.date(from: dateStr) else { return false }
            return date >= startOfWeek
        }.count
    }

    func resetOnboarding() {
        profile = nil
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.set(false, forKey: onboardingKey)
    }

    func deleteAccount() {
        let allKeys = [profileKey, sessionsKey, onboardingKey, streakKey, lastSessionKey,
                       drillsKey, xpKey, analysisCountKey, maxStreakKey, reviewDateKey,
                       reviewCountKey, sessionDatesKey, lastStreakBrokenKey, lastReassessmentKey,
                       dailyDrillSeedKey, weeklyGoalKey, sessionNotesKey, trainingPlanKey, smartPlanKey,
                       "kickiq_drill_day",
                       "kickiq_pref_streak", "kickiq_pref_weekly", "kickiq_pref_monthly"]
        allKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        profile = nil
        sessions = []
        hasCompletedOnboarding = false
        streakCount = 0
        lastSessionDate = nil
        completedDrillIDs = []
        xpPoints = 0
        analysisCount = 0
        maxStreak = 0
        sessionDates = []
        lastStreakBrokenDate = nil
        lastMonthlyReassessment = nil
        pendingMilestones = []
        reviewPromptCount = 0
        lastReviewPromptDate = nil
        dailyDrillSeed = 0
        weeklyGoal = nil
        sessionNotes = []
        trainingPlan = nil
        smartTrainingPlan = nil

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    var shouldPromptReview: Bool {
        guard analysisCount >= 3 else { return false }
        guard reviewPromptCount < 3 else { return false }
        if let lastDate = lastReviewPromptDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
            guard daysSince >= 30 else { return false }
        }
        return true
    }

    func recordReviewPrompt() {
        reviewPromptCount += 1
        lastReviewPromptDate = .now
        UserDefaults.standard.set(reviewPromptCount, forKey: reviewCountKey)
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: reviewDateKey)
    }

    var skillScore: Int {
        guard let latest = sessions.first else { return 0 }
        return latest.overallScore
    }

    var latestSession: TrainingSession? { sessions.first }

    var playerLevel: PlayerLevel {
        PlayerLevel.level(for: xpPoints)
    }

    var xpProgress: (current: Int, needed: Int)? {
        PlayerLevel.xpToNextLevel(currentXP: xpPoints)
    }

    var earnedBadges: [MilestoneBadge] {
        var badges: [MilestoneBadge] = []
        if maxStreak >= 7 { badges.append(.streak7) }
        if maxStreak >= 30 { badges.append(.streak30) }
        if maxStreak >= 90 { badges.append(.streak90) }
        if analysisCount >= 1 { badges.append(.firstAnalysis) }
        if analysisCount >= 5 { badges.append(.fiveAnalyses) }
        if analysisCount >= 10 { badges.append(.tenAnalyses) }
        if analysisCount >= 25 { badges.append(.twentyFiveAnalyses) }
        return badges
    }

    var streakMessage: String {
        if streakCount > 0 {
            return "Keep the fire going!"
        }
        if lastStreakBrokenDate != nil {
            return "Welcome back! Start a new streak today."
        }
        return "Start your streak today"
    }

    var isStreakBroken: Bool {
        guard let last = lastSessionDate else { return false }
        let calendar = Calendar.current
        return !calendar.isDateInToday(last) && !calendar.isDateInYesterday(last)
    }

    var shouldShowMonthlyReassessment: Bool {
        guard let last = lastMonthlyReassessment else { return analysisCount >= 3 }
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
        return daysSince >= 30
    }

    func recordMonthlyReassessment() {
        lastMonthlyReassessment = .now
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: lastReassessmentKey)
    }

    var todaysDrillIndex: Int {
        dailyDrillSeed
    }

    var weakestSkills: [SkillCategory] {
        guard let latest = sessions.first else {
            return profile?.position.skills ?? []
        }
        let sorted = latest.skillScores.sorted { $0.score < $1.score }
        return Array(sorted.prefix(2).map(\.category))
    }

    func hasSessionOnDate(_ date: Date) -> Bool {
        let dateStr = dateFormatter.string(from: date)
        return sessionDates.contains(dateStr)
    }

    func sessionCountOnDate(_ date: Date) -> Int {
        let dateStr = dateFormatter.string(from: date)
        return sessionDates.contains(dateStr) ? 1 : 0
    }

    private func recordSessionDate() {
        let now = Date()
        let calendar = Calendar.current

        if let last = lastSessionDate {
            if calendar.isDateInYesterday(last) {
                streakCount += 1
            } else if !calendar.isDateInToday(last) {
                streakCount = 1
            }
        } else {
            streakCount = 1
        }

        lastSessionDate = now
        if streakCount > maxStreak {
            maxStreak = streakCount
            UserDefaults.standard.set(maxStreak, forKey: maxStreakKey)
        }
        UserDefaults.standard.set(streakCount, forKey: streakKey)
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastSessionKey)
    }

    func checkNewMilestones() -> [MilestoneBadge] {
        let current = earnedBadges
        let newOnes = current.filter { !pendingMilestones.contains($0) }
        return newOnes
    }

    func markMilestonesShown(_ badges: [MilestoneBadge]) {
        pendingMilestones.append(contentsOf: badges)
    }

    private func updateDailyDrillSeed() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let storedSeed = UserDefaults.standard.integer(forKey: dailyDrillSeedKey)
        let storedDay = UserDefaults.standard.double(forKey: "kickiq_drill_day")
        let storedDate = Date(timeIntervalSince1970: storedDay)

        if storedDay == 0 || !calendar.isDate(storedDate, inSameDayAs: today) {
            dailyDrillSeed = Int.random(in: 0...999)
            UserDefaults.standard.set(dailyDrillSeed, forKey: dailyDrillSeedKey)
            UserDefaults.standard.set(today.timeIntervalSince1970, forKey: "kickiq_drill_day")
        } else {
            dailyDrillSeed = storedSeed
        }
    }

    private func updateStreak() {
        guard let last = lastSessionDate else {
            streakCount = 0
            return
        }
        let calendar = Calendar.current
        if !calendar.isDateInToday(last) && !calendar.isDateInYesterday(last) {
            if streakCount > 0 {
                lastStreakBrokenDate = .now
                UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: lastStreakBrokenKey)
            }
            streakCount = 0
            UserDefaults.standard.set(0, forKey: streakKey)
        }
    }
}
