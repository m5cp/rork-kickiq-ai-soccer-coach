import SwiftUI

struct CustomContentLibraryView: View {
    let customContentService: CustomContentService
    let storage: StorageService
    @State private var showImport = false
    @State private var selectedTab: CustomContentType = .drill
    @State private var appeared = false
    @State private var deleteTrigger = 0

    var body: some View {
        ScrollView {
            VStack(spacing: KickIQAICoachTheme.Spacing.md) {
                summaryCard
                contentTypePicker
                contentList
            }
            .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
            .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("My Content")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImport = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showImport) {
            PDFImportView(customContentService: customContentService)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: deleteTrigger)
    }

    private var summaryCard: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.lg) {
            statBlock(count: customContentService.library.drills.count, label: "Drills", icon: "figure.soccer")
            dividerLine
            statBlock(count: customContentService.library.conditioning.count, label: "Fitness", icon: "heart.circle.fill")
            dividerLine
            statBlock(count: customContentService.library.benchmarks.count, label: "Benchmarks", icon: "chart.bar.doc.horizontal.fill")
        }
        .padding(KickIQAICoachTheme.Spacing.md + 4)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private func statBlock(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
            Text("\(count)")
                .font(.title2.weight(.black))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(KickIQAICoachTheme.divider)
            .frame(width: 1, height: 50)
    }

    private var contentTypePicker: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(CustomContentType.allCases) { type in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 12))
                        Text(type.rawValue)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(selectedTab == type ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == type ? KickIQAICoachTheme.accent : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    @ViewBuilder
    private var contentList: some View {
        switch selectedTab {
        case .drill:
            if customContentService.library.drills.isEmpty {
                emptySection(type: .drill)
            } else {
                drillsList
            }
        case .conditioning:
            if customContentService.library.conditioning.isEmpty {
                emptySection(type: .conditioning)
            } else {
                conditioningList
            }
        case .benchmark:
            if customContentService.library.benchmarks.isEmpty {
                emptySection(type: .benchmark)
            } else {
                benchmarksList
            }
        }
    }

    private var drillsList: some View {
        LazyVStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(Array(customContentService.library.drills.enumerated()), id: \.element.id) { index, drill in
                customDrillRow(drill, index: index)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private func customDrillRow(_ drill: CustomDrillItem, index: Int) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "figure.soccer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(drill.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(drill.targetSkill)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("·")
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(drill.duration)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text("·")
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(drill.difficulty.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }

            Spacer()

            Button {
                customContentService.removeDrill(drill.id)
                deleteTrigger += 1
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var conditioningList: some View {
        LazyVStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(Array(customContentService.library.conditioning.enumerated()), id: \.element.id) { index, item in
                customConditioningRow(item, index: index)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private func customConditioningRow(_ item: CustomConditioningItem, index: Int) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.focus)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("·")
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(item.duration)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }

            Spacer()

            Button {
                customContentService.removeConditioning(item.id)
                deleteTrigger += 1
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private var benchmarksList: some View {
        LazyVStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            ForEach(Array(customContentService.library.benchmarks.enumerated()), id: \.element.id) { index, item in
                customBenchmarkRow(item, index: index)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private func customBenchmarkRow(_ item: CustomBenchmarkItem, index: Int) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.category)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                    Text("·")
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    Text(item.unit)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    if !item.higherIsBetter {
                        Text("· Lower is better")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Button {
                customContentService.removeBenchmark(item.id)
                deleteTrigger += 1
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
    }

    private func emptySection(type: CustomContentType) -> some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 30)
            Image(systemName: type.icon)
                .font(.system(size: 36))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.3))

            Text("No Custom \(type.rawValue)s")
                .font(.headline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("Import a PDF to add your own\n\(type.rawValue.lowercased()) content.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showImport = true
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "doc.badge.plus")
                    Text("Import PDF")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.accent)
                .padding(.horizontal, KickIQAICoachTheme.Spacing.lg)
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 4)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: Capsule())
            }

            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }
}
