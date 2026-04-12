import SwiftUI

struct JournalView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var selectedEntry: JournalEntry?
    @State private var filterType: JournalEntryType?
    @State private var searchText: String = ""

    private var filteredEntries: [JournalEntry] {
        var entries = storage.journalEntries
        if let filterType {
            entries = entries.filter { $0.type == filterType }
        }
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.title.localizedStandardContains(searchText)
                || $0.summary.localizedStandardContains(searchText)
                || $0.fullContent.localizedStandardContains(searchText)
                || $0.tags.contains { $0.localizedStandardContains(searchText) }
            }
        }
        return entries
    }

    private var groupedEntries: [(String, [JournalEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            formatter.string(from: entry.date)
        }
        return grouped.sorted { a, b in
            let dateA = filteredEntries.first { formatter.string(from: $0.date) == a.key }?.date ?? .distantPast
            let dateB = filteredEntries.first { formatter.string(from: $0.date) == b.key }?.date ?? .distantPast
            return dateA > dateB
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .padding(.vertical, KickIQTheme.Spacing.sm)

                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: KickIQTheme.Spacing.lg) {
                            ForEach(groupedEntries, id: \.0) { dateLabel, entries in
                                Section {
                                    ForEach(entries) { entry in
                                        Button {
                                            selectedEntry = entry
                                        } label: {
                                            journalCard(entry)
                                        }
                                    }
                                } header: {
                                    dateHeader(dateLabel)
                                }
                            }
                        }
                        .padding(.horizontal, KickIQTheme.Spacing.md)
                        .padding(.bottom, KickIQTheme.Spacing.xl)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search entries...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
            .sheet(item: $selectedEntry) { entry in
                JournalDetailSheet(entry: entry, storage: storage)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                filterChip(label: "All", type: nil)
                filterChip(label: "Debriefs", type: .postGameDebrief)
                filterChip(label: "AI Chats", type: .chatSession)
                filterChip(label: "Analyses", type: .analysis)
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private func filterChip(label: String, type: JournalEntryType?) -> some View {
        let isSelected = filterType == type
        return Button {
            withAnimation(.spring(response: 0.3)) {
                filterType = type
            }
        } label: {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .black : KickIQTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? KickIQTheme.accent : KickIQTheme.card,
                    in: Capsule()
                )
        }
        .sensoryFeedback(.selection, trigger: filterType)
    }

    private func dateHeader(_ label: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
            Spacer()
        }
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private func journalCard(_ entry: JournalEntry) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(entryColor(entry.type).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: entryIcon(entry.type))
                    .font(.title3)
                    .foregroundStyle(entryColor(entry.type))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textPrimary)

                    if let rating = entry.gameRating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                            Text("\(rating)/5")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(KickIQTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(KickIQTheme.accent.opacity(0.15), in: Capsule())
                    }
                }

                Text(entry.summary)
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .lineLimit(2)

                Text(entry.date, format: .dateTime.hour().minute())
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var emptyState: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.1))
                    .frame(width: 88, height: 88)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.5))
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("No Journal Entries Yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Your post-game debriefs and AI coach\nchats will appear here automatically.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func entryIcon(_ type: JournalEntryType) -> String {
        switch type {
        case .postGameDebrief: "sportscourt.fill"
        case .chatSession: "brain.head.profile.fill"
        case .analysis: "video.fill"
        }
    }

    private func entryColor(_ type: JournalEntryType) -> Color {
        switch type {
        case .postGameDebrief: .green
        case .chatSession: .purple
        case .analysis: KickIQTheme.accent
        }
    }
}

struct JournalDetailSheet: View {
    let entry: JournalEntry
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.lg) {
                    headerSection
                    contentSection

                    if !entry.tags.isEmpty {
                        tagsSection
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(entry.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ShareLink(item: entry.fullContent) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(KickIQTheme.accent)
                    }
                }
            }
            .alert("Delete Entry?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    storage.deleteJournalEntry(entry.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This journal entry will be permanently deleted.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .presentationContentInteraction(.scrolls)
    }

    private var headerSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: typeIcon)
                        .font(.title2)
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.type.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(typeColor)

                    Text(entry.date, format: .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }

                Spacer()

                if let rating = entry.gameRating {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundStyle(star <= rating ? KickIQTheme.accent : KickIQTheme.textSecondary.opacity(0.3))
                            }
                        }
                        Text("Game Rating")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }
                }
            }
        }
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private var contentSection: some View {
        Text(entry.fullContent)
            .font(.body)
            .foregroundStyle(KickIQTheme.textPrimary.opacity(0.9))
            .lineSpacing(5)
            .padding(KickIQTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            .textSelection(.enabled)
    }

    private var tagsSection: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            ForEach(entry.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(KickIQTheme.accent.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(KickIQTheme.accent.opacity(0.1), in: Capsule())
            }
        }
    }

    private var typeIcon: String {
        switch entry.type {
        case .postGameDebrief: "sportscourt.fill"
        case .chatSession: "brain.head.profile.fill"
        case .analysis: "video.fill"
        }
    }

    private var typeColor: Color {
        switch entry.type {
        case .postGameDebrief: .green
        case .chatSession: .purple
        case .analysis: KickIQTheme.accent
        }
    }
}
