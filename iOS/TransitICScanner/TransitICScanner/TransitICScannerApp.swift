import SwiftUI
import SwiftData
import Combine
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
}

@main struct TransitICScannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("deleteAds") var deleteAds = false
    @StateObject private var debugModel = DebugModel()
    @StateObject private var adsModel = AdsModel()
    @StateObject private var getCountry = GetCountry()
    
    let container: ModelContainer

    init() {
        self.container = try! SavedDataModelContainer.makeContainer()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardItemsStore)
                .environmentObject(debugModel)
                .environmentObject(getCountry)
                .environmentObject(adsModel)
                .modelContainer(container)
        }
    }
}
