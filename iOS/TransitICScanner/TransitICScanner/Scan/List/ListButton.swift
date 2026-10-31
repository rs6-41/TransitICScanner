import SwiftUI
import CoreNFC

struct CardListRow: View {
    @State var isFormDisplay = false
    @EnvironmentObject var debug: DebugModel

    let item: CardInfo

    @Binding var deleteAds: Bool
    var externalDevice: Bool
    @ObservedObject var smartCardManager: SmartCardManager

    init(
        item: CardInfo,
        deleteAds: Binding<Bool>,
        smartCardManager: SmartCardManager,
        externalDevice: Bool = false
    ) {
        self.item = item
        self._deleteAds = deleteAds
        self.smartCardManager = smartCardManager
        self.externalDevice = externalDevice
    }

    var body: some View {
        VStack(alignment: .leading) {
            switch item.scanOption.scanType {
            case .nfc:
                ScanningButton(
                    item: item,
                    deleteAds: $deleteAds,
                    smartCardManager: smartCardManager
                )

            case .scraping:
                if let view = item.scanOption.scrapingView {
                    Button {
                        isFormDisplay = true
                    } label: {
                        ListButtonInner(item: item)
                    }
                    .sheet(isPresented: $isFormDisplay) {
                        view()
                    }
                }

            case .external:
                Button {
                    if externalDevice {
                    } else {
                    }
                } label: {
                    ListButtonInner(item: item)
                        .opacity(!externalDevice ? 0.5 : 1.0)
                }
            }

            if debug.isDisplay {
                CardListItemDebugView(item: item)
            }
        }
    }
}

struct ListButtonInner: View {
    @State var isCardInfoView = false
    let item: CardInfo

    var body: some View {
        HStack {
            CardImage(name: item.logo)

            VStack(alignment: .leading) {
                HStack(spacing: 3) {
                    switch item.scanOption.scanType {
                    case .nfc:
                        Image(systemName: "wave.3.right")
                            .imageScale(.small)
                    case .scraping:
                        Image(systemName: "creditcard.and.numbers")
                            .imageScale(.small)
                    case .external:
                        Image(systemName: "wave.3.right")
                            .imageScale(.small)
                    }

                    Text(LocalizedStringKey(item.name))
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey(item.area.rawValue))
                            .fontWeight(.semibold)

                        if let prefectures = item.prefectures {
                            ForEach(prefectures, id: \.self) { prefecture in
                                Text(LocalizedStringKey("locate.prefecture." + prefecture))

                                if prefecture != prefectures.last {
                                    Text(String(", "))
                                }
                            }
                        }
                    }

                    if let description = item.description {
                        Text(LocalizedStringKey(description))
                    }
                }
                .foregroundStyle(Color.gray)
                .font(.caption)
            }

            Spacer()

            if item.infomation != nil {
                Button {
                    isCardInfoView.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                }
                .foregroundStyle(Color.accentColor)
                .sheet(isPresented: $isCardInfoView) {
                    NavigationStack {
                        ScrollView {
                            item.infomation
                        }
                    }
                }
            }
        }
        .foregroundStyle(Color.primary)
    }
}

struct ScanningButton: View {
    let item: CardInfo

    @StateObject private var model: NFCScannerModel
    @State var nfcError = false
    @Binding var deleteAds: Bool
    @ObservedObject var smartCardManager: SmartCardManager
    @State private var scanErrorMessage: String?

    init(
        item: CardInfo,
        deleteAds: Binding<Bool>,
        smartCardManager: SmartCardManager
    ) {
        self.item = item
        self._deleteAds = deleteAds
        self.smartCardManager = smartCardManager
        _model = StateObject(
            wrappedValue: NFCScannerModel(scanOption: item.scanOption)
        )
    }

    var body: some View {
        Button {
            scanErrorMessage = nil
            if smartCardManager.selectedSource == .external {
                guard smartCardManager.hasConnectedReader else {
                    scanErrorMessage = String(localized: "cardList.external.disable")
                    nfcError = true
                    return
                }

                Task {
                    do {
                        model.result = nil
                        try await model.scanWithExternalReader(
                            using: smartCardManager
                        )
                    } catch {
                        scanErrorMessage = error.localizedDescription
                        nfcError = true
                    }
                }
            } else if checkDevice() {
                model.readerSetup()
            } else {
                nfcError = true
            }
        } label: {
            ListButtonInner(item: item)
        }
        .navigationDestination(item: $model.result) { result in
            ResultView(
                result: result,
                scandata: true,
                saveListID: .constant(UUID()),
                deleteAds: $deleteAds
            )
        }
        .alert(
            LocalizedStringKey("error"),
            isPresented: $nfcError
        ) {
        } message: {
            Text(scanErrorMessage ?? String(localized: "cardList.error.nfc"))
        }
    }

    func checkDevice() -> Bool {
        NFCTagReaderSession.readingAvailable
    }
}

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
                        Label(LocalizedStringKey("cardList.reader.external"),systemImage: "app.connected.to.app.below.fill")
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
                case .external:Image(systemName:"app.connected.to.app.below.fill")
            }
        }
    }
}
