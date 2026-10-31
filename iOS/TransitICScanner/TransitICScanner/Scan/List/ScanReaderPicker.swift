import SwiftUI

struct ScanReaderPicker: View {
    @ObservedObject var manager: SmartCardManager

    var body: some View {
        Menu {
            Section {
                Button(action: {
                    manager.selectedSource = ScanReaderSource.builtIn
                }) {
                    Label(LocalizedStringKey("cardList.reader.builtIn"),systemImage: "iphone.radiowaves.left.and.right")
                }
                if manager.hasConnectedReader {
                    Button(action: {
                        manager.selectedSource = ScanReaderSource.external
                    }) {
                        Label(LocalizedStringKey("cardList.reader.external"),systemImage: "mediastick")
                    }
                }
            } header: {
                HStack {
                    Circle()
                        .fill(
                            !manager.isAvailable
                                ? Color.red
                                : manager.hasConnectedReader
                                    ? Color.green
                                    : Color.gray
                        )
                        .frame(width: 9, height: 9)
                    Text(
                        !manager.isAvailable
                        ? String(localized: "cardList.reader.unavailable")
                        : manager.hasConnectedReader
                        ? String(localized: "cardList.reader.connected")
                        : String(localized: "cardList.reader.disconnected")
                    )
                }
            }
            
        } label: {
            switch manager.selectedSource {
                case .builtIn: Image(systemName:"iphone.radiowaves.left.and.right")
                case .external:Image(systemName:"mediastick")
            }
        }
    }
}
