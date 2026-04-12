import SwiftUI

struct PlanResultView: View {
    let plan: SavedPlan
    let storage: StorageService
    let onAccept: (SavedPlan) -> Void
    let onRegenerate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeek: Int = 1
    @State private var showCalendarAlert = false
    @State private var calendarService = CalendarService()
    @State private var calendarSynced = false
    @State private var showPDFShare = false
    @State private var showQRShare = false
    @State private var pdfURL: URL?
    @State private var acceptedPlan: SavedPlan?
    @State private var showPostAccept = false
    @State private var acceptTrigger = 0

    private var accentColor: Color {
        plan.planType == .conditioning ? .orange : KickIQTheme.accent
    }

    private var weeks: [Int] {
        let maxWeek = plan.days.map(\.weekNumber).max() ?? 1
        return Array(1...maxWeek)
    }

    private var daysForSelectedWeek: [SavedPlanDay] {
        plan.days.filter { $0.weekNumber == selectedWeek }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md + 4) {
                    summaryCard
                    weekPicker
                    daysList
                    actionButtons
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl + 60)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Your Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                acceptRejectBar
            }
        }
        .sheet(isPresented: $showPostAccept) {
            PostAcceptActionsSheet(
                plan: acceptedPlan ?? plan,
                storage: storage,
                onDone: { dismiss() }
            )
        }
        .sheet(isPresented: $showQRShare) {
            let payload = buildQRPayload()
            QRCodeShareSheet(
                payload: payload,
                title: "Share Plan",
                subtitle: "Let someone scan to import this training plan"
            )
        }
        .sheet(isPresented: $showPDFShare) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        .sensoryFeedback(.success, trigger: acceptTrigger)
        .alert("Calendar Access", isPresented: $showCalendarAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable calendar access in Settings to sync your plan.")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.planType == .conditioning ? "CONDITIONING PLAN" : "SKILL TRAINING PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(accentColor)
                    Text(plan.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(plan.weekCount)")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(accentColor)
                    Text("WEEKS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .frame(width: 56, height: 56)
                .background(accentColor.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(plan.focusAreas, id: \.self) { area in
                        Text(area)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accentColor.opacity(0.12), in: Capsule())
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)

            HStack(spacing: 0) {
                planStatCell(value: "\(plan.totalDays)", label: "Days", color: accentColor)
                planStatDivider
                planStatCell(value: "\(plan.totalDrills)", label: "Drills", color: .green)
                planStatDivider
                planStatCell(value: plan.sessionDuration.label, label: "Per Session", color: .blue)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    private func planStatCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var planStatDivider: some View {
        Rectangle()
            .fill(KickIQTheme.divider)
            .frame(width: 1, height: 28)
    }

    private var weekPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(weeks, id: \.self) { week in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedWeek = week }
                    } label: {
                        Text("Week \(week)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selectedWeek == week ? .black : KickIQTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedWeek == week ? accentColor : KickIQTheme.card,
                                in: Capsule()
                            )
                    }
                    .sensoryFeedback(.selection, trigger: selectedWeek == week)
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private var daysList: some View {
        VStack(spacing: 0) {
            ForEach(Array(daysForSelectedWeek.enumerated()), id: \.element.id) { index, day in
                dayRow(day)
                if index < daysForSelectedWeek.count - 1 {
                    Divider()
                        .background(KickIQTheme.divider)
                        .padding(.leading, 56)
                }
            }
        }
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func dayRow(_ day: SavedPlanDay) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Text("\(day.dayNumber)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Day \(day.dayNumber) — \(day.focus)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Image(systemName: day.intensity.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(intensityColor(day.intensity))
                        Text(day.intensity.rawValue)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                        Text("·")
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
                        Text("\(day.drills.count) drills")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }

                Spacer()
            }

            ForEach(day.drills) { drill in
                HStack(spacing: 8) {
                    Circle()
                        .fill(KickIQTheme.surface)
                        .frame(width: 6, height: 6)
                    Text(drill.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text(drill.duration)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                }
                .padding(.leading, 54)
            }
        }
        .padding(KickIQTheme.Spacing.md)
    }

    private var actionButtons: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            Button {
                syncToCalendar()
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: calendarSynced ? "checkmark.circle.fill" : "calendar.badge.plus")
                    Text(calendarSynced ? "Synced to Calendar" : "Sync to Calendar")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(calendarSynced ? .green : accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    calendarSynced ? Color.green.opacity(0.12) : accentColor.opacity(0.12),
                    in: .rect(cornerRadius: KickIQTheme.Radius.md)
                )
            }
            .disabled(calendarSynced)

            HStack(spacing: KickIQTheme.Spacing.sm) {
                Button {
                    exportPDF()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                        Text("Export PDF")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }

                Button {
                    showQRShare = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode")
                        Text("QR Code")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            }
        }
    }

    private var acceptRejectBar: some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            Button {
                onRegenerate()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Regenerate")
                }
                .font(.headline)
                .foregroundStyle(accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentColor.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }

            Button {
                var accepted = plan
                if calendarSynced {
                    accepted.isSyncedToCalendar = true
                }
                acceptedPlan = accepted
                onAccept(accepted)
                acceptTrigger += 1
                showPostAccept = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept Plan")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentColor, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private func syncToCalendar() {
        Task {
            if !calendarService.isAuthorized {
                let granted = await calendarService.requestAccess()
                if !granted {
                    showCalendarAlert = true
                    return
                }
            }
            if !calendarService.calendarSyncEnabled {
                calendarService.enableSync(true)
            }
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            for day in plan.days {
                guard let date = calendar.date(byAdding: .day, value: day.dayNumber - 1, to: today) else { continue }
                let dailyPlan = DailyPlan(
                    date: date,
                    dayNumber: day.dayNumber,
                    focus: day.focus,
                    intensity: day.intensity,
                    duration: day.duration,
                    mode: .solo,
                    weaknessPriority: plan.focusAreas,
                    drills: day.drills.map {
                        SmartDrill(
                            name: $0.name,
                            description: $0.description,
                            duration: $0.duration,
                            difficulty: $0.difficulty,
                            targetSkill: $0.targetSkill,
                            coachingCues: $0.coachingCues,
                            reps: $0.reps,
                            reason: ""
                        )
                    }
                )
                let _ = calendarService.addTrainingEvent(for: dailyPlan)
            }
            calendarSynced = true
        }
    }

    private func exportPDF() {
        pdfURL = PlanPDFExporter.generatePDF(for: plan)
        if pdfURL != nil {
            showPDFShare = true
        }
    }

    private func buildQRPayload() -> QRSharePayload {
        let qrDays = plan.days.prefix(7).map { day in
            QRDailyPlanPayload(
                focus: day.focus,
                intensity: day.intensity,
                duration: day.duration,
                mode: .solo,
                weaknessPriority: plan.focusAreas,
                drills: day.drills.map {
                    QRDrillPayload(
                        name: $0.name,
                        description: $0.description,
                        duration: $0.duration,
                        difficulty: $0.difficulty,
                        targetSkill: $0.targetSkill,
                        coachingCues: $0.coachingCues,
                        reps: $0.reps
                    )
                }
            )
        }
        return QRSharePayload(trainingPlan: QRTrainingPlanPayload(
            summary: plan.summaryText,
            days: Array(qrDays)
        ))
    }

    private func intensityColor(_ intensity: TrainingIntensity) -> Color {
        switch intensity {
        case .light: .green
        case .medium: .orange
        case .heavy: .red
        }
    }
}

