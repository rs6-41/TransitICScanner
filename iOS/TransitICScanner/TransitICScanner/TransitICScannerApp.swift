import SwiftUI
import SwiftData
import Combine

@main struct TransitICScannerApp: App {
    
    @AppStorage("deleteAds") var deleteAds = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardItemsStore)
                .onAppear() {
                    cardSetup()
                }
        }
        .modelContainer(
            try! SavedDataModelContainer.makeContainer()
        )
    }
    func cardSetup() {
        #if DEBUG
            cardItemsStore.cardItems = devCards
        #else
            cardItemsStore.cardItems = relCards
        #endif
    }
}
