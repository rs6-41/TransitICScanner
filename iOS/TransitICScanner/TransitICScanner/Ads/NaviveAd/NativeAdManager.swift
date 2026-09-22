import Foundation
import Combine
import GoogleMobileAds

final class NativeAdManager: NSObject, ObservableObject {
    @Published private(set) var ad: NativeAd?

    private var adLoader: AdLoader?

    private let adUnitID = "ca-app-pub-3940256099942544/3986624511"

    func loadAd() {
        guard ad == nil else {
            return
        }

        let loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )

        loader.delegate = self
        adLoader = loader

        loader.load(Request())
    }
}

extension NativeAdManager: NativeAdLoaderDelegate {
    func adLoader(
        _ adLoader: AdLoader,
        didReceive nativeAd: NativeAd
    ) {
        nativeAd.delegate = self

        DispatchQueue.main.async { [weak self] in
            self?.ad = nativeAd
        }
    }

    func adLoader(
        _ adLoader: AdLoader,
        didFailToReceiveAdWithError error: Error
    ) {
        print("Native Ad Load Failed: \(error.localizedDescription)")
    }
}

extension NativeAdManager: NativeAdDelegate {
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
    }

    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
    }

    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
    }

    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
    }

    func nativeAdWillLeaveApplication(_ nativeAd: NativeAd) {
    }
}
