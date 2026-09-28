import SwiftUI

/// Record your 10 to 15 second voice sample. Re-record any time.
struct RecordView: View {
    @EnvironmentObject var diag: DiagLog
    @StateObject private var recorder = VoiceRecorder()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("My Voice")
                    .font(.title2).bold()
                Text("Record 10 to 15 seconds in a quiet room. Speak normal. Re-record any time to change it.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if recorder.isRecording {
                    Text("\(Int(recorder.seconds))s")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    Text("Recording...")
                } else {
                    Image(systemName: recorder.hasVoice ? "checkmark.circle.fill" : "mic.circle")
                        .font(.system(size: 64))
                        .foregroundColor(recorder.hasVoice ? .green : .gray)
                }

                if recorder.isRecording {
                    Button("Stop and Save") {
                        recorder.stop(diag: diag)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button(recorder.hasVoice ? "Re-record My Voice" : "Record My Voice") {
                        recorder.start(diag: diag)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text(recorder.statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("My Voice")
            .onAppear { recorder.refresh() }
        }
    }
}
