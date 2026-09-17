import SwiftUI
import SwiftData
import Combine

@main struct TransitICScannerApp: App {
    
    @AppStorage("deleteAds") var deleteAds = false
    @StateObject private var debugModel = DebugModel()
    @StateObject private var getCountry = GetCountry()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardItemsStore)
                .environmentObject(debugModel)
                .environmentObject(getCountry)
        }
        .modelContainer(
            try! SavedDataModelContainer.makeContainer()
        )
    }
    
}
