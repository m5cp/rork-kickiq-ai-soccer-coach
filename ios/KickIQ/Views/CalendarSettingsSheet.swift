import SwiftUI
import EventKit

struct CalendarSettingsSheet: View {
    let calendarService: CalendarService
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var syncEnabled: Bool = false
    @State private var selectedReminder: Int = 30
    @State private var selectedCalendarID: String = ""
    @State private var showSyncAllConfirm = false
    @State private var syncResult: String?
    @State private var showResult = false

    private let reminderOptions: [(label: String, value: Int)] = [
        ("None", 0),
        ("15 min before", 15),
        ("30 min before", 30),
        ("1 hour before", 60),
        ("2 hours before", 120),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    statusCard
                    if calendarService.isAuthorized {
                        syncToggle
                        if syncEnabled {
                            calendarPicker
                            reminderPicker
                            syncAllButton
                            removeAllButton
                        }
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
            .alert("Sync Complete", isPresented: $showResult) {
                Button("OK") {}
            } message: {
                Text(syncResult ?? "")
            }
            .confirmationDialog("Sync All Sessions", isPresented: $showSyncAllConfirm) {
                Button("Sync All to Calendar") {
                    syncAllSessions()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will add all training plan sessions to your calendar.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            syncEnabled = calendarService.calendarSyncEnabled
            selectedReminder = calendarService.reminderMinutesBefore
            selectedCalendarID = calendarService.selectedCalendarID ?? calendarService.selectedCalendar?.calendarIdentifier ?? ""
        }
    }

    private var statusCard: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(calendarService.isAuthorized ? Color.green.opacity(0.12) : KickIQTheme.accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: calendarService.isAuthorized ? "calendar.badge.checkmark" : "calendar.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(calendarService.isAuthorized ? .green : KickIQTheme.accent)
            }

            VStack(spacing: 4) {
                Text(calendarService.isAuthorized ? "Calendar Connected" : "Connect Your Calendar")
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(calendarService.isAuthorized
                     ? "Training sessions can sync to Apple Calendar"
                     : "Allow access to sync your training plan to Apple Calendar with reminders")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if !calendarService.isAuthorized {
                Button {
                    Task {
                        _ = await calendarService.requestAccess()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                        Text("Allow Calendar Access")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
        .padding(KickIQTheme.Spacing.lg)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    private var syncToggle: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("SYNC SETTINGS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(width: 24)
                Text("Auto-sync to Calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $syncEnabled)
                    .tint(KickIQTheme.accent)
                    .labelsHidden()
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            .onChange(of: syncEnabled) { _, newValue in
                calendarService.enableSync(newValue)
            }
        }
    }

    private var calendarPicker: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("CALENDAR")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { cal in
                Button {
                    selectedCalendarID = cal.calendarIdentifier
                    calendarService.setCalendar(cal.calendarIdentifier)
                } label: {
                    HStack(spacing: KickIQTheme.Spacing.sm + 2) {
                        Circle()
                            .fill(Color(cgColor: cal.cgColor))
                            .frame(width: 12, height: 12)
                        Text(cal.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Spacer()
                        if selectedCalendarID == cal.calendarIdentifier {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
    }

    private var reminderPicker: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("REMINDER")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            ForEach(reminderOptions, id: \.value) { option in
                Button {
                    selectedReminder = option.value
                    calendarService.setReminder(option.value)
                } label: {
                    HStack {
                        Image(systemName: option.value == 0 ? "bell.slash" : "bell.fill")
                            .font(.subheadline)
                            .foregroundStyle(option.value == 0 ? KickIQTheme.textSecondary : KickIQTheme.accent)
                            .frame(width: 24)
                        Text(option.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Spacer()
                        if selectedReminder == option.value {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
    }

    private var syncAllButton: some View {
        Button {
            showSyncAllConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                Text("Sync All Plan Sessions")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private var removeAllButton: some View {
        Button {
            calendarService.removeAllTrainingEvents()
            syncResult = "All KickIQ events removed from your calendar."
            showResult = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.minus")
                Text("Remove All from Calendar")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.red.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private func syncAllSessions() {
        guard let plan = storage.smartTrainingPlan else {
            syncResult = "No training plan found. Generate a plan first."
            showResult = true
            return
        }
        let count = calendarService.addRecurringTrainingEvents(for: plan.days)
        syncResult = "\(count) session\(count == 1 ? "" : "s") synced to your calendar."
        showResult = true
    }
}
