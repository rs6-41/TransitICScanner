import SwiftUI
import Foundation
import CoreNFC

let idKMT = CardInfo(
    logo: "idKMT",
    name: "cardList.idKMT",
    sortName: "cardList.idKMT.sortName",
    area: .id,
    countryCode: ["id"],
    prefectures: ["Jakarta"],
    regionOption: .southEastAsia,
    description: "cardList.idKMT.description",
    scand_description: "idKMT.scand.description",
    searchWords: ["KAI","Commuter","Kartu Multi Trip","KMT","Jakarta","Indonesia"],
    scanOption: ScanOption(
        id: .idKMT,
        nameShort: "idKMT.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["90B7"],
        historyCount: 20,
        currencyType: .idr,
        converter: .idKMT,
        scrapingView: nil
    ),
    infomation: nil,
    sample: ResultSample(
        balance: 4000,
        idm: "0127FFFFFFFF6EAB",
        type: "card.KMT",
        history: []
    )
)

extension NFCScannerModel {

    func idKMT_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession,
        optionType: String = ""
    ) {
        guard case let .feliCa(felicaTag) = tag else {
            session.invalidate(
                errorMessage: String(localized: "scanner.coreNFC.error.notfeliCa")
            )
            return
        }

        Task {
            guard let data = await idKMT_readData(
                felicaTag,
                count: self.scanOption.historyCount
            ) else {
                return
            }

            let info = idKMT_info(felicaTag, data: data)

            await MainActor.run {
                self.result = Result(
                    balance: Double(data.balance),
                    isHistory: true,
                    history: data.histories,
                    info: info,
                    converter: idKMT.scanOption.converter,
                    isLastHide: true,
                    description: idKMT.scand_description,
                    savedAt: Date.now
                )

                self.session?.alertMessage =
                    String(localized: "scanner.coreNFC.scanning.done")

                session.invalidate()
            }
        }
    }

    func idKMT_scanExternal(using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let reader = KMTExternalAPDU(
                transmit: manager.apduSender(for: card)
            )

            let idmData = try await reader.send(
                0xCA,
                p1: 0x00,
                p2: 0x00,
                le: 256
            )

            guard idmData.count >= 8 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaIDm")
                )
            }

            let idm = idmData.prefix(8)
                .map { String(format: "%02X", $0) }
                .joined()

            let idBlocks = try await reader.readBlocks(
                service: [0x0B, 0x30],
                count: 1,
                failureKey: "error.smartCardReader.felicaInfoService"
            )

            guard let idBlock = idBlocks.first else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let balanceBlocks = try await reader.readBlocks(
                service: [0x17, 0x10],
                count: 1,
                failureKey: "error.smartCardReader.felicaInfoService"
            )

            guard let balanceBlock = balanceBlocks.first else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let historyBlocks = try await reader.readBlocks(
                service: [0x0F, 0x20],
                count: min(max(self.scanOption.historyCount, 0), 20),
                failureKey: "error.smartCardReader.felicaHistoryService",
                stopAtEmpty: true
            )

            guard let data = KMTData.parse(
                idBlock: idBlock,
                balanceBlock: balanceBlock,
                historyBlocks: historyBlocks
            ) else {
                throw ReaderError.message(
                    String(localized: "scanner.coreNFC.scanning.error.read")
                )
            }

            let info = ResultCardInfo(
                idm: idm,
                name: idKMT.name,
                nameShort: idKMT.scanOption.nameShort,
                currencyType: idKMT.scanOption.currencyType,
                type: "card.KMT",
                serial: data.serialNumber,
                version: nil,
                validDate: nil,
                issueInfo: issueInfo(
                    region: idKMT.area.rawValue,
                    area: "locate.prefecture.Jakarta",
                    city: nil,
                    issuer: "issue.id.jakarta.issuer.KaiCommuter"
                )
            )

            return Result(
                balance: Double(data.balance),
                isHistory: true,
                history: data.histories,
                info: info,
                converter: idKMT.scanOption.converter,
                isLastHide: true,
                description: idKMT.scand_description,
                savedAt: Date.now
            )
        }

        await MainActor.run {
            self.result = result
        }
    }

    func idKMT_readData(
        _ felicaTag: NFCFeliCaTag,
        count: Int
    ) async -> KMTData? {
        guard let idBlock = await idKMT_read(
            felicaTag,
            service: Data([0x0B, 0x30]),
            blocks: [0]
        )?.first else {
            return nil
        }

        guard let balanceBlock = await idKMT_read(
            felicaTag,
            service: Data([0x17, 0x10]),
            blocks: [0]
        )?.first else {
            return nil
        }

        let historyCount = min(max(count, 0), 20)

        guard let historyBlocks = await idKMT_read(
            felicaTag,
            service: Data([0x0F, 0x20]),
            blocks: Array(0..<historyCount).map { UInt8($0) }
        ) else {
            return nil
        }

        guard let data = KMTData.parse(
            idBlock: idBlock,
            balanceBlock: balanceBlock,
            historyBlocks: historyBlocks
        ) else {
            self.session?.invalidate(
                errorMessage: String(localized: "scanner.coreNFC.scanning.error.read")
            )
            return nil
        }

        return data
    }

    func idKMT_read(
        _ tag: NFCFeliCaTag,
        service: Data,
        blocks: [UInt8]
    ) async -> [Data]? {
        guard !blocks.isEmpty else {
            return []
        }

        var result: [Data] = []

        for start in stride(from: 0, to: blocks.count, by: 10) {
            let end = min(start + 10, blocks.count)
            let blockList = blocks[start..<end].map {
                Data([0x80, $0])
            }

            let readResult: [Data]? = await withCheckedContinuation { continuation in
                tag.readWithoutEncryption(
                    serviceCodeList: [service],
                    blockList: blockList
                ) { status1, status2, data, error in
                    guard error == nil,
                          status1 == 0,
                          status2 == 0,
                          data.count == blockList.count else {
                        continuation.resume(returning: nil)
                        return
                    }

                    continuation.resume(returning: data)
                }
            }

            guard let readResult else {
                return nil
            }

            result.append(contentsOf: readResult)
        }

        return result
    }

    func idKMT_info(
        _ felicaTag: NFCFeliCaTag,
        data: KMTData
    ) -> ResultCardInfo {
        let idm = felicaTag.currentIDm
            .map { String(format: "%02X", $0) }
            .joined()

        return ResultCardInfo(
            idm: idm,
            name: idKMT.name,
            nameShort: idKMT.scanOption.nameShort,
            currencyType: idKMT.scanOption.currencyType,
            type: "card.KMT",
            serial: data.serialNumber,
            version: nil,
            validDate: nil,
            issueInfo: issueInfo(
                region: idKMT.area.rawValue,
                area: nil,
                city: nil,
                issuer: nil
            )
        )
    }
}

