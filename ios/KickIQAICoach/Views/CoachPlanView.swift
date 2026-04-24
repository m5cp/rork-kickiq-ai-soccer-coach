import SwiftUI

private enum CoachTab: String, CaseIterable, Identifiable {
    case builder = "Session Builder"
    case campaign = "Season Generator"
    case blocks = "Phase Blocks"
    case library = "Library"
    case evaluations = "Evaluations"
    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .builder: return "Build"
        case .campaign: return "Season"
        case .blocks: return "Blocks"
        case .library: return "Library"
        case .evaluations: return "Evals"
        }
    }

    var icon: String {
        switch self {
        case .builder: return "hammer.fill"
        case .campaign: return "calendar"
        case .blocks: return "square.stack.3d.up.fill"
        case .library: return "books.vertical.fill"
        case .evaluations: return "person.text.rectangle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .builder: return "Build a single training session step-by-step"
        case .campaign: return "Full season, phase, month, week or custom range"
        case .blocks: return "Group weeks of sessions around a focus theme"
        case .library: return "All saved sessions, grouped by category"
        case .evaluations: return "Rate players and customize criteria"
        }
    }
}

struct CoachPlanView: View {
    @State private var coachStorage = CoachStorageService()
    @State private var selectedTab: CoachTab = .library

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CoachTab.allCases) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.caption.weight(.bold))
                                Text(tab.shortLabel)
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(selectedTab == tab ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? KickIQAICoachTheme.accent : KickIQAICoachTheme.card, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)

            HStack(spacing: 8) {
                Image(systemName: selectedTab.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(selectedTab.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 4)

            Group {
                switch selectedTab {
                case .builder:
                    SessionBuilderView(coachStorage: coachStorage, onSaved: { selectedTab = .library })
                case .campaign:
                    CoachCampaignView(coachStorage: coachStorage)
                case .blocks:
                    BlockPlannerView(coachStorage: coachStorage)
                case .library:
                    SessionLibraryView(coachStorage: coachStorage, onNew: { selectedTab = .builder })
                case .evaluations:
                    EvaluationsView(coachStorage: coachStorage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationTitle("Coach Planning")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Session Library

private struct LibraryCategory: Identifiable {
    let name: String
    let icon: String
    var id: String { name }
}

private let libraryCategories: [LibraryCategory] = [
    .init(name: "Defending", icon: "shield.lefthalf.filled"),
    .init(name: "Attacking", icon: "arrow.up.forward.circle.fill"),
    .init(name: "Attacking Transition", icon: "hare.fill"),
    .init(name: "Defensive Transition", icon: "arrow.uturn.backward.circle.fill"),
]

private struct SessionLibraryView: View {
    @Bindable var coachStorage: CoachStorageService
    var onNew: () -> Void
    @State private var sharingSessionID: UUID?

    private func sessions(for category: String) -> [CoachSession] {
        coachStorage.sessions.filter { $0.gameMoment.category == category }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(libraryCategories) { cat in
                    let sessions = sessions(for: cat.name)
                    if !sessions.isEmpty {
                        categorySection(cat, sessions: sessions)
                    }
                }

                if coachStorage.sessions.isEmpty {
                    ContentUnavailableView("No Sessions Yet", systemImage: "clipboard", description: Text("Tap + to build your first session."))
                        .padding(.top, 40)
                }
            }
            .padding(.vertical, 16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onNew()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(item: Binding(
            get: { sharingSessionID.map { IDWrapper(id: $0) } },
            set: { sharingSessionID = $0?.id }
        )) { wrap in
            if let s = coachStorage.sessions.first(where: { $0.id == wrap.id }) {
                CoachShareSheet(shareable: .session(s))
            }
        }
    }

    private func categorySection(_ cat: LibraryCategory, sessions: [CoachSession]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: cat.icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(KickIQAICoachTheme.accent.opacity(0.15), in: Circle())
                Text(cat.name)
                    .font(.title3.bold())
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Spacer()
                Text("\(sessions.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(KickIQAICoachTheme.surface, in: Capsule())
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    NavigationLink {
                        LibrarySessionDetailWrapper(coachStorage: coachStorage, sessionID: session.id)
                    } label: {
                        LibraryTileView(session: session)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            sharingSessionID = session.id
                        } label: { Label("Share", systemImage: "square.and.arrow.up") }
                        Button {
                            coachStorage.duplicateSession(session)
                        } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                        Button(role: .destructive) {
                            coachStorage.deleteSession(session)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct IDWrapper: Identifiable { let id: UUID }

private struct LibraryTileView: View {
    let session: CoachSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: session.gameMoment.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(KickIQAICoachTheme.accent, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayGameMoment.uppercased())
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .tracking(0.8)
                    Text(session.displayTitle)
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
            .padding(14)

            Divider().background(KickIQAICoachTheme.divider)

            HStack(spacing: 0) {
                statPill(icon: "clock.fill", value: "\(session.duration)m", label: "Duration")
                Divider().background(KickIQAICoachTheme.divider).frame(height: 28)
                statPill(icon: "flame.fill", value: "\(session.intensity)", label: "Intensity")
                Divider().background(KickIQAICoachTheme.divider).frame(height: 28)
                statPill(icon: "square.stack.3d.up.fill", value: "\(session.activities.count)", label: "Drills")
            }
            .padding(.vertical, 10)
        }
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KickIQAICoachTheme.divider.opacity(0.4), lineWidth: 0.5)
        )
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Detail Wrapper

private struct LibrarySessionDetailWrapper: View {
    @Bindable var coachStorage: CoachStorageService
    let sessionID: UUID
    @State private var showShare = false

    var body: some View {
        if let idx = coachStorage.sessions.firstIndex(where: { $0.id == sessionID }) {
            SessionPhaseDetailView(
                session: Binding(
                    get: { coachStorage.sessions[idx] },
                    set: { coachStorage.sessions[idx] = $0 }
                ),
                onUpdate: { coachStorage.updateSession($0) },
                onShare: { showShare = true }
            )
            .sheet(isPresented: $showShare) {
                CoachShareSheet(shareable: .session(coachStorage.sessions[idx]))
            }
        } else {
            ContentUnavailableView("Session not found", systemImage: "questionmark.folder")
        }
    }
}

// MARK: - Legacy Session Detail (unused)

private struct SessionDetailView: View {
    @Bindable var coachStorage: CoachStorageService
    @State var session: CoachSession
    @State private var editingTitle = false
    @State private var editingMoment = false
    @State private var titleDraft = ""
    @State private var momentDraft = ""
    @State private var editingActivity: SessionActivity?
    @State private var runningActivity: SessionActivity?
    @State private var runningSession: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                titleRow
                momentRow

                Button {
                    runningSession = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Run Session")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 14))
                }
                .disabled(session.activities.isEmpty)
                .opacity(session.activities.isEmpty ? 0.5 : 1)

                VStack(spacing: 0) {
                    infoRow("Objective", value: session.objective)
                    Divider().background(KickIQAICoachTheme.divider)
                    infoRow("Duration", value: "\(session.duration) min")
                    Divider().background(KickIQAICoachTheme.divider)
                    infoRow("Intensity", value: "\(session.intensity)/10")
                    Divider().background(KickIQAICoachTheme.divider)
                    infoRow("Age Group", value: session.ageGroup)
                    Divider().background(KickIQAICoachTheme.divider)
                    infoRow("Players", value: "\(session.playerCount)")
                }
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))

                Text("Activities")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                VStack(spacing: 10) {
                    ForEach(session.activities) { activity in
                        activityRow(activity)
                            .contextMenu {
                                Button {
                                    runningActivity = activity
                                } label: { Label("Start Timer", systemImage: "play.fill") }
                                Button {
                                    editingActivity = activity
                                } label: { Label("Edit", systemImage: "pencil") }
                            }
                    }
                }

                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text(session.notes)
                            .font(.subheadline)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
        }
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationTitle(session.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingActivity) { activity in
            ActivityEditSheet(activity: activity) { updated in
                if let idx = session.activities.firstIndex(where: { $0.id == updated.id }) {
                    session.activities[idx] = updated
                    coachStorage.updateSession(session)
                }
            }
        }
        .sheet(item: $runningActivity) { activity in
            SessionActivityTimerView(activity: activity, sessionTitle: session.displayTitle)
        }
        .fullScreenCover(isPresented: $runningSession) {
            SessionRunnerView(session: session)
        }
    }

    private var titleRow: some View {
        HStack {
            if editingTitle {
                TextField("Title", text: $titleDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commitTitle)
                Button("Save", action: commitTitle)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            } else {
                Text(session.displayTitle)
                    .font(.title2.bold())
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Spacer()
                Button {
                    titleDraft = session.displayTitle
                    editingTitle = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
    }

    private var momentRow: some View {
        HStack(spacing: 8) {
            Image(systemName: session.gameMoment.icon)
                .foregroundStyle(KickIQAICoachTheme.accent)
            if editingMoment {
                TextField("Game Moment", text: $momentDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commitMoment)
                Button("Save", action: commitMoment)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            } else {
                Text(session.displayGameMoment)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Spacer()
                Button {
                    momentDraft = session.displayGameMoment
                    editingMoment = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .padding(12)
        .background(KickIQAICoachTheme.accent.opacity(0.12), in: .rect(cornerRadius: 12))
    }

    private func commitTitle() {
        session.customTitle = titleDraft.isEmpty ? nil : titleDraft
        coachStorage.updateSession(session)
        editingTitle = false
    }

    private func commitMoment() {
        session.customGameMoment = momentDraft.isEmpty ? nil : momentDraft
        coachStorage.updateSession(session)
        editingMoment = false
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func activityRow(_ activity: SessionActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(activity.order)")
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 28, height: 28)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Button { editingActivity = activity } label: {
                    HStack {
                        Text(activity.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Spacer()
                        Text("\(activity.duration)m")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
                    }
                }
                .buttonStyle(.plain)
                Text("\(activity.fieldSize) · \(activity.playerNumbers)")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Button {
                runningActivity = activity
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 12))
    }
}

// MARK: - Activity Edit Sheet

private struct ActivityEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var activity: SessionActivity
    @State private var titleDraft: String
    @State private var editingTitle = false
    var onSave: (SessionActivity) -> Void

    init(activity: SessionActivity, onSave: @escaping (SessionActivity) -> Void) {
        self._activity = State(initialValue: activity)
        self._titleDraft = State(initialValue: activity.displayTitle)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    if editingTitle {
                        TextField("Title", text: $titleDraft)
                        Button("Done") {
                            activity.customTitle = titleDraft.isEmpty ? nil : titleDraft
                            editingTitle = false
                        }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    } else {
                        HStack {
                            Text(activity.displayTitle)
                            Spacer()
                            Button {
                                titleDraft = activity.displayTitle
                                editingTitle = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(KickIQAICoachTheme.accent)
                            }
                        }
                    }
                }

                Section("Details") {
                    Stepper("Duration: \(activity.duration) min", value: $activity.duration, in: 5...60, step: 5)
                    TextField("Field Size", text: $activity.fieldSize)
                    TextField("Player Numbers", text: $activity.playerNumbers)
                }

                Section("Setup") {
                    TextField("Setup", text: $activity.setupDescription, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Instructions") {
                    TextField("Instructions", text: $activity.instructions, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    ForEach(activity.phases.indices, id: \.self) { idx in
                        TextField("Phase", text: $activity.phases[idx], axis: .vertical)
                    }
                    .onDelete { activity.phases.remove(atOffsets: $0) }
                    Button {
                        activity.phases.append("")
                    } label: {
                        Label("Add Phase", systemImage: "plus.circle.fill")
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                } header: { Text("Phases") }

                Section {
                    ForEach(activity.coachingPoints.indices, id: \.self) { idx in
                        TextField("Point", text: $activity.coachingPoints[idx], axis: .vertical)
                    }
                    .onDelete { activity.coachingPoints.remove(atOffsets: $0) }
                    Button {
                        activity.coachingPoints.append("")
                    } label: {
                        Label("Add Point", systemImage: "plus.circle.fill")
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                } header: { Text("Coaching Points") }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(activity)
                        dismiss()
                    }
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Session Builder (4-Step Guided Flow)

private enum BuilderStep: Int, CaseIterable {
    case objective = 0
    case subObjective = 1
    case activities = 2
    case review = 3

    var title: String {
        switch self {
        case .objective: return "Objective"
        case .subObjective: return "Sub-objective"
        case .activities: return "Activities"
        case .review: return "Review"
        }
    }

    var headline: String {
        switch self {
        case .objective: return "What's the focus?"
        case .subObjective: return "Narrow it down"
        case .activities: return "Plan the activities"
        case .review: return "Review & save"
        }
    }

    var helper: String {
        switch self {
        case .objective: return "Pick the main game moment this session will train."
        case .subObjective: return "Choose the specific concept you want players to learn."
        case .activities: return "Add the drills players will run. Tap each to edit details."
        case .review: return "Name your session and add any final notes."
        }
    }
}

private struct SessionBuilderView: View {
    @Bindable var coachStorage: CoachStorageService
    var onSaved: () -> Void

    @State private var step: BuilderStep = .objective

    @State private var selectedMoment: GameMoment?
    @State private var selectedObjective: String?

    @State private var duration: Int = 75
    @State private var intensity: Double = 6
    @State private var ageGroup: String = "U15-U19"
    @State private var playerCount: Int = 16

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var activities: [SessionActivity] = []
    @State private var editingActivity: SessionActivity?

    private let categories = ["Defending", "Attacking", "Attacking Transition", "Defensive Transition"]

    var body: some View {
        VStack(spacing: 0) {
            progressHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    stepIntro

                    Group {
                        switch step {
                        case .objective: objectiveStep
                        case .subObjective: subObjectiveStep
                        case .activities: activitiesStep
                        case .review: reviewStep
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

            Divider()

            footerBar
        }
        .sheet(item: $editingActivity) { activity in
            ActivityEditSheet(activity: activity) { updated in
                if let idx = activities.firstIndex(where: { $0.id == updated.id }) {
                    activities[idx] = updated
                }
            }
        }
    }

    // MARK: Progress header

    private var progressHeader: some View {
        HStack(spacing: 6) {
            ForEach(BuilderStep.allCases, id: \.rawValue) { s in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface)
                        .frame(height: 4)
                    Text(s.title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(s == step ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var stepIntro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STEP \(step.rawValue + 1) OF \(BuilderStep.allCases.count)")
                .font(.caption2.weight(.black))
                .tracking(1.2)
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text(step.headline)
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text(step.helper)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Step 1 — Objective

    private var objectiveStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(categories, id: \.self) { cat in
                VStack(alignment: .leading, spacing: 10) {
                    Text(cat.uppercased())
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(GameMoment.allCases.filter { $0.category == cat }) { m in
                            momentCard(m)
                        }
                    }
                }
            }
        }
    }

    private func momentCard(_ m: GameMoment) -> some View {
        let isSelected = selectedMoment == m
        return Button {
            if selectedMoment != m { selectedObjective = nil }
            selectedMoment = m
        } label: {
            VStack(spacing: 10) {
                Image(systemName: m.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.white : KickIQAICoachTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.white.opacity(0.18) : KickIQAICoachTheme.accent.opacity(0.12), in: Circle())
                Text(m.rawValue)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? Color.white : KickIQAICoachTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(12)
            .background(
                isSelected ? AnyShapeStyle(KickIQAICoachTheme.accent) : AnyShapeStyle(KickIQAICoachTheme.card),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.3) : KickIQAICoachTheme.divider.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: Step 2 — Sub-objective

    private var subObjectiveStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let moment = selectedMoment {
                HStack(spacing: 8) {
                    Image(systemName: moment.icon)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text(moment.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
            }

            ForEach(selectedMoment?.subObjectives ?? [], id: \.self) { obj in
                let isSelected = selectedObjective == obj
                Button {
                    selectedObjective = obj
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.white : KickIQAICoachTheme.textSecondary.opacity(0.5))
                        Text(obj)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isSelected ? Color.white : KickIQAICoachTheme.textPrimary)
                        Spacer()
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? AnyShapeStyle(KickIQAICoachTheme.accent) : AnyShapeStyle(KickIQAICoachTheme.card),
                        in: .rect(cornerRadius: 14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(KickIQAICoachTheme.divider.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Step 3 — Activities

    private var activitiesStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SESSION PARAMETERS")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                Picker("Duration", selection: $duration) {
                    ForEach([45, 60, 75, 90], id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Intensity")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Spacer()
                    Text("\(Int(intensity)) / 10")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                Slider(value: $intensity, in: 1...10, step: 1)
                    .tint(KickIQAICoachTheme.accent)

                Stepper("Players: \(playerCount)", value: $playerCount, in: 4...30)
                    .font(.subheadline.weight(.semibold))

                HStack {
                    Text("Age Group")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    TextField("U15-U19", text: $ageGroup)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                }
            }
            .padding(14)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))

            HStack {
                Text("DRILLS")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Spacer()
                Text("\(activities.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            if activities.isEmpty {
                Button {
                    activities = (1...4).map { i in
                        SessionActivity(order: i, title: "Activity \(i)", duration: 15, fieldSize: "", playerNumbers: "", setupDescription: "", instructions: "", phases: [], coachingPoints: [])
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Generate 4 Activities")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            ForEach(activities) { a in
                Button { editingActivity = a } label: {
                    HStack(spacing: 12) {
                        Text("\(a.order)")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                            .frame(width: 28, height: 28)
                            .background(KickIQAICoachTheme.accent.opacity(0.15), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.displayTitle)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text("\(a.duration) min")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    .padding(12)
                    .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        activities.removeAll { $0.id == a.id }
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }

            if !activities.isEmpty {
                Button {
                    let next = (activities.map(\.order).max() ?? 0) + 1
                    activities.append(SessionActivity(order: next, title: "Activity \(next)", duration: 15, fieldSize: "", playerNumbers: "", setupDescription: "", instructions: "", phases: [], coachingPoints: []))
                } label: {
                    Label("Add Activity", systemImage: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(KickIQAICoachTheme.accent.opacity(0.12), in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Step 4 — Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("NAME THIS SESSION")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                TextField("e.g. Wednesday Finishing", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                summaryRow(label: "Objective", value: selectedMoment?.rawValue ?? "—")
                summaryRow(label: "Sub-objective", value: selectedObjective ?? "—")
                summaryRow(label: "Duration", value: "\(duration) min")
                summaryRow(label: "Intensity", value: "\(Int(intensity)) / 10")
                summaryRow(label: "Players", value: "\(playerCount)")
                summaryRow(label: "Age Group", value: ageGroup)
                summaryRow(label: "Activities", value: "\(activities.count)")
            }
            .padding(14)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 10) {
                Text("NOTES (OPTIONAL)")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                TextField("Anything to remember for this session", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: Footer

    private var footerBar: some View {
        HStack(spacing: 12) {
            if step != .objective {
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        step = BuilderStep(rawValue: step.rawValue - 1) ?? .objective
                    }
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KickIQAICoachTheme.accent.opacity(0.12), in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Button {
                if step == .review {
                    save()
                } else {
                    withAnimation(.spring(response: 0.35)) {
                        step = BuilderStep(rawValue: step.rawValue + 1) ?? .review
                    }
                }
            } label: {
                Text(step == .review ? "Save Session" : "Continue")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isContinueEnabled ? KickIQAICoachTheme.accent : KickIQAICoachTheme.accent.opacity(0.3), in: .rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!isContinueEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(KickIQAICoachTheme.background)
    }

    private var isContinueEnabled: Bool {
        switch step {
        case .objective: return selectedMoment != nil
        case .subObjective: return selectedObjective != nil
        case .activities: return !activities.isEmpty
        case .review: return !title.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func save() {
        guard let moment = selectedMoment, let obj = selectedObjective else { return }
        let session = CoachSession(
            title: title,
            gameMoment: moment,
            customGameMoment: nil,
            objective: obj,
            duration: duration,
            intensity: Int(intensity),
            ageGroup: ageGroup,
            playerCount: playerCount,
            activities: activities,
            notes: notes
        )
        coachStorage.addSession(session)
        title = ""
        notes = ""
        activities = []
        selectedMoment = nil
        selectedObjective = nil
        onSaved()
    }
}

// MARK: - Block Planner

private struct BlockPlannerView: View {
    @Bindable var coachStorage: CoachStorageService
    @State private var showNew = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if coachStorage.blocks.isEmpty {
                    emptyIntroCard
                } else {
                    infoBanner
                    ForEach(coachStorage.blocks) { block in
                        NavigationLink {
                            BlockDetailView(coachStorage: coachStorage, block: block)
                        } label: {
                            blockCard(block)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNew = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showNew) {
            NewBlockSheet(coachStorage: coachStorage)
        }
    }

    private var emptyIntroCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(18)
                .background(KickIQAICoachTheme.accent.opacity(0.12), in: Circle())

            VStack(spacing: 8) {
                Text("Training Blocks")
                    .font(.title2.bold())
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text("Group 4–8 weeks of sessions into a focused training block. Blocks help you progress one theme — like finishing or pressing — over time.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                bulletRow(icon: "1.circle.fill", text: "Name your block and set a duration")
                bulletRow(icon: "2.circle.fill", text: "Assign sessions to each week")
                bulletRow(icon: "3.circle.fill", text: "Share as PDF, link, or QR code")
            }
            .padding(.horizontal, 4)

            Button {
                showNew = true
            } label: {
                Label("Create Block", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 20))
        .padding(.top, 20)
    }

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var infoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text("Blocks group weeks of sessions around a single focus.")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Spacer()
        }
        .padding(12)
        .background(KickIQAICoachTheme.accent.opacity(0.08), in: .rect(cornerRadius: 12))
    }

    private func blockCard(_ block: TrainingBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(block.title)
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            HStack {
                Label("\(block.weeks) weeks", systemImage: "calendar")
                Label(block.startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }
}

private struct NewBlockSheet: View {
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var weeks = 6
    @State private var startDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Block Title", text: $title)
                Stepper("Weeks: \(weeks)", value: $weeks, in: 4...8)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            }
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        let block = TrainingBlock(title: title, weeks: weeks, sessions: [], startDate: startDate)
                        coachStorage.addBlock(block)
                        dismiss()
                    }
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

private struct BlockDetailView: View {
    @Bindable var coachStorage: CoachStorageService
    @State var block: TrainingBlock
    @State private var pickingSlot: (week: Int, slot: Int)?

    private let sessionsPerWeek = 3

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<block.weeks, id: \.self) { week in
                    weekRow(week: week)
                }
            }
            .padding(16)
        }
        .navigationTitle(block.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { pickingSlot.map { SlotID(week: $0.week, slot: $0.slot) } },
            set: { newVal in pickingSlot = newVal.map { ($0.week, $0.slot) } }
        )) { slot in
            SessionPickerSheet(coachStorage: coachStorage) { session in
                let idx = slot.week * sessionsPerWeek + slot.slot
                while block.sessions.count <= idx {
                    block.sessions.append(session)
                }
                if block.sessions.count > idx {
                    block.sessions[idx] = session
                }
                coachStorage.updateBlock(block)
                pickingSlot = nil
            }
        }
    }

    private func weekRow(week: Int) -> some View {
        let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: week, to: block.startDate) ?? block.startDate
        let isPast = weekStart < Date()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Week \(week + 1)")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Spacer()
                Text(weekStart.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
            ForEach(0..<sessionsPerWeek, id: \.self) { slot in
                slotRow(week: week, slot: slot, isPast: isPast)
            }
        }
        .padding(14)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }

    private func slotRow(week: Int, slot: Int, isPast: Bool) -> some View {
        let idx = week * sessionsPerWeek + slot
        let session = idx < block.sessions.count ? block.sessions[idx] : nil
        return Button {
            pickingSlot = (week, slot)
        } label: {
            HStack {
                if let s = session {
                    Image(systemName: isPast ? "checkmark.circle.fill" : s.gameMoment.icon)
                        .foregroundStyle(isPast ? Color.green : KickIQAICoachTheme.accent)
                    Text(s.displayTitle)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("Add Session")
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                Spacer()
            }
            .font(.subheadline)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private struct SlotID: Identifiable {
    let week: Int
    let slot: Int
    var id: String { "\(week)-\(slot)" }
}

private struct SessionPickerSheet: View {
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss
    var onPick: (CoachSession) -> Void

    var body: some View {
        NavigationStack {
            List(coachStorage.sessions) { session in
                Button {
                    onPick(session)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: session.gameMoment.icon)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                        VStack(alignment: .leading) {
                            Text(session.displayTitle)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text(session.displayGameMoment)
                                .font(.caption)
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Pick Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - Evaluations

private struct EvaluationsView: View {
    @Bindable var coachStorage: CoachStorageService
    @State private var showAdd = false
    @State private var showEditCriteria = false
    @State private var editing: PlayerEvaluation?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                criteriaBar
                ForEach(coachStorage.evaluations.sorted(by: { $0.evaluationDate > $1.evaluationDate })) { e in
                    Button {
                        editing = e
                    } label: {
                        evaluationCard(e)
                    }
                    .buttonStyle(.plain)
                }

                if coachStorage.evaluations.isEmpty {
                    ContentUnavailableView("No Evaluations", systemImage: "person.text.rectangle", description: Text("Tap + to add one."))
                        .padding(.top, 40)
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus").foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEvaluationSheet(coachStorage: coachStorage, existing: nil)
        }
        .sheet(item: $editing) { e in
            AddEvaluationSheet(coachStorage: coachStorage, existing: e)
        }
        .sheet(isPresented: $showEditCriteria) {
            EditCriteriaSheet(coachStorage: coachStorage)
        }
    }

    private var criteriaBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "slider.horizontal.3")
                .foregroundStyle(KickIQAICoachTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Criteria")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Text(coachStorage.evaluationCriteria.map(\.name).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                showEditCriteria = true
            } label: {
                Text("Edit")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 12))
    }

    private func evaluationCard(_ e: PlayerEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.playerName)
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(e.evaluationDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                Spacer()
                Text(String(format: "%.1f", e.averageScore))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(KickIQAICoachTheme.accent, in: Capsule())
            }
            ForEach(coachStorage.evaluationCriteria) { c in
                bar(c.name, value: e.score(for: c.id))
            }
        }
        .padding(14)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }

    private func bar(_ label: String, value: Int) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(KickIQAICoachTheme.surface)
                    Capsule().fill(KickIQAICoachTheme.accent)
                        .frame(width: geo.size.width * CGFloat(value) / 10.0)
                }
            }
            .frame(height: 6)
            Text("\(value)")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .frame(width: 20)
        }
    }
}

private struct AddEvaluationSheet: View {
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss
    var existing: PlayerEvaluation?

    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var scores: [String: Double] = [:]
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Player Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Ratings") {
                    ForEach(coachStorage.evaluationCriteria) { c in
                        ratingSlider(c.name, value: Binding(
                            get: { scores[c.id] ?? 5 },
                            set: { scores[c.id] = $0 }
                        ))
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(existing == nil ? "New Evaluation" : "Edit Evaluation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let e = existing {
                    name = e.playerName
                    date = e.evaluationDate
                    notes = e.notes
                    for c in coachStorage.evaluationCriteria {
                        scores[c.id] = Double(e.score(for: c.id))
                    }
                } else {
                    for c in coachStorage.evaluationCriteria where scores[c.id] == nil {
                        scores[c.id] = 5
                    }
                }
            }
        }
    }

    private func ratingSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .fontWeight(.semibold)
            }
            Slider(value: value, in: 1...10, step: 1)
                .tint(KickIQAICoachTheme.accent)
        }
    }

    private func save() {
        var eval = existing ?? PlayerEvaluation(playerName: "", evaluationDate: Date(), technical: 5, tactical: 5, physical: 5, character: 5, notes: "")
        eval.playerName = name
        eval.evaluationDate = date
        eval.notes = notes
        for c in coachStorage.evaluationCriteria {
            let v = Int(scores[c.id] ?? 5)
            eval.setScore(v, for: c.id)
        }
        if existing == nil {
            coachStorage.addEvaluation(eval)
        } else {
            coachStorage.updateEvaluation(eval)
        }
        dismiss()
    }
}

private struct EditCriteriaSheet: View {
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss
    @State private var working: [EvaluationCriterion] = []
    @State private var newName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Rename, reorder, add or remove evaluation criteria. Changes apply to all future evaluations.")
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }

                Section("Criteria") {
                    ForEach($working) { $c in
                        TextField("Name", text: $c.name)
                    }
                    .onDelete { working.remove(atOffsets: $0) }
                    .onMove { working.move(fromOffsets: $0, toOffset: $1) }
                }

                Section("Add Criterion") {
                    HStack {
                        TextField("e.g. Leadership, Speed", text: $newName)
                        Button {
                            addCriterion()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        working = EvaluationCriterion.defaults
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Edit Criteria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let cleaned = working.map { EvaluationCriterion(id: $0.id, name: $0.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Criterion" : $0.name) }
                        coachStorage.updateCriteria(cleaned)
                        dismiss()
                    }
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .fontWeight(.semibold)
                    .disabled(working.isEmpty)
                }
            }
            .onAppear {
                if working.isEmpty { working = coachStorage.evaluationCriteria }
            }
        }
    }

    private func addCriterion() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let id = trimmed.lowercased().replacingOccurrences(of: " ", with: "_") + "_" + String(UUID().uuidString.prefix(4))
        working.append(EvaluationCriterion(id: id, name: trimmed))
        newName = ""
    }
}
