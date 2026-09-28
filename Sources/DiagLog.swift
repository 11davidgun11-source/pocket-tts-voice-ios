import Foundation

/// Simple on-screen log. Same idea as the web Diagnostics Log.
final class DiagLog: ObservableObject {
    @Published var lines: [String] = []

    private func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }

    func add(_ text: String) {
        let line = "[\(stamp())] \(text)"
        DispatchQueue.main.async {
            self.lines.append(line)
            if self.lines.count > 200 {
                self.lines.removeFirst(self.lines.count - 200)
            }
        }
    }

    func clear() {
        DispatchQueue.main.async { self.lines.removeAll() }
    }

    var fullText: String { lines.joined(separator: "\n") }
}
