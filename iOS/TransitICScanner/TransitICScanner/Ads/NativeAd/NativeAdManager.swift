import Foundation
import Combine
import GoogleMobileAds
import SwiftUI

let dev_NativeAdUnitID =
    "ca-app-pub-3940256099942544/3986624511"

var NativeAdUnitIDValue = NativeUnitID

final class NativeAdManager: NSObject, ObservableObject {
    @Published private(set) var ad: NativeAd?
    @Published private(set) var loadCompleted = false

    private var adLoader: AdLoader?

    func loadAd() {
        guard AdConsentManager.shared.canRequestAds else {
            return
        }

        guard ad == nil, !loadCompleted else {
            return
        }

        let imageOptions =
            NativeAdImageAdLoaderOptions()

        imageOptions.isImageLoadingDisabled = true
        imageOptions.shouldRequestMultipleImages = false

        let mediaOptions =
            NativeAdMediaAdLoaderOptions()

        mediaOptions.mediaAspectRatio = .square

        let viewOptions =
            NativeAdViewAdOptions()

        viewOptions.preferredAdChoicesPosition =
            .bottomRightCorner

        let loader = AdLoader(
            adUnitID: NativeAdUnitIDValue,
            rootViewController: nil,
            adTypes: [.native],
            options: [
                imageOptions,
                mediaOptions,
                viewOptions,
            ]
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
            self?.loadCompleted = true
        }
    }

    func adLoader(
        _ adLoader: AdLoader,
        didFailToReceiveAdWithError error: Error
    ) {
        Log.debug(
            "Native Ad Load Failed: \(error.localizedDescription)"
        )

        DispatchQueue.main.async { [weak self] in
            self?.loadCompleted = true
        }
    }
}

extension NativeAdManager: NativeAdDelegate {
    func nativeAdDidRecordImpression(
        _ nativeAd: NativeAd
    ) {
    }

    func nativeAdDidRecordClick(
        _ nativeAd: NativeAd
    ) {
    }

    func nativeAdWillPresentScreen(
        _ nativeAd: NativeAd
    ) {
    }

    func nativeAdWillDismissScreen(
        _ nativeAd: NativeAd
    ) {
    }

    func nativeAdDidDismissScreen(
        _ nativeAd: NativeAd
    ) {
    }

    func nativeAdWillLeaveApplication(
        _ nativeAd: NativeAd
    ) {
    }
}
