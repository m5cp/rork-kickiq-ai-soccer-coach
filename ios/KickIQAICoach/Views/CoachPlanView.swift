import SwiftUI

private enum CoachPlanSegment: String, CaseIterable, Identifiable {
    case builder = "Builder"
    case block = "Block"
    case library = "Library"
    case evaluations = "Evaluations"

    var id: String { rawValue }
}

struct CoachPlanView: View {
    @State private var coachStorage = CoachStorageService()
    @State private var segment: CoachPlanSegment = .library

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    ForEach(CoachPlanSegment.allCases) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm)

                Group {
                    switch segment {
                    case .builder:
                        SessionBuilderView(coachStorage: coachStorage) {
                            segment = .library
                        }
                    case .block:
                        BlockPlannerView(coachStorage: coachStorage)
                    case .library:
                        SessionLibraryView(coachStorage: coachStorage) {
                            segment = .builder
                        }
                    case .evaluations:
                        EvaluationsView(coachStorage: coachStorage)
                    }
                }
            }
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(KickIQAICoachTheme.accent)
    }
}

// MARK: - Session Library

private struct SessionLibraryView: View {
    @Bindable var coachStorage: CoachStorageService
    var onNew: () -> Void

    @State private var selectedSession: CoachSession?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                ForEach(coachStorage.sessionsByMoment(), id: \.moment) { group in
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                            Image(systemName: group.moment.icon)
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            Text(group.moment.rawValue)
                                .font(.headline)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Spacer()
                            Text("\(group.sessions.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        }
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)

                        ForEach(group.sessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                SessionCard(session: session)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    selectedSession = session
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button {
                                    coachStorage.duplicateSession(session)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                Button(role: .destructive) {
                                    coachStorage.deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                        }
                    }
                }

                if coachStorage.sessions.isEmpty {
                    emptyState
                }
            }
            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
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
        .sheet(item: $selectedSession) { session in
            SessionDetailView(sessionID: session.id, coachStorage: coachStorage)
        }
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Image(systemName: "clipboard")
                .font(.system(size: 42))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
            Text("No sessions yet")
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text("Tap + to build your first session")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct SessionCard: View {
    let session: CoachSession

    var body: some View {
        HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                Image(systemName: session.gameMoment.icon)
                    .font(.title3)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(2)
                Text(session.displayGameMoment)
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Label("\(session.duration)m", systemImage: "clock")
                    Label("\(session.activities.count)", systemImage: "list.bullet")
                    HStack(spacing: 1) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(i < (session.intensity + 1) / 2 ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary.opacity(0.3))
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Session Detail

private struct SessionDetailView: View {
    let sessionID: UUID
    @Bindable var coachStorage: CoachStorageService

    @Environment(\.dismiss) private var dismiss
    @State private var renamingTitle: Bool = false
    @State private var renamingMoment: Bool = false
    @State private var titleDraft: String = ""
    @State private var momentDraft: String = ""
    @State private var editingActivity: SessionActivity?

    private var sessionBinding: Binding<CoachSession>? {
        guard let index = coachStorage.sessions.firstIndex(where: { $0.id == sessionID }) else { return nil }
        return Binding(
            get: { coachStorage.sessions[index] },
            set: { newValue in
                coachStorage.sessions[index] = newValue
                coachStorage.save()
            }
        )
    }

    var body: some View {
        NavigationStack {
            if let binding = sessionBinding {
                content(binding: binding)
            } else {
                Text("Session not found")
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }
        }
        .tint(KickIQAICoachTheme.accent)
    }

    @ViewBuilder
    private func content(binding: Binding<CoachSession>) -> some View {
        let session = binding.wrappedValue
        ScrollView {
            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
                // Title
                HStack {
                    if renamingTitle {
                        TextField("Title", text: $titleDraft)
                            .font(.title2.weight(.bold))
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                binding.wrappedValue.customTitle = titleDraft.isEmpty ? nil : titleDraft
                                renamingTitle = false
                            }
                    } else {
                        Text(session.displayTitle)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Button {
                            titleDraft = session.displayTitle
                            renamingTitle = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                    Spacer()
                }

                // Moment badge
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: session.gameMoment.icon)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    if renamingMoment {
                        TextField("Moment", text: $momentDraft)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                binding.wrappedValue.customGameMoment = momentDraft.isEmpty ? nil : momentDraft
                                renamingMoment = false
                            }
                    } else {
                        Text(session.displayGameMoment)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                        Button {
                            momentDraft = session.displayGameMoment
                            renamingMoment = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())

                // Info rows
                VStack(spacing: 0) {
                    infoRow(icon: "target", label: "Objective", value: session.objective)
                    Divider().overlay(KickIQAICoachTheme.divider)
                    infoRow(icon: "clock", label: "Duration", value: "\(session.duration) min")
                    Divider().overlay(KickIQAICoachTheme.divider)
                    infoRow(icon: "flame.fill", label: "Intensity", value: "\(session.intensity) / 10")
                    Divider().overlay(KickIQAICoachTheme.divider)
                    infoRow(icon: "person.2.fill", label: "Age Group", value: session.ageGroup)
                    Divider().overlay(KickIQAICoachTheme.divider)
                    infoRow(icon: "person.3.fill", label: "Players", value: "\(session.playerCount)")
                }
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))

                // Activities
                Text("Activities")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .padding(.top, KickIQAICoachTheme.Spacing.sm)

                ForEach(session.activities) { activity in
                    Button {
                        editingActivity = activity
                    } label: {
                        ActivityRow(activity: activity)
                    }
                    .buttonStyle(.plain)
                }

                // Notes
                if !session.notes.isEmpty {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .padding(.top, KickIQAICoachTheme.Spacing.sm)
                    Text(session.notes)
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .padding(KickIQAICoachTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
        }
        .background(KickIQAICoachTheme.background.ignoresSafeArea())
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
        }
        .sheet(item: $editingActivity) { activity in
            ActivityEditSheet(activity: activity) { updated in
                if let idx = binding.wrappedValue.activities.firstIndex(where: { $0.id == updated.id }) {
                    binding.wrappedValue.activities[idx] = updated
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(KickIQAICoachTheme.Spacing.md)
    }
}

private struct ActivityRow: View {
    let activity: SessionActivity

    var body: some View {
        HStack(alignment: .top, spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle().fill(KickIQAICoachTheme.accent.opacity(0.15))
                Text("\(activity.order)")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Label("\(activity.duration)m", systemImage: "clock")
                    Text("•")
                    Text(activity.fieldSize)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Text(activity.playerNumbers)
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.8))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
    }
}

// MARK: - Activity Edit Sheet

private struct ActivityEditSheet: View {
    @State var activity: SessionActivity
    var onSave: (SessionActivity) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var renamingTitle: Bool = false
    @State private var titleDraft: String = ""
    @State private var newPhase: String = ""
    @State private var newPoint: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if renamingTitle {
                            TextField("Title", text: $titleDraft)
                                .onSubmit {
                                    activity.customTitle = titleDraft.isEmpty ? nil : titleDraft
                                    renamingTitle = false
                                }
                        } else {
                            Text(activity.displayTitle)
                                .fontWeight(.semibold)
                            Spacer()
                            Button {
                                titleDraft = activity.displayTitle
                                renamingTitle = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(KickIQAICoachTheme.accent)
                            }
                        }
                    }
                }

                Section("Setup") {
                    Stepper("Duration: \(activity.duration) min", value: $activity.duration, in: 5...60, step: 5)
                    TextField("Field size", text: $activity.fieldSize)
                    TextField("Player numbers", text: $activity.playerNumbers)
                }

                Section("Description") {
                    TextField("Setup", text: $activity.setupDescription, axis: .vertical)
                        .lineLimit(2...6)
                    TextField("Instructions", text: $activity.instructions, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("Phases") {
                    ForEach(activity.phases.indices, id: \.self) { i in
                        TextField("Phase", text: $activity.phases[i], axis: .vertical)
                            .lineLimit(1...4)
                    }
                    .onDelete { activity.phases.remove(atOffsets: $0) }
                    HStack {
                        TextField("Add phase", text: $newPhase)
                        Button {
                            guard !newPhase.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            activity.phases.append(newPhase)
                            newPhase = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                }

                Section("Coaching Points") {
                    ForEach(activity.coachingPoints.indices, id: \.self) { i in
                        TextField("Point", text: $activity.coachingPoints[i], axis: .vertical)
                            .lineLimit(1...4)
                    }
                    .onDelete { activity.coachingPoints.remove(atOffsets: $0) }
                    HStack {
                        TextField("Add point", text: $newPoint)
                        Button {
                            guard !newPoint.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            activity.coachingPoints.append(newPoint)
                            newPoint = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                }
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
                    .fontWeight(.semibold)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .tint(KickIQAICoachTheme.accent)
    }
}

// MARK: - Session Builder

private struct SessionBuilderView: View {
    @Bindable var coachStorage: CoachStorageService
    var onSaved: () -> Void

    @State private var step: Int = 1
    @State private var selectedMoment: GameMoment?
    @State private var customMomentName: [GameMoment: String] = [:]
    @State private var selectedObjective: String = ""
    @State private var customObjectives: [String: String] = [:]
    @State private var duration: Int = 75
    @State private var intensity: Double = 7
    @State private var ageGroup: String = "U15-U19"
    @State private var playerCount: Int = 16
    @State private var activities: [SessionActivity] = []
    @State private var sessionTitle: String = ""
    @State private var notes: String = ""
    @State private var editingActivity: SessionActivity?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                stepHeader
                switch step {
                case 1: step1Moment
                case 2: step2Objective
                case 3: step3Parameters
                case 4: step4Activities
                default: step5Review
                }
                navButtons
            }
            .padding(KickIQAICoachTheme.Spacing.md)
        }
        .sheet(item: $editingActivity) { act in
            ActivityEditSheet(activity: act) { updated in
                if let idx = activities.firstIndex(where: { $0.id == updated.id }) {
                    activities[idx] = updated
                }
            }
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
            Text("Step \(step) of 5")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text(stepTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
    }

    private var stepTitle: String {
        switch step {
        case 1: return "Pick a game moment"
        case 2: return "Select an objective"
        case 3: return "Set parameters"
        case 4: return "Build activities"
        default: return "Review and save"
        }
    }

    private var step1Moment: some View {
        let categories = ["Defending", "Attacking", "Attacking Transition", "Defensive Transition"]
        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
            ForEach(categories, id: \.self) { cat in
                let moments = GameMoment.allCases.filter { $0.category == cat }
                if !moments.isEmpty {
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        Text(cat)
                            .font(.headline)
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: KickIQAICoachTheme.Spacing.sm) {
                            ForEach(moments) { moment in
                                MomentCard(
                                    moment: moment,
                                    name: customMomentName[moment] ?? moment.rawValue,
                                    selected: selectedMoment == moment
                                ) {
                                    selectedMoment = moment
                                } onRename: { newName in
                                    customMomentName[moment] = newName
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var step2Objective: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            if let m = selectedMoment {
                ForEach(m.subObjectives, id: \.self) { obj in
                    let displayName = customObjectives[obj] ?? obj
                    Button {
                        selectedObjective = obj
                    } label: {
                        HStack {
                            Text(displayName)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Spacer()
                            if selectedObjective == obj {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(KickIQAICoachTheme.accent)
                            }
                        }
                        .padding(KickIQAICoachTheme.Spacing.md)
                        .background(
                            selectedObjective == obj
                                ? KickIQAICoachTheme.accent.opacity(0.15)
                                : KickIQAICoachTheme.card,
                            in: .rect(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Rename") {
                            renameObjective(obj)
                        }
                    }
                }
            }
        }
    }

    private func renameObjective(_ key: String) {
        let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = customObjectives[key] ?? key }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let t = alert.textFields?.first?.text, !t.isEmpty {
                customObjectives[key] = t
            }
        })
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            root.present(alert, animated: true)
        }
    }

    private var step3Parameters: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            Picker("Duration", selection: $duration) {
                ForEach([45, 60, 75, 90], id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text("Intensity: \(Int(intensity))/10")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Slider(value: $intensity, in: 1...10, step: 1)
                    .tint(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Age Group")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                TextField("e.g. U15-U19", text: $ageGroup)
                    .textFieldStyle(.roundedBorder)
            }

            Stepper("Players: \(playerCount)", value: $playerCount, in: 4...32)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
    }

    private var step4Activities: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(activities) { activity in
                Button {
                    editingActivity = activity
                } label: {
                    ActivityRow(activity: activity)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        activities.removeAll { $0.id == activity.id }
                        renumber()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button {
                let next = SessionActivity(
                    order: activities.count + 1,
                    title: "New Activity",
                    duration: 15,
                    fieldSize: "",
                    playerNumbers: "",
                    setupDescription: "",
                    instructions: "",
                    phases: [],
                    coachingPoints: []
                )
                activities.append(next)
            } label: {
                Label("Add activity", systemImage: "plus.circle.fill")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .padding(KickIQAICoachTheme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
            }
        }
        .onAppear {
            if activities.isEmpty {
                activities = (1...4).map { order in
                    SessionActivity(
                        order: order,
                        title: activityPreset(order),
                        duration: order == 4 ? 25 : (order == 1 ? 15 : 20),
                        fieldSize: "",
                        playerNumbers: "",
                        setupDescription: "",
                        instructions: "",
                        phases: [],
                        coachingPoints: []
                    )
                }
            }
        }
    }

    private func activityPreset(_ order: Int) -> String {
        switch order {
        case 1: return "Warm-Up"
        case 2: return "Technical"
        case 3: return "Tactical"
        default: return "Scrimmage"
        }
    }

    private func renumber() {
        for i in activities.indices {
            activities[i].order = i + 1
        }
    }

    private var step5Review: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Session title")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                TextField("Title", text: $sessionTitle)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                saveSession()
            } label: {
                Text("Save to Library")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: 14))
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.5)
        }
    }

    private var canSave: Bool {
        selectedMoment != nil && !sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveSession() {
        guard let m = selectedMoment else { return }
        let session = CoachSession(
            title: sessionTitle,
            customTitle: nil,
            gameMoment: m,
            customGameMoment: customMomentName[m],
            objective: customObjectives[selectedObjective] ?? selectedObjective,
            duration: duration,
            intensity: Int(intensity),
            ageGroup: ageGroup,
            playerCount: playerCount,
            activities: activities,
            notes: notes
        )
        coachStorage.addSession(session)
        onSaved()
    }

    private var navButtons: some View {
        HStack {
            if step > 1 {
                Button("Back") { step -= 1 }
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            Spacer()
            if step < 5 {
                Button {
                    step += 1
                } label: {
                    Text("Next")
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQAICoachTheme.onAccent)
                        .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                        .background(KickIQAICoachTheme.accent, in: Capsule())
                }
                .disabled(!canAdvance)
                .opacity(canAdvance ? 1 : 0.5)
            }
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1: return selectedMoment != nil
        case 2: return !selectedObjective.isEmpty
        default: return true
        }
    }
}

private struct MomentCard: View {
    let moment: GameMoment
    let name: String
    let selected: Bool
    var onTap: () -> Void
    var onRename: (String) -> Void

    @State private var renaming: Bool = false
    @State private var draft: String = ""

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: moment.icon)
                    .font(.title2)
                    .foregroundStyle(selected ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.accent)
                if renaming {
                    TextField("Name", text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !draft.isEmpty { onRename(draft) }
                            renaming = false
                        }
                } else {
                    Text(name)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(selected ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(KickIQAICoachTheme.Spacing.sm)
            .background(
                selected ? AnyShapeStyle(KickIQAICoachTheme.accent) : AnyShapeStyle(KickIQAICoachTheme.card),
                in: .rect(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") {
                draft = name
                renaming = true
            }
        }
    }
}

// MARK: - Block Planner

private struct BlockPlannerView: View {
    @Bindable var coachStorage: CoachStorageService
    @State private var showingNewBlock: Bool = false
    @State private var selectedBlockID: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: KickIQAICoachTheme.Spacing.md) {
                ForEach(coachStorage.blocks) { block in
                    Button {
                        selectedBlockID = block.id
                    } label: {
                        BlockCard(block: block)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            coachStorage.deleteBlock(block)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button {
                    showingNewBlock = true
                } label: {
                    Label("New Training Block", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(KickIQAICoachTheme.Spacing.md)
                        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 14))
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
        }
        .sheet(isPresented: $showingNewBlock) {
            NewBlockSheet(coachStorage: coachStorage)
        }
        .sheet(item: Binding(
            get: { selectedBlockID.map { IDWrapper(id: $0) } },
            set: { selectedBlockID = $0?.id }
        )) { wrapper in
            BlockDetailView(blockID: wrapper.id, coachStorage: coachStorage)
        }
    }
}

private struct IDWrapper: Identifiable {
    let id: UUID
}

private struct BlockCard: View {
    let block: TrainingBlock

    var body: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Text("\(block.weeks) weeks · \(block.sessions.count) sessions")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Text(block.startDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
    }
}

private struct NewBlockSheet: View {
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var weeks: Int = 4
    @State private var startDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Block") {
                    TextField("Title", text: $title)
                    Stepper("Weeks: \(weeks)", value: $weeks, in: 4...8)
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        let block = TrainingBlock(title: title, weeks: weeks, sessions: [], startDate: startDate)
                        coachStorage.addBlock(block)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .disabled(title.isEmpty)
                }
            }
        }
        .tint(KickIQAICoachTheme.accent)
    }
}

