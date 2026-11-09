import SwiftUI
import UIKit

struct PlaceholderAdsView: View {
    @State var icon: UIImage?
    @State var headline: String
    @State var bodyText: String?
    @State var advertiser: String?
    @State var callToAction: String?
    @State var url: URL?
    @Environment(\.openURL) var openURL

    var body: some View {
        HStack {
            if let icon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey(headline))
                    .fontWeight(.semibold)
                Group {
                    if let bodyText {
                        Text(LocalizedStringKey(bodyText))
                    }
                    if let advertiser {
                        Text(LocalizedStringKey(advertiser))
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(Color.gray)
                .lineLimit(3)
            }
            Spacer()
            if let url {
                Button(action: {
                    openURL(url)
                }) {
                    Text(LocalizedStringKey(callToAction ?? "ads.placeholder.myapp.button"))
                }
                .font(.system(size: 14))
                .allowsHitTesting(true)
                .fontWeight(.semibold)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(50)
                .glassEffect()
            }
        }
    }
}
