import SwiftUI

struct CoachCampaignView: View {
    @Bindable var coachStorage: CoachStorageService
    @State private var showGenerator = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Button {
                    showGenerator = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                        Text("Generate Campaign")
                            .font(.headline)
                    }
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                if coachStorage.campaigns.isEmpty {
                    ContentUnavailableView(
                        "No Campaigns Yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Generate your first multi-week training campaign based on periodization.")
                    )
                    .padding(.top, 40)
                }

                ForEach(coachStorage.campaigns.sorted(by: { $0.createdAt > $1.createdAt })) { campaign in
                    NavigationLink {
                        CampaignDetailView(coachStorage: coachStorage, campaign: campaign)
                    } label: {
                        campaignCard(campaign)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            coachStorage.deleteCampaign(campaign)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showGenerator) {
            CampaignGeneratorSheet(coachStorage: coachStorage)
        }
    }

    private func campaignCard(_ c: Campaign) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.title)
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(c.style.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                Spacer()
                Text("\(c.weeks.count)w")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(KickIQAICoachTheme.accent, in: Capsule())
            }
            HStack(spacing: 12) {
                Label(c.ageGroup, systemImage: "person.2.fill")
                Label(c.level, systemImage: "chart.bar.fill")
                Label(c.startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }
}

struct CampaignGeneratorSheet: View {
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var style: PeriodizationStyle = .tacticalMorphocycle
    @State private var weeks: Int = 6
    @State private var sessionsPerWeek: Int = 3
    @State private var ageGroup: String = "U15-U19"
    @State private var level: String = "Competitive"
    @State private var startDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Campaign") {
                    TextField("Title", text: $title)
                        .submitLabel(.done)
                }

                Section("Periodization Style") {
                    ForEach(PeriodizationStyle.allCases) { s in
                        Button {
                            style = s
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: style == s ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(KickIQAICoachTheme.accent)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.rawValue)
                                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                        .fontWeight(.semibold)
                                    Text(s.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Plan") {
                    Stepper("Weeks: \(weeks)", value: $weeks, in: 1...16)
                    Stepper("Sessions per week: \(sessionsPerWeek)", value: $sessionsPerWeek, in: 1...5)
                    TextField("Age Group", text: $ageGroup)
                    TextField("Level", text: $level)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Generate Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Generate") { generate() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func generate() {
        let campaign = CampaignGenerator.generate(
            title: title,
            style: style,
            weeks: weeks,
            sessionsPerWeek: sessionsPerWeek,
            ageGroup: ageGroup,
            level: level,
            startDate: startDate,
            library: coachStorage.sessions
        )
        coachStorage.addCampaign(campaign)
        dismiss()
    }
}

struct CampaignDetailView: View {
    @Bindable var coachStorage: CoachStorageService
    @State var campaign: Campaign
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard

                ForEach(campaign.weeks) { week in
                    weekCard(week)
                }
            }
            .padding(16)
        }
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationTitle(campaign.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            CoachShareSheet(shareable: .campaign(campaign, resolve: { id in
                campaign.embeddedSessions.first { $0.id == id } ?? coachStorage.sessions.first { $0.id == id }
            }))
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(campaign.style.rawValue)
                .font(.caption.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text(campaign.title)
                .font(.title3.bold())
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            HStack(spacing: 12) {
                Label("\(campaign.weeks.count) weeks", systemImage: "calendar")
                Label(campaign.ageGroup, systemImage: "person.2.fill")
                Label(campaign.level, systemImage: "chart.bar.fill")
            }
            .font(.caption)
            .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }

    private func weekCard(_ week: CampaignWeek) -> some View {
        let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: week.weekNumber - 1, to: campaign.startDate) ?? campaign.startDate
        return HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(KickIQAICoachTheme.accent)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Week \(week.weekNumber)")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text("·")
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(week.phaseLabel.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Spacer()
                    Text(weekStart.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                ForEach(week.sessionIDs, id: \.self) { sid in
                    if let session = resolve(sid) {
                        NavigationLink {
                            CampaignSessionDetailView(coachStorage: coachStorage, campaign: $campaign, sessionID: sid)
                        } label: {
                            sessionRow(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
        }
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }

    private func sessionRow(_ s: CoachSession) -> some View {
        HStack(spacing: 10) {
            Image(systemName: s.gameMoment.icon)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 28, height: 28)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(s.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text("\(s.duration) min · \(s.displayGameMoment)")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(10)
        .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: 10))
    }

    private func resolve(_ id: UUID) -> CoachSession? {
        campaign.embeddedSessions.first { $0.id == id } ?? coachStorage.sessions.first { $0.id == id }
    }
}

struct CampaignSessionDetailView: View {
    @Bindable var coachStorage: CoachStorageService
    @Binding var campaign: Campaign
    let sessionID: UUID
    @State private var showShare = false

    var body: some View {
        Group {
            if let binding = sessionBinding {
                SessionPhaseDetailView(
                    session: binding,
                    onUpdate: { updated in
                        if let idx = campaign.embeddedSessions.firstIndex(where: { $0.id == updated.id }) {
                            campaign.embeddedSessions[idx] = updated
                            coachStorage.updateCampaign(campaign)
                        }
                    },
                    onShare: { showShare = true }
                )
            } else {
                ContentUnavailableView("Session not found", systemImage: "questionmark.folder")
            }
        }
        .sheet(isPresented: $showShare) {
            if let s = campaign.embeddedSessions.first(where: { $0.id == sessionID }) {
                CoachShareSheet(shareable: .session(s))
            }
        }
    }

    private var sessionBinding: Binding<CoachSession>? {
        guard let idx = campaign.embeddedSessions.firstIndex(where: { $0.id == sessionID }) else { return nil }
        return Binding(
            get: { campaign.embeddedSessions[idx] },
            set: { campaign.embeddedSessions[idx] = $0 }
        )
    }
}
