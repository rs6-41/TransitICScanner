import SwiftUI
import SwiftData

@main struct TransitICScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        
        .modelContainer(
            for: [
                SavedCard.self,
                SavedHistory.self
            ]
        )
    }
}
