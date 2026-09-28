import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ModelStore
    @EnvironmentObject var diag: DiagLog

    var body: some View {
        TabView {
            SpeakView()
                .tabItem { Label("Speak", systemImage: "megaphone") }
            RecordView()
                .tabItem { Label("My Voice", systemImage: "mic") }
            FilesView()
                .tabItem { Label("Files", systemImage: "folder") }
            SetupView()
                .tabItem { Label("Setup", systemImage: "gear") }
            LogView()
                .tabItem { Label("Log", systemImage: "list.bullet") }
        }
        .onAppear {
            store.refresh()
            diag.add("app start")
        }
    }
}
