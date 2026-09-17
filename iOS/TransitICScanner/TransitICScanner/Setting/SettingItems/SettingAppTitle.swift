import SwiftUI

struct SettingAppTitle: View {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
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
                        Text(LocalizedStringKey("appName"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(LocalizedStringKey("setting.version:\(version)"))
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
}

#Preview {
    SettingAppTitle()
}
