import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

struct BannerAdsView: View {
    @State var adsHeight:CGFloat = 50.0
    @StateObject private var debugModel = DebugModel()
  var body: some View {
      GeometryReader { geometry in
          let adSize = currentOrientationAnchoredAdaptiveBanner(width: (geometry.size.width))
          BannerViewContainer(adSize)
              .frame(height: adSize.size.height)
              .onAppear() {
                  adsHeight = adSize.size.height
              }
      }.frame(height: adsHeight)
  }
}

struct BannerAdsView_Previews: PreviewProvider {
  static var previews: some View {
      BannerAdsView()
  }
}

private struct BannerViewContainer: UIViewRepresentable {
    typealias UIViewType = BannerView
    let adSize: AdSize
    
    init(_ adSize: AdSize) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = "ca-app-pub-3940256099942544/2435281174"
        banner.load(Request())
        banner.delegate = context.coordinator
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    
    class BannerCoordinator: NSObject, BannerViewDelegate {
      let parent: BannerViewContainer
      init(_ parent: BannerViewContainer) {
        self.parent = parent
      }
      func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("DID RECEIVE AD.")
      }
      func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
      }
    }
}
