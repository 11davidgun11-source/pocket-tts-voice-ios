import SwiftUI
import AVFoundation

/// Your made files. Play, make M4A copy, share, delete.
struct FilesView: View {
    @EnvironmentObject var diag: DiagLog
    @State private var files: [URL] = []
    @State private var player: AVAudioPlayer?
    @State private var busyName: String?

    var body: some View {
        NavigationView {
            Group {
                if files.isEmpty {
                    VStack {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No files yet. Make one in Speak.")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(files, id: \.self) { url in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(url.lastPathComponent)
                                .font(.subheadline)
                                .lineLimit(1)
                            HStack {
                                Button("Play") { play(url: url) }
                                    .buttonStyle(.bordered)
                                ShareLink(item: url) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                                if url.pathExtension.lowercased() == "wav" {
                                    Button(busyName == url.lastPathComponent ? "..." : "M4A") {
                                        Task { await makeM4A(url: url) }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(busyName != nil)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    delete(url: url)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .navigationTitle("Files")
            .onAppear { files = AudioExport.listOutputs() }
        }
    }

    private func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            diag.add("play failed: \(error.localizedDescription)")
        }
    }

    private func makeM4A(url: URL) async {
        busyName = url.lastPathComponent
        defer {
            busyName = nil
            files = AudioExport.listOutputs()
        }
        if let m4a = await AudioExport.makeM4A(from: url) {
            diag.add("m4a done: \(m4a.lastPathComponent)")
        } else {
            diag.add("m4a failed for \(url.lastPathComponent)")
        }
    }

    private func delete(url: URL) {
        try? FileManager.default.removeItem(at: url)
        files = AudioExport.listOutputs()
    }
}
