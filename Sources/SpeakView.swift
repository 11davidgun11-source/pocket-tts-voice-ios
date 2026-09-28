import SwiftUI
import AVFoundation

/// Type text, press Speak, hear your voice. Saves WAV to Files.
struct SpeakView: View {
    @EnvironmentObject var store: ModelStore
    @EnvironmentObject var diag: DiagLog

    @State private var text = ""
    @State private var busy = false
    @State private var statusText = ""
    @State private var lastFile: URL?
    @State private var player: AVAudioPlayer?

    private let engine = TTSService()
    private let maxChars = 1000

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Speak")
                    .font(.title2).bold()

                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
                    .disabled(busy)

                HStack {
                    Text("\(text.count)/\(maxChars)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if busy { ProgressView() }
                }

                Button(busy ? "Working..." : "Speak") {
                    hideKeyboard()
                    Task { await speak() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(busy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                if let lastFile {
                    HStack {
                        Button("Play Last") { play(url: lastFile) }
                            .buttonStyle(.bordered)
                        ShareLink(item: lastFile) {
                            Label("Share WAV", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Speak")
        }
    }

    private func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            statusText = "Play failed."
            diag.add("play failed: \(error.localizedDescription)")
        }
    }

    private func speak() async {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard clean.count <= maxChars else {
            statusText = "Too long. Keep under \(maxChars) letters. Split in two."
            return
        }
        guard store.allReady else {
            statusText = "Model not ready. Open Setup tab first."
            return
        }
        let voiceURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("my-voice.wav")
        guard FileManager.default.fileExists(atPath: voiceURL.path) else {
            statusText = "No voice print. Open My Voice tab first."
            return
        }

        busy = true
        statusText = "Warming engine, first run is slow..."
        diag.add("speak tap, text \(clean.count) chars")
        defer { busy = false }

        let ok = await Task.detached {
            self.engine.warmup(store: self.store, diag: self.diag)
        }.value
        guard ok else {
            statusText = "Engine failed to start. See Log."
            return
        }

        let outURL = AudioExport.newOutputURL()
        statusText = "Making audio..."
        let made = await Task.detached {
            self.engine.speak(text: clean, voiceWavPath: voiceURL.path, outURL: outURL, diag: self.diag)
        }.value

        if let made {
            lastFile = made
            statusText = "Saved: \(made.lastPathComponent)"
            play(url: made)
        } else {
            statusText = "Failed. See Log tab."
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
