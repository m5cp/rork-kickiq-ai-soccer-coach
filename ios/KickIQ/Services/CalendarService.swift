import EventKit
import Foundation

@Observable
@MainActor
class CalendarService {
    private let eventStore = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var calendarSyncEnabled: Bool = false
    var reminderMinutesBefore: Int = 30
    var selectedCalendarID: String?

    private let syncEnabledKey = "kickiq_calendar_sync"
    private let reminderKey = "kickiq_calendar_reminder"
    private let calendarIDKey = "kickiq_calendar_id"
    private let eventMapKey = "kickiq_calendar_events"

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        calendarSyncEnabled = UserDefaults.standard.bool(forKey: syncEnabledKey)
        reminderMinutesBefore = UserDefaults.standard.object(forKey: reminderKey) as? Int ?? 30
        selectedCalendarID = UserDefaults.standard.string(forKey: calendarIDKey)
    }

    var isAuthorized: Bool {
        authorizationStatus == .fullAccess || authorizationStatus == .authorized
    }

    var availableCalendars: [EKCalendar] {
        guard isAuthorized else { return [] }
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }

    var selectedCalendar: EKCalendar? {
        if let id = selectedCalendarID {
            return eventStore.calendar(withIdentifier: id)
        }
        return eventStore.defaultCalendarForNewEvents
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    func enableSync(_ enabled: Bool) {
        calendarSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: syncEnabledKey)
    }

    func setReminder(_ minutes: Int) {
        reminderMinutesBefore = minutes
        UserDefaults.standard.set(minutes, forKey: reminderKey)
    }

    func setCalendar(_ calendarID: String) {
        selectedCalendarID = calendarID
        UserDefaults.standard.set(calendarID, forKey: calendarIDKey)
    }

    private var eventMap: [String: String] {
        get {
            (UserDefaults.standard.dictionary(forKey: eventMapKey) as? [String: String]) ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: eventMapKey)
        }
    }

    func addTrainingEvent(for day: DailyPlan, notes: String? = nil) -> Bool {
        guard isAuthorized, calendarSyncEnabled else { return false }
        guard let calendar = selectedCalendar else { return false }

        if let existingID = eventMap[day.id],
           eventStore.event(withIdentifier: existingID) != nil {
            return true
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "KickIQ: \(day.focus)"
        event.calendar = calendar
        event.startDate = day.date
        event.endDate = Calendar.current.date(byAdding: .minute, value: day.duration.rawValue, to: day.date) ?? day.date

        var noteLines: [String] = []
        noteLines.append("Category: \(day.intensity.rawValue) Intensity")
        noteLines.append("Duration: \(day.duration.label)")
        noteLines.append("Mode: \(day.mode.rawValue)")
        if !day.weaknessPriority.isEmpty {
            noteLines.append("Focus Areas: \(day.weaknessPriority.joined(separator: ", "))")
        }
        noteLines.append("")
        noteLines.append("Drills:")
        for drill in day.drills {
            noteLines.append("• \(drill.name) (\(drill.duration))")
        }
        if let notes, !notes.isEmpty {
            noteLines.append("")
            noteLines.append(notes)
        }
        event.notes = noteLines.joined(separator: "\n")

        if reminderMinutesBefore > 0 {
            event.addAlarm(EKAlarm(relativeOffset: TimeInterval(-reminderMinutesBefore * 60)))
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            var map = eventMap
            map[day.id] = event.eventIdentifier
            eventMap = map
            return true
        } catch {
            return false
        }
    }

    func addRecurringTrainingEvents(for days: [DailyPlan]) -> Int {
        guard isAuthorized, calendarSyncEnabled else { return 0 }
        var count = 0
        for day in days {
            if addTrainingEvent(for: day) {
                count += 1
            }
        }
        return count
    }

    func removeTrainingEvent(for dayID: String) -> Bool {
        guard isAuthorized else { return false }
        guard let eventID = eventMap[dayID],
              let event = eventStore.event(withIdentifier: eventID) else { return false }

        do {
            try eventStore.remove(event, span: .thisEvent)
            var map = eventMap
            map.removeValue(forKey: dayID)
            eventMap = map
            return true
        } catch {
            return false
        }
    }

    func removeAllTrainingEvents() {
        for (dayID, eventID) in eventMap {
            if let event = eventStore.event(withIdentifier: eventID) {
                try? eventStore.remove(event, span: .thisEvent)
            }
            var map = eventMap
            map.removeValue(forKey: dayID)
            eventMap = map
        }
    }

    func isEventSynced(dayID: String) -> Bool {
        guard let eventID = eventMap[dayID] else { return false }
        return eventStore.event(withIdentifier: eventID) != nil
    }

    func addConditioningEvent(plan: ConditioningPlan) -> Bool {
        guard isAuthorized, calendarSyncEnabled else { return false }
        guard let calendar = selectedCalendar else { return false }

        let key = "conditioning_\(plan.id)"
        if let existingID = eventMap[key],
           eventStore.event(withIdentifier: existingID) != nil {
            return true
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "KickIQ Conditioning: \(plan.focusType.rawValue)"
        event.calendar = calendar
        event.startDate = plan.createdAt
        event.endDate = Foundation.Calendar.current.date(byAdding: .minute, value: plan.duration.rawValue, to: plan.createdAt) ?? plan.createdAt

        var noteLines: [String] = []
        noteLines.append("Focus: \(plan.focusType.rawValue)")
        noteLines.append("Duration: \(plan.duration.label)")
        noteLines.append("")
        noteLines.append("Drills:")
        for drill in plan.drills {
            noteLines.append("• \(drill.name) (\(drill.duration))")
        }
        event.notes = noteLines.joined(separator: "\n")

        if reminderMinutesBefore > 0 {
            event.addAlarm(EKAlarm(relativeOffset: TimeInterval(-reminderMinutesBefore * 60)))
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            var map = eventMap
            map[key] = event.eventIdentifier
            eventMap = map
            return true
        } catch {
            return false
        }
    }

    func cleanup() {
        UserDefaults.standard.removeObject(forKey: syncEnabledKey)
        UserDefaults.standard.removeObject(forKey: reminderKey)
        UserDefaults.standard.removeObject(forKey: calendarIDKey)
        UserDefaults.standard.removeObject(forKey: eventMapKey)
        calendarSyncEnabled = false
        selectedCalendarID = nil
        reminderMinutesBefore = 30
    }
}
