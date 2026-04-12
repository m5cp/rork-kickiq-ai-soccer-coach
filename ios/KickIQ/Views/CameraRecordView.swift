import SwiftUI
import AVFoundation

struct CameraRecordView: View {
    let onVideoRecorded: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var cameraService = CameraRecordingService()
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    #if targetEnvironment(simulator)
                    cameraUnavailablePlaceholder
                    #else
                    if AVCaptureDevice.default(for: .video) != nil {
                        cameraContent
                    } else {
                        cameraUnavailablePlaceholder
                    }
                    #endif
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        stopRecordingIfNeeded()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onDisappear {
            stopRecordingIfNeeded()
            cameraService.stopSession()
        }
    }

    private var cameraContent: some View {
        ZStack {
            CameraPreviewRepresentable(session: cameraService.captureSession)
                .ignoresSafeArea()

            VStack {
                Spacer()

                if cameraService.isRecording {
                    recordingIndicator
                }

                Spacer()

                controlsBar
                    .padding(.bottom, 40)
            }

            if let error = cameraService.errorMessage {
                VStack {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .task {
            await cameraService.setupSession()
        }
    }

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)

            Text(formattedTime)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.black.opacity(0.6), in: Capsule())
    }

    private var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var controlsBar: some View {
        HStack(spacing: 40) {
            Spacer()

            Button {
                if cameraService.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 72, height: 72)

                    if cameraService.isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 58, height: 58)
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: cameraService.isRecording)

            Spacer()
        }
    }

    private var cameraUnavailablePlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera Preview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text("Install this app on your device\nvia the Rork App to use the camera.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func startRecording() {
        cameraService.startRecording()
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                recordingTime += 1
                if recordingTime >= 30 {
                    stopRecording()
                }
            }
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        cameraService.stopRecording { url in
            if let url {
                onVideoRecorded(url)
                dismiss()
            }
        }
    }

    private func stopRecordingIfNeeded() {
        if cameraService.isRecording {
            timer?.invalidate()
            timer = nil
            cameraService.stopRecording { _ in }
        }
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
