import SwiftUI

//TODO: カスタム広告を検証後に有効化（コメントアウトしている）

#if !targetEnvironment(macCatalyst)
struct ListAdView: View {
    @StateObject private var nativeAdManager = NativeAdManager()

    @Binding var deleteAds: Bool
    @State var isDisplayMyAppAdd = true
    @EnvironmentObject var ads: AdsModel
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.colorScheme) private var colorScheme
    @State var colorSchemeID = 0
    
    @State var myAppsAd = myAppsAds.randomElement()
    
    @State private var adSize: CGSize = CGSize(width:0, height:60)

    var body: some View {
        if !deleteAds {
            Section() {
                VStack {
                    /*
                    if let nativeAd = nativeAdManager.ad {
                        NativeAdRepresentable(nativeAd: nativeAd, size: $adSize)
                            .id(colorSchemeID)
                            .allowsHitTesting(false)
                    } else
                     */
                    if nativeAdManager.loadCompleted {
                        ZStack {
                            if isDisplayMyAppAdd {
                                myAppsAd
                                    .id(colorSchemeID)
                            }
                            BannerAdsView(loadingError: $isDisplayMyAppAdd)
                                .id(colorSchemeID)
                        }
                    } else {
                        PlaceholderAdsView(icon: UIImage(named:"twICash"),headline: String("Placeholder"),bodyText: String("PlaceholderPlaceholder"),callToAction:String("Placeholder"))
                            .redacted(reason: .placeholder)
                            .id(colorSchemeID)
                    }
                }
                .onChange(of:colorScheme) {
                    colorSchemeID += 1
                }
                .frame(minHeight: adSize.height)
                .onAppear() {
                    Task {
                        //nativeAdManager.loadAd()
                    }
                }
            } header: {
                HStack {
                    Text(LocalizedStringKey("ads"))
                    Spacer()
                    if adDeleteDisplay {
                        Button(action: {
                            ads.isDeleteAdsSheet = true
                        }) {
                            Text(LocalizedStringKey("ads.delete"))
                                .fontWeight(.regular)
                        }
                    }
                }
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

#endif
