import Foundation

nonisolated enum AgeGroup: String, Codable, Sendable {
    case child
    case teen
    case adult

    var isMinor: Bool { self != .adult }

    var requiresParentalConsent: Bool { self == .child }

    var label: String {
        switch self {
        case .child: "Under 13"
        case .teen: "13–17"
        case .adult: "18+"
        }
    }
}

@Observable
@MainActor
final class AgeSafetyService {
    static let shared = AgeSafetyService()

    var dateOfBirth: Date?
    var parentalConsentGranted: Bool = false
    var parentName: String = ""
    var parentEmail: String = ""
    var chatEnabledByParent: Bool = true
    var socialEnabledByParent: Bool = true

    private let dobKey = "kickiq_safety_dob"
    private let consentKey = "kickiq_safety_consent"
    private let parentNameKey = "kickiq_safety_parent_name"
    private let parentEmailKey = "kickiq_safety_parent_email"
    private let chatEnabledKey = "kickiq_safety_chat_enabled"
    private let socialEnabledKey = "kickiq_safety_social_enabled"
    private let consentDateKey = "kickiq_safety_consent_date"

    private init() {
        load()
    }

    private func load() {
        if let interval = UserDefaults.standard.object(forKey: dobKey) as? TimeInterval {
            dateOfBirth = Date(timeIntervalSince1970: interval)
        }
        parentalConsentGranted = UserDefaults.standard.bool(forKey: consentKey)
        parentName = UserDefaults.standard.string(forKey: parentNameKey) ?? ""
        parentEmail = UserDefaults.standard.string(forKey: parentEmailKey) ?? ""
        chatEnabledByParent = UserDefaults.standard.object(forKey: chatEnabledKey) as? Bool ?? true
        socialEnabledByParent = UserDefaults.standard.object(forKey: socialEnabledKey) as? Bool ?? true
    }

    func setDateOfBirth(_ date: Date) {
        dateOfBirth = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: dobKey)
    }

    func grantParentalConsent(parentName: String, parentEmail: String, enableChat: Bool) {
        self.parentName = parentName
        self.parentEmail = parentEmail
        self.parentalConsentGranted = true
        self.chatEnabledByParent = enableChat
        UserDefaults.standard.set(parentName, forKey: parentNameKey)
        UserDefaults.standard.set(parentEmail, forKey: parentEmailKey)
        UserDefaults.standard.set(true, forKey: consentKey)
        UserDefaults.standard.set(enableChat, forKey: chatEnabledKey)
        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: consentDateKey)
    }

    func revokeParentalConsent() {
        parentalConsentGranted = false
        chatEnabledByParent = false
        socialEnabledByParent = false
        UserDefaults.standard.set(false, forKey: consentKey)
        UserDefaults.standard.set(false, forKey: chatEnabledKey)
        UserDefaults.standard.set(false, forKey: socialEnabledKey)
    }

    func setChatEnabled(_ enabled: Bool) {
        chatEnabledByParent = enabled
        UserDefaults.standard.set(enabled, forKey: chatEnabledKey)
    }

    func setSocialEnabled(_ enabled: Bool) {
        socialEnabledByParent = enabled
        UserDefaults.standard.set(enabled, forKey: socialEnabledKey)
    }

    func reset() {
        dateOfBirth = nil
        parentalConsentGranted = false
        parentName = ""
        parentEmail = ""
        chatEnabledByParent = true
        socialEnabledByParent = true
        [dobKey, consentKey, parentNameKey, parentEmailKey, chatEnabledKey, socialEnabledKey, consentDateKey]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    var currentAge: Int? {
        guard let dob = dateOfBirth else { return nil }
        let years = Calendar.current.dateComponents([.year], from: dob, to: .now).year
        return years
    }

    var ageGroup: AgeGroup {
        guard let age = currentAge else { return .adult }
        if age < 13 { return .child }
        if age < 18 { return .teen }
        return .adult
    }

    var isMinor: Bool { ageGroup.isMinor }

    /// AI chat allowed: adults always; teens always; under-13 only if parent granted consent AND enabled chat.
    var isChatAllowed: Bool {
        switch ageGroup {
        case .adult: return true
        case .teen: return true
        case .child: return parentalConsentGranted && chatEnabledByParent
        }
    }

    /// Social/user-to-user features: adults/teens yes; under-13 only with parent toggle.
    var isSocialAllowed: Bool {
        switch ageGroup {
        case .adult, .teen: return true
        case .child: return parentalConsentGranted && socialEnabledByParent
        }
    }

    /// Analytics tracking — disabled entirely for all minors.
    var isAnalyticsAllowed: Bool {
        !isMinor
    }

    /// Whether Parental Controls section should be visible in Settings.
    var showsParentalControls: Bool {
        ageGroup == .child
    }

    /// Safety system prompt addendum for AI chat when user is a minor.
    var minorSafetyPromptAddendum: String? {
        guard isMinor else { return nil }
        let ageLine: String = {
            switch ageGroup {
            case .child: "The user is under 13 years old. Use simple, encouraging language appropriate for a young child."
            case .teen: "The user is between 13 and 17 years old. Use age-appropriate, respectful language."
            case .adult: ""
            }
        }()
        return """

        IMPORTANT CHILD-SAFETY RULES (the user is a minor):
        \(ageLine)
        - Never discuss sexual, violent, adult, romantic, or politically charged topics.
        - Never discuss self-harm, eating disorders, substance use, weapons, or dangerous dieting. If a user brings these up, respond with care and direct them to tell a trusted adult or contact a helpline (e.g. in the US: 988 Suicide & Crisis Lifeline).
        - Never ask for or store personal information: full name, address, phone number, school name, or photos.
        - Never suggest meeting anyone in person, sharing contact info, or leaving the app to chat elsewhere.
        - Do not offer medical, legal, or financial advice. If asked, kindly tell them to speak with a parent, coach, or doctor.
        - Keep all coaching language positive, body-positive, and non-judgmental.
        """
    }

    /// Quick screening of user text for clearly unsafe topics. Returns a safe redirect message if blocked.
    func unsafeRedirectIfNeeded(for text: String) -> String? {
        guard isMinor else { return nil }
        let lower = text.lowercased()
        let selfHarmKeywords = ["kill myself", "suicide", "self harm", "self-harm", "cut myself", "hurt myself", "end my life", "want to die"]
        if selfHarmKeywords.contains(where: { lower.contains($0) }) {
            return "I'm really glad you reached out. What you're feeling matters, and a trusted adult — a parent, guardian, coach, or teacher — can help right now. If you're in the US, you can also call or text 988 any time to talk with someone who cares. You're not alone."
        }
        let abuseKeywords = ["someone hurt me", "being abused", "touched me", "inappropriately"]
        if abuseKeywords.contains(where: { lower.contains($0) }) {
            return "I'm sorry you're dealing with this. Please tell a trusted adult — a parent, teacher, coach, or counselor — as soon as possible. In the US, you can also call the Childhelp hotline at 1-800-422-4453. You deserve to be safe."
        }
        let adultKeywords = ["sexual", "nude", "porn", "drugs", "alcohol", "vape", "weed"]
        if adultKeywords.contains(where: { lower.contains($0) }) {
            return "Let's keep our conversation focused on soccer and training. If you want to talk about something else, a parent or trusted adult is the best person to ask."
        }
        return nil
    }
}
