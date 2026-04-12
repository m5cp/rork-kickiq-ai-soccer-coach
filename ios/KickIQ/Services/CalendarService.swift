import EventKit
import Foundation

@Observable
@MainActor
class CalendarService {
    var isAuthorized = false
    var errorMessage: String?

    private let eventStore = EKEventStore()

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isAuthorized = granted
        } catch {
            errorMessage = "Calendar access denied"
            isAuthorized = false
        }
    }

    func addTrainingSession(title: String, date: Date, duration: TimeInterval = 3600, notes: String? = nil) async -> Bool {
        guard isAuthorized else {
            await requestAccess()
            guard isAuthorized else { return false }
            return await addTrainingSession(title: title, date: date, duration: duration, notes: notes)
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "KickIQ: \(title)"
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        let alarm = EKAlarm(relativeOffset: -900)
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            errorMessage = "Failed to save event"
            return false
        }
    }

    func addTrainingPlanToCalendar(plan: TrainingPlan, startDate: Date = .now) async -> Int {
        guard isAuthorized else {
            await requestAccess()
            guard isAuthorized else { return 0 }
            return await addTrainingPlanToCalendar(plan: plan, startDate: startDate)
        }

        let calendar = Calendar.current
        var addedCount = 0

        for (index, day) in plan.days.enumerated() {
            guard !day.restDay else { continue }
            guard let eventDate = calendar.date(byAdding: .day, value: index, to: calendar.startOfDay(for: startDate)) else { continue }

            let trainingDate = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: eventDate) ?? eventDate
            let drillNames = day.drills.map(\.name).joined(separator: "\n- ")
            let notes = "Focus: \(day.focus)\n\nDrills:\n- \(drillNames)"

            let success = await addTrainingSession(
                title: "\(day.focus) Training",
                date: trainingDate,
                duration: 3600,
                notes: notes
            )
            if success { addedCount += 1 }
        }

        return addedCount
    }
}
