import SwiftUI

/// Same Diagnostics Log idea as the web UI. Copy it to report a problem.
struct LogView: View {
    @EnvironmentObject var diag: DiagLog

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text(diag.fullText.isEmpty ? "Log is empty." : diag.fullText)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                HStack {
                    Button("Copy") {
                        UIPasteboard.general.string = diag.fullText
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Clear", role: .destructive) {
                        diag.clear()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Log")
        }
    }
}
