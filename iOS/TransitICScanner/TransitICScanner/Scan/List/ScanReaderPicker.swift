import SwiftUI
import CoreNFC

struct ScanReaderPicker: View {
    @ObservedObject var manager: SmartCardManager

    private static let builtInSelectionID = "__builtInReader__"

    private var readerSelection: Binding<String> {
        Binding(
            get: {
                if manager.selectedSource == .builtIn {
                    return Self.builtInSelectionID
                }
                return manager.selectedReaderID
                    ?? manager.readers.first?.id
                    ?? Self.builtInSelectionID
            },
            set: { selection in
                if selection == Self.builtInSelectionID {
                    manager.selectReader(source: .builtIn)
                } else {
                    manager.selectReader(source: .external, readerID: selection)
                }
            }
        )
    }

    var body: some View {
        Menu {
            Section {
                Picker("", selection: readerSelection) {
                    if NFCReaderSession.readingAvailable {
                        Label(
                            LocalizedStringKey("cardList.reader.builtIn"),
                            systemImage: "iphone.radiowaves.left.and.right"
                        )
                        .tag(Self.builtInSelectionID)
                    }

                    ForEach(manager.readers) { reader in
                        Label(reader.name, systemImage: "mediastick")
                            .tag(reader.id)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
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
