import SwiftUI
import SwiftData


@main struct TransitICScannerApp: App {
    
    @AppStorage("deleteAds") var deleteAds = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            try! SavedDataModelContainer.makeContainer()
        )
    }
}
