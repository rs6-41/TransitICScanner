import SwiftUI
import CoreNFC

struct ScanReaderPicker: View {
    @ObservedObject var manager: SmartCardManager

    var body: some View {
        Menu {
            Section {
                Picker("",selection: $manager.selectedSource) {
                    if NFCReaderSession.readingAvailable {
                        Label(LocalizedStringKey("cardList.reader.builtIn"),systemImage: "iphone.radiowaves.left.and.right")
                            .tag(ScanReaderSource.builtIn)
                    }
                    
                    if manager.hasConnectedReader {
                        Label(LocalizedStringKey("cardList.reader.external"),systemImage: "mediastick")
                            .tag(ScanReaderSource.external)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onAppear() {
                    if !manager.hasConnectedReader {
                        manager.selectedSource = ScanReaderSource.builtIn
                    }
                    if !NFCReaderSession.readingAvailable {
                        manager.selectedSource = ScanReaderSource.external
                    }
                }
                .onChange(of:manager.hasConnectedReader) {
                    // iPhoneで外部リーダーが切断されたら内蔵リーダーに切り替える
                    if !manager.hasConnectedReader && NFCReaderSession.readingAvailable {
                        manager.selectedSource = ScanReaderSource.builtIn
                    }
                    // 外部リーダーが接続されたら切り替える
                    if manager.hasConnectedReader {
                        manager.selectedSource = ScanReaderSource.external
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
            
            .tint(Color(.label))
            
        } label: {
            switch manager.selectedSource {
            case .builtIn:
                if NFCReaderSession.readingAvailable {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                }

            case .external:
                if manager.hasConnectedReader {
                    Image(systemName: "mediastick")
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
            }
        }
        .connectedReaderBackground(manager)
        .connectedReaderLabelColor(manager)
    }
}

extension View {
    @ViewBuilder
    func connectedReaderBackground(_ manager: SmartCardManager) -> some View {
        if !manager.isAvailable {
            self
        } else {
            if manager.hasConnectedReader {
                self
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green)
            } else {
                self
            }
        }
    }
    
    @ViewBuilder
    func connectedReaderLabelColor(_ manager: SmartCardManager) -> some View {
        if manager.selectedSource == .builtIn && NFCReaderSession.readingAvailable {
            self
        } else if manager.selectedSource == .external && manager.hasConnectedReader {
            self
        } else {
            self.tint(Color.yellow)
        }
    }
}
