import SwiftUI

struct AssignDrillSheet: View {
    let teamId: String
    let members: [TeamMemberDTO]
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var assignmentService = CoachAssignmentService.shared
    @State private var drillsService = DrillsService()
    @State private var selectedDrillName: String = ""
    @State private var note: String = ""
    @State private var assignToAll = true
    @State private var selectedMemberId: String?
    @State private var assigned = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if assigned {
                        successView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(assigned ? "Drill Assigned" : "Assign Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(assigned ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            if let profile = storage.profile {
                drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
            }
        }
    }

    private var formView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("SELECT DRILL")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)

                if drillsService.allDrills.isEmpty {
                    TextField("Drill name", text: $selectedDrillName)
                        .font(.headline)
                        .padding(KickIQTheme.Spacing.md)
                        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 6) {
                            ForEach(drillsService.allDrills.prefix(20)) { drill in
                                Button {
                                    selectedDrillName = drill.name
                                } label: {
                                    HStack {
                                        Text(drill.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(selectedDrillName == drill.name ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                                        Spacer()
                                        if selectedDrillName == drill.name {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(KickIQTheme.accent)
                                        }
                                    }
                                    .padding(KickIQTheme.Spacing.sm + 4)
                                    .background(
                                        selectedDrillName == drill.name ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.card,
                                        in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("ASSIGN TO")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)

                Button {
                    assignToAll = true
                    selectedMemberId = nil
                } label: {
                    HStack {
                        Image(systemName: "person.3.fill")
                        Text("Whole Team")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if assignToAll {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .padding(KickIQTheme.Spacing.md)
                    .background(assignToAll ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }

                let players = members.filter { TeamRole(rawValue: $0.role) == .player }
                ForEach(players) { member in
                    Button {
                        assignToAll = false
                        selectedMemberId = member.user_id
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                            Text(member.display_name ?? "Player")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            if !assignToAll && selectedMemberId == member.user_id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(KickIQTheme.accent)
                            }
                        }
                        .foregroundStyle(KickIQTheme.textPrimary)
                        .padding(KickIQTheme.Spacing.md)
                        .background(!assignToAll && selectedMemberId == member.user_id ? KickIQTheme.accent.opacity(0.12) : KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    }
                }
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                Text("NOTE (OPTIONAL)")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary)
                TextField("e.g. Focus on weak foot", text: $note)
                    .font(.subheadline)
                    .padding(KickIQTheme.Spacing.md)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
            }

            Button {
                Task {
                    let success = await assignmentService.assignDrill(
                        teamId: teamId,
                        drillId: UUID().uuidString,
                        drillName: selectedDrillName,
                        assignedTo: assignToAll ? nil : selectedMemberId,
                        note: note.isEmpty ? nil : note,
                        dueDate: nil
                    )
                    if success {
                        withAnimation(.spring(response: 0.4)) { assigned = true }
                    }
                }
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    if assignmentService.isLoading {
                        ProgressView().tint(.black)
                    }
                    Text("Assign Drill")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .disabled(selectedDrillName.isEmpty)
            .opacity(selectedDrillName.isEmpty ? 0.5 : 1)
        }
    }

    private var successView: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }

            Text("Drill Assigned!")
                .font(.title2.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text(assignToAll ? "The whole team will see this drill." : "The player will see this assignment.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
