import Foundation
import AVFoundation

/// Output file helpers: list, play, share, M4A copy.
enum AudioExport {
    static var outputsDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("outputs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func newOutputURL() -> URL {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return outputsDir.appendingPathComponent("voice-\(f.string(from: Date())).wav")
    }

    static func listOutputs() -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: outputsDir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files
            .filter { $0.pathExtension.lowercased() == "wav" || $0.pathExtension.lowercased() == "m4a" }
            .sorted {
                let d0 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let d1 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return d0 > d1
            }
    }

    /// Make an M4A copy next to the WAV. Returns its URL or nil.
    static func makeM4A(from wavURL: URL) async -> URL? {
        let m4aURL = wavURL.deletingPathExtension().appendingPathExtension("m4a")
        if FileManager.default.fileExists(atPath: m4aURL.path) {
            try? FileManager.default.removeItem(at: m4aURL)
        }
        let asset = AVURLAsset(url: wavURL)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return nil
        }
        session.outputURL = m4aURL
        session.outputFileType = .m4a
        await session.export()
        guard session.status == .completed else {
            return nil
        }
        return m4aURL
    }
}
