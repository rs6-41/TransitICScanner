import SwiftUI
import UIKit
import GoogleMobileAds
import Observation

@Observable
class adSetting {
    let icon: CGFloat = 48.0
    var textWidth: CGFloat = 150
    var viewSize: CGFloat = 0.0
    var viewUsed: CGFloat = 0.0
}

struct NativeAdContentView: View {
    let iconView: UIView?
    let mediaView: UIView?
    let headlineView: UIView?
    let bodyView: UIView?
    let advertiserView: UIView?
    let callToActionView: UIView?

    private let setting = adSetting()

    var body: some View {
        HStack(spacing: 8) {
            if let mediaView {
                ExistingUIView(view: mediaView)
                    .frame(width: 120, height: 120)
            } else if let iconView {
                ExistingUIView(view: iconView)
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 0) {
                if let headlineView {
                    ExistingUIView(view: headlineView)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let bodyView {
                    ExistingUIView(view: bodyView)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let advertiserView {
                    ExistingUIView(view: advertiserView)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let callToActionView {
                    ExistingUIView(view: callToActionView)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct ExistingUIView: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> UIView {
        view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

struct NativeAdTextView: View {
    let text: String
    let font: Font
    let secondary: Bool
    let lineLimit: Int

    init(
        text: String,
        font: Font = .body,
        secondary: Bool = false,
        lineLimit: Int = 1
    ) {
        self.text = text
        self.font = font
        self.secondary = secondary
        self.lineLimit = lineLimit
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(secondary ? .secondary : .primary)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
            .allowsHitTesting(false)
    }
}

struct NativeAdIconView: View {
    let image: UIImage?
    let size: CGFloat

    init(
        image: UIImage?,
        size: CGFloat = 48
    ) {
        self.image = image
        self.size = size
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .allowsHitTesting(false)
    }
}

struct NativeAdCallToActionView: View {
    let text: String
    let url: URL?

    init(
        text: String,
        url: URL?
    ) {
        self.text = text
        self.url = url
    }

    var body: some View {
        if let url {
            Link(destination: url) {
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentColor)
                    )
                    .allowsHitTesting(true)
            }
        } else {
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor)
                )
                .allowsHitTesting(false)
        }
    }
}

private struct NativeAdTextHostingView: View {
    let text: String
    let font: Font
    let secondary: Bool
    let lineLimit: Int

    var body: some View {
        NativeAdTextView(
            text: text,
            font: font,
            secondary: secondary,
            lineLimit: lineLimit
        )
    }
}

private struct NativeAdIconHostingView: View {
    let image: UIImage?
    let size: CGFloat

    var body: some View {
        NativeAdIconView(
            image: image,
            size: size
        )
    }
}

private struct NativeAdCallToActionHostingView: View {
    let text: String

    var body: some View {
        NativeAdCallToActionView(
            text: text,
            url: nil
        )
    }
}

final class NativeAdContainerView: NativeAdView {

    var onSizeChanged: ((CGSize) -> Void)?

    private let contentStack = UIStackView()
    private let textStack = UIStackView()

    private var assetHostingControllers: [UIViewController] = []

    private var lastReportedSize: CGSize = .zero

    private var configuredAd: NativeAd?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.distribution = .fill
        contentStack.spacing = 8

        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.distribution = .fill
        textStack.spacing = 4

        addSubview(contentStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let newSize = bounds.size

        guard newSize.width > 0,
              newSize.height > 0 else {
            return
        }

        guard abs(newSize.width - lastReportedSize.width) > 0.5 ||
              abs(newSize.height - lastReportedSize.height) > 0.5 else {
            return
        }

        lastReportedSize = newSize

        let callback = onSizeChanged

        DispatchQueue.main.async {
            callback?(newSize)
        }
    }

    func configure(with nativeAd: NativeAd) {
        guard configuredAd !== nativeAd else {
            return
        }

        clearAdViews()

        configuredAd = nativeAd

        let setting = adSetting()

        let headlineController = UIHostingController(
            rootView: NativeAdTextHostingView(
                text: nativeAd.headline ?? "",
                font: .system(size:12),
                secondary: false,
                lineLimit: 1
            )
        )

        assetHostingControllers.append(headlineController)

        let headlineView = headlineController.view!

        headlineView.backgroundColor = .clear
        headlineView.isUserInteractionEnabled = false
        headlineView.translatesAutoresizingMaskIntoConstraints = false

        textStack.addArrangedSubview(headlineView)

        self.headlineView = headlineView

        if let body = nativeAd.body,
           !body.isEmpty {

            let bodyController = UIHostingController(
                rootView: NativeAdTextHostingView(
                    text: body,
                    font: .system(size:11),
                    secondary: true,
                    lineLimit:2
                )
            )

            assetHostingControllers.append(bodyController)

            let bodyView = bodyController.view!

            bodyView.backgroundColor = .clear
            bodyView.isUserInteractionEnabled = false
            bodyView.translatesAutoresizingMaskIntoConstraints = false

            textStack.addArrangedSubview(bodyView)

            self.bodyView = bodyView
        }

        if let advertiser = nativeAd.advertiser,
           !advertiser.isEmpty {

            let advertiserController = UIHostingController(
                rootView: NativeAdTextHostingView(
                    text: advertiser,
                    font: .system(size:10),
                    secondary: true,
                    lineLimit: 1
                )
            )

            assetHostingControllers.append(advertiserController)

            let advertiserView = advertiserController.view!

            advertiserView.backgroundColor = .clear
            advertiserView.isUserInteractionEnabled = false
            advertiserView.translatesAutoresizingMaskIntoConstraints = false

            textStack.addArrangedSubview(advertiserView)

            self.advertiserView = advertiserView
        }

        if let callToAction = nativeAd.callToAction,
           !callToAction.isEmpty {

            let ctaController = UIHostingController(
                rootView: NativeAdCallToActionHostingView(
                    text: callToAction
                )
            )

            assetHostingControllers.append(ctaController)

            let ctaView = ctaController.view!

            ctaView.backgroundColor = .clear
            ctaView.isUserInteractionEnabled = false
            ctaView.translatesAutoresizingMaskIntoConstraints = false

            textStack.addArrangedSubview(ctaView)

            self.callToActionView = ctaView
        }

        let hasMedia =
            nativeAd.mediaContent.hasVideoContent ||
            nativeAd.mediaContent.mainImage != nil

        if hasMedia {
            let mediaView = MediaView()

            mediaView.translatesAutoresizingMaskIntoConstraints = false
            mediaView.contentMode = .scaleAspectFill
            mediaView.clipsToBounds = true
            mediaView.layer.cornerRadius = 8
            mediaView.mediaContent = nativeAd.mediaContent

            contentStack.addArrangedSubview(mediaView)

            NSLayoutConstraint.activate([
                mediaView.widthAnchor.constraint(equalToConstant: 120),
                mediaView.heightAnchor.constraint(equalToConstant: 120)
            ])

            self.mediaView = mediaView

        } else if let icon = nativeAd.icon?.image {

            let iconController = UIHostingController(
                rootView: NativeAdIconHostingView(
                    image: icon,
                    size: setting.icon
                )
            )

            assetHostingControllers.append(iconController)

            let iconView = iconController.view!

            iconView.backgroundColor = .clear
            iconView.isUserInteractionEnabled = false
            iconView.translatesAutoresizingMaskIntoConstraints = false

            contentStack.addArrangedSubview(iconView)

            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: setting.icon),
                iconView.heightAnchor.constraint(equalToConstant: setting.icon)
            ])

            self.iconView = iconView
        }

        textStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentStack.topAnchor),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentStack.bottomAnchor)
        ])

        self.nativeAd = nativeAd

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func clearAdViews() {
        nativeAd = nil

        headlineView = nil
        bodyView = nil
        advertiserView = nil
        iconView = nil
        mediaView = nil
        callToActionView = nil

        for controller in assetHostingControllers {
            controller.view.removeFromSuperview()
            controller.removeFromParent()
        }

        assetHostingControllers.removeAll()

        while let view = contentStack.arrangedSubviews.first {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        while let view = textStack.arrangedSubviews.first {
            textStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

