import SwiftUI

struct ListAdView: View {
    @StateObject private var nativeAdManager = NativeAdManager()

    let index: Int
    @Binding var deleteAds: Bool

    var body: some View {
        Group {
            if !deleteAds {
                if let nativeAd = nativeAdManager.ad {
                    NativeAdRepresentable(nativeAd: nativeAd)
                        .frame(maxWidth:.infinity)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("loading")
                }
            }
        }
        .padding(.vertical)
        .task {
            nativeAdManager.loadAd()
        }
    }
}
