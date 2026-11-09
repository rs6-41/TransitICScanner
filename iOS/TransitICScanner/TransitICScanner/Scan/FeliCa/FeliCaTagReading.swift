import Foundation
@preconcurrency import CoreNFC

/// FeliCa の Read Without Encryption を、内蔵リーダー(CoreNFC)と外部リーダー(PC/SC)で
/// 共通に扱うためのインターフェース。
///
/// 各カードの読取処理はこのプロトコルだけに依存させ、
/// どちらのリーダーでも同じ解析処理を通るようにする。
protocol FeliCaTagReading {
    /// カードの IDm (8 byte)
    var currentIDm: Data { get }

    /// `NFCFeliCaTag.readWithoutEncryption` と同じ契約で、指定ブロックを読み取る。
    /// - Parameters:
    ///   - serviceCodeList: サービスコード (リトルエンディアン 2 byte) の配列
    ///   - blockList: ブロックリストエレメント (2 byte: `0x80 | サービス番号`, ブロック番号)
    func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        completionHandler: @escaping @Sendable (Int, Int, [Data], (any Error)?) -> Void
    )
}

/// CoreNFC の `NFCFeliCaTag` をそのまま転送する実装
struct CoreNFCFeliCaTag: FeliCaTagReading {
    let tag: any NFCFeliCaTag

    var currentIDm: Data { tag.currentIDm }

    func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        completionHandler: @escaping @Sendable (Int, Int, [Data], (any Error)?) -> Void
    ) {
        tag.readWithoutEncryption(
            serviceCodeList: serviceCodeList,
            blockList: blockList,
            completionHandler: completionHandler
        )
    }
}

/// PC/SC 外部リーダーの FeliCa 疑似 APDU (FF A4 / FF B0) で読み取る実装
final class ExternalFeliCaTag: FeliCaTagReading, @unchecked Sendable {
    let currentIDm: Data
    private let transmit: APDUSend

    /// 失敗時に CoreNFC 互換の completionHandler へ渡すステータスフラグ
    private static let failureStatus = 0xFF

    init(currentIDm: Data, transmit: @escaping APDUSend) {
        self.currentIDm = currentIDm
        self.transmit = transmit
    }

    /// 外部リーダーから IDm を取得して初期化する
    static func connect(transmit: @escaping APDUSend) async throws -> ExternalFeliCaTag {
        let (idm, sw1, sw2) = try await transmit(0xFF, 0xCA, 0x00, 0x00, Data(), 256)

        guard sw1 == 0x90, sw2 == 0x00, idm.count >= 8 else {
            throw ReaderError.message(
                String(localized: "error.smartCardReader.felicaIDm")
            )
        }

        return ExternalFeliCaTag(currentIDm: Data(idm.prefix(8)), transmit: transmit)
    }

    func readWithoutEncryption(
        serviceCodeList: [Data],
        blockList: [Data],
        completionHandler: @escaping @Sendable (Int, Int, [Data], (any Error)?) -> Void
    ) {
        Task {
            do {
                let blocks = try await read(
                    serviceCodeList: serviceCodeList,
                    blockList: blockList
                )
                completionHandler(0x00, 0x00, blocks, nil)
            } catch {
                completionHandler(Self.failureStatus, Self.failureStatus, [], error)
            }
        }
    }

    private func read(serviceCodeList: [Data], blockList: [Data]) async throws -> [Data] {
        var selectedService: Int?
        var blocks: [Data] = []

        for element in blockList {
            let bytes = [UInt8](element)

            // 2 byte 形式 (先頭ビット 1) のみ対応
            guard bytes.count == 2, bytes[0] & 0x80 != 0 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let serviceIndex = Int(bytes[0] & 0x0F)
            guard serviceCodeList.indices.contains(serviceIndex) else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaInfoService")
                )
            }

            if selectedService != serviceIndex {
                try await select(service: serviceCodeList[serviceIndex])
                selectedService = serviceIndex
            }

            let (payload, sw1, sw2) = try await transmit(0xFF, 0xB0, 0x00, bytes[1], Data(), 256)

            guard sw1 == 0x90, sw2 == 0x00 else {
                throw ReaderError.message(
                    String(
                        format: String(localized: "error.smartCardReader.felicaCommandFailed"),
                        Int(sw1),
                        Int(sw2)
                    )
                )
            }

            guard payload.count >= 16 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            blocks.append(Data(payload.prefix(16)))
        }

        return blocks
    }

    private func select(service: Data) async throws {
        let (_, sw1, sw2) = try await transmit(0xFF, 0xA4, 0x00, 0x01, service, 0)

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    format: String(localized: "error.smartCardReader.felicaInfoService"),
                    Int(sw1),
                    Int(sw2)
                )
            )
        }
    }
}
