import AVFoundation
import UIKit

@Observable
@MainActor
class CameraRecordingService: NSObject {
    let captureSession = AVCaptureSession()
    var isRecording = false
    var errorMessage: String?

    private var movieOutput = AVCaptureMovieFileOutput()
    private var recordingCompletion: ((URL?) -> Void)?
    private var isSessionConfigured = false

    func setupSession() async {
        guard !isSessionConfigured else { return }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                errorMessage = "Camera access denied"
                return
            }
        } else if status == .denied || status == .restricted {
            errorMessage = "Camera access denied. Enable in Settings > Privacy > Camera."
            return
        }

        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .audio)
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            errorMessage = "Could not access camera"
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        guard captureSession.canAddOutput(movieOutput) else {
            errorMessage = "Could not configure video recording"
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(movieOutput)

        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }

        captureSession.commitConfiguration()
        isSessionConfigured = true

        Task.detached { [captureSession] in
            captureSession.startRunning()
        }
    }

    func startRecording() {
        guard isSessionConfigured, !isRecording else { return }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        recordingCompletion = completion
        movieOutput.stopRecording()
    }

    func stopSession() {
        Task.detached { [captureSession] in
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
}

extension CameraRecordingService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            isRecording = false
            if let error {
                errorMessage = "Recording failed: \(error.localizedDescription)"
                recordingCompletion?(nil)
            } else {
                recordingCompletion?(outputFileURL)
            }
            recordingCompletion = nil
        }
    }
}
