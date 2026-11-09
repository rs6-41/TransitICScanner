// MARK: - CryptoTokenKitで外部リーダーを使用する

import Foundation
import CryptoTokenKit
import Combine

struct SmartCardReader: Identifiable, Hashable {
    let id: String
    let name: String

    let state: TKSmartCardSlot.State
}

enum ReaderError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let message): message
        }
    }
}

@MainActor
final class SmartCardManager: ObservableObject {
    @Published private(set) var readers: [SmartCardReader] = []
    @Published private(set) var selectedSource: ScanReaderSource = .builtIn
    @Published private(set) var isAvailable = false

    private var slotManager: TKSmartCardSlotManager?

    private var monitoringTask: Task<Void, Never>?
    private var hasUserSelectedReader = false

    // MARK: - 開始
    /// CryptoTokenKitを初期化
    func start() {
        stop()

        // Smart Card Slot Managerを取得
        guard let manager = TKSmartCardSlotManager.default else {
            readers = []
            isAvailable = false
            selectedReaderID = nil
            selectedSource = .builtIn
            return
        }

        slotManager = manager
        isAvailable = true

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
        let updatedReaders = slotNames.compactMap { name in
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

        if readers != updatedReaders {
            readers = updatedReaders
        }
        if updatedReaders.isEmpty {
            if selectedReaderID != nil {
                selectedReaderID = nil
            }
            if selectedSource != .builtIn {
                selectedSource = .builtIn
            }
        } else {
            if let selectedReaderID, !updatedReaders.contains(where: { $0.id == selectedReaderID }) {
                self.selectedReaderID = updatedReaders.first?.id
            } else if selectedReaderID == nil {
                selectedReaderID = updatedReaders.first?.id
            }

            if !hasUserSelectedReader, selectedSource != .external {
                selectedSource = .external
            }
        }
    }

    @Published private(set) var selectedReaderID: String?

    var hasConnectedReader: Bool { !readers.isEmpty }

    func selectReader(source: ScanReaderSource, readerID: String? = nil) {
        hasUserSelectedReader = true
        selectedSource = source
        if source == .external, let readerID {
            selectedReaderID = readerID
        }
    }

    // MARK: - セッション
    func makeSession(name: String, command: String) async throws -> [String] {
        /// 指定された名称のカードリーダーでカードを検出
        if let slot = await slotManager?.getSlot(withName: name) {
            /// カードリーダーのオブジェクト(TKSmartCard)を作成
            if let card = slot.makeSmartCard() {
                do {
                    let response: [String]

                    /// セッションを開始
                    try await card.beginSession()

                    if let h = Data(hex: command) {
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
        throw ReaderError.message(String(localized: "error.smartCardReader.notDetectionCard"))
    }

    /// Holds one exclusive external-card session for a complete card scan.
    func withCard<T>(readerID: String? = nil, operation: (TKSmartCard) async throws -> T) async throws -> T {
        guard let slotManager else {
            throw ReaderError.message(String(localized: "error.smartCardReader.unavailable"))
        }

        let slotName = readerID ?? selectedReaderID
        guard let slotName,
            let slot = await slotManager.getSlot(withName: slotName),
            slot.state != .missing
        else {
            throw ReaderError.message(String(localized: "error.smartCardReader.unavailable"))
        }

        switch slot.state {
        case .empty, .probing:
            throw ReaderError.message(String(localized: "error.smartCardReader.notDetectionCard"))
        case .muteCard:
            throw ReaderError.message(String(localized: "error.smartCardReader.unreadableCard"))
        case .validCard:
            break
        @unknown default:
            throw ReaderError.message(String(localized: "error.smartCardReader.unavailable"))
        }

        guard let card = slot.makeSmartCard() else {
            throw ReaderError.message(String(localized: "error.smartCardReader.notDetectionCard"))
        }

        let didBegin: Bool
        do {
            didBegin = try await card.beginSession()
        } catch {
            if !card.isValid || slot.state == .empty {
                throw ReaderError.message(String(localized: "error.smartCardReader.notDetectionCard"))
            }
            throw error
        }
        guard didBegin else {
            throw ReaderError.message(String(localized: "error.smartCardReader.sessionStart"))
        }
        defer { card.endSession() }

        return try await operation(card)
    }

    func apduSender(for card: TKSmartCard) -> APDUSend {
        { cla, ins, p1, p2, data, le in
            guard data.count <= 255 else {
                throw ReaderError.message(String(localized: "error.smartCardReader.apduDataTooLong"))
            }

            var command = Data([cla, ins, p1, p2])
            if !data.isEmpty {
                command.append(UInt8(data.count))
                command.append(data)
            }
            if le > 0 {
                command.append(le == 256 ? 0 : UInt8(le))
            }

            let response = try await card.transmit(command)
            guard response.count >= 2 else {
                throw ReaderError.message(String(localized: "error.smartCardReader.incompleteResponse"))
            }
            return (
                Data(response.dropLast(2)),
                response[response.count - 2],
                response[response.count - 1]
            )
        }
    }

    /// 返答を1バイトごとの16進数配列として返却
    func hexConvert(_ text: String) -> [String] {
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
                try? await Task.sleep(for: .milliseconds(500))

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
