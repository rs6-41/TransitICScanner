import SwiftUI
import CoreNFC

struct CardListRow: View {
    @State var isFormDisplay = false
    @EnvironmentObject var debug: DebugModel

    let item: CardInfo
    let onResult: (ScanResult) -> Void

    var externalDevice: Bool
    @ObservedObject var smartCardManager: SmartCardManager

    init(
        item: CardInfo,
        smartCardManager: SmartCardManager,
        externalDevice: Bool = false,
        onResult: @escaping (ScanResult) -> Void
    ) {
        self.item = item
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

/// カードの読み取りを開始するボタン
///
/// 読み取り（内蔵リーダー / 外部リーダー / シミュレータでのサンプル）が成功すると `onResult` を呼ぶ。
/// 結果画面への遷移は呼び出し元（CardList）が行う。
struct ScanningButton: View {
    let item: CardInfo
    let onResult: (ScanResult) -> Void
    @ObservedObject var smartCardManager: SmartCardManager

    @StateObject private var model: NFCScannerModel
    @State private var isErrorPresented = false
    @State private var errorMessage: String?

    init(
        item: CardInfo,
        smartCardManager: SmartCardManager,
        onResult: @escaping (ScanResult) -> Void
    ) {
        self.item = item
        self.onResult = onResult
        self.smartCardManager = smartCardManager
        _model = StateObject(
            wrappedValue: NFCScannerModel(scanOption: item.scanOption)
        )
    }

    var body: some View {
        Button(action: startScan) {
            ListButtonInner(item: item)
        }
        .onChange(of: model.result) {
            // 読取結果を呼び出し元へ渡したら消しておく（同じカードを続けて読めるように）
            guard let result = model.result else { return }
            onResult(result)
            model.result = nil
        }
        .onChange(of: model.scanError) {
            // 読取画面が閉じた後に、タイムアウトなどシステム側の理由で終了したことを通知する
            if let scanError = model.scanError {
                showError(scanError.message)
            }
        }
        .alert(
            LocalizedStringKey("error"),
            isPresented: $isErrorPresented
        ) {
        } message: {
            Text(errorMessage ?? String(localized: "cardList.error.nfc"))
        }
    }

    // MARK: - 読み取り

    private func startScan() {
        errorMessage = nil

        if smartCardManager.selectedSource == .external {
            scanWithExternalReader()
        } else if Self.usesSimulatedScan {
            simulateScan()
        } else if NFCTagReaderSession.readingAvailable {
            model.scanError = nil
            model.readerSetup()
        } else {
            showError(nil)
        }
    }

    private func scanWithExternalReader() {
        guard smartCardManager.hasConnectedReader else {
            showError(String(localized: "cardList.external.disable"))
            return
        }

        Task {
            do {
                try await model.scanWithExternalReader(using: smartCardManager)
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    /// シミュレータでは NFC が使えないため、読取の代わりにサンプル結果を返す（画面遷移の確認用）
    private static var usesSimulatedScan: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    /// 読取画面が閉じるまでの時間を待ってから、カード定義のサンプル結果を読取結果として返す
    private func simulateScan() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            model.result = getResultSample(model: item)
        }
    }

    /// エラーを表示する（`message` が nil の場合は NFC 非対応の案内）
    private func showError(_ message: String?) {
        errorMessage = message
        isErrorPresented = true
    }
}
