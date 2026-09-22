import SwiftUI

struct ListAdView: View {
    @StateObject private var nativeAdManager = NativeAdManager()

    @Binding var deleteAds: Bool

    var body: some View {
        ZStack {
            if !deleteAds {
                if let nativeAd = nativeAdManager.ad {
                    NativeAdRepresentable(nativeAd: nativeAd)
                        .frame(height:60)
                } else {
                    //BannerAdsView()
                }
            }
        }
        .task {
            nativeAdManager.loadAd()
        }
    }
}
