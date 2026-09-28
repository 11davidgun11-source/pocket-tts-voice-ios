import Foundation

/// Downloads the 7 iPhone-ready model files once, then checks them.
/// Files live in Documents/models. No login needed. Public files.
final class ModelStore: ObservableObject {
    struct ModelFile {
        let name: String
        var ready: Bool = false
    }

    // Must match the file names inside sherpa-onnx-pocket-tts-int8-2026-01-26
    static let fileNames = [
        "lm_flow.int8.onnx",
        "lm_main.int8.onnx",
        "encoder.onnx",
        "decoder.int8.onnx",
        "text_conditioner.onnx",
        "vocab.json",
        "token_scores.json",
    ]

    // Set at first release upload. Public download. No login.
    static var downloadBaseURL = "https://github.com/11davidgun11-source/pocket-tts-voice-ios/releases/download/models-v1/"

    @Published var files: [ModelFile] = fileNames.map { ModelFile(name: $0) }
    @Published var downloading = false
    @Published var progress: Double = 0
    @Published var statusText = "Not checked yet."

    var modelsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("models", isDirectory: true)
    }

    var allReady: Bool { files.allSatisfy { $0.ready } }

    func path(for name: String) -> String {
        modelsDir.appendingPathComponent(name).path
    }

    @MainActor
    func refresh() {
        let fm = FileManager.default
        try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        for i in files.indices {
            let url = modelsDir.appendingPathComponent(files[i].name)
            var isDir: ObjCBool = false
            let ok = fm.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue
            let size = (try? fm.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            files[i].ready = ok && size > 0
        }
        statusText = allReady ? "Model ready. 7 of 7 files." : "Model missing. Press Download."
    }

    @MainActor
    func downloadAll(diag: DiagLog) async {
        guard !downloading else { return }
        downloading = true
        progress = 0
        defer { downloading = false }

        let fm = FileManager.default
        try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        statusText = "Download start. About 94 MB, one time."
        diag.add("model download start")

        for (index, file) in ModelStore.fileNames.enumerated() {
            let dest = modelsDir.appendingPathComponent(file)
            if fm.fileExists(atPath: dest.path) {
                try? fm.removeItem(at: dest)
            }
            guard let url = URL(string: ModelStore.downloadBaseURL + file) else {
                statusText = "Bad download link."
                diag.add("bad url for \(file)")
                return
            }
            do {
                statusText = "File \(index + 1) of 7: \(file)"
                let (tmpURL, _) = try await URLSession.shared.download(from: url)
                try fm.moveItem(at: tmpURL, to: dest)
                diag.add("got \(file)")
            } catch {
                statusText = "Download failed: \(file). Check net and retry."
                diag.add("download failed \(file): \(error.localizedDescription)")
                return
            }
            progress = Double(index + 1) / Double(ModelStore.fileNames.count)
        }

        refresh()
        if allReady {
            statusText = "Model ready. 7 of 7 files."
            diag.add("model ready, 7 of 7")
        }
    }
}
