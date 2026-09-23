import SwiftUI
import UIKit

struct PlaceholderAdsView: View {
    @State var icon: UIImage?
    @State var headline: String
    @State var bodyText: String?
    @State var advertiser: String?
    @State var callToAction: String?
    @State var url: URL?

    var body: some View {
        PlaceholderAdsContainerView(
            icon: icon,
            headline: headline,
            body: bodyText,
            advertiser: advertiser,
            callToAction: callToAction,
            url:url
        )
    }
}

struct PlaceholderAdsContainerView: UIViewControllerRepresentable {
    let icon: UIImage?
    let headline: String
    let body: String?
    let advertiser: String?
    let callToAction: String?
    let url: URL?

    func makeUIViewController(
        context: Context
    ) -> UIViewController {
        let headlineController = UIHostingController(
            rootView: NativeAdTextView(
                text: headline,
                font: .system(
                    size: 14,
                    weight: .semibold
                ),
                secondary: false
            )
        )

        let bodyController: UIHostingController<NativeAdTextView>?

        if let body {
            bodyController = UIHostingController(
                rootView: NativeAdTextView(
                    text: body,
                    font: .system(size: 12),
                    secondary: true
                )
            )
        } else {
            bodyController = nil
        }

        let advertiserController:
            UIHostingController<NativeAdTextView>?

        if let advertiser {
            advertiserController = UIHostingController(
                rootView: NativeAdTextView(
                    text: advertiser,
                    font: .system(size: 10),
                    secondary: true
                )
            )
        } else {
            advertiserController = nil
        }

        let iconController:
            UIHostingController<NativeAdIconView>?

        if let icon {
            iconController = UIHostingController(
                rootView: NativeAdIconView(
                    image: icon
                )
            )
        } else {
            iconController = nil
        }

        let callToActionController:
            UIHostingController<NativeAdCallToActionView>?

        if let callToAction {
            callToActionController = UIHostingController(
                rootView: NativeAdCallToActionView(
                    text: callToAction,
                    url: url
                )
            )
        } else {
            callToActionController = nil
        }

        headlineController.view.backgroundColor = .clear
        headlineController.view.isUserInteractionEnabled = false

        bodyController?.view.backgroundColor = .clear
        bodyController?.view.isUserInteractionEnabled = false

        advertiserController?.view.backgroundColor = .clear
        advertiserController?.view.isUserInteractionEnabled = false

        iconController?.view.backgroundColor = .clear
        iconController?.view.isUserInteractionEnabled = false

        callToActionController?.view.backgroundColor = .clear
        callToActionController?.view.isUserInteractionEnabled = false

        let contentView = NativeAdContentView(
            iconView: iconController?.view,
            headlineView: headlineController.view,
            bodyView: bodyController?.view,
            advertiserView: advertiserController?.view,
            callToActionView: callToActionController?.view
        )

        let controller = UIHostingController(
            rootView: contentView
        )

        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false

        context.coordinator.assetHostingControllers = [
            headlineController,
            bodyController,
            advertiserController,
            iconController,
            callToActionController
        ].compactMap {
            $0
        }

        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var assetHostingControllers: [UIViewController] = []
    }
}
