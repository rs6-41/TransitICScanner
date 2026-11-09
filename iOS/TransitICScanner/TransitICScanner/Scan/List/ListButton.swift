import SwiftUI
import CoreNFC

struct CardListRow: View {
    @State var isFormDisplay = false
    @EnvironmentObject var debug: DebugModel

    let item: CardInfo
    var onResult: ((ScanResult) -> Void)?

    @Binding var deleteAds: Bool
    var externalDevice: Bool
    @ObservedObject var smartCardManager: SmartCardManager

    init(
        item: CardInfo,
        deleteAds: Binding<Bool>,
        smartCardManager: SmartCardManager,
        externalDevice: Bool = false,
        onResult: ((ScanResult) -> Void)? = nil
    ) {
        self.item = item
        self._deleteAds = deleteAds
        self.smartCardManager = smartCardManager
        self.externalDevice = externalDevice
        self.onResult = onResult
    }

    var body: some View {
                VStack(alignment: .leading, spacing: 4) {
            switch item.scanOption.scanType {
            case .nfc:
                ScanningButton(
                    item: item,
                    deleteAds: $deleteAds,
                    smartCardManager: smartCardManager,
                    onResult: onResult
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

                VStack(alignment: .leading, spacing: 3) {
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

            if item.information != nil {
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
                            item.information
                        }
                    }
                }
            }
        }
        .foregroundStyle(Color.primary)
#if targetEnvironment(macCatalyst)
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
#endif
    }
}

struct ScanningButton: View {
    let item: CardInfo
    var onResult: ((ScanResult) -> Void)?

    @StateObject private var model: NFCScannerModel
    @State var nfcError = false
    @Binding var deleteAds: Bool
    @ObservedObject var smartCardManager: SmartCardManager
    @State private var scanErrorMessage: String?

    init(
        item: CardInfo,
        deleteAds: Binding<Bool>,
        smartCardManager: SmartCardManager,
        onResult: ((ScanResult) -> Void)? = nil
    ) {
        self.item = item
        self.onResult = onResult
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
                model.scanError = nil
                model.readerSetup()
            } else {
                nfcError = true
            }
        } label: {
            ListButtonInner(item: item)
        }
        .navigationDestination(item: Binding(
            get: { onResult == nil ? model.result : nil },
            set: { model.result = $0 }
        )) { result in
            ResultView(
                result: result,
                scandata: true,
                saveListID: .constant(UUID()),
                deleteAds: $deleteAds
            )
        }
        .onChange(of: model.result) {
            if let result = model.result {
                onResult?(result)
            }
        }
        .onChange(of: model.scanError) {
            // 読取画面が閉じた後に、タイムアウトなどシステム側の理由で終了したことを通知する
            if let scanError = model.scanError {
                scanErrorMessage = scanError.message
                nfcError = true
            }
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
