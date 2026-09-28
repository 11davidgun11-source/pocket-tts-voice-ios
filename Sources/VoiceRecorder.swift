import Foundation
import AVFoundation

/// Records your voice sample. 24 kHz mono WAV. Same format the model wants.
/// One voice print only: Documents/my-voice.wav. Re-record replaces it.
final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var seconds: TimeInterval = 0
    @Published var hasVoice = false
    @Published var statusText = ""

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    var voiceURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("my-voice.wav")
    }

    func refresh() {
        let fm = FileManager.default
        let ok = fm.fileExists(atPath: voiceURL.path)
        let size = (try? fm.attributesOfItem(atPath: voiceURL.path)[.size] as? Int) ?? 0
        hasVoice = ok && size > 1000
        if !isRecording {
            statusText = hasVoice ? "Voice print saved. Ready." : "No voice print yet. Record one."
        }
    }

    func requestMic(_ done: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { ok in
            DispatchQueue.main.async { done(ok) }
        }
    }

    func start(diag: DiagLog) {
        requestMic { ok in
            guard ok else {
                self.statusText = "Mic blocked. Allow mic in Settings."
                diag.add("mic permission denied")
                return
            }
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)

                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVSampleRateKey: 24000,
                    AVNumberOfChannelsKey: 1,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
                self.recorder = try AVAudioRecorder(url: self.voiceURL, settings: settings)
                self.recorder?.delegate = self
                self.recorder?.isMeteringEnabled = true
                self.recorder?.record()

                self.isRecording = true
                self.seconds = 0
                self.statusText = "Recording. Speak normal. 10 to 15 sec best."
                diag.add("record start")

                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    self.seconds += 0.5
                    self.recorder?.updateMeters()
                    if self.seconds >= 20 {
                        self.stop(diag: diag)
                    }
                }
            } catch {
                self.statusText = "Record failed to start."
                diag.add("record start failed: \(error.localizedDescription)")
            }
        }
    }

    func stop(diag: DiagLog) {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        refresh()
        diag.add("record stop, length \(Int(seconds))s")
        if seconds < 3 {
            statusText = "Too short. Need 3 sec or more. Try again."
            hasVoice = false
        } else {
            statusText = "Voice print saved (\(Int(seconds))s). Ready."
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            statusText = "Record cut off. Try again."
        }
    }
}
