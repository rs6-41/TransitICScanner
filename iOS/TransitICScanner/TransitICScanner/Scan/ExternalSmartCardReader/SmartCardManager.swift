// MARK: - CryptoTokenKitで外部リーダーを使用する

import Foundation
import CryptoTokenKit
import Combine

struct SmartCardReader: Identifiable,Hashable {
    let id: String
    let name: String

    let state: TKSmartCardSlot.State
}

enum ReaderError: Error {
    case message(String)
}

@MainActor
final class SmartCardManager: ObservableObject {
    @Published private(set) var readers: [SmartCardReader] = []
    
    private var slotManager: TKSmartCardSlotManager?
    
    private var monitoringTask: Task<Void, Never>?

    // MARK: - 開始
    /// CryptoTokenKitを初期化
    func start() {
        stop()

        // Smart Card Slot Managerを取得
        guard let manager = TKSmartCardSlotManager.default else {
            readers = []
            return
        }

        slotManager = manager

        updateReaders()
        startMonitoring()
    }

    // MARK: - リーダー取得
    private func updateReaders() {
        guard let slotManager else {
            readers = []
            return
        }

        /// CryptoTokenKitから利用可能なSlot名を取得
        let slotNames = slotManager.slotNames

        /// 各Slotの情報を返す
        readers = slotNames.compactMap { name in
            if let slot = slotManager.slotNamed(name) {
                return SmartCardReader(
                    id: name,
                    name: name,
                    state: slot.state
                )
            } else {
                return nil
            }
        }
    }
    
    // MARK: - セッション
    func makeSession(name:String,command:String) async throws -> [String] {
        /// 指定された名称のカードリーダーでカードを検出
        if let slot = await slotManager?.getSlot(withName:name) {
            /// カードリーダーのオブジェクト(TKSmartCard)を作成
            if let card = slot.makeSmartCard() {
                do {
                    let response:[String]
                    
                    /// セッションを開始
                    try await card.beginSession()
                    
                    if let h = Data(hex:command) {
                        let r = try await card.transmit(h)
                        response = r.map { String(format: "%02X", $0) }
                    } else {
                        response = []
                    }
                    
                    /// セッションを終了
                    card.endSession()
                    return response
                    
                } catch {
                    card.endSession()
                    throw ReaderError.message(error.localizedDescription)
                }
            }
        }
        throw ReaderError.message(String(localized:"error.smartCardReader.notDetectionCard"))
    }
    
    
    /// 返答を1バイトごとの16進数配列として返却
    func hexConvert(_ text:String) -> [String] {
        return stride(from: 0, to: text.count, by: 2).map { i -> String in
            let startIndex = text.index(text.startIndex, offsetBy: i)
            let endIndex = text.index(startIndex, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
            return String(text[startIndex..<endIndex])
        }
    }
    

    // MARK: - 監視
    /// リーダーの状態を自動更新する
    private func startMonitoring() {
        monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))

                if Task.isCancelled {
                    break
                }

                updateReaders()
            }
        }
    }

    deinit {
        monitoringTask?.cancel()
    }
    
    ///停止
    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}

extension Data {
    init?(hex: String) {
        let len = hex.count
        guard len % 2 == 0 else { return nil }
        var data = Data(capacity: len / 2)
        var index = hex.startIndex
        
        for _ in 0..<(len / 2) {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let num = UInt8(byteString, radix: 16) else { return nil }
            data.append(num)
            index = nextIndex
        }
        self = data
    }
}



let externalViewDebug = CardInfo(
    logo: "placeholderCard",
    name: "ExternalReaderViewDebug",
    sortName:"ExternalReaderViewDebug",
    area: .kr,
    countryCode: ["kr"],
    prefectures: nil,
    regionOption: nil,
    description:"ExternalReaderViewDebug",
    scand_description: "ExternalReaderViewDebug",
    searchWords: [],
    scanOption: ScanOption(
        name: "ExternalReaderViewDebug",
        nameShort:"ExternalReaderViewDebug",
        scanType: .external,
        pollingOption: [],
        felicaSystemCodes: nil,
        historyCount: 0,
        currencyType:.krw,
        converter: .jpIC,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:0,
            idm:"01928374656",
            type:"",
            history: []
        )
)
