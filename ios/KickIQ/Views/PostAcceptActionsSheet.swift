import SwiftUI

struct PostAcceptActionsSheet: View {
    let plan: SavedPlan
    let storage: StorageService
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var calendarService = CalendarService()
    @State private var calendarSynced = false
    @State private var showCalendarAlert = false
    @State private var showPDFShare = false
    @State private var showQRShare = false
    @State private var pdfURL: URL?
    @State private var syncing = false

    private var accentColor: Color {
        plan.planType == .conditioning ? .orange : KickIQTheme.accent
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: KickIQTheme.Spacing.lg) {
                Spacer().frame(height: KickIQTheme.Spacing.sm)

                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: true)
                }

                VStack(spacing: 6) {
                    Text("Plan Saved!")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text(plan.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: KickIQTheme.Spacing.sm) {
                    Button {
                        syncToCalendar()
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            if syncing {
                                ProgressView().tint(calendarSynced ? .green : accentColor)
                            } else {
                                Image(systemName: calendarSynced ? "checkmark.circle.fill" : "calendar.badge.plus")
                            }
                            Text(calendarSynced ? "Synced to Calendar" : "Sync to Calendar")
                            Spacer()
                            if !calendarSynced && !syncing {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(calendarSynced ? .green : KickIQTheme.textPrimary)
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .padding(.vertical, 16)
                        .background(
                            calendarSynced ? Color.green.opacity(0.1) : KickIQTheme.card,
                            in: .rect(cornerRadius: KickIQTheme.Radius.lg)
                        )
                    }
                    .disabled(calendarSynced || syncing)
                    .sensoryFeedback(.success, trigger: calendarSynced)

                    Button {
                        exportPDF()
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Image(systemName: "doc.text.fill")
                            Text("Share PDF")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .padding(.vertical, 16)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }

                    Button {
                        showQRShare = true
                    } label: {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            Image(systemName: "qrcode")
                            Text("Share QR Code")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .padding(.vertical, 16)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)

                Spacer()

                Button {
                    dismiss()
                    onDone()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.md)
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .presentationContentInteraction(.scrolls)
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
                subtitle: "Let someone scan to import this training plan"
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
            Text("Please enable calendar access in Settings to sync your plan.")
        }
    }

    private func syncToCalendar() {
        syncing = true
        Task {
            if !calendarService.isAuthorized {
                let granted = await calendarService.requestAccess()
                if !granted {
                    syncing = false
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
            var updatedPlan = plan
            updatedPlan.isSyncedToCalendar = true
            storage.updateSavedPlan(updatedPlan)
            calendarSynced = true
            syncing = false
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
}
