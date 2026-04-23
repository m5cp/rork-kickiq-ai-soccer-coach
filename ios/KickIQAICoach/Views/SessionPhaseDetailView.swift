import SwiftUI

struct SessionPhaseDetailView: View {
    @Binding var session: CoachSession
    var onUpdate: (CoachSession) -> Void
    var onShare: (() -> Void)? = nil

    @State private var editingTitle = false
    @State private var editingMoment = false
    @State private var titleDraft = ""
    @State private var momentDraft = ""
    @State private var editingActivity: SessionActivity?
    @State private var runningActivity: SessionActivity?
    @State private var runningSession = false

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
                        Text("Run Session").fontWeight(.semibold)
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

                phaseBlockList

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
        .toolbar {
            if onShare != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onShare?()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                }
            }
        }
        .sheet(item: $editingActivity) { activity in
            SessionActivityEditSheet(activity: activity) { updated in
                if let idx = session.activities.firstIndex(where: { $0.id == updated.id }) {
                    session.activities[idx] = updated
                    onUpdate(session)
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

    private var phaseBlockList: some View {
        let grouped = Dictionary(grouping: session.activities) { $0.resolvedPhase }
        return VStack(spacing: 12) {
            ForEach(TrainingPhase.allCases) { phase in
                if let acts = grouped[phase], !acts.isEmpty {
                    phaseBlock(phase, activities: acts.sorted { $0.order < $1.order })
                }
            }
        }
    }

    private func phaseBlock(_ phase: TrainingPhase, activities: [SessionActivity]) -> some View {
        let total = activities.reduce(0) { $0 + $1.duration }
        return HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(KickIQAICoachTheme.accent)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: phase.icon)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text(phase.rawValue.uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        .tracking(1)
                    Spacer()
                    Text("\(total) MIN")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                ForEach(activities) { a in
                    activityRow(a)
                }
            }
            .padding(12)
        }
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 12))
    }

    private func activityRow(_ activity: SessionActivity) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button { editingActivity = activity } label: {
                VStack(alignment: .leading, spacing: 4) {
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
                    if !activity.fieldSize.isEmpty || !activity.playerNumbers.isEmpty {
                        Text([activity.fieldSize, activity.playerNumbers].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Button {
                runningActivity = activity
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KickIQAICoachTheme.surface, in: .rect(cornerRadius: 10))
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(KickIQAICoachTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func commitTitle() {
        session.customTitle = titleDraft.isEmpty ? nil : titleDraft
        onUpdate(session)
        editingTitle = false
    }

    private func commitMoment() {
        session.customGameMoment = momentDraft.isEmpty ? nil : momentDraft
        onUpdate(session)
        editingMoment = false
    }
}

struct SessionActivityEditSheet: View {
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

                Section("Training Phase") {
                    Picker("Phase", selection: Binding(
                        get: { activity.trainingPhase ?? activity.resolvedPhase },
                        set: { activity.trainingPhase = $0 }
                    )) {
                        ForEach(TrainingPhase.allCases) { phase in
                            Label(phase.rawValue, systemImage: phase.icon).tag(phase)
                        }
                    }
                    .pickerStyle(.menu)
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
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
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
