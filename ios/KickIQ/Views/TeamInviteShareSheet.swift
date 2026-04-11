import SwiftUI

struct TeamInviteShareSheet: View {
    let team: TeamDTO
    @Environment(\.dismiss) private var dismiss
    @State private var teamService = TeamService.shared
    @State private var copied = false
    @State private var showShareSheet = false
    @State private var showRegenerateAlert = false

    private var inviteMessage: String {
        "Join my team \"\(team.name)\" on KickIQ! Use this code to join: \(team.join_code)\n\nDownload KickIQ and enter the code in Team → Join with Code."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(KickIQTheme.accent.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(KickIQTheme.accent)
                    }

                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        Text("Invite Players")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("Share this code with your players so they can join \"\(team.name)\"")
                            .font(.subheadline)
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: KickIQTheme.Spacing.md) {
                        Text(team.join_code)
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundStyle(KickIQTheme.accent)
                            .tracking(4)

                        Text("Each team has a unique code.\nOnly players with this code can join.")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(KickIQTheme.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

                    VStack(spacing: KickIQTheme.Spacing.sm) {
                        Button {
                            UIPasteboard.general.string = team.join_code
                            withAnimation(.spring(response: 0.3)) { copied = true }
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                withAnimation { copied = false }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.subheadline.weight(.semibold))
                                Text(copied ? "Copied!" : "Copy Code")
                                    .font(.headline)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                        }
                        .sensoryFeedback(.success, trigger: copied)

                        Button {
                            showShareSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "message.fill")
                                    .font(.subheadline.weight(.semibold))
                                Text("Share via Message")
                                    .font(.headline)
                            }
                            .foregroundStyle(KickIQTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.md)
                            .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.lg))
                        }

                        Button {
                            showRegenerateAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption.weight(.semibold))
                                Text("Regenerate Code")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .padding(.top, KickIQTheme.Spacing.sm)
                        }
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.top, KickIQTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Share Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [inviteMessage])
            }
            .alert("Regenerate Code?", isPresented: $showRegenerateAlert) {
                Button("Regenerate", role: .destructive) {
                    Task {
                        if let _ = await teamService.regenerateJoinCode(teamId: team.id) {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will create a new join code. The old code will stop working and any players who haven't joined yet will need the new code.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
