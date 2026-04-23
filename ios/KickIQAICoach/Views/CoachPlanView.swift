import SwiftUI

private enum CoachTab: String, CaseIterable, Identifiable {
    case builder = "Builder"
    case blocks = "Blocks"
    case library = "Library"
    case evaluations = "Evals"
    var id: String { rawValue }
}

struct CoachPlanView: View {
    @State private var coachStorage = CoachStorageService()
    @State private var selectedTab: CoachTab = .library

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(CoachTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Group {
                    switch selectedTab {
                    case .builder:
                        SessionBuilderView(coachStorage: coachStorage, onSaved: { selectedTab = .library })
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
            .navigationTitle("Coach Plan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Session Library

private struct SessionLibraryView: View {
    @Bindable var coachStorage: CoachStorageService
    var onNew: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(coachStorage.sessionsByMoment(), id: \.moment) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: group.moment.icon)
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            Text(group.moment.rawValue)
                                .font(.headline)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 10) {
                            ForEach(group.sessions) { session in
                                NavigationLink {
                                    SessionDetailView(coachStorage: coachStorage, session: session)
                                } label: {
                                    SessionCardView(session: session)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
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
    }
}

private struct SessionCardView: View {
    let session: CoachSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.gameMoment.icon)
                .font(.title3)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 40, height: 40)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(session.displayTitle)
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text(session.displayGameMoment)
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                HStack(spacing: 10) {
                    Label("\(session.duration)m", systemImage: "clock")
                    Label("\(session.intensity)", systemImage: "flame.fill")
                    Label("\(session.activities.count)", systemImage: "square.stack.3d.up")
                }
                .font(.caption2)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .padding(14)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }
}

// MARK: - Session Detail

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

// MARK: - Session Builder

private struct SessionBuilderView: View {
    @Bindable var coachStorage: CoachStorageService
    var onSaved: () -> Void

    @State private var selectedMoment: GameMoment?
    @State private var customMomentName: [GameMoment: String] = [:]
    @State private var renamingMoment: GameMoment?
    @State private var renameDraft = ""

    @State private var selectedObjective: String?
    @State private var customObjectives: [String: String] = [:]
    @State private var renamingObjective: String?

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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                step1
                if selectedMoment != nil { step2 }
                if selectedObjective != nil { step3 }
                if selectedObjective != nil { step4 }
                if selectedObjective != nil { step5 }
            }
            .padding(16)
        }
        .sheet(item: $editingActivity) { activity in
            ActivityEditSheet(activity: activity) { updated in
                if let idx = activities.firstIndex(where: { $0.id == updated.id }) {
                    activities[idx] = updated
                }
            }
        }
        .alert("Rename", isPresented: Binding(get: { renamingMoment != nil }, set: { if !$0 { renamingMoment = nil } })) {
            TextField("Name", text: $renameDraft)
            Button("Save") {
                if let m = renamingMoment { customMomentName[m] = renameDraft }
                renamingMoment = nil
            }
            Button("Cancel", role: .cancel) { renamingMoment = nil }
        }
        .alert("Rename Objective", isPresented: Binding(get: { renamingObjective != nil }, set: { if !$0 { renamingObjective = nil } })) {
            TextField("Name", text: $renameDraft)
            Button("Save") {
                if let o = renamingObjective { customObjectives[o] = renameDraft }
                renamingObjective = nil
            }
            Button("Cancel", role: .cancel) { renamingObjective = nil }
        }
    }

    private var step1: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(number: 1, title: "Game Moment")
            ForEach(categories, id: \.self) { cat in
                Text(cat)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(GameMoment.allCases.filter { $0.category == cat }) { m in
                        momentCard(m)
                    }
                }
            }
        }
    }

    private func momentCard(_ m: GameMoment) -> some View {
        let name = customMomentName[m] ?? m.rawValue
        let isSelected = selectedMoment == m
        return Button {
            selectedMoment = m
            selectedObjective = nil
        } label: {
            VStack(spacing: 8) {
                Image(systemName: m.icon)
                    .font(.title2)
                Text(name)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isSelected ? Color.white : KickIQAICoachTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? AnyShapeStyle(KickIQAICoachTheme.accent) : AnyShapeStyle(KickIQAICoachTheme.card),
                in: .rect(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                renameDraft = name
                renamingMoment = m
            } label: { Label("Rename", systemImage: "pencil") }
        }
    }

    private var step2: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepHeader(number: 2, title: "Sub-Objective")
            ForEach(selectedMoment?.subObjectives ?? [], id: \.self) { obj in
                let name = customObjectives[obj] ?? obj
                let isSelected = selectedObjective == obj
                Button {
                    selectedObjective = obj
                } label: {
                    HStack {
                        Text(name)
                            .foregroundStyle(isSelected ? Color.white : KickIQAICoachTheme.textPrimary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark").foregroundStyle(.white)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? AnyShapeStyle(KickIQAICoachTheme.accent) : AnyShapeStyle(KickIQAICoachTheme.card),
                        in: .rect(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        renameDraft = name
                        renamingObjective = obj
                    } label: { Label("Rename", systemImage: "pencil") }
                }
            }
        }
    }

    private var step3: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(number: 3, title: "Session Parameters")
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration").font(.caption).foregroundStyle(KickIQAICoachTheme.textSecondary)
                Picker("Duration", selection: $duration) {
                    ForEach([45, 60, 75, 90], id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Intensity: \(Int(intensity))").font(.caption).foregroundStyle(KickIQAICoachTheme.textSecondary)
                Slider(value: $intensity, in: 1...10, step: 1)
                    .tint(KickIQAICoachTheme.accent)

                TextField("Age Group", text: $ageGroup)
                    .textFieldStyle(.roundedBorder)
                Stepper("Players: \(playerCount)", value: $playerCount, in: 4...30)
            }
            .padding(14)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
        }
    }

    private var step4: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepHeader(number: 4, title: "Activities")
            if activities.isEmpty {
                Button {
                    activities = (1...4).map { i in
                        SessionActivity(order: i, title: "Activity \(i)", duration: 15, fieldSize: "", playerNumbers: "", setupDescription: "", instructions: "", phases: [], coachingPoints: [])
                    }
                } label: {
                    Label("Generate 4 Activities", systemImage: "wand.and.stars")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 12))
                }
            }

            ForEach(activities) { a in
                Button { editingActivity = a } label: {
                    HStack {
                        Text("\(a.order). \(a.displayTitle)")
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Spacer()
                        Text("\(a.duration)m").foregroundStyle(KickIQAICoachTheme.accent)
                        Image(systemName: "chevron.right").foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                    .padding(14)
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
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
    }

    private var step5: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepHeader(number: 5, title: "Save")
            TextField("Session Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)

            Button {
                save()
            } label: {
                Text("Save Session")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 12))
            }
            .disabled(title.isEmpty || selectedMoment == nil || selectedObjective == nil)
            .opacity((title.isEmpty || selectedMoment == nil || selectedObjective == nil) ? 0.5 : 1)
        }
    }

    private func stepHeader(number: Int, title: String) -> some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(KickIQAICoachTheme.accent, in: Circle())
            Text(title)
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
    }

    private func save() {
        guard let moment = selectedMoment, let obj = selectedObjective else { return }
        let session = CoachSession(
            title: title,
            gameMoment: moment,
            customGameMoment: customMomentName[moment],
            objective: customObjectives[obj] ?? obj,
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
                ForEach(coachStorage.blocks) { block in
                    NavigationLink {
                        BlockDetailView(coachStorage: coachStorage, block: block)
                    } label: {
                        blockCard(block)
                    }
                    .buttonStyle(.plain)
                }

                if coachStorage.blocks.isEmpty {
                    ContentUnavailableView("No Training Blocks", systemImage: "calendar", description: Text("Tap + to create a new block."))
                        .padding(.top, 40)
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
    @State private var editing: PlayerEvaluation?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
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
            bar("Technical", value: e.technical)
            bar("Tactical", value: e.tactical)
            bar("Physical", value: e.physical)
            bar("Character", value: e.character)
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
    @State private var technical: Double = 5
    @State private var tactical: Double = 5
    @State private var physical: Double = 5
    @State private var character: Double = 5
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Player Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Ratings") {
                    ratingSlider("Technical", value: $technical)
                    ratingSlider("Tactical", value: $tactical)
                    ratingSlider("Physical", value: $physical)
                    ratingSlider("Character", value: $character)
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
                    technical = Double(e.technical)
                    tactical = Double(e.tactical)
                    physical = Double(e.physical)
                    character = Double(e.character)
                    notes = e.notes
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
        eval.technical = Int(technical)
        eval.tactical = Int(tactical)
        eval.physical = Int(physical)
        eval.character = Int(character)
        eval.notes = notes

        if existing == nil {
            coachStorage.addEvaluation(eval)
        } else {
            coachStorage.updateEvaluation(eval)
        }
        dismiss()
    }
}
