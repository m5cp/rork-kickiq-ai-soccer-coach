import SwiftUI

struct SessionNotesSheet: View {
    let sessionID: String
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var noteText: String = ""
    @FocusState private var isFocused: Bool

    private var notes: [SessionNote] {
        storage.notesForSession(sessionID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                        if notes.isEmpty {
                            emptyState
                        } else {
                            ForEach(notes) { note in
                                noteCard(note)
                            }
                        }
                    }
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .padding(.top, KickIQTheme.Spacing.md)
                    .padding(.bottom, KickIQTheme.Spacing.xl)
                }
                .scrollIndicators(.hidden)

                inputBar
            }
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Session Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .presentationContentInteraction(.scrolls)
    }

    private var emptyState: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            Spacer().frame(height: 40)

            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(KickIQTheme.accent.opacity(0.5))

            Text("No Notes Yet")
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Add notes about what you worked on,\nhow you felt, or what to focus on next.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func noteCard(_ note: SessionNote) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.accent)
                Text(note.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary)
                Spacer()
            }

            Text(note.text)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var inputBar: some View {
        HStack(spacing: KickIQTheme.Spacing.sm) {
            TextField("Add a note...", text: $noteText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textPrimary)
                .lineLimit(1...4)
                .focused($isFocused)
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.vertical, KickIQTheme.Spacing.sm + 2)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))

            Button {
                guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let note = SessionNote(sessionID: sessionID, text: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                storage.addSessionNote(note)
                noteText = ""
                isFocused = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? KickIQTheme.textSecondary.opacity(0.3) : KickIQTheme.accent)
            }
            .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .sensoryFeedback(.impact(weight: .light), trigger: notes.count)
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, KickIQTheme.Spacing.sm)
        .background(KickIQTheme.surface)
    }
}