struct KMTData {
    let serialNumber: String
    let balance: UInt32
    let lastTransactionAmount: UInt32
    let transactionCounter: UInt32
    let histories: [ResultHistory]

    static func parse(
        idBlock: Data,
        balanceBlock: Data,
        historyBlocks: [Data]
    ) -> KMTData? {
        guard idBlock.count >= 16,
              balanceBlock.count >= 16 else {
            return nil
        }

        let serialBytes = Array(idBlock.prefix(16))

        let serialNumber: String
        if serialBytes.allSatisfy({ $0 >= 0x20 && $0 < 0x7F }) {
            serialNumber = String(
                decoding: serialBytes,
                as: UTF8.self
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            serialNumber = serialBytes
                .map { String(format: "%02X", $0) }
                .joined()
        }

        let balance = uint32LittleEndian(balanceBlock, offset: 0)
        let lastTransactionAmount = uint32LittleEndian(balanceBlock, offset: 4)
        let transactionCounter = uint24BigEndian(balanceBlock, offset: 13)

        let histories = historyBlocks.compactMap {
            parseHistory($0)
        }

        return KMTData(
            serialNumber: serialNumber,
            balance: balance,
            lastTransactionAmount: lastTransactionAmount,
            transactionCounter: transactionCounter,
            histories: histories
        )
    }

    private static func parseHistory(_ data: Data) -> ResultHistory? {
        guard data.count >= 16,
              data[0] != 0 else {
            return nil
        }

        let gateCode = uint16BigEndian(data, offset: 8)

        guard gateCode != 0 else {
            return nil
        }

        let processType = data[12]
        let sequenceNumber = uint24BigEndian(data, offset: 13)
        let rawAmount = Int64(uint32BigEndian(data, offset: 4))

        let amount: Int64 = processType == 1
            ? rawAmount
            : -rawAmount

        let date = parseDate(data)

        let gateHigh = UInt8((gateCode >> 8) & 0xFF)
        let gateLow = UInt8(gateCode & 0xFF)

        let lineIn: UInt8
        let stationIn: UInt8
        let lineOut: UInt8
        let stationOut: UInt8

        if processType == 0 || processType == 2 {
            lineIn = gateHigh
            stationIn = gateLow
            lineOut = 0
            stationOut = 0
        } else {
            lineIn = 0
            stationIn = 0
            lineOut = gateHigh
            stationOut = gateLow
        }

        return ResultHistory(
            processType: processType,
            date: date,
            balance: Double(amount),
            amount: nil,
            lineIn: lineIn,
            stationIn: stationIn,
            lineOut: lineOut,
            stationOut: stationOut,
            transactionId: Int(sequenceNumber)
        )
    }

    private static func parseDate(_ data: Data) -> DateComponents {
        let rawTimestamp = uint32BigEndian(data, offset: 0)
        let epoch2000: TimeInterval = 946_684_800
        let epochTransition: UInt32 = 599_616_000

        let offset: TimeInterval =
            rawTimestamp < epochTransition ? -6 * 60 * 60 : 0

        let date = Date(
            timeIntervalSince1970:
                epoch2000 + TimeInterval(rawTimestamp) + offset
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!

        return calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
    }

    private static func uint16BigEndian(
        _ data: Data,
        offset: Int
    ) -> UInt16 {
        (UInt16(data[offset]) << 8)
        | UInt16(data[offset + 1])
    }

    private static func uint24BigEndian(
        _ data: Data,
        offset: Int
    ) -> UInt32 {
        (UInt32(data[offset]) << 16)
        | (UInt32(data[offset + 1]) << 8)
        | UInt32(data[offset + 2])
    }

    private static func uint32BigEndian(
        _ data: Data,
        offset: Int
    ) -> UInt32 {
        (UInt32(data[offset]) << 24)
        | (UInt32(data[offset + 1]) << 16)
        | (UInt32(data[offset + 2]) << 8)
        | UInt32(data[offset + 3])
    }

    private static func uint32LittleEndian(
        _ data: Data,
        offset: Int
    ) -> UInt32 {
        UInt32(data[offset])
        | (UInt32(data[offset + 1]) << 8)
        | (UInt32(data[offset + 2]) << 16)
        | (UInt32(data[offset + 3]) << 24)
    }
}

private struct KMTExternalAPDU {
    let transmit: APDUSend

    func send(
        _ ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data = Data(),
        le: Int = 0
    ) async throws -> Data {
        let (payload, sw1, sw2) = try await transmit(
            0xFF,
            ins,
            p1,
            p2,
            data,
            le
        )

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    format: String(localized:
                        "error.smartCardReader.felicaCommandFailed"
                    ),
                    Int(sw1),
                    Int(sw2)
                )
            )
        }

        return payload
    }

    func readBlocks(
        service: [UInt8],
        count: Int,
        start: Int = 0,
        failureKey: String,
        stopAtEmpty: Bool = false
    ) async throws -> [Data] {
        let (_, sw1, sw2) = try await transmit(
            0xFF,
            0xA4,
            0x00,
            0x01,
            Data(service),
            0
        )

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    format: String(localized:
                        String.LocalizationValue(failureKey)
                    ),
                    Int(sw1),
                    Int(sw2)
                )
            )
        }

        var blocks: [Data] = []

        for index in start..<(start + count) {
            let data = try await send(
                0xB0,
                p1: 0x00,
                p2: UInt8(index),
                le: 256
            )

            guard data.count >= 16 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let block = Data(data.prefix(16))

            if stopAtEmpty &&
                (block.allSatisfy { $0 == 0 } ||
                 block.allSatisfy { $0 == 0xFF }) {
                break
            }

            blocks.append(block)
        }

        return blocks
    }
}