private struct BlockDetailView: View {
    let blockID: UUID
    @Bindable var coachStorage: CoachStorageService
    @Environment(\.dismiss) private var dismiss
    @State private var weekMoments: [Int: GameMoment] = [:]
    @State private var pickerSlot: SessionSlotID?

    private var block: TrainingBlock? {
        coachStorage.blocks.first { $0.id == blockID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let block = block {
                    LazyVStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
                        ForEach(0..<block.weeks, id: \.self) { week in
                            weekRow(week: week, block: block)
                        }
                    }
                    .padding(KickIQAICoachTheme.Spacing.md)
                }
            }
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle(block?.title ?? "Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .sheet(item: $pickerSlot) { slot in
                SessionPickerSheet(coachStorage: coachStorage) { session in
                    addSessionToBlock(session, slot: slot)
                }
            }
        }
        .tint(KickIQAICoachTheme.accent)
    }

    private func weekRow(week: Int, block: TrainingBlock) -> some View {
        let weekStart = Calendar.current.date(byAdding: .day, value: week * 7, to: block.startDate) ?? block.startDate
        let weekSessions = block.sessions.filter { sessionWeek(for: $0, blockStart: block.startDate) == week }
        let moment = weekMoments[week] ?? weekSessions.first?.gameMoment

        return VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                Text("Week \(week + 1)")
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Spacer()
                Text(weekStart, style: .date)
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Menu {
                ForEach(GameMoment.allCases) { m in
                    Button(m.rawValue) { weekMoments[week] = m }
                }
            } label: {
                HStack {
                    Image(systemName: moment?.icon ?? "target")
                    Text(moment?.rawValue ?? "Set focus")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
            }

            ForEach(0..<3, id: \.self) { slot in
                let assigned = weekSessions.first { s in
                    slotIndex(for: s, blockStart: block.startDate) == slot
                }
                slotView(week: week, slot: slot, assigned: assigned, weekStart: weekStart)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
    }

    private func slotView(week: Int, slot: Int, assigned: CoachSession?, weekStart: Date) -> some View {
        let sessionDate = Calendar.current.date(byAdding: .day, value: slot * 2, to: weekStart) ?? weekStart
        let completed = assigned != nil && sessionDate < Date()

        return Button {
            if assigned == nil {
                pickerSlot = SessionSlotID(week: week, slot: slot)
            }
        } label: {
            HStack {
                Text("S\(slot + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .frame(width: 24, alignment: .leading)

                if let a = assigned {
                    Text(a.displayTitle)
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("Add Session")
                        .font(.subheadline)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Spacer()
                    Image(systemName: "plus.circle")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .padding(KickIQAICoachTheme.Spacing.sm)
            .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func sessionWeek(for session: CoachSession, blockStart: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: blockStart, to: session.createdAt).day ?? 0
        return max(0, days / 7)
    }

    private func slotIndex(for session: CoachSession, blockStart: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: blockStart, to: session.createdAt).day ?? 0
        return min(2, (days % 7) / 2)
    }

    private func addSessionToBlock(_ session: CoachSession, slot: SessionSlotID) {
        guard var b = block else { return }
        var copy = session
        copy.id = UUID()
        let weekStart = Calendar.current.date(byAdding: .day, value: slot.week * 7, to: b.startDate) ?? b.startDate
        copy.createdAt = Calendar.current.date(byAdding: .day, value: slot.slot * 2, to: weekStart) ?? weekStart
        b.sessions.append(copy)
        coachStorage.updateBlock(b)
    }
}

private struct SessionSlotID: Identifiable {
    let week: Int
    let slot: Int
    var id: String { "\(week)-\(slot)" }
}

private struct SessionPickerSheet: View {
    @Bindable var coachStorage: CoachStorageService
    var onPick: (CoachSession) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(coachStorage.sessions) { session in
                    Button {
                        onPick(session)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.displayTitle)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            Text(session.displayGameMoment)
                                .font(.caption)
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                }
            }
            .navigationTitle("Pick Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(KickIQAICoachTheme.accent)
    }
}

// MARK: - Evaluations

private struct EvaluationsView: View {
    @Bindable var coachStorage: CoachStorageService
    @State private var showingAdd: Bool = false
    @State private var editingID: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(coachStorage.evaluations.sorted(by: { $0.evaluationDate > $1.evaluationDate })) { eval in
                    Button {
                        editingID = eval.id
                    } label: {
                        EvaluationCard(eval: eval)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            coachStorage.deleteEvaluation(eval)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                if coachStorage.evaluations.isEmpty {
                    VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 42))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.5))
                        Text("No evaluations yet")
                            .font(.headline)
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(KickIQAICoachTheme.Spacing.md)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEvaluationSheet(coachStorage: coachStorage, existing: nil)
        }
        .sheet(item: Binding(
            get: { editingID.map { IDWrapper(id: $0) } },
            set: { editingID = $0?.id }
        )) { wrapper in
            if let existing = coachStorage.evaluations.first(where: { $0.id == wrapper.id }) {
                AddEvaluationSheet(coachStorage: coachStorage, existing: existing)
            }
        }
    }
}

