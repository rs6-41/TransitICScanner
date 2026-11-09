import SwiftUI

struct SettingFeatureView: View {
    @AppStorage("testCardEnabled") var isTestCardEnabled = false

    @EnvironmentObject var store: CardItemsStore

    @AppStorage("enableCardType") var enableCardType = 0
    @State var isDevCard = false

    var body: some View {
        List {
            Section() {
                Link(destination: URL(string: "https://testflight.apple.com/join/GYrHt3mb")!) {
                    SquareIcon(text: "setting.feature.testflight", systemImage: "airplane.departure", color: Color.blue)
                }
            }
            Section() {
                VStack(alignment: .leading) {
                    Toggle(isOn: $isTestCardEnabled) {
                        SquareIcon(
                            text: "setting.feature.card", subText: "setting.feature.card.description",
                            systemImage: "tram.card", color: Color.purple)
                    }
                    if isDevCard {
                        Text(LocalizedStringKey("setting.feature.card.description.devMode"))
                            .padding(.top, 3)
                            .foregroundStyle(Color.red)
                            .font(.caption)
                    }
                }
                .onChange(of: isTestCardEnabled) {
                    if isTestCardEnabled {
                        store.cardItems = featureCards + relCards
                    } else {
                        store.cardItems = relCards
                    }
                }
                .disabled(isDevCard)
            } header: {
                Text(LocalizedStringKey("setting.feature.sectionTitle"))
            } footer: {
                Text(LocalizedStringKey("setting.feature.description"))
            }
        }
        .navigationTitle(LocalizedStringKey("setting.feature"))
        .contentMargins(.top, 10)

        .onAppear() {
            checkDevCard()
        }
        .onChange(of: enableCardType) {
            checkDevCard()
        }
    }

    //開発モードでは一部設定を無効化する
    func checkDevCard() {
        if enableCardType == 0 {  //未設定
            isDevCard = false
        } else if enableCardType == 1 {  //rel
            isDevCard = false
            isTestCardEnabled = false
            isDevCard = true
        } else {  //その他
            isDevCard = false
            isTestCardEnabled = true
            isDevCard = true
        }
    }
}
