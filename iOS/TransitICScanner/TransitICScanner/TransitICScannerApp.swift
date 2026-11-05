import SwiftUI
import SwiftData
import Combine
#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
#endif


class AppDelegate: UIResponder, UIApplicationDelegate {
#if !targetEnvironment(macCatalyst)
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
    #endif
}

@main
struct TransitICScannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("deleteAds") var deleteAds = false
    @StateObject private var debugModel = DebugModel()
    @StateObject private var adsModel = AdsModel()
    @StateObject private var getCountry = GetCountry()
    
    @StateObject var smartCardManager = SmartCardManager()

    let container: ModelContainer

    init() {
        do {
            self.container = try SavedDataModelContainer.makeContainer()
        } catch {
            fatalError(
                "ModelContainerを作成できません: \(error)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(smartCardManager: smartCardManager)
                .environmentObject(cardItemsStore)
                .environmentObject(debugModel)
                .environmentObject(getCountry)
                .environmentObject(adsModel)
                .navigationTitle(" ")
                .background {
                    WindowAccessor()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .help) {}
        }
        .modelContainer(container)
    }
}


struct WindowAccessor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        DispatchQueue.main.async {
            #if targetEnvironment(macCatalyst)
            view.window?.windowScene?.titlebar?.titleVisibility = .hidden
            #endif
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
