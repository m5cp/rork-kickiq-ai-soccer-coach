import SwiftUI

struct GeneratedPlanDetailView: View {
    let storage: StorageService
    @State var plan: GeneratedPlan
    @State private var calendarService = CalendarService()
    @State private var expandedWeek: Int? = 1
    @State private var expandedDay: String?
    @State private var appeared = false
    @State private var showCalendarAlert = false
    @State private var calendarEventsAdded = 0
    @State private var showQRSheet = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    planSummaryCard
                    configStatsRow
                    actionButtons
                    weeksList
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("\(plan.config.planType.rawValue) Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .alert("Calendar Sync", isPresented: $showCalendarAlert) {
                Button("OK") {}
            } message: {
                Text(calendarEventsAdded > 0 ? "\(calendarEventsAdded) training sessions added to your calendar!" : "Could not add events. Please check calendar permissions in Settings.")
            }
            .sheet(isPresented: $showQRSheet) {
                PlanQRShareSheet(plan: plan)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var planSummaryCard: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: plan.config.planType == .skills ? "figure.soccer" : "heart.circle.fill")
                        .font(.caption)
                    Text("\(plan.config.planType.rawValue.uppercased()) PLAN")
                        .font(.caption.weight(.black))
                        .tracking(1)
                }
                .foregroundStyle(KickIQAICoachTheme.accent)

                Spacer()

                Text(plan.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Text(plan.summary)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .lineSpacing(3)

            if plan.isSynced {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("Synced to Calendar")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
                .padding(.top, 2)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
    }

    private var configStatsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(plan.config.weeks)", label: "Weeks", icon: "calendar")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 32)
            statItem(value: "\(plan.config.daysPerWeek)", label: "Days/Wk", icon: "repeat")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 32)
            statItem(value: "\(plan.config.minutesPerSession)m", label: "Per Session", icon: "clock.fill")
            Rectangle().fill(KickIQAICoachTheme.divider).frame(width: 1, height: 32)
            statItem(value: "\(plan.totalDrills)", label: "Drills", icon: "figure.run")
        }
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(value)
                    .font(.caption.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            if !plan.isSynced {
                Button {
                    Task { await syncToCalendar() }
                } label: {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Accept & Sync to Calendar")
                    }
                    .font(.headline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: plan.isSynced)
            }

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Button {
                    Task { await exportPDF() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                        Text("PDF")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md).stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1))
                }

                Button {
                    showQRSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode")
                        Text("Share QR")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.md).stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var weeksList: some View {
        LazyVStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ForEach(plan.weeks) { week in
                weekSection(week)
            }
        }
    }

    private func weekSection(_ week: GeneratedPlanWeek) -> some View {
        let isExpanded = expandedWeek == week.weekNumber

        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expandedWeek = isExpanded ? nil : week.weekNumber
                }
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .fill(KickIQAICoachTheme.accent.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Text("W\(week.weekNumber)")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week \(week.weekNumber)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        let trainingDays = week.days.filter { !$0.restDay }.count
                        Text("\(trainingDays) training days")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(KickIQAICoachTheme.Spacing.md)
            }
            .sensoryFeedback(.selection, trigger: isExpanded)

            if isExpanded {
                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    ForEach(week.days) { day in
                        dayRow(day)
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(Double(week.weekNumber) * 0.04), value: appeared)
    }

    private func dayRow(_ day: TrainingPlanDay) -> some View {
        let isDayExpanded = expandedDay == day.id

        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedDay = isDayExpanded ? nil : day.id
                }
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: day.restDay ? "bed.double.fill" : "figure.soccer")
                        .font(.caption)
                        .foregroundStyle(day.restDay ? .blue : KickIQAICoachTheme.accent)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(day.dayLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text(day.focus)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    Spacer()

                    if !day.restDay {
                        Text("\(day.drills.count) drills")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
                            .rotationEffect(.degrees(isDayExpanded ? 90 : 0))
                    }
                }
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
            }

            if isDayExpanded && !day.restDay {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(day.drills) { drill in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(KickIQAICoachTheme.accent)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(drill.name)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                    Spacer()
                                    Text(drill.duration)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(KickIQAICoachTheme.accent)
                                }
                                Text(drill.description)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                                    .lineLimit(2)
                                if !drill.reps.isEmpty {
                                    Text(drill.reps)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
                .padding(.bottom, KickIQAICoachTheme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
    }

    private func syncToCalendar() async {
        await calendarService.requestAccess()
        guard calendarService.isAuthorized else {
            calendarEventsAdded = 0
            showCalendarAlert = true
            return
        }

        var count = 0
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: .now)

        for week in plan.weeks {
            for (dayIndex, day) in week.days.enumerated() {
                guard !day.restDay else { continue }
                let weekOffset = (week.weekNumber - 1) * 7
                guard let eventDate = calendar.date(byAdding: .day, value: weekOffset + dayIndex, to: startDate) else { continue }
                let trainingDate = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: eventDate) ?? eventDate
                let drillNames = day.drills.map(\.name).joined(separator: "\n- ")
                let notes = "Focus: \(day.focus)\n\nDrills:\n- \(drillNames)"

                let success = await calendarService.addTrainingSession(
                    title: "\(plan.config.planType.rawValue): \(day.focus)",
                    date: trainingDate,
                    duration: Double(plan.config.minutesPerSession * 60),
                    notes: notes
                )
                if success { count += 1 }
            }
        }

        calendarEventsAdded = count
        if count > 0 {
            plan.isSynced = true
            storage.saveGeneratedPlan(plan)
        }
        showCalendarAlert = true
    }

    private func exportPDF() async {
        let renderer = ImageRenderer(content: PlanPDFContent(plan: plan))
        renderer.scale = 2

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("KickIQ_\(plan.config.planType.rawValue)_Plan.pdf")

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(tempURL as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        pdfURL = tempURL
        showShareSheet = true
    }
}

