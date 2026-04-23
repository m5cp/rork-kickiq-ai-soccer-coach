import SwiftUI
import UIKit
import PDFKit

enum CoachShareable {
    case session(CoachSession)
    case campaign(Campaign, resolve: (UUID) -> CoachSession?)

    var title: String {
        switch self {
        case .session(let s): return s.displayTitle
        case .campaign(let c, _): return c.title
        }
    }

    @MainActor
    var pdfData: Data {
        switch self {
        case .session(let s): return CoachShareService.pdfData(session: s)
        case .campaign(let c, let r): return CoachShareService.pdfData(campaign: c, resolve: r)
        }
    }

    var textSummary: String {
        switch self {
        case .session(let s): return CoachShareService.textSummary(session: s)
        case .campaign(let c, let r): return CoachShareService.textSummary(campaign: c, resolve: r)
        }
    }

    var deepLink: URL? {
        switch self {
        case .session(let s): return CoachShareService.deepLink(session: s)
        case .campaign(let c, _): return CoachShareService.deepLink(campaign: c)
        }
    }
}

struct CoachShareSheet: View {
    let shareable: CoachShareable
    @Environment(\.dismiss) private var dismiss
    @State private var showPDF = false
    @State private var showQR = false
    @State private var shareItems: [Any] = []
    @State private var showActivity = false
    @State private var copiedFlash = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(shareable.title)
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    shareButton(title: "Export PDF", icon: "doc.richtext.fill") { showPDF = true }
                    shareButton(title: "Send as Text", icon: "text.bubble.fill") {
                        shareItems = [shareable.textSummary]
                        showActivity = true
                    }
                    shareButton(title: "Show QR Code", icon: "qrcode") { showQR = true }
                    shareButton(title: "Copy Link", icon: "link") {
                        if let url = shareable.deepLink {
                            UIPasteboard.general.string = url.absoluteString
                            withAnimation { copiedFlash = true }
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                withAnimation { copiedFlash = false }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                if copiedFlash {
                    Text("Link copied")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(.top, 8)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .sheet(isPresented: $showPDF) {
                PDFPreviewSheet(title: shareable.title, data: shareable.pdfData)
            }
            .sheet(isPresented: $showQR) {
                QRCodeSheet(title: shareable.title, payload: shareable.deepLink?.absoluteString ?? shareable.textSummary)
            }
            .sheet(isPresented: $showActivity) {
                ActivityShareView(items: shareItems)
            }
        }
        .presentationDetents([.medium])
    }

    private func shareButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct QRCodeSheet: View {
    let title: String
    let payload: String
    @State private var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .padding(20)
                        .background(Color.white, in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 32)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Scan to open in KickIQ")
                    .font(.caption)
                    .foregroundStyle(KickIQAICoachTheme.textSecondary)

                if let image {
                    Button {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                }

                Spacer()
            }
            .padding(.top, 20)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
            }
            .onAppear {
                image = CoachShareService.qrImage(from: payload)
            }
        }
    }
}

struct PDFPreviewSheet: View {
    let title: String
    let data: Data
    @Environment(\.dismiss) private var dismiss
    @State private var tempURL: URL?
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            Group {
                if let url = tempURL {
                    PDFKitView(url: url)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(KickIQAICoachTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                if let url = tempURL {
                    ActivityShareView(items: [url])
                }
            }
            .onAppear { writeToTemp() }
        }
    }

    private func writeToTemp() {
        let safe = title.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safe).pdf")
        try? data.write(to: url)
        tempURL = url
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        view.backgroundColor = .systemBackground
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
