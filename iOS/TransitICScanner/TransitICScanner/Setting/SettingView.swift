import SwiftUI
import SwiftData
import StoreKit

struct SettingView: View {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    @Environment(\.modelContext) private var modelContext
    @State var deleteAlert = false
    @AppStorage("deleteAds") var deleteAds = false
    
    @AppStorage("cloudSyncEnabled") var isCloudSyncEnabled = true
    @State var isIcloud = false
    @State var iCloudAlert = false
    
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
                
                if !deleteAds {
                    Section(header:Text("setting.ads")) {
                        HStack {
                            SquareIcon(text:"", systemImage: "xmark.app.fill",color:Color.green)
                            ProductView(id: "delete_ads")
                                .productViewStyle(.compact)
                        }
                        SquareIcon(text:"setting.ads.restore", systemImage: "arrow.counterclockwise.circle",color:Color.orange)
                    }
                }
                
                Section(header:Text("setting.data")) {
                    HStack {
                        Toggle(isOn: $isIcloud) {
                            SquareIcon(text:"setting.data.cloud", systemImage: "icloud.fill",color:Color.blue)
                        }
                        Spacer()
                            .frame(width:10)
                    }
                    .onAppear() {
                        isIcloud = isCloudSyncEnabled
                    }
                    .onChange(of: isIcloud) {
                        if isIcloud == false {
                            iCloudAlert = true
                        } else {
                            isCloudSyncEnabled = true
                        }
                    }
                    .alert(LocalizedStringKey("setting.data.cloud.off"), isPresented: $iCloudAlert) {
                       Button(LocalizedStringKey("setting.data.cloud.off.ok"), role: .destructive) {
                           isCloudSyncEnabled = false
                       }
                       Button(LocalizedStringKey("cancel"), role: .cancel) {
                           isIcloud = true
                       }
                    } message: {
                        Text(LocalizedStringKey("setting.data.cloud.off.message"))
                    }
                    
                    
                    Button(action: {
                        deleteAlert.toggle()
                    }) {
                        SquareIcon(text:"setting.data.reset", systemImage: "trash",color:Color.red)
                    }
                    .foregroundStyle(Color.red)
                }
                .alert(LocalizedStringKey("setting.data.reset"), isPresented: $deleteAlert) {
                   Button(LocalizedStringKey("setting.data.reset.ok"), role: .destructive) {
                       deleteAll()
                   }
                   Button(LocalizedStringKey("cancel"), role: .cancel) {}
                } message: {
                    Text(LocalizedStringKey("setting.data.reset.message"))
                }
                
                Section(header:Text(LocalizedStringKey("setting.other"))) {
                    NavigationLink(destination: AcknowledgmentView()) {
                        SquareIcon(text:"setting.acknowledgment", systemImage: "info.bubble.fill",color:Color.gray)
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
    @MainActor
    func deleteAll() {
        do {
            try ResultSave.deleteAll(from: modelContext)
        } catch {
            
        }
    }
}


#Preview {
    SettingView()
}
