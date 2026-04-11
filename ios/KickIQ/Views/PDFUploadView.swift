import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFUploadView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false
    @State private var importedPlans: [ImportedPlan] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var selectedPlan: ImportedPlan?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    if importedPlans.isEmpty && !isProcessing {
                        uploadPrompt
                    } else {
                        importedPlansList
                    }
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Upload Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
                if !importedPlans.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showFilePicker = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(item: $selectedPlan) { plan in
                ImportedPlanDetailSheet(plan: plan)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            loadSavedPlans()
        }
    }

    private var uploadPrompt: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("Import Training Plans")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Upload a PDF training plan from your coach, team, or any source. The app will extract the exercises and structure for easy access.")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
                featureRow(icon: "doc.text.fill", color: .blue, text: "Import any PDF training plan")
                featureRow(icon: "text.viewfinder", color: .orange, text: "Automatically extracts text content")
                featureRow(icon: "list.bullet.rectangle", color: .green, text: "Organized for easy reading")
                featureRow(icon: "square.and.arrow.down", color: .purple, text: "Saved locally for offline access")
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))

            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    if isProcessing {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "doc.badge.plus")
                    }
                    Text(isProcessing ? "Processing..." : "Choose PDF File")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
            .disabled(isProcessing)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var importedPlansList: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            if isProcessing {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    ProgressView().tint(KickIQTheme.accent)
                    Text("Processing PDF...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .padding(KickIQTheme.Spacing.md)
            }

            ForEach(importedPlans) { plan in
                Button {
                    selectedPlan = plan
                } label: {
                    importedPlanCard(plan)
                }
            }
        }
    }

    private func importedPlanCard(_ plan: ImportedPlan) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12))
                    Text("IMPORTED PLAN")
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                }
                .foregroundStyle(KickIQTheme.accent)

                Spacer()

                Text(plan.importedAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(KickIQTheme.textSecondary)
            }

            Text(plan.title)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)
                .multilineTextAlignment(.leading)

            Text(plan.preview)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: KickIQTheme.Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 10))
                    Text("\(plan.pageCount) page\(plan.pageCount == 1 ? "" : "s")")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(KickIQTheme.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("View")
                        .font(.caption.weight(.bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(KickIQTheme.accent)
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                .fill(KickIQTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                        .stroke(KickIQTheme.accent.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isProcessing = true
            errorMessage = nil

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Could not access the selected file."
                isProcessing = false
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            guard let pdfDocument = PDFDocument(url: url) else {
                errorMessage = "Could not read the PDF. Please try a different file."
                isProcessing = false
                return
            }

            let pageCount = pdfDocument.pageCount
            var fullText = ""

            for i in 0..<min(pageCount, 50) {
                if let page = pdfDocument.page(at: i), let text = page.string {
                    fullText += text + "\n\n"
                }
            }

            let fileName = url.deletingPathExtension().lastPathComponent
            let title = fileName
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized

            let preview = String(fullText.prefix(300)).trimmingCharacters(in: .whitespacesAndNewlines)

            let plan = ImportedPlan(
                title: title,
                content: fullText,
                preview: preview.isEmpty ? "No readable text content found." : preview,
                pageCount: pageCount
            )

            importedPlans.insert(plan, at: 0)
            saveImportedPlans()
            isProcessing = false

        case .failure(let error):
            errorMessage = "Failed to import: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func loadSavedPlans() {
        if let data = UserDefaults.standard.data(forKey: "kickiq_imported_plans"),
           let decoded = try? JSONDecoder().decode([ImportedPlan].self, from: data) {
            importedPlans = decoded
        }
    }

    private func saveImportedPlans() {
        if let data = try? JSONEncoder().encode(importedPlans) {
            UserDefaults.standard.set(data, forKey: "kickiq_imported_plans")
        }
    }
}

struct ImportedPlanDetailSheet: View {
    let plan: ImportedPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
                        HStack(spacing: KickIQTheme.Spacing.sm) {
                            HStack(spacing: 5) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                Text("IMPORTED · \(plan.pageCount) PAGES")
                                    .font(.caption.weight(.bold))
                                    .tracking(0.8)
                            }
                            .foregroundStyle(KickIQTheme.accent)

                            Spacer()

                            Text(plan.importedAt, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }

                        Text(plan.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(KickIQTheme.textPrimary)
                    }

                    Text(plan.content)
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textPrimary.opacity(0.85))
                        .lineSpacing(5)
                }
                .padding(KickIQTheme.Spacing.md + 4)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }
}

nonisolated struct ImportedPlan: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let content: String
    let preview: String
    let pageCount: Int
    let importedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        preview: String,
        pageCount: Int,
        importedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.preview = preview
        self.pageCount = pageCount
        self.importedAt = importedAt
    }
}
