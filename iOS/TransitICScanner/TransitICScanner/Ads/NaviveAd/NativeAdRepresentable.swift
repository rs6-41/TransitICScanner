import SwiftUI
#if !targetEnvironment(macCatalyst)
import GoogleMobileAds
#endif

struct NativeAdRepresentable: UIViewRepresentable {
    
    let nativeAd: NativeAd
    @Binding var size: CGSize
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    func makeUIView(
        context: Context
    ) -> NativeAdContainerView {
        let view = NativeAdContainerView()
        view.onSizeChanged = { newSize in
            guard newSize.width > 0,
                  newSize.height > 0 else {
                return
            }
            guard abs(size.width - newSize.width) > 0.5 ||
                    abs(size.height - newSize.height) > 0.5 else {
                return
            }
            DispatchQueue.main.async {
                size = newSize
            }
        }
        context.coordinator.configure(
            view: view,
            nativeAd: nativeAd
        )
        return view
    }
    func updateUIView(
        _ uiView: NativeAdContainerView,
        context: Context
    ) {
        uiView.onSizeChanged = { newSize in
            guard newSize.width > 0,
                  newSize.height > 0 else {
                return
            }
            guard abs(size.width - newSize.width) > 0.5 ||
                    abs(size.height - newSize.height) > 0.5 else {
                return
            }
            DispatchQueue.main.async {
                size = newSize
            }
        }
        context.coordinator.configure(
            view: uiView,
            nativeAd: nativeAd
        )
    }
    final class Coordinator {
        private weak var configuredView: NativeAdContainerView?
        private weak var configuredAd: NativeAd?
        func configure(
            view: NativeAdContainerView,
            nativeAd: NativeAd
        ) {
            guard configuredView !== view ||
                    configuredAd !== nativeAd else {
                return
            }
            configuredView = view
            configuredAd = nativeAd
            view.configure(with: nativeAd)
        }
    }
}
