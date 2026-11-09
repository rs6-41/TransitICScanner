import SwiftUI

struct SettingAppTitle: View {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    let appEnvironment = AppEnvironment.current
    @Binding var devSettingAlert: Bool

    var body: some View {
        Section {
            VStack {
                Spacer()
                    .frame(height: 50)
                HStack {
                    Spacer()
                    VStack(alignment: .center) {
                        Image("icon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .padding(.top, 2)
                            .onTapGesture(count: 15) {
                                devSettingAlert = true
                            }
                        Text(LocalizedStringKey("appName"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        VStack(alignment: .center, spacing: 2) {
                            HStack(spacing: 5) {
                                Text(LocalizedStringKey("setting.version:\(version)"))
                                if let stage = stage() {
                                    Text(LocalizedStringKey(stage))
                                }
                            }
                            if appEnvironment == .dev {
                                Text(String("(\(buildNumber))"))
                            }
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    }
                    .padding(.vertical, 5)
                    Spacer()
                }
            }
        }
        .listRowInsets(
            .init(top: .zero, leading: .zero, bottom: .zero, trailing: .zero)
        )
        .listRowBackground(Color.clear)
        .padding(.vertical, 5)
    }

    func stage() -> String? {
        switch appEnvironment {
        case .dev:
            return "setting.appVersion.stage.dev"

        case .beta:
            return "setting.appVersion.stage.beta"

        case .rel: return nil
        }
    }
}

#Preview {
    SettingAppTitle(devSettingAlert: .constant(false))
}
