import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

let dev_BannerUnitID = "ca-app-pub-3940256099942544/2435281174"
var BannerUnitIDValue = bannerUnitID

struct BannerAdsView: View {
    @State var adsHeight: CGFloat = 50.0
    @StateObject private var debugModel = DebugModel()
    @Binding var loadingError: Bool

    var body: some View {
        GeometryReader { geometry in
            let adSize = currentOrientationAnchoredAdaptiveBanner(
                width: geometry.size.width
            )

            BannerViewContainer(
                adSize: adSize,
                loadingError: $loadingError
            )
            .frame(height: adSize.size.height)
            .onAppear {
                adsHeight = adSize.size.height
            }
        }
        .frame(height: adsHeight)
    }
}

struct BannerAdsView_Previews: PreviewProvider {
    static var previews: some View {
        BannerAdsView(
            loadingError: .constant(false)
        )
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    typealias UIViewType = BannerView

    let adSize: AdSize
    @Binding var loadingError: Bool

    init(
        adSize: AdSize,
        loadingError: Binding<Bool>
    ) {
        self.adSize = adSize
        self._loadingError = loadingError
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        
        
        
        @EnvironmentObject var debug: DebugModel
        
        banner.adUnitID = BannerUnitIDValue
        banner.delegate = context.coordinator
        banner.load(Request())

        return banner
    }

    func updateUIView(
        _ uiView: BannerView,
        context: Context
    ) {}

    func makeCoordinator() -> BannerCoordinator {
        BannerCoordinator(self)
    }

    class BannerCoordinator: NSObject, BannerViewDelegate {
        let parent: BannerViewContainer

        init(_ parent: BannerViewContainer) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("DID RECEIVE AD.")

            DispatchQueue.main.async {
                self.parent.loadingError = false
            }
        }

        func bannerView(
            _ bannerView: BannerView,
            didFailToReceiveAdWithError error: Error
        ) {
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")

            DispatchQueue.main.async {
                self.parent.loadingError = true
            }
        }
    }
}
