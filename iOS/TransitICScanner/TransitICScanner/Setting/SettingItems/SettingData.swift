import SwiftUI
import SwiftData

struct SettingData: View {
    @State var isIcloud = false
    @State var iCloudAlert = false
    @Binding var isCloudSyncEnabled:Bool
    @State var deleteAlert = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
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
            .onChange(of:isCloudSyncEnabled) {
                CloudSyncSettings.setEnabled(isCloudSyncEnabled)
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
    }
    @MainActor
    private func deleteAll() {
        do {
            try ResultSave.deleteAll(from: modelContext)
        } catch {
            StorageErrorNotifier.shared.report(error, operation: "保存データの全件削除")
        }
    }
}
