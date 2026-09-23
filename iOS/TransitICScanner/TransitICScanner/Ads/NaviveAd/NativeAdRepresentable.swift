import SwiftUI
import GoogleMobileAds

struct NativeAdRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdContainerView {
        NativeAdContainerView()
    }

    func updateUIView(
        _ uiView: NativeAdContainerView,
        context: Context
    ) {
        uiView.configure(with: nativeAd)
    }
}
