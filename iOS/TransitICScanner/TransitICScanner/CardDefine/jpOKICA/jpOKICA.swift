import SwiftUI
import Foundation
import CoreNFC

let jpOKICA = CardInfo(
    logo: "jpOKICA",
    name: "cardList.jpOKICA",
    sortName: "cardList.jpOKICA.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Okinawa"],
    regionOption: nil,
    description: "cardList.jpOKICA.description",
    scand_description: "jpIC.scand.description",
    searchWords: ["card.OKICA","おきか","オキカ","ゆいレール","那覇","琉球"],
    scanOption: ScanOption(
        name: "jpOKICA",
        nameShort: "jpOKICA.short",
        scanType: .nfc,
        pollingOption: [.iso18092],
        felicaSystemCodes: ["8FC1"],
        historyCount: 20,
        currencyType: .jpy,
        converter: .jpOKICA,
        scrapingView: nil
    ),
    infomation: nil,
    sample: ResultSample(
        balance: 1200.0,
        idm: "0405820A9A93CDEF",
        type: "card.OKICA",
        history: [
            ResultHistory(processType: 0x01, processType4: UInt32(0x16010002),date: sampleDay2,balance: 1200,amount: nil,lineIn: 0x00,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 152
            ),
            ResultHistory(processType: 0x01, processType4: UInt32(0x08020000),date: sampleDay1,balance: 1500,amount: nil,lineIn: 0x00,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 151
            )
        ]
    )
)

extension NFCScannerModel {

    func jpOKICA_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession,
        optionType: String = ""
    ) {
        guard case let .feliCa(felicaTag) = tag else {
            session.invalidate(
                errorMessage: String(
                    localized: "scanner.coreNFC.error.notfeliCa"
                )
            )
            return
        }

        Task {
            guard let history = await okica_history(
                felicaTag,
                count: self.scanOption.historyCount
            ) else {
                return
            }

            let balance = history.first?.balance ?? 0

            let info = await okica_info(
                felicaTag,
                optionType: optionType
            )

            await MainActor.run {
                self.result = Result(
                    balance: Double(balance),
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: jpOKICA.scanOption.converter,
                    isLastHide: true,
                    description: jpOKICA.scand_description,
                    savedAt: Date.now
                )

                self.session?.alertMessage =
                    String(localized: "scanner.coreNFC.scanning.done")

                session.invalidate()
            }
        }
    }

    func okica_history(
        _ felicaTag: NFCFeliCaTag,
        count: Int = 20
    ) async -> [ResultHistory]? {

        await withCheckedContinuation { continuation in

            let serviceCode = Data([0x8F, 0x02])

            let blockCount = min(
                max(count, 1),
                20
            )

            let blocksPerRead = 10

            let blockLists = stride(
                from: 0,
                to: blockCount,
                by: blocksPerRead
            ).map { start in

                let end = min(
                    start + blocksPerRead,
                    blockCount
                )

                return (start..<end).map {
                    Data([
                        0x80,
                        UInt8($0)
                    ])
                }
            }

            func readBlocks(
                _ blockList: [Data],
                completion: @escaping ([Data]?) -> Void
            ) {
                felicaTag.readWithoutEncryption(
                    serviceCodeList: [serviceCode],
                    blockList: blockList
                ) {
                    status1,
                    status2,
                    blockData,
                    error in

                    print(
                        "OKICA history status:",
                        status1,
                        status2,
                        "count:",
                        blockData.count
                    )

                    guard error == nil,
                          status1 == 0x00,
                          status2 == 0x00 else {

                        print(
                            "OKICA history read error:",
                            error as Any
                        )

                        completion(nil)
                        return
                    }

                    completion(blockData)
                }
            }

            func readNext(
                _ index: Int,
                result: [Data]
            ) {

                if index >= blockLists.count {

                    let history = result.compactMap {
                        okica_parseHistory($0)
                    }

                    continuation.resume(
                        returning: history
                    )

                    return
                }

                readBlocks(blockLists[index]) {
                    blockData in

                    guard let blockData else {
                        continuation.resume(
                            returning: nil
                        )
                        return
                    }

                    readNext(
                        index + 1,
                        result: result + blockData
                    )
                }
            }

            readNext(
                0,
                result: []
            )
        }
    }

    private func okica_parseHistory(
        _ data: Data
    ) -> ResultHistory? {

        let bytes = [UInt8](data)

        guard bytes.count == 16 else {
            return nil
        }

        let hex = bytes
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        print("OKICA history:", hex)

        if bytes.allSatisfy({ $0 == 0x00 }) {
            return nil
        }

        if bytes.allSatisfy({ $0 == 0xFF }) {
            return nil
        }

        let processType4 =
            (UInt32(bytes[0]) << 24) |
            (UInt32(bytes[1]) << 16) |
            (UInt32(bytes[2]) << 8) |
            UInt32(bytes[3])

        let rawDate =
            (UInt16(bytes[4]) << 8) |
            UInt16(bytes[5])

        let year =
            Int((rawDate >> 9) & 0x7F) + 2000

        let month =
            Int((rawDate >> 5) & 0x0F)

        let day =
            Int(rawDate & 0x1F)

        guard year >= 2000,
              month >= 1,
              month <= 12,
              day >= 1,
              day <= 31 else {
            return nil
        }

        let balance =
            Int(bytes[10]) |
            (Int(bytes[11]) << 8)

        let transactionId =
            (Int(bytes[13]) << 8) |
            Int(bytes[14])

        return ResultHistory(
            processType: bytes[1],
            processType4: processType4,
            date: DateComponents(
                year: year,
                month: month,
                day: day
            ),
            balance: Double(balance),
            amount: nil,
            lineIn: bytes[6],
            stationIn: bytes[7],
            lineOut: bytes[8],
            stationOut: bytes[9],
            transactionId: transactionId
        )
    }

    func okica_info(
        _ felicaTag: NFCFeliCaTag,
        optionType: String
    ) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map {
                String(
                    format: "%02X",
                    $0
                )
            }
            .joined()

        return ResultCardInfo(
            idm: idm,
            name: jpOKICA.name,
            nameShort: jpOKICA.scanOption.nameShort,
            currencyType: jpOKICA.scanOption.currencyType,
            type: "",
            serial: nil,
            version: nil,
            validDate: nil,
            issueInfo: issueInfo(region:jpOKICA.area.rawValue,area:"locate.prefecture.Okinawa",issuer:"issue.jp.okinawa.issuer.okica")
        )
    }

    func okica_read(
        _ tag: NFCFeliCaTag,
        service: Data,
        blocks: [UInt8]
    ) async -> [Data]? {

        await withCheckedContinuation { continuation in

            let blockList = blocks.map {
                Data([
                    0x80,
                    $0
                ])
            }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) {
                status1,
                status2,
                data,
                error in

                guard error == nil,
                      status1 == 0x00,
                      status2 == 0x00 else {

                    continuation.resume(
                        returning: nil
                    )

                    return
                }

                continuation.resume(
                    returning: data
                )
            }
        }
    }

    func okica_readMultiple(
        _ tag: NFCFeliCaTag,
        service: Data,
        count: Int
    ) async -> [Data]? {

        await withCheckedContinuation { continuation in

            let blockList = (0..<count).map {
                Data([
                    0x80,
                    UInt8($0)
                ])
            }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) {
                status1,
                status2,
                data,
                error in

                guard error == nil,
                      status1 == 0x00,
                      status2 == 0x00 else {

                    continuation.resume(
                        returning: nil
                    )

                    return
                }

                continuation.resume(
                    returning: data
                )
            }
        }
    }
}