struct PlanQRShareSheet: View {
    let plan: GeneratedPlan
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                Text("Share Plan")
                    .font(.title3.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("\(plan.config.planType.rawValue) • \(plan.config.weeks) Weeks")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)

                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .background(Color.white, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                        .padding(KickIQAICoachTheme.Spacing.md)
                } else {
                    ProgressView()
                        .frame(width: 200, height: 200)
                }

                Text("Scan to view plan details")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                if let qrImage {
                    ShareLink(item: Image(uiImage: qrImage), preview: SharePreview("KickIQ \(plan.config.planType.rawValue) Plan", image: Image(uiImage: qrImage))) {
                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share QR Code")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                    }
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            let summary = "KickIQ \(plan.config.planType.rawValue) Plan: \(plan.config.weeks) weeks, \(plan.config.daysPerWeek) days/week, \(plan.config.minutesPerSession) min sessions. \(plan.summary)"
            qrImage = QRSharingService.generateQRCode(from: "kickiq://plan?\(summary)")
        }
    }
}

struct PlanPDFContent: View {
    let plan: GeneratedPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("KICKIQ")
                        .font(.system(size: 14, weight: .black).width(.compressed))
                        .tracking(4)
                        .foregroundStyle(Color(hex: 0x7BAFD4))
                    Text("\(plan.config.planType.rawValue.uppercased()) TRAINING PLAN")
                        .font(.system(size: 18, weight: .black))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(plan.config.weeks) Weeks • \(plan.config.daysPerWeek) Days/Week")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(plan.config.minutesPerSession) min/session")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            Rectangle().fill(Color(hex: 0x7BAFD4)).frame(height: 2)

            Text(plan.summary)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(plan.weeks) { week in
                VStack(alignment: .leading, spacing: 8) {
                    Text("WEEK \(week.weekNumber)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Color(hex: 0x7BAFD4))

                    ForEach(week.days) { day in
                        if !day.restDay {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(day.dayLabel)
                                        .font(.system(size: 11, weight: .bold))
                                    Text("— \(day.focus)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(day.drills) { drill in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .font(.system(size: 10))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("\(drill.name) (\(drill.duration))")
                                                .font(.system(size: 10, weight: .semibold))
                                            if !drill.reps.isEmpty {
                                                Text(drill.reps)
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Text("Generated by KickIQ AI Coach")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(plan.createdAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 612, height: 792)
        .background(.white)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
