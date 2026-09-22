import SwiftUI
import UIKit
import GoogleMobileAds
import Observation

@Observable class adSetting {
    let icon:CGFloat = 48.0
    var textWidth:CGFloat = 150
    var textPadding:CGFloat = 8
    var buttonWidth:CGFloat = 100
    var viewSize = 0.0
    var viewUsed = 0.0
}

struct NativeAdContentView: View {
    let iconView: UIView?
    let headlineView: UIView
    let bodyView: UIView?
    let advertiserView: UIView?
    let callToActionView: UIView?
    
    @State var setting = adSetting()
    

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Color(.systemGroupedBackground)
                    .allowsHitTesting(false)
                    .opacity(0.001)
                    .onAppear() {
                        setting.viewSize = geometry.size.width
                        checkTextWidth()
                    }
                    .onChange(of:geometry.size.width) {
                        setting.viewSize = geometry.size.width
                        checkTextWidth()
                    }
            }.allowsHitTesting(false)
            VStack(alignment:.leading) {
                HStack(alignment:.center,spacing:0) {
                    
                    if let iconView {
                        ExistingUIView(view: iconView)
                            .frame(width: setting.icon, height: setting.icon)
                            .onAppear() {
                                setting.viewUsed += setting.icon
                                checkTextWidth()
                            }
                            .onDisappear() {
                                setting.viewUsed -= setting.icon
                            }
                    }
                    VStack(alignment:.leading,spacing: 0) {
                        ExistingUIView(view: headlineView)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .allowsHitTesting(false)
                        if let bodyView {
                            ExistingUIView(view: bodyView)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .allowsHitTesting(false)
                        }
                        if let advertiserView {
                            ExistingUIView(view: advertiserView)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    if let callToActionView {
                        ExistingUIView(view: callToActionView)
                            .frame(width:setting.buttonWidth)
                    }
                }
            }
        }
        .environment(setting)
    }
    func checkTextWidth() {
        setting.textWidth = setting.viewSize - setting.viewUsed - (setting.textPadding * 2)
    }
}

struct ExistingUIView: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> UIView {
        view
    }

    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {
    }
}

struct NativeAdTextView: View {
    let text: String
    let font: Font
    let color: Color
    @Environment(adSetting.self) private var setting

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .padding(.vertical,0)
            .padding(.horizontal,setting.textPadding)
            .frame(
                width: setting.textWidth,
                alignment: .leading
            )
    }
}

struct NativeAdIconView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(
                width: adSetting().icon,
                height: adSetting().icon
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
    }
}

struct NativeAdCallToActionView: View {
    let text: String
    @State var url: URL?
    @Environment(adSetting.self) private var setting
    
    @Environment(\.openURL) var openURL

    var body: some View {
        ZStack {
            if let url {
                Button(action: {
                    openURL(url)
                }) {
                    NativeAdCallToActionButton(text:text)
                }
            } else {
                NativeAdCallToActionButton(text:text)
            }
        }
    }
}
struct NativeAdCallToActionButton: View {
    let text: String
    @Environment(adSetting.self) private var setting

    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: 13,weight: .semibold))
                .foregroundStyle(.white)
                .frame(minHeight: 32)
                .padding(.horizontal,setting.textPadding)
                .background(
                    GeometryReader { geometry in
                        Color.blue
                            .clipShape(.rect(cornerRadius: 30))
                            .onAppear {
                                setting.buttonWidth = geometry.size.width
                                setting.viewUsed += geometry.size.width
                                setting.textWidth = setting.viewSize - setting.viewUsed
                            }
                            .onDisappear {
                                setting.viewUsed -= geometry.size.width
                            }
                            .onChange(of:geometry.size.width) {
                                setting.buttonWidth = geometry.size.width
                                setting.viewUsed += geometry.size.width
                                setting.textWidth = setting.viewSize - setting.viewUsed
                            }
                    }
                )
        }
    }
}

final class NativeAdContainerView: NativeAdView {
    private var hostingController:
        UIHostingController<NativeAdContentView>?

    private var assetHostingControllers:
        [UIViewController] = []

    private var configuredAd: NativeAd?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        backgroundColor = UIColor.clear
    }

    func configure(with nativeAd: NativeAd) {
        guard configuredAd !== nativeAd else {
            return
        }

        configuredAd = nativeAd

        hostingController?.view.removeFromSuperview()
        hostingController = nil
        assetHostingControllers.removeAll()

        let headlineController = UIHostingController(
            rootView: NativeAdTextView(
                text: nativeAd.headline ?? "",
                font: .system(
                    size: 14,
                    weight: .semibold
                ),
                color: .primary
            )
        )

        let bodyController:
            UIHostingController<NativeAdTextView>?

        if let body = nativeAd.body {
            bodyController = UIHostingController(
                rootView: NativeAdTextView(
                    text: body,
                    font: .system(size: 12),
                    color: .secondary
                )
            )
        } else {
            bodyController = nil
        }

        let advertiserController:
            UIHostingController<NativeAdTextView>?

        if let advertiser = nativeAd.advertiser {
            advertiserController = UIHostingController(
                rootView: NativeAdTextView(
                    text: advertiser,
                    font: .system(size: 10),
                    color: .secondary
                )
            )
        } else {
            advertiserController = nil
        }

        let iconController:
            UIHostingController<NativeAdIconView>?

        if let image = nativeAd.icon?.image {
            iconController = UIHostingController(
                rootView: NativeAdIconView(
                    image: image
                )
            )
        } else {
            iconController = nil
        }

        let callToActionController:
            UIHostingController<NativeAdCallToActionView>?

        if let callToAction = nativeAd.callToAction {
            callToActionController = UIHostingController(
                rootView: NativeAdCallToActionView(
                    text: callToAction
                )
            )
        } else {
            callToActionController = nil
        }

        guard let headlineView = headlineController.view else {
            return
        }

        headlineView.backgroundColor = UIColor.clear
        headlineView.isUserInteractionEnabled = false

        let bodyView = bodyController?.view
        bodyView?.backgroundColor = UIColor.clear
        bodyView?.isUserInteractionEnabled = false

        let advertiserView = advertiserController?.view
        advertiserView?.backgroundColor = UIColor.clear
        advertiserView?.isUserInteractionEnabled = false

        let iconView = iconController?.view
        iconView?.backgroundColor = UIColor.clear
        iconView?.isUserInteractionEnabled = false

        let callToActionView = callToActionController?.view
        callToActionView?.backgroundColor = UIColor.clear
        callToActionView?.isUserInteractionEnabled = false

        assetHostingControllers = [
            headlineController,
            bodyController,
            advertiserController,
            iconController,
            callToActionController
        ].compactMap {
            $0
        }

        self.headlineView = headlineView
        self.bodyView = bodyView
        self.advertiserView = advertiserView
        self.iconView = iconView
        self.callToActionView = callToActionView

        let contentView = NativeAdContentView(
            iconView: iconView,
            headlineView: headlineView,
            bodyView: bodyView,
            advertiserView: advertiserView,
            callToActionView: callToActionView
        )

        let controller = UIHostingController(
            rootView: contentView
        )

        guard let controllerView = controller.view else {
            return
        }

        controllerView.backgroundColor = UIColor.clear
        controllerView.isUserInteractionEnabled = false
        controllerView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(controllerView)

        NSLayoutConstraint.activate([
            controllerView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            controllerView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            controllerView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            controllerView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            )
        ])

        hostingController = controller

        self.nativeAd = nativeAd
    }
}
