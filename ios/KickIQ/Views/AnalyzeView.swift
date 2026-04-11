import SwiftUI
import PhotosUI
import AVFoundation

struct AnalyzeView: View {
    let storage: StorageService
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var aiService = AIAnalysisService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var thumbnailImage: UIImage?
    @State private var extractedFrames: [UIImage] = []
    @State private var videoURL: URL?
    @State private var analysisResult: TrainingSession?
    @State private var showResults = false
    @State private var appeared = false
    @State private var pulseAnimation = false
    @State private var showCameraUnavailable = false
    @State private var showFilmingGuide = false
    @State private var showProfile = false

    private var isIPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQTheme.background.ignoresSafeArea()

                if showResults, let result = analysisResult {
                    AnalysisResultView(session: result, storage: storage) {
                        resetState()
                    }
                } else if aiService.isAnalyzing {
                    analyzingState
                } else {
                    uploadState
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        profileToolbarIcon
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(storage: storage, calendarService: CalendarService())
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { await handleVideoSelection(newItem) }
        }
        .alert(isPresented: $showCameraUnavailable) {
            cameraUnavailableAlert
        }
        .sheet(isPresented: $showFilmingGuide) {
            FilmingGuideSheet()
        }
    }

    private var uploadState: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("ANALYZE")
                    .font(.system(isIPad ? .largeTitle : .largeTitle, design: .default, weight: .black).width(.compressed))
                    .tracking(3)
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Upload a training clip for AI feedback")
                    .font(isIPad ? .title3 : .subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            if let position = storage.profile?.position {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: position.icon)
                        .foregroundStyle(KickIQTheme.accent)
                    Text("Analyzing as \(position.rawValue)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.vertical, 10)
                .background(KickIQTheme.card, in: Capsule())
            }

            clipRequirements

            if isIPad {
                HStack(spacing: KickIQTheme.Spacing.lg) {
                    recordButton
                    uploadButton
                }
                .frame(maxWidth: AdaptiveLayout.iPadMaxContentWidth)
            } else {
                VStack(spacing: KickIQTheme.Spacing.md) {
                    recordButton
                    uploadButton
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            pulseAnimation = true
        }
    }

    private var clipRequirements: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                requirementPill(icon: "timer", text: "15–30 sec")
                requirementPill(icon: "arrow.up.doc", text: "Under 100 MB")
                requirementPill(icon: "iphone.gen3", text: "Landscape")
            }

            Button {
                showFilmingGuide = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13))
                    Text("How to film for best results")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(KickIQTheme.accent)
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .opacity(appeared ? 1 : 0)
    }

    private func requirementPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(KickIQTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(KickIQTheme.surface, in: Capsule())
    }

    private var recordButton: some View {
        Button {
            showCameraUnavailable = true
        } label: {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "video.fill")
                        .font(.title3)
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Record Clip")
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Use camera to film your session")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .accessibilityLabel("Record a training clip using the camera")
    }

    private var cameraUnavailableAlert: Alert {
        Alert(
            title: Text("Camera Not Available"),
            message: Text("Install this app on your device via the Rork App to use the camera for recording training clips."),
            dismissButton: .default(Text("OK"))
        )
    }

    private var uploadButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .any(of: [.videos, .images])) {
            HStack(spacing: KickIQTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3)
                        .foregroundStyle(KickIQTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload from Library")
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text("Select a video or photo from your session")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.4))
            }
            .padding(KickIQTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                    .fill(KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.lg)
                            .stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .accessibilityLabel("Upload a training clip from your photo library")
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedItem)
    }

    private var analyzingState: some View {
        VStack(spacing: KickIQTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(KickIQTheme.divider, lineWidth: 8)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: aiService.analysisProgress)
                    .stroke(KickIQTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: aiService.analysisProgress)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(KickIQTheme.accent)
                    .symbolEffect(.pulse, isActive: true)
            }

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text(aiService.statusMessage)
                    .font(.headline)
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: aiService.statusMessage)

                Text("\(Int(aiService.analysisProgress * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            Spacer()
            Spacer()
        }
    }

    private func handleVideoSelection(_ item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            thumbnailImage = image
            extractedFrames = [image]
            videoURL = nil
        } else if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
            videoURL = movie.url
            let frames = await AIAnalysisService.extractFrames(from: movie.url, count: 4)
            extractedFrames = frames
            thumbnailImage = frames.first
        }

        guard !extractedFrames.isEmpty,
              let position = storage.profile?.position,
              let level = storage.profile?.skillLevel else { return }

        let result = await aiService.analyzeVideo(frames: extractedFrames, videoURL: videoURL, position: position, skillLevel: level)

        if let result {
            analysisResult = result
            storage.addSession(result)
            withAnimation(.spring(response: 0.5)) { showResults = true }
        }
    }

    private func resetState() {
        withAnimation(.spring(response: 0.4)) {
            showResults = false
            analysisResult = nil
            thumbnailImage = nil
            extractedFrames = []
            videoURL = nil
            selectedItem = nil
        }
    }

    @ViewBuilder
    private var profileToolbarIcon: some View {
        if let avatar = storage.profile?.avatar,
           let data = avatar.imageDataValue,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.4), lineWidth: 1.5))
        } else {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(KickIQTheme.accent)
            }
            .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 1))
        }
    }
}

nonisolated struct VideoTransferable: Transferable {
    let url: URL

    nonisolated static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            return VideoTransferable(url: destination)
        }
    }
}
