import SwiftUI

struct ListAdView: View {
    @StateObject private var nativeAdManager = NativeAdManager()

    @Binding var deleteAds: Bool
    @State var isDisplayMyAppAdd = true

    var body: some View {
        VStack() {
            if !deleteAds {
                if let nativeAd = nativeAdManager.ad {
                    NativeAdRepresentable(nativeAd: nativeAd)
                } else if nativeAdManager.loadCompleted {
                    ZStack {
                        BannerAdsView(loadingError: $isDisplayMyAppAdd)
                        if isDisplayMyAppAdd {
                            myAppsAds.randomElement()
                        }
                    }
                } else {
                    PlaceholderAdsView(icon: UIImage(named:"twICash"),headline: String("Placeholder"),bodyText: String("PlaceholderPlaceholder"),callToAction:String("Placeholder"))
                        .redacted(reason: .placeholder)
                }
            }
        }
        .frame(height: 60)
        .onAppear() {
            Task {
                nativeAdManager.loadAd()
            }
        }
    }
    func placeholderImage() -> UIImage? {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
