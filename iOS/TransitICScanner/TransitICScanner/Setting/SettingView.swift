import SwiftUI

struct SettingView: View {
    let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Transit IC Scanner"
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    var body: some View {
        NavigationStack {
            List {
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
                                Text(appName)
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
                
                Section(header:Text("setting.ads")) {
                    Label(LocalizedStringKey("setting.ads.delete"), systemImage: "xmark.app.fill")
                    Label(LocalizedStringKey("setting.ads.restore"), systemImage: "arrow.trianglehead.clockwise")
                }
                
                Section(header:Text("setting.data")) {
                    Button(action: {
                        
                    }) {
                        Label(LocalizedStringKey("setting.data.reset"), systemImage: "trash")
                    }
                    .foregroundStyle(Color.red)
                }
                Section(header:Text(LocalizedStringKey("setting.other"))) {
                    NavigationLink(destination: AcknowledgmentView()) {
                        Text(LocalizedStringKey("setting.acknowledgment"))
                    }
                }
            }
            .listSectionSpacing(.compact)
                        .contentMargins(.top, 0)
                        .environment(\.defaultMinListRowHeight, 1)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            .zero
                        }
            .navigationTitle(LocalizedStringKey("tab.setting"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}


#Preview {
    SettingView()
}
