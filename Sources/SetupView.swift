import SwiftUI

/// First-run screen: download the model once, see file checks.
struct SetupView: View {
    @EnvironmentObject var store: ModelStore
    @EnvironmentObject var diag: DiagLog

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("One time setup")
                    .font(.title2).bold()
                Text("Download the voice model once. About 94 MB. Then the app works with no internet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(store.files, id: \.name) { file in
                    HStack {
                        Image(systemName: file.ready ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(file.ready ? .green : .gray)
                        Text(file.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }

                if store.downloading {
                    ProgressView(value: store.progress)
                    Text("File \(Int(store.progress * 7) + 1) of 7")
                        .font(.caption)
                }

                Text(store.statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button(store.allReady ? "Model Ready" : "Download Model") {
                    Task { await store.downloadAll(diag: diag) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.allReady || store.downloading)

                Spacer()
            }
            .padding()
            .navigationTitle("Setup")
            .onAppear { store.refresh() }
        }
    }
}
