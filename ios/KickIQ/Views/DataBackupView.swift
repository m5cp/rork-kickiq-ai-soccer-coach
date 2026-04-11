import SwiftUI
import UniformTypeIdentifiers

struct DataBackupView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportData: Data?
    @State private var importResult: ImportResult?
    @State private var showImportAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    headerSection
                    exportSection
                    importSection
                    infoSection
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Data Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: KickIQBackupDocument(data: exportData ?? Data()),
                contentType: .json,
                defaultFilename: "KickIQ_Backup_\(formattedDate)"
            ) { result in
                switch result {
                case .success:
                    importResult = ImportResult(success: true, message: "Backup exported successfully!")
                    showImportAlert = true
                case .failure:
                    importResult = ImportResult(success: false, message: "Failed to export backup.")
                    showImportAlert = true
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert(importResult?.success == true ? "Success" : "Error", isPresented: $showImportAlert) {
                Button("OK") {}
            } message: {
                Text(importResult?.message ?? "")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var headerSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "externaldrive.fill.badge.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.xs) {
                Text("Back Up Your Data")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text("Export your profile, sessions, and progress to a file. Import it on another device or after reinstalling.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, KickIQTheme.Spacing.md)
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("EXPORT")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            Button {
                exportData = DataBackupService.exportData(from: storage)
                if exportData != nil {
                    showExporter = true
                }
            } label: {
                HStack(spacing: KickIQTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(KickIQTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title3)
                            .foregroundStyle(KickIQTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Backup")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("Save your data as a JSON file")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                statItem(icon: "person.fill", value: storage.profile?.name ?? "—", label: "Player")
                statItem(icon: "video.fill", value: "\(storage.sessions.count)", label: "Sessions")
                statItem(icon: "flame.fill", value: "\(storage.maxStreak)", label: "Best Streak")
                statItem(icon: "star.fill", value: "\(storage.xpPoints)", label: "XP")
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("IMPORT")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            Button {
                showImporter = true
            } label: {
                HStack(spacing: KickIQTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import Backup")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                        Text("Restore from a KickIQ backup file")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary.opacity(0.3))
                }
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                Text("Backups include your profile, all analysis sessions, streak data, XP, personal records, favorites, and notes. Team data is stored in the cloud and syncs automatically.")
                    .font(.caption)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.6))
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(KickIQTheme.accent)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(KickIQTheme.textPrimary)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(success: false, message: "Could not access the file.")
                showImportAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                try DataBackupService.importData(from: data, into: storage)
                importResult = ImportResult(success: true, message: "Data imported successfully! Your profile and sessions have been restored.")
            } catch {
                importResult = ImportResult(success: false, message: "Invalid backup file: \(error.localizedDescription)")
            }
            showImportAlert = true

        case .failure(let error):
            importResult = ImportResult(success: false, message: "Failed to open file: \(error.localizedDescription)")
            showImportAlert = true
        }
    }
}

private struct ImportResult {
    let success: Bool
    let message: String
}

struct KickIQBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
