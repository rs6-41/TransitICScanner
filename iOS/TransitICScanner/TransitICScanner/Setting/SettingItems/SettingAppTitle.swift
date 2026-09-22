import SwiftUI

struct SettingAppTitle: View {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    let appEnvironment = Bundle.main.object(
        forInfoDictionaryKey: "AppEnvironment"
    ) as? String
    @Binding var devSettingAlert:Bool
    
    var body: some View {
        Section {
            VStack {
                Spacer()
                    .frame(height:50)
                HStack {
                    Spacer()
                    VStack(alignment:.center) {
                        Image("icon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .padding(.top,2)
                            .onTapGesture(count: 15) {
                                devSettingAlert = true
                            }
                        Text(LocalizedStringKey("appName"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        VStack(alignment:.center,spacing:2) {
                            HStack(spacing:5) {
                                Text(LocalizedStringKey("setting.version:\(version)"))
                                if let stage = stage() {
                                    Text(LocalizedStringKey(stage))
                                }
                            }
                            if appEnvironment == "DEV" {
                                Text("(\(buildNumber))")
                            }
                        }
                        .foregroundStyle(.gray)
                        .font(.caption)
                    }
                    .padding(.vertical,5)
                    Spacer()
                }
            }
        }
        .listRowInsets(
            .init(top: .zero,leading: .zero,bottom: .zero,trailing: .zero)
        )
        .listRowBackground(Color.clear)
        .padding(.vertical,5)
    }
    
    func stage() -> String? {
        switch appEnvironment {
        case "DEV":
            return "setting.appVersion.stage.dev"
            
        case "BETA":
            return "setting.appVersion.stage.beta"
            
        case "REL": return nil
        case .none: return nil
        case .some(_): return nil
        }
    }
}

#Preview {
    SettingAppTitle(devSettingAlert: .constant(false))
}
