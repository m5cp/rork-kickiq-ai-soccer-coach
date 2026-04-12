import SwiftUI

struct ConditioningCategoryDetailView: View {
    let focus: ConditioningFocus
    let drills: [Drill]
    let storage: StorageService
    @State private var drillsService = DrillsService()
    @State private var selectedDrill: Drill?
    @State private var completedTrigger = 0
    @State private var showQRSheet = false
    @State private var qrDrill: Drill?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                categoryHeader
                drillsList
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(focus.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDrill) { drill in
            DrillDetailSheet(drill: drill, storage: storage, drillsService: drillsService, completedTrigger: $completedTrigger)
        }
        .sheet(isPresented: $showQRSheet) {
            if let drill = qrDrill {
                QRDrillShareSheet(drill: drill)
            }
        }
        .onAppear {
            if let profile = storage.profile {
                drillsService.loadDrills(for: profile.position, weakness: profile.weakness, skillLevel: profile.skillLevel)
            }
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: completedTrigger)
    }

    private var categoryHeader: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: focus.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(drills.count) exercise\(drills.count == 1 ? "" : "s") available")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                let completed = drills.filter { storage.completedDrillIDs.contains($0.id) }.count
                if completed > 0 {
                    Text("\(completed) completed")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                } else {
                    Text("Start your first exercise")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var drillsList: some View {
        LazyVStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(Array(drills.enumerated()), id: \.element.id) { index, drill in
                Button {
                    selectedDrill = drill
                } label: {
                    drillRow(drill)
                }
                .contextMenu {
                    Button {
                        qrDrill = drill
                        showQRSheet = true
                    } label: {
                        Label("Share QR Code", systemImage: "qrcode")
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(response: 0.35).delay(Double(index) * 0.05), value: appeared)
            }
        }
    }

    private func drillRow(_ drill: Drill) -> some View {
        let isCompleted = storage.completedDrillIDs.contains(drill.id)

        return HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.15) : KickIQAICoachTheme.surface)
                    .frame(width: 40, height: 40)
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(isCompleted ? .green : KickIQAICoachTheme.textSecondary.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
                Text(drill.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Label(drill.duration, systemImage: "clock")
                    Text("·")
                    Text(drill.difficulty.rawValue)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.3))
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }
}
