import SwiftUI
import UniformTypeIdentifiers

struct PDFImportView: View {
    let customContentService: CustomContentService
    @Environment(\.dismiss) private var dismiss
    @State private var parsingService = PDFParsingService()
    @State private var selectedContentType: CustomContentType = .drill
    @State private var showFilePicker = false
    @State private var importedFileName: String?
    @State private var extractedText: String?
    @State private var importComplete = false
    @State private var importedCount = 0
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    headerSection
                    contentTypePicker
                    uploadSection
                    if parsingService.isProcessing {
                        processingState
                    }
                    if let error = parsingService.errorMessage {
                        errorBanner(error)
                    }
                    if let result = parsingService.parseResult {
                        parseResultPreview(result)
                    }
                    if importComplete {
                        successBanner
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Import Content")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [KickIQAICoachTheme.accent.opacity(0.2), KickIQAICoachTheme.accent.opacity(0.02)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .symbolEffect(.pulse, isActive: appeared)
            }

            VStack(spacing: 6) {
                Text("IMPORT YOUR CONTENT")
                    .font(.system(.subheadline, design: .default, weight: .black))
                    .tracking(2)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)

                Text("Upload a PDF with drills, exercises, or\nbenchmarks and AI will extract them for you.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, KickIQAICoachTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var contentTypePicker: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("CONTENT TYPE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(CustomContentType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedContentType = type
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 20, weight: .bold))
                            Text(type.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(selectedContentType == type ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                        .background(
                            selectedContentType == type ? KickIQAICoachTheme.accent : KickIQAICoachTheme.card,
                            in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md)
                        )
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedContentType)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var uploadSection: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            if let fileName = importedFileName {
                HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .fill(KickIQAICoachTheme.accent.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "doc.fill")
                            .font(.body)
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(fileName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                            .lineLimit(1)
                        Text("PDF Document")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        resetImport()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                    }
                }
                .padding(KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
            }

            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: importedFileName == nil ? "doc.badge.plus" : "arrow.triangle.2.circlepath")
                    Text(importedFileName == nil ? "Select PDF File" : "Choose Different File")
                }
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.lg)
                        .stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 1.5)
                )
            }

            if extractedText != nil && parsingService.parseResult == nil && !parsingService.isProcessing {
                Button {
                    Task { await processDocument() }
                } label: {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Extract with AI")
                    }
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                    .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                }
                .sensoryFeedback(.impact, trigger: parsingService.isProcessing)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var processingState: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(KickIQAICoachTheme.accent)

            Text("AI is reading your document...")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("Extracting \(selectedContentType.rawValue.lowercased()) from PDF")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
    }

    private func parseResultPreview(_ result: PDFParseResult) -> some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("FOUND \(itemCount(result)) ITEMS")
                    .font(.caption.weight(.black))
                    .tracking(1)
                    .foregroundStyle(.green)
            }

            switch selectedContentType {
            case .drill:
                ForEach(Array(result.drills.enumerated()), id: \.offset) { _, drill in
                    parsedItemRow(name: drill.name, subtitle: drill.targetSkill ?? "General", icon: "figure.soccer")
                }
            case .conditioning:
                ForEach(Array(result.conditioning.enumerated()), id: \.offset) { _, item in
                    parsedItemRow(name: item.name, subtitle: item.focus ?? "General", icon: "heart.circle.fill")
                }
            case .benchmark:
                ForEach(Array(result.benchmarks.enumerated()), id: \.offset) { _, item in
                    parsedItemRow(name: item.name, subtitle: item.category ?? "General", icon: "chart.bar.doc.horizontal.fill")
                }
            }

            Button {
                importResults(result)
            } label: {
                HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import \(itemCount(result)) Items")
                }
                .font(.headline)
                .foregroundStyle(KickIQAICoachTheme.onAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
            }
            .sensoryFeedback(.success, trigger: importComplete)
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
    }

    private func parsedItemRow(name: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQAICoachTheme.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var successBanner: some View {
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: importComplete)

            Text("Successfully Imported!")
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Text("\(importedCount) items added to your library")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)

            Text("Custom content appears in your\nDrills, Conditioning, and Benchmark tabs.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KickIQAICoachTheme.Spacing.xl)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                parsingService.errorMessage = "Could not access the file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            importedFileName = url.lastPathComponent
            importComplete = false
            parsingService.parseResult = nil
            parsingService.errorMessage = nil

            if let text = parsingService.extractTextFromPDF(at: url) {
                extractedText = text
            } else {
                parsingService.errorMessage = "Could not read text from this PDF. Make sure it contains selectable text (not scanned images)."
            }

        case .failure(let error):
            parsingService.errorMessage = "File selection failed: \(error.localizedDescription)"
        }
    }

    private func processDocument() async {
        guard let text = extractedText, let fileName = importedFileName else { return }
        await parsingService.parsePDFWithAI(text: text, contentType: selectedContentType, fileName: fileName)
    }

    private func importResults(_ result: PDFParseResult) {
        let fileName = importedFileName ?? "Unknown"
        customContentService.importFromParseResult(result, fileName: fileName, contentType: selectedContentType)
        importedCount = itemCount(result)
        withAnimation(.spring(response: 0.5)) {
            importComplete = true
        }
    }

    private func resetImport() {
        importedFileName = nil
        extractedText = nil
        parsingService.parseResult = nil
        parsingService.errorMessage = nil
        importComplete = false
    }

    private func itemCount(_ result: PDFParseResult) -> Int {
        switch selectedContentType {
        case .drill: result.drills.count
        case .conditioning: result.conditioning.count
        case .benchmark: result.benchmarks.count
        }
    }
}
