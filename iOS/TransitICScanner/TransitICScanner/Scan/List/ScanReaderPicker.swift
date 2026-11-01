import SwiftUI
import CoreNFC

struct ScanReaderPicker: View {
    @ObservedObject var manager: SmartCardManager
    var showsIconAndText = false

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
                Text(
                    !manager.isAvailable
                    ? String(localized: "cardList.reader.unavailable")
                    : manager.hasConnectedReader
                    ? String(localized: "cardList.reader.connected")
                    : String(localized: "cardList.reader.disconnected")
                )
            }
            .tint(Color(.label))

        } label: {
            if showsIconAndText {
                VStack(alignment:.leading) {
                    Text(LocalizedStringKey("navigation.readerSelection"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray)
                        .padding(.bottom,1)
                    Label {
                        switch manager.selectedSource {
                        case .builtIn:
                            if NFCNDEFReaderSession.readingAvailable {
                                Text(LocalizedStringKey("cardList.reader.builtIn"))
                            } else {
                                Text(LocalizedStringKey("cardList.reader.enptyReader"))
                            }
                        case .external:
                            if let selectedReader = manager.readers.first(where: {
                                $0.id == manager.selectedReaderID
                            }) {
                                Text(verbatim: selectedReader.name)
                            } else {
                                Text(LocalizedStringKey("cardList.external.title"))
                            }
                        }
                    } icon: {
                        Image(systemName: selectedReaderSymbol)
                    }
                }
            } else {
                Image(systemName: selectedReaderSymbol)
            }
        }
        .readerPickerStyle(manager, showsIconAndText: showsIconAndText)
    }

    private var selectedReaderSymbol: String {
        switch manager.selectedSource {
        case .builtIn:
            NFCReaderSession.readingAvailable
                ? "iphone.radiowaves.left.and.right"
                : "exclamationmark.triangle.fill"
        case .external:
            manager.hasConnectedReader
                ? "mediastick"
                : "exclamationmark.triangle.fill"
        }
    }
}

extension View {
    @ViewBuilder
    func readerPickerStyle(
        _ manager: SmartCardManager,
        showsIconAndText: Bool
    ) -> some View {
        if showsIconAndText {
            self.buttonStyle(.plain)
        } else {
            self
                .connectedReaderBackground(manager)
                .connectedReaderLabelColor(manager)
        }
    }

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
