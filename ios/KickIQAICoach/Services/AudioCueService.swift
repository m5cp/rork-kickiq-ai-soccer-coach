import AVFoundation

@Observable
@MainActor
class AudioCueService {
    private var audioPlayer: AVAudioPlayer?
    private var toneGenerator: AVAudioEngine?
    var isMuted: Bool = UserDefaults.standard.bool(forKey: "kickiq_audio_muted")

    func toggleMute() {
        isMuted.toggle()
        UserDefaults.standard.set(isMuted, forKey: "kickiq_audio_muted")
    }

    func playCountdownBeep() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1057)
    }

    func playFinalBeep() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1304)
    }

    func playRestStart() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1114)
    }

    func playComplete() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1025)
    }

    func playGo() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1113)
    }
}
