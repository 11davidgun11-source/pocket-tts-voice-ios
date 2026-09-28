import SwiftUI

@main
struct PocketVoiceApp: App {
    @StateObject private var modelStore = ModelStore()
    @StateObject private var diag = DiagLog()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelStore)
                .environmentObject(diag)
        }
    }
}
