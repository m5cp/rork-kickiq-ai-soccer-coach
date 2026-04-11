import SwiftUI

struct SavedPlansView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SavedPlan?
    @State private var showPDFShare = false
    @State private var showQRShare = false
    @State private var pdfURL: URL?
    @State private var qrPayload: QRSharePayload?
    @State private var planToDelete: SavedPlan?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if storage.savedPlans.isEmpty {
                    emptyState
                } else {
                    plansList
                }
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Saved Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .sheet(item: $selectedPlan) { plan in
            SavedPlanDetailView(plan: plan, storage: storage)
        }
        .sheet(isPresented: $showPDFShare) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showQRShare) {
            if let payload = qrPayload {
                QRCodeShareSheet(
                    payload: payload,
                    title: "Share Plan",
                    subtitle: "Scan to import this training plan"
                )
            }
        }
        .alert("Delete Plan?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let plan = planToDelete {
                    withAnimation { storage.deleteSavedPlan(plan.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This plan will be permanently removed.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(KickIQTheme.accent)
            }
            Text("No Saved Plans")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)
            Text("Generate and accept a training plan to see it here.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, KickIQTheme.Spacing.lg)
    }

    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: KickIQTheme.Spacing.md) {
                ForEach(storage.savedPlans) { plan in
                    planCard(plan)
                }
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.bottom, KickIQTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func planCard(_ plan: SavedPlan) -> some View {
        let accentColor: Color = plan.planType == .conditioning ? .orange : KickIQTheme.accent
        let progress = plan.totalDays > 0 ? Double(plan.completedDays) / Double(plan.totalDays) : 0

        return VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: plan.planType == .conditioning ? "flame.fill" : "figure.soccer")
                            .font(.caption)
                            .foregroundStyle(accentColor)
                        Text(plan.planType == .conditioning ? "CONDITIONING" : "SKILL DRILLS")
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(accentColor)
                    }
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(plan.weekCount)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(accentColor)
                    Text("wks")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(plan.focusAreas, id: \.self) { area in
                        Text(area)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.1), in: Capsule())
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)

            HStack(spacing: KickIQTheme.Spacing.sm) {
                Text("\(plan.completedDays)/\(plan.totalDays) days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(plan.completedDays == plan.totalDays && plan.totalDays > 0 ? .green : KickIQTheme.textSecondary)

                Spacer()

                Text(plan.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(KickIQTheme.divider).frame(height: 6)
                    Capsule()
                        .fill(progress >= 1 ? Color.green : accentColor)
                        .frame(width: max(0, geo.size.width * progress), height: 6)
                }
            }
            .frame(height: 6)

            HStack(spacing: KickIQTheme.Spacing.sm) {
                Button {
                    selectedPlan = plan
                } label: {
                    Text("View")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accentColor, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }

                Button {
                    pdfURL = PlanPDFExporter.generatePDF(for: plan)
                    if pdfURL != nil { showPDFShare = true }
                } label: {
                    Image(systemName: "doc.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 40, height: 36)
                        .background(accentColor.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }

                Button {
                    qrPayload = buildQRPayload(plan)
                    showQRShare = true
                } label: {
                    Image(systemName: "qrcode")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 40, height: 36)
                        .background(accentColor.opacity(0.12), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }

                Button {
                    planToDelete = plan
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 40, height: 36)
                        .background(.red.opacity(0.08), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func buildQRPayload(_ plan: SavedPlan) -> QRSharePayload {
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
}

struct SavedPlanDetailView: View {
    let plan: SavedPlan
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeek: Int = 1
    @State private var localPlan: SavedPlan
    @State private var completedTrigger = 0
    @State private var showPDFShare = false
    @State private var showQRShare = false
    @State private var pdfURL: URL?
    @State private var calendarService = CalendarService()
    @State private var calendarSynced = false
    @State private var showCalendarAlert = false

    init(plan: SavedPlan, storage: StorageService) {
        self.plan = plan
        self.storage = storage
        _localPlan = State(initialValue: plan)
    }

    private var accentColor: Color {
        localPlan.planType == .conditioning ? .orange : KickIQTheme.accent
    }

    private var weeks: [Int] {
        let maxWeek = localPlan.days.map(\.weekNumber).max() ?? 1
        return Array(1...maxWeek)
    }

    private var daysForSelectedWeek: [SavedPlanDay] {
        localPlan.days.filter { $0.weekNumber == selectedWeek }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.md) {
                    progressHeader
                    weekPicker
                    dayCards
                    exportActions
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(localPlan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .sensoryFeedback(.success, trigger: completedTrigger)
        .sheet(isPresented: $showPDFShare) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showQRShare) {
            let payload = buildQRPayload()
            QRCodeShareSheet(
                payload: payload,
                title: "Share Plan",
                subtitle: "Scan to import this plan"
            )
        }
        .alert("Calendar Access", isPresented: $showCalendarAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable calendar access in Settings.")
        }
        .onAppear {
            calendarSynced = localPlan.isSyncedToCalendar
        }
    }

    private var progressHeader: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localPlan.planType == .conditioning ? "CONDITIONING" : "SKILL TRAINING")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(accentColor)
                    Text("\(localPlan.completedDays)/\(localPlan.totalDays) days completed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                let pct = localPlan.totalDays > 0 ? Int(Double(localPlan.completedDays) / Double(localPlan.totalDays) * 100) : 0
                Text("\(pct)%")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(pct >= 100 ? .green : accentColor)
            }

            GeometryReader { geo in
                let progress = localPlan.totalDays > 0 ? Double(localPlan.completedDays) / Double(localPlan.totalDays) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(KickIQTheme.divider).frame(height: 8)
                    Capsule()
                        .fill(progress >= 1 ? Color.green : accentColor)
                        .frame(width: max(0, geo.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(localPlan.focusAreas, id: \.self) { area in
                        Text(area)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.1), in: Capsule())
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
    }

    private var weekPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(weeks, id: \.self) { week in
                    let weekDays = localPlan.days.filter { $0.weekNumber == week }
                    let weekComplete = weekDays.allSatisfy(\.isFullyCompleted) && !weekDays.isEmpty

                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedWeek = week }
                    } label: {
                        HStack(spacing: 4) {
                            if weekComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.green)
                            }
                            Text("Week \(week)")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(selectedWeek == week ? .black : KickIQTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedWeek == week ? accentColor : KickIQTheme.card,
                            in: Capsule()
                        )
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private var dayCards: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            ForEach(Array(daysForSelectedWeek.enumerated()), id: \.element.id) { _, day in
                dayCard(day)
            }
        }
    }

    private func dayCard(_ day: SavedPlanDay) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(day.isFullyCompleted ? Color.green.opacity(0.15) : accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    if day.isFullyCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(day.dayNumber)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(day.dayNumber) — \(day.focus)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: day.intensity.icon)
                            .font(.system(size: 9))
                        Text(day.intensity.rawValue)
                            .font(.caption2.weight(.medium))
                        Text("·")
                        Text("\(day.completedCount)/\(day.drills.count)")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()
            }

            ForEach(Array(day.drills.enumerated()), id: \.element.id) { drillIdx, drill in
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Button {
                        completeDrill(dayID: day.id, drillIndex: drillIdx)
                    } label: {
                        Image(systemName: drill.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(drill.isCompleted ? .green : KickIQTheme.textSecondary.opacity(0.3))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(drill.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(drill.isCompleted ? KickIQTheme.textSecondary : KickIQTheme.textPrimary)
                            .strikethrough(drill.isCompleted, color: KickIQTheme.textSecondary)
                        HStack(spacing: 4) {
                            Text(drill.duration)
                            if !drill.reps.isEmpty {
                                Text("·")
                                Text(drill.reps)
                            }
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                    }

                    Spacer()
                }
                .padding(.leading, 44)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var exportActions: some View {
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
                    pdfURL = PlanPDFExporter.generatePDF(for: localPlan)
                    if pdfURL != nil { showPDFShare = true }
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
                        Text("Share QR")
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

    private func completeDrill(dayID: String, drillIndex: Int) {
        guard let dayIdx = localPlan.days.firstIndex(where: { $0.id == dayID }),
              drillIndex < localPlan.days[dayIdx].drills.count else { return }
        localPlan.days[dayIdx].drills[drillIndex].isCompleted.toggle()
        storage.updateSavedPlan(localPlan)
        completedTrigger += 1
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
            for day in localPlan.days {
                guard let date = calendar.date(byAdding: .day, value: day.dayNumber - 1, to: today) else { continue }
                let dailyPlan = DailyPlan(
                    date: date,
                    dayNumber: day.dayNumber,
                    focus: day.focus,
                    intensity: day.intensity,
                    duration: day.duration,
                    mode: .solo,
                    weaknessPriority: localPlan.focusAreas,
                    drills: day.drills.map {
                        SmartDrill(name: $0.name, description: $0.description, duration: $0.duration, difficulty: $0.difficulty, targetSkill: $0.targetSkill, coachingCues: $0.coachingCues, reps: $0.reps, reason: "")
                    }
                )
                let _ = calendarService.addTrainingEvent(for: dailyPlan)
            }
            calendarSynced = true
            localPlan.isSyncedToCalendar = true
            storage.updateSavedPlan(localPlan)
        }
    }

    private func buildQRPayload() -> QRSharePayload {
        let qrDays = localPlan.days.prefix(7).map { day in
            QRDailyPlanPayload(
                focus: day.focus,
                intensity: day.intensity,
                duration: day.duration,
                mode: .solo,
                weaknessPriority: localPlan.focusAreas,
                drills: day.drills.map {
                    QRDrillPayload(name: $0.name, description: $0.description, duration: $0.duration, difficulty: $0.difficulty, targetSkill: $0.targetSkill, coachingCues: $0.coachingCues, reps: $0.reps)
                }
            )
        }
        return QRSharePayload(trainingPlan: QRTrainingPlanPayload(summary: localPlan.summaryText, days: Array(qrDays)))
    }
}
