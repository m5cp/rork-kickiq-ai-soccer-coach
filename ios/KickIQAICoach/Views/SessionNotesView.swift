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
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
                        if notes.isEmpty {
                            emptyState
                        } else {
                            ForEach(notes) { note in
                                noteCard(note)
                            }
                        }
                    }
                    .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                    .padding(.top, KickIQAICoachTheme.Spacing.md)
                    .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
                }
                .scrollIndicators(.hidden)

                inputBar
            }
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Session Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .presentationContentInteraction(.scrolls)
    }

    private var emptyState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Spacer().frame(height: 40)

            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(KickIQAICoachTheme.accent.opacity(0.5))

            Text("No Notes Yet")
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("Add notes about what you worked on,\nhow you felt, or what to focus on next.")
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func noteCard(_ note: SessionNote) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            HStack {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(note.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                Spacer()
            }

            Text(note.text)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private var inputBar: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            TextField("Add a note...", text: $noteText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
                .lineLimit(1...4)
                .focused($isFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isFocused = false }
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))

            Button {
                guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let note = SessionNote(sessionID: sessionID, text: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                storage.addSessionNote(note)
                noteText = ""
                isFocused = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? KickIQAICoachTheme.textSecondary.opacity(0.3) : KickIQAICoachTheme.accent)
            }
            .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .sensoryFeedback(.impact(weight: .light), trigger: notes.count)
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
        .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
        .background(KickIQAICoachTheme.surface)
    }
}
