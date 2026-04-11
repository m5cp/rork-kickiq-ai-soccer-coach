import SwiftUI
import AVFoundation

struct QRScannerView: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var scannedPayload: QRSharePayload?
    @State private var showImportConfirm = false
    @State private var importSuccess = false
    @State private var errorMessage: String?
    @State private var torchOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQTheme.background.ignoresSafeArea()

                #if targetEnvironment(simulator)
                simulatorPlaceholder
                #else
                if AVCaptureDevice.default(for: .video) != nil {
                    QRCameraPreview(onCodeScanned: handleScan, torchOn: $torchOn)
                        .ignoresSafeArea()

                    scannerOverlay
                } else {
                    simulatorPlaceholder
                }
                #endif

                VStack {
                    Spacer()
                    bottomCard
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
                #if !targetEnvironment(simulator)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        torchOn.toggle()
                    } label: {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .foregroundStyle(torchOn ? KickIQTheme.accent : KickIQTheme.textSecondary)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showImportConfirm) {
                if let payload = scannedPayload {
                    QRImportConfirmSheet(payload: payload, storage: storage, onImported: {
                        importSuccess = true
                        showImportConfirm = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            dismiss()
                        }
                    })
                }
            }
            .sensoryFeedback(.success, trigger: importSuccess)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var simulatorPlaceholder: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(KickIQTheme.accent.opacity(0.5))

            Text("Camera Preview")
                .font(.title2.weight(.semibold))
                .foregroundStyle(KickIQTheme.textPrimary)

            Text("Install this app on your device\nvia the Rork App to scan QR codes.")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scannerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            RoundedRectangle(cornerRadius: KickIQTheme.Radius.xl)
                .frame(width: 260, height: 260)
                .blendMode(.destinationOut)

            RoundedRectangle(cornerRadius: KickIQTheme.Radius.xl)
                .stroke(KickIQTheme.accent, lineWidth: 3)
                .frame(width: 260, height: 260)

            VStack {
                Spacer()
                    .frame(height: 80)
                Text("Point camera at a KickIQ QR code")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, KickIQTheme.Spacing.md)
                    .padding(.vertical, KickIQTheme.Spacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 160)
            }
        }
        .compositingGroup()
    }

    private var bottomCard: some View {
        VStack(spacing: KickIQTheme.Spacing.sm) {
            if importSuccess {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("Imported successfully!")
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                .padding(KickIQTheme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
            } else if let error = errorMessage {
                HStack(spacing: KickIQTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                .padding(KickIQTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.bottom, KickIQTheme.Spacing.xl)
    }

    private func handleScan(_ code: String) {
        guard scannedPayload == nil && !showImportConfirm else { return }

        if let payload = QRCodeService.decodePayload(from: code) {
            scannedPayload = payload
            showImportConfirm = true
            errorMessage = nil
        } else {
            errorMessage = "Not a valid KickIQ QR code"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                errorMessage = nil
            }
        }
    }
}

struct QRCameraPreview: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    @Binding var torchOn: Bool

    func makeUIViewController(context: Context) -> QRCameraViewController {
        let vc = QRCameraViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: QRCameraViewController, context: Context) {
        uiViewController.setTorch(torchOn)
    }
}

class QRCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.layer.bounds
        view.layer.addSublayer(layer)

        previewLayer = layer
        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        Task { @MainActor in
            guard !hasScanned else { return }
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }
            hasScanned = true
            onCodeScanned?(value)
            try? await Task.sleep(for: .seconds(2))
            hasScanned = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

struct QRImportConfirmSheet: View {
    let payload: QRSharePayload
    let storage: StorageService
    let onImported: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    importHeader

                    importDetails

                    importButton
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Import Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
    }

    private var importHeader: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(KickIQTheme.accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: importIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(KickIQTheme.accent)
            }

            VStack(spacing: KickIQTheme.Spacing.xs) {
                Text(importTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)
                Text(importSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, KickIQTheme.Spacing.md)
    }

    @ViewBuilder
    private var importDetails: some View {
        switch payload.type {
        case .drill:
            if let drill = payload.drill {
                drillPreview(drill)
            }
        case .analysis, .session:
            if let session = payload.session {
                sessionPreview(session)
            }
        case .dailyPlan:
            if let plan = payload.dailyPlan {
                planPreview(plan)
            }
        }
    }

    private func drillPreview(_ drill: QRDrillPayload) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text(drill.name)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)

            Text(drill.description)
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)
                .lineSpacing(3)

            HStack(spacing: KickIQTheme.Spacing.md) {
                Label(drill.duration, systemImage: "clock")
                Label(drill.difficulty.rawValue, systemImage: "speedometer")
                Label(drill.targetSkill, systemImage: "target")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(KickIQTheme.textSecondary)

            if !drill.coachingCues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("COACHING CUES")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                    ForEach(drill.coachingCues, id: \.self) { cue in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(KickIQTheme.accent)
                                .padding(.top, 2)
                            Text(cue)
                                .font(.caption)
                                .foregroundStyle(KickIQTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func sessionPreview(_ session: QRSessionPayload) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Analysis Results")
                        .font(.headline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                    Text(session.position.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.accent)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text("\(session.overallScore)")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(KickIQTheme.accent)
                    Text("/ 100")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }

            HStack(spacing: KickIQTheme.Spacing.md) {
                Label("\(session.skillScores.count) skills", systemImage: "chart.bar.fill")
                Label("\(session.drills.count) drills", systemImage: "figure.run")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(KickIQTheme.textSecondary)

            if !session.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Strengths")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                    ForEach(session.strengths.prefix(2), id: \.self) { s in
                        Text("• \(s)")
                            .font(.caption)
                            .foregroundStyle(KickIQTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private func planPreview(_ plan: QRDailyPlanPayload) -> some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text(plan.focus)
                .font(.headline)
                .foregroundStyle(KickIQTheme.textPrimary)

            HStack(spacing: KickIQTheme.Spacing.md) {
                Label(plan.intensity.rawValue, systemImage: plan.intensity.icon)
                Label(plan.duration.label, systemImage: "clock")
                Label(plan.mode.rawValue, systemImage: plan.mode.icon)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(KickIQTheme.textSecondary)

            Text("\(plan.drills.count) drills in this session")
                .font(.subheadline)
                .foregroundStyle(KickIQTheme.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(plan.drills.prefix(3), id: \.name) { drill in
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(KickIQTheme.accent)
                        Text(drill.name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(KickIQTheme.textPrimary)
                    }
                }
                if plan.drills.count > 3 {
                    Text("+ \(plan.drills.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
    }

    private var importButton: some View {
        Button {
            performImport()
        } label: {
            HStack(spacing: KickIQTheme.Spacing.sm) {
                Image(systemName: "square.and.arrow.down")
                Text("Import to KickIQ")
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KickIQTheme.Spacing.md)
            .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
    }

    private func performImport() {
        switch payload.type {
        case .drill:
            if let drill = payload.drill {
                let imported = QRCodeService.importDrill(from: drill)
                storage.completeDrill(imported)
            }
        case .analysis, .session:
            if let session = payload.session {
                let imported = QRCodeService.importSession(from: session)
                storage.addSession(imported)
            }
        case .dailyPlan:
            break
        }
        onImported()
    }

    private var importIcon: String {
        switch payload.type {
        case .drill: "figure.run"
        case .analysis, .session: "chart.bar.fill"
        case .dailyPlan: "calendar"
        }
    }

    private var importTitle: String {
        switch payload.type {
        case .drill: "Import Drill"
        case .analysis, .session: "Import Analysis"
        case .dailyPlan: "Import Training Session"
        }
    }

    private var importSubtitle: String {
        switch payload.type {
        case .drill: "Add this drill to your library"
        case .analysis, .session: "Save this analysis to your history"
        case .dailyPlan: "View this training session's drills"
        }
    }
}