private struct EvaluationCard: View {
    let eval: PlayerEvaluation

    var body: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eval.playerName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    Text(eval.evaluationDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                Spacer()
                Text(String(format: "%.1f", eval.averageScore))
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(KickIQAICoachTheme.accent, in: Capsule())
            }

            VStack(spacing: 6) {
                bar("Technical", value: eval.technical)
                bar("Tactical", value: eval.tactical)
                bar("Physical", value: eval.physical)
                bar("Character", value: eval.character)
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
    }

    private func bar(_ label: String, value: Int) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            Text(label)
                .font(.caption)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .frame(width: 72, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(KickIQAICoachTheme.divider.opacity(0.3))
                    Capsule()
                        .fill(KickIQAICoachTheme.accent)
                        .frame(width: geo.size.width * CGFloat(value) / 10.0)
                }
            }
            .frame(height: 6)
            Text("\(value)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .frame(width: 18)
        }
    }
}

private struct AddEvaluationSheet: View {
    @Bindable var coachStorage: CoachStorageService
    var existing: PlayerEvaluation?

    @Environment(\.dismiss) private var dismiss
    @State private var playerName: String = ""
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
                    TextField("Name", text: $playerName)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Ratings") {
                    ratingRow("Technical", value: $technical)
                    ratingRow("Tactical", value: $tactical)
                    ratingRow("Physical", value: $physical)
                    ratingRow("Character", value: $character)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(existing == nil ? "New Evaluation" : "Evaluation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .disabled(playerName.isEmpty)
                }
            }
            .onAppear {
                if let e = existing {
                    playerName = e.playerName
                    date = e.evaluationDate
                    technical = Double(e.technical)
                    tactical = Double(e.tactical)
                    physical = Double(e.physical)
                    character = Double(e.character)
                    notes = e.notes
                }
            }
        }
        .tint(KickIQAICoachTheme.accent)
    }

    private func ratingRow(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue))/10")
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .fontWeight(.semibold)
            }
            Slider(value: value, in: 1...10, step: 1)
                .tint(KickIQAICoachTheme.accent)
        }
    }

    private func save() {
        if var e = existing {
            e.playerName = playerName
            e.evaluationDate = date
            e.technical = Int(technical)
            e.tactical = Int(tactical)
            e.physical = Int(physical)
            e.character = Int(character)
            e.notes = notes
            coachStorage.updateEvaluation(e)
        } else {
            let e = PlayerEvaluation(
                playerName: playerName,
                evaluationDate: date,
                technical: Int(technical),
                tactical: Int(tactical),
                physical: Int(physical),
                character: Int(character),
                notes: notes
            )
            coachStorage.addEvaluation(e)
        }
        dismiss()
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
}
