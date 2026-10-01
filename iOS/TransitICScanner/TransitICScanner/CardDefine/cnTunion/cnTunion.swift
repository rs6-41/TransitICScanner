import Foundation
import SwiftUI
import CoreNFC


let cnTunion = CardInfo(
    logo: "cnTunion_beijing",
    name: "cardList.cnTunion",
    sortName: "cardList.cnTunion.sortName",
    area: .cn,
    countryCode: ["cn", "hk", "mo"],
    prefectures: nil,
    regionOption: nil,
    description: String(localized: "cardList.cnTunion.description"),
    scand_description: "",
    searchWords: ["zhongguojiaotonglianhe"],
    scanOption: ScanOption(
        name: "cnTunion",
        nameShort: "cnTunion.short",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currencyType: .rmb,
        converter: .cnTunion,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance: 295.0,
            idm: "03104770012345678901",
            type: "上海公共交通卡",
            history: [
                ResultHistory(
                    processType: 0x02,
                    date: sampleDay2,
                    balance: 300,
                    amount: 100,
                    lineIn: 0x11,
                    stationIn: 0x11,
                    lineOut: 0x11,
                    stationOut: 0x11,
                    transactionId: 151
                ),
                ResultHistory(
                    processType: 0x04,
                    date: sampleDay3,
                    balance: 295,
                    amount: 15,
                    lineIn: 0x11,
                    stationIn: 0x11,
                    lineOut: 0x11,
                    stationOut: 0x11,
                    transactionId: 152
                )
            ]
        )
)


final class CNTRunionFullLog {

    private(set) var text = ""

    func append(_ value: String) {
        text += value
        text += "\n"
    }

    func appendData(
        _ title: String,
        _ data: Data
    ) {
        let hex = data
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        append(
            "\(title) [\(data.count) bytes]: \(hex)"
        )
    }

    func appendBytes(
        _ title: String,
        _ bytes: [UInt8]
    ) {
        let hex = bytes
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        append(
            "\(title) [\(bytes.count) bytes]: \(hex)"
        )
    }
}


extension NFCScannerModel {

    func cnTunion_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession
    ) {

        guard case let .iso7816(isoTag) = tag else {
            session.invalidate(
                errorMessage: "Not ISO7816 tag"
            )
            return
        }

        let fullLog = CNTRunionFullLog()

        fullLog.append(
            "===== T-UNION FULL LOG START ====="
        )

        fullLog.append(
            "Scan Date: \(Date.now)"
        )

        print("T-Union scan started")

        fullLog.append(
            "T-Union scan started"
        )

        let identifierHex = isoTag.identifier
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        print(
            "ISO7816 identifier:",
            identifierHex
        )

        fullLog.append(
            "ISO7816 identifier [\(isoTag.identifier.count) bytes]: \(identifierHex)"
        )

        let aid = isoTag.initialSelectedAID

        if aid.isEmpty {

            print(
                "Initial Selected AID: empty"
            )

            fullLog.append(
                "Initial Selected AID: empty"
            )

        } else {

            let aidHex = aid.utf8
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            print(
                "Initial Selected AID:",
                aidHex
            )

            fullLog.append(
                "Initial Selected AID [\(aid.utf8.count) bytes]: \(aidHex)"
            )
        }

        if let historicalBytes = isoTag.historicalBytes {

            fullLog.appendData(
                "Historical Bytes",
                historicalBytes
            )

            print(
                "Historical Bytes:",
                historicalBytes
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined(separator: " ")
            )

        } else {

            fullLog.append(
                "Historical Bytes: nil"
            )

            print(
                "Historical Bytes: nil"
            )
        }

        if let applicationData = isoTag.applicationData {

            fullLog.appendData(
                "Application Data",
                applicationData
            )

            print(
                "Application Data:",
                applicationData
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined(separator: " ")
            )

        } else {

            fullLog.append(
                "Application Data: nil"
            )

            print(
                "Application Data: nil"
            )
        }
        
        fullLog.append("")
        fullLog.append(
            "===== ASYNC SCAN START ====="
        )

        Task { @MainActor [self] in
            await cnTunion_scanAsync(
                isoTag,
                session: session,
                fullLog: fullLog
            )
        }
    }

    @MainActor
    private func cnTunion_scanAsync(
        _ isoTag: NFCISO7816Tag,
        session: NFCTagReaderSession,
        fullLog: CNTRunionFullLog
    ) async {

        let aids: [Data] = [
            Data([
                0xA0, 0x00, 0x00, 0x06,
                0x32, 0x01, 0x01, 0x05
            ]),
            Data([
                0xA0, 0x00, 0x00, 0x06,
                0x32, 0x01, 0x01, 0x06
            ]),
            Data([
                0x32, 0x50, 0x41, 0x59,
                0x2E, 0x53, 0x59, 0x53,
                0x2E, 0x44, 0x44, 0x46,
                0x30, 0x31
            ])
        ]

        fullLog.append(
            "===== AID SELECTION ====="
        )

        var fciData: Data? = nil

        for aid in aids {

            let aidHex = aid
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            print(
                "Selecting AID:",
                aidHex
            )

            fullLog.appendData(
                "SELECT AID",
                aid
            )

            if let (
                response,
                sw1,
                sw2
            ) = await cnTunion_sendAPDU(
                isoTag,
                ins: 0xA4,
                p1: 0x04,
                p2: 0x00,
                data: aid,
                le: 256,
                cla: 0x00,
                fullLog: fullLog
            ),
            sw1 == 0x90,
            sw2 == 0x00 {

                fciData = response

                print(
                    "Selected AID:",
                    aidHex
                )

                fullLog.append(
                    "Selected AID: \(aidHex)"
                )

                fullLog.appendData(
                    "FCI",
                    response
                )

                break

            } else {

                print(
                    "Failed to select AID:",
                    aidHex
                )

                fullLog.append(
                    "Failed to select AID: \(aidHex)"
                )
            }
        }

        guard let fci = fciData else {

            fullLog.append(
                "T-Union application not found"
            )

            fullLog.append(
                "===== T-UNION FULL LOG END ====="
            )

            session.invalidate(
                errorMessage:
                    "T-Union application not found"
            )

            return
        }

        fullLog.append("")
        fullLog.append(
            "===== FCI PARSE ====="
        )

        fullLog.appendData(
            "FCI",
            fci
        )

        _ = cnTunion_parseFCI(
            fci,
            fullLog: fullLog
        )

        fullLog.append("")
        fullLog.append(
            "===== RAW DUMP ====="
        )

        let managementP1 =
            UInt8(0x80 | 0x17)

        print(
            String(
                format:
                    "--- SFI17_MANAGEMENT READ BINARY P1=%02X P2=00 ---",
                managementP1
            )
        )

        fullLog.append(
            String(
                format:
                    "--- SFI17_MANAGEMENT READ BINARY P1=%02X P2=00 ---",
                managementP1
            )
        )

        if let (
            response,
            sw1,
            sw2
        ) = await cnTunion_sendAPDU(
            isoTag,
            ins: 0xB0,
            p1: managementP1,
            p2: 0x00,
            data: Data(),
            le: 0x3C,
            cla: 0x00,
            fullLog: fullLog
        ) {

            let hex = response
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            let log = String(
                format:
                    "SFI17 SW=%02X%02X LEN=%d EXPECTED=%d RAW=%@",
                sw1,
                sw2,
                response.count,
                0x3C,
                hex
            )

            print(log)
            fullLog.append(log)
        }

        let transactionP2 =
            UInt8((0x18 << 3) | 0x04)

        print(
            String(
                format:
                    "--- SFI18_TRANSACTION P2=%02X ---",
                transactionP2
            )
        )

        fullLog.append(
            String(
                format:
                    "--- SFI18_TRANSACTION P2=%02X ---",
                transactionP2
            )
        )

        for record in 1...20 {

            guard let (
                response,
                sw1,
                sw2
            ) = await cnTunion_sendAPDU(
                isoTag,
                ins: 0xB2,
                p1: UInt8(record),
                p2: transactionP2,
                le: 256,
                cla: 0x00,
                fullLog: fullLog
            ) else {

                print(
                    "SFI18 record=\(record) APDU_FAILED"
                )

                fullLog.append(
                    "SFI18 record=\(record) APDU_FAILED"
                )

                continue
            }

            let hex = response
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            let log = String(
                format:
                    "SFI18 record=%d SW=%02X%02X LEN=%d EXPECTED=23 RAW=%@",
                record,
                sw1,
                sw2,
                response.count,
                hex
            )

            print(log)
            fullLog.append(log)

            if sw1 == 0x6A &&
                sw2 == 0x83 {
                break
            }
        }

        let tripP2 =
            UInt8((0x1E << 3) | 0x04)

        print(
            String(
                format:
                    "--- SFI1E_TRIP P2=%02X ---",
                tripP2
            )
        )

        fullLog.append(
            String(
                format:
                    "--- SFI1E_TRIP P2=%02X ---",
                tripP2
            )
        )

        for record in 1...20 {

            guard let (
                response,
                sw1,
                sw2
            ) = await cnTunion_sendAPDU(
                isoTag,
                ins: 0xB2,
                p1: UInt8(record),
                p2: tripP2,
                le: 256,
                cla: 0x00,
                fullLog: fullLog
            ) else {

                print(
                    "SFI1E record=\(record) APDU_FAILED"
                )

                fullLog.append(
                    "SFI1E record=\(record) APDU_FAILED"
                )

                continue
            }

            let hex = response
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            let log = String(
                format:
                    "SFI1E record=%d SW=%02X%02X LEN=%d EXPECTED=48 RAW=%@",
                record,
                sw1,
                sw2,
                response.count,
                hex
            )

            print(log)
            fullLog.append(log)

            if sw1 == 0x6A &&
                sw2 == 0x83 {
                break
            }
        }

        fullLog.append(
            "===== RAW DUMP END ====="
        )

        fullLog.append("")
        fullLog.append(
            "===== BALANCE ====="
        )

        let rawBalance =
            await cnTunion_getBalanceFallback(
                isoTag,
                fullLog: fullLog
            )

        let rawBalanceText: String

        if let rawBalance {
            rawBalanceText = String(rawBalance)
        } else {
            rawBalanceText = "nil"
        }

        fullLog.append(
            "Raw balance: \(rawBalanceText)"
        )

        fullLog.append("")
        fullLog.append(
            "===== CARD INFO ====="
        )
        let info =
            await cnTunion_getInfoFromFCI(
                fci,
                tag: isoTag,
                fullLog: fullLog
            )

        fullLog.append("")
        fullLog.append(
            "===== HISTORY PARSE ====="
        )

        let (
            history,
            computedBalance
        ) = await cnTunion_readKnownRecords(
            isoTag,
            fullLog: fullLog
        )

        let balance =
            computedBalance ??
            history?.first(
                where: {
                    $0.balance != 0
                }
            )?.balance ??
            rawBalance

        fullLog.append("")
        fullLog.append(
            "===== FINAL RESULT ====="
        )

        let computedBalanceText: String

        if let computedBalance {
            computedBalanceText = String(computedBalance)
        } else {
            computedBalanceText = "nil"
        }

        let finalBalanceText: String
        if let balance {
            finalBalanceText = String(balance)
        } else {
            finalBalanceText = "nil"
        }

        fullLog.append(
            "Computed Balance: \(computedBalanceText)"
        )

        fullLog.append(
            "Final Balance: \(finalBalanceText)"
        )

        fullLog.append(
            "History Count: \(history?.count ?? 0)"
        )

        fullLog.append("")
        fullLog.append(
            "===== T-UNION FULL LOG END ====="
        )

        await MainActor.run {

            self.result = Result(
                balance: balance,
                isHistory: true,
                history: history,
                info: info,
                converter: cnTunion.scanOption.converter,
                isLastHide: false,
                description: cnTunion.scand_description,
                savedAt: Date.now,
                fullLog: fullLog.text
            )

            session.invalidate()
        }
    }


    private func cnTunion_sendAPDU(
        _ tag: NFCISO7816Tag,
        ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data = Data(),
        le: Int = 256,
        cla: UInt8 = 0x00,
        fullLog: CNTRunionFullLog? = nil
    ) async -> (
        Data,
        UInt8,
        UInt8
    )? {

        let apdu = NFCISO7816APDU(
            instructionClass: cla,
            instructionCode: ins,
            p1Parameter: p1,
            p2Parameter: p2,
            data: data,
            expectedResponseLength: le
        )

        let commandHex = data
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        let commandLog = String(
            format:
                "APDU Command: CLA:%02X INS:%02X P1:%02X P2:%02X Le:%d Data:%@",
            cla,
            ins,
            p1,
            p2,
            le,
            commandHex
        )

        print(commandLog)

        fullLog?.append(commandLog)

        do {

            let (
                response,
                sw1,
                sw2
            ) = try await tag.sendCommand(
                apdu: apdu
            )

            let responseHex = response
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            let responseLog = String(
                format:
                    "APDU Response: SW1:%02X SW2:%02X Data:%@",
                sw1,
                sw2,
                responseHex
            )

            print(responseLog)

            fullLog?.append(responseLog)

            return (
                response,
                sw1,
                sw2
            )

        } catch {

            let errorLog =
                "APDU error: \(error.localizedDescription)"

            print(errorLog)

            fullLog?.append(errorLog)

            return nil
        }
    }


    private func cnTunion_parseFCI(
        _ data: Data,
        fullLog: CNTRunionFullLog? = nil
    ) -> [UInt8] {

        var sfiList: [UInt8] = []

        let bytes = [UInt8](data)

        fullLog?.appendData(
            "FCI Parse Input",
            data
        )

        func parseLength(
            _ offset: Int
        ) -> (
            length: Int,
            lengthBytes: Int
        )? {

            guard offset < bytes.count else {
                return nil
            }

            let first = bytes[offset]

            if first & 0x80 == 0 {
                return (
                    Int(first),
                    1
                )
            }

            let numBytes =
                Int(first & 0x7F)

            guard numBytes > 0,
                  offset + numBytes < bytes.count else {
                return nil
            }

            var length = 0

            for i in 1...numBytes {
                length =
                    (length << 8) |
                    Int(bytes[offset + i])
            }

            return (
                length,
                1 + numBytes
            )
        }

        func parseTLV(
            _ start: Int,
            _ end: Int
        ) {

            var index = start

            while index < end {

                let tagStart = index
                var tagLength = 1

                if bytes[index] & 0x1F == 0x1F {

                    index += 1

                    while index < end {

                        tagLength += 1

                        let byte = bytes[index]

                        index += 1

                        if byte & 0x80 == 0 {
                            break
                        }
                    }

                } else {

                    index += 1
                }

                guard tagStart + tagLength <= end else {
                    return
                }

                guard let (
                    length,
                    lengthBytes
                ) = parseLength(index) else {
                    return
                }

                index += lengthBytes

                guard index + length <= end else {
                    return
                }

                let tag =
                    Array(
                        bytes[
                            tagStart..<tagStart + tagLength
                        ]
                    )

                if tag.count == 1,
                   tag[0] == 0x94 {

                    let aflBytes =
                        bytes[
                            index..<index + length
                        ]

                    for i in stride(
                        from: aflBytes.startIndex,
                        to: aflBytes.endIndex,
                        by: 4
                    ) {

                        if i + 3 < aflBytes.endIndex {

                            let sfi =
                                aflBytes[i] >> 3

                            if sfi != 0 &&
                                !sfiList.contains(sfi) {

                                sfiList.append(sfi)
                            }
                        }
                    }
                }

                if tag.count == 1 {

                    let tagValue =
                        tag[0]

                    if tagValue == 0x6F ||
                        tagValue == 0xA5 ||
                        tagValue == 0xBF ||
                        tagValue == 0x70 {

                        parseTLV(
                            index,
                            index + length
                        )
                    }
                }

                index += length
            }
        }

        parseTLV(
            0,
            bytes.count
        )

        let result =
            sfiList
                .map {
                    String($0)
                }
                .joined(separator: ", ")

        print(
            "Parsed SFIs from FCI:",
            result
        )

        fullLog?.append(
            "Parsed SFIs from FCI: \(result)"
        )

        return sfiList
    }


    private func cnTunion_parseFCITag(
        _ data: Data,
        targetTag: [UInt8]
    ) -> Data? {

        let bytes = [UInt8](data)

        func parseLength(
            _ offset: Int,
            _ end: Int
        ) -> (
            length: Int,
            lengthBytes: Int
        )? {

            guard offset < end else {
                return nil
            }

            let first = bytes[offset]

            if first & 0x80 == 0 {

                return (
                    Int(first),
                    1
                )
            }

            let numberOfBytes =
                Int(first & 0x7F)

            guard numberOfBytes > 0,
                  offset + numberOfBytes < end else {
                return nil
            }

            var length = 0

            for i in 1...numberOfBytes {

                length =
                    (length << 8) |
                    Int(bytes[offset + i])
            }

            return (
                length,
                1 + numberOfBytes
            )
        }

        func parseTLV(
            _ start: Int,
            _ end: Int
        ) -> Data? {

            var index = start

            while index < end {

                let tagStart = index
                var tagLength = 1

                if bytes[index] & 0x1F == 0x1F {

                    index += 1

                    while index < end {

                        tagLength += 1

                        let byte = bytes[index]

                        index += 1

                        if byte & 0x80 == 0 {
                            break
                        }
                    }

                } else {

                    index += 1
                }

                guard tagStart + tagLength <= end else {
                    return nil
                }

                guard let (
                    length,
                    lengthBytes
                ) = parseLength(
                    index,
                    end
                ) else {
                    return nil
                }

                index += lengthBytes

                guard index + length <= end else {
                    return nil
                }

                let tag =
                    Array(
                        bytes[
                            tagStart..<tagStart + tagLength
                        ]
                    )

                if tag == targetTag {

                    return Data(
                        bytes[
                            index..<index + length
                        ]
                    )
                }

                let constructed =
                    tag.count == 1 &&
                    (
                        tag[0] == 0x6F ||
                        tag[0] == 0xA5 ||
                        tag[0] == 0x70 ||
                        tag[0] == 0xBF
                    )

                if constructed {

                    if let result =
                        parseTLV(
                            index,
                            index + length
                        ) {

                        return result
                    }
                }

                index += length
            }

            return nil
        }

        return parseTLV(
            0,
            bytes.count
        )
    }


    private func cnTunion_readManagementInfo(
        _ tag: NFCISO7816Tag,
        fullLog: CNTRunionFullLog? = nil
    ) async -> Data? {

        let sfi: UInt8 = 0x17

        let p1 =
            UInt8(0x80 | sfi)

        let p2: UInt8 = 0x00

        let title =
            String(
                format:
                    "T-Union SFI 0x17 READ BINARY: CLA=00 INS=B0 P1=%02X P2=%02X Le=3C",
                p1,
                p2
            )

        print(title)

        fullLog?.append(title)

        guard let (
            response,
            sw1,
            sw2
        ) = await cnTunion_sendAPDU(
            tag,
            ins: 0xB0,
            p1: p1,
            p2: p2,
            data: Data(),
            le: 0x3C,
            cla: 0x00,
            fullLog: fullLog
        ) else {

            print(
                "T-Union SFI 0x17 READ BINARY APDU failed"
            )

            fullLog?.append(
                "T-Union SFI 0x17 READ BINARY APDU failed"
            )

            return nil
        }

        let statusLog =
            String(
                format:
                    "T-Union SFI 0x17 READ BINARY: SW=%02X%02X LEN=%d",
                sw1,
                sw2,
                response.count
            )

        print(statusLog)

        fullLog?.append(statusLog)

        fullLog?.appendData(
            "T-Union SFI 0x17 RAW",
            response
        )

        guard sw1 == 0x90,
              sw2 == 0x00 else {

            return nil
        }

        guard response.count >= 8 else {
            return nil
        }

        return response
    }


    private func cnTunion_getCityCode(
        _ tag: NFCISO7816Tag,
        fullLog: CNTRunionFullLog? = nil
    ) async -> String? {

        guard let data =
            await cnTunion_readManagementInfo(
                tag,
                fullLog: fullLog
            ) else {

            print(
                "T-Union city code: SFI 0x17 could not be read"
            )

            fullLog?.append(
                "T-Union city code: SFI 0x17 could not be read"
            )

            return nil
        }

        let bytes = [UInt8](data)

        guard bytes.count >= 8 else {
            return nil
        }

        let internationalCode =
            bytes[0...3]
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

        let provinceCode =
            bytes[4...5]
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

        let cityCodeRaw =
            (UInt16(bytes[6]) << 8) |
            UInt16(bytes[7])

        let cityCode =
            String(
                format: "%04X",
                cityCodeRaw
            )

        print(
            "T-Union SFI 0x17 international code:",
            internationalCode
        )

        print(
            "T-Union SFI 0x17 province code:",
            provinceCode
        )

        print(
            String(
                format:
                    "T-Union SFI 0x17 city code: %02X %02X -> %04X",
                bytes[6],
                bytes[7],
                cityCodeRaw
            )
        )

        fullLog?.append(
            "International Code: \(internationalCode)"
        )

        fullLog?.append(
            "Province Code: \(provinceCode)"
        )

        fullLog?.append(
            "City Code: \(cityCode)"
        )

        if bytes.count >= 10 {

            let unionCardType =
                (UInt16(bytes[8]) << 8) |
                UInt16(bytes[9])

            print(
                String(
                    format:
                        "T-Union SFI 0x17 union card type: %04X",
                    unionCardType
                )
            )

            fullLog?.append(
                String(
                    format:
                        "Union Card Type: %04X",
                    unionCardType
                )
            )
        }

        if bytes.count >= 11 {

            print(
                String(
                    format:
                        "T-Union SFI 0x17 card type: %02X",
                    bytes[10]
                )
            )

            fullLog?.append(
                String(
                    format:
                        "Card Type: %02X",
                    bytes[10]
                )
            )
        }

        return cityCode
    }


    private func cnTunion_getInfoFromFCI(
        _ fci: Data,
        tag: NFCISO7816Tag,
        fullLog: CNTRunionFullLog? = nil
    ) async -> ResultCardInfo? {

        let cityCode =
            await cnTunion_getCityCode(
                tag,
                fullLog: fullLog
            ) ?? ""

        fullLog?.append(
            "City Code: \(cityCode)"
        )

        guard let metadata =
            cnTunion_parseFCITag(
                fci,
                targetTag: [0x9F, 0x0C]
            ) else {

            print(
                "9F0C not found in FCI"
            )

            fullLog?.append(
                "9F0C not found in FCI"
            )

            return ResultCardInfo(
                idm: "",
                name: cnTunion.name,
                nameShort: cnTunion.scanOption.nameShort,
                currencyType: cnTunion.scanOption.currencyType,
                type: cityCode,
                serial: nil,
                version: nil,
                validDate: nil
            )
        }

        let bytes = [UInt8](metadata)

        fullLog?.appendData(
            "9F0C",
            metadata
        )

        guard bytes.count >= 28 else {

            fullLog?.append(
                "9F0C metadata too short: \(bytes.count)"
            )

            return ResultCardInfo(
                idm: "",
                name: cnTunion.name,
                nameShort: cnTunion.scanOption.nameShort,
                currencyType: cnTunion.scanOption.currencyType,
                type: cityCode,
                serial: nil,
                version: nil,
                validDate: nil
            )
        }

        let cardNumberBytes =
            bytes[10..<20]

        let issueDateBytes =
            bytes[20..<24]

        let expiryDateBytes =
            bytes[24..<28]

        let cardNumber =
            cardNumberBytes
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

        let issueDate =
            issueDateBytes
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

        let expiryDate =
            expiryDateBytes
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

        var version = ""

        if let versionData =
            cnTunion_parseFCITag(
                fci,
                targetTag: [0x9F, 0x08]
            ) {

            version =
                versionData
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined()

            fullLog?.appendData(
                "9F08 Version",
                versionData
            )
        } else {

            fullLog?.append(
                "9F08 Version: not found"
            )
        }

        print(
            "T-Union card number:",
            cardNumber
        )

        print(
            "T-Union version:",
            version
        )

        print(
            "T-Union issue date:",
            issueDate
        )

        print(
            "T-Union expiry date:",
            expiryDate
        )

        print(
            "T-Union city code:",
            cityCode
        )

        fullLog?.append(
            "Card Number: \(cardNumber)"
        )

        fullLog?.append(
            "Version: \(version)"
        )

        fullLog?.append(
            "Issue Date: \(issueDate)"
        )

        fullLog?.append(
            "Expiry Date: \(expiryDate)"
        )
        
        var issueArea:String? = nil
        var issueCity:String? = nil
        var issuer:String? = nil

        return ResultCardInfo(
            idm: cardNumber,
            name: cnTunion.name,
            nameShort: cnTunion.scanOption.nameShort,
            currencyType: cnTunion.scanOption.currencyType,
            type: cityCode,
            serial: cardNumber,
            version: version,
            validDate:
                "\(issueDate)-\(expiryDate)",
            issueInfo: issueInfo(region:cnTunion.area.rawValue,area:issueArea,city:issueCity,issuer:issuer)
        )
    }


    private func cnTunion_getBalanceFallback(
        _ tag: NFCISO7816Tag,
        fullLog: CNTRunionFullLog? = nil
    ) async -> Double? {

        fullLog?.append(
            "GET BALANCE"
        )

        guard let (
            resp,
            sw1,
            sw2
        ) = await cnTunion_sendAPDU(
            tag,
            ins: 0x5C,
            p1: 0x00,
            p2: 0x02,
            data: Data(),
            le: 4,
            cla: 0x80,
            fullLog: fullLog
        ) else {

            fullLog?.append(
                "GET BALANCE: APDU failed"
            )

            return nil
        }

        guard sw1 == 0x90,
              sw2 == 0x00,
              resp.count >= 4 else {

            fullLog?.append(
                String(
                    format:
                        "GET BALANCE failed: SW=%02X%02X LEN=%d",
                    sw1,
                    sw2,
                    resp.count
                )
            )

            return nil
        }

        let value =
            (UInt32(resp[0]) << 24) |
            (UInt32(resp[1]) << 16) |
            (UInt32(resp[2]) << 8) |
            UInt32(resp[3])

        let balance =
            Double(value) / 100.0

        print(
            String(
                format:
                    "Balance decode: %02X %02X %02X %02X -> %u / 100 = %.2f",
                resp[0],
                resp[1],
                resp[2],
                resp[3],
                value,
                balance
            )
        )

        fullLog?.append(
            String(
                format:
                    "Balance decode: %02X %02X %02X %02X -> %u / 100 = %.2f",
                resp[0],
                resp[1],
                resp[2],
                resp[3],
                value,
                balance
            )
        )

        return balance
    }


    private func cnTunion_readKnownRecords(
        _ tag: NFCISO7816Tag,
        fullLog: CNTRunionFullLog? = nil
    ) async -> (
        history: [ResultHistory]?,
        computedBalance: Double?
    ) {

        var transactionLogs:
            [ResultHistory] = []

        var tripLogs:
            [ResultHistory] = []

        let p2 =
            UInt8(
                (0x18 << 3) | 0x04
            )

        fullLog?.append(
            "===== PARSE SFI18 ====="
        )

        for record in 1...20 {

            guard let (
                resp,
                sw1,
                sw2
            ) = await cnTunion_sendAPDU(
                tag,
                ins: 0xB2,
                p1: UInt8(record),
                p2: p2,
                le: 256,
                cla: 0x00,
                fullLog: fullLog
            ) else {
                continue
            }

            if sw1 == 0x90 &&
                sw2 == 0x00 &&
                resp.count >= 23 &&
                !resp.allSatisfy({ $0 == 0 }) {

                let parsed =
                    cnTunion_parseTransactionRecord(
                        resp,
                        fullLog: fullLog
                    )

                transactionLogs.append(
                    contentsOf: parsed
                )
            }
        }

        let tripP2 =
            UInt8(
                (0x1E << 3) | 0x04
            )

        fullLog?.append(
            "===== PARSE SFI1E ====="
        )

        for record in 1...20 {

            guard let (
                resp,
                sw1,
                sw2
            ) = await cnTunion_sendAPDU(
                tag,
                ins: 0xB2,
                p1: UInt8(record),
                p2: tripP2,
                le: 256,
                cla: 0x00,
                fullLog: fullLog
            ) else {
                continue
            }

            if sw1 == 0x90 &&
                sw2 == 0x00 &&
                resp.count >= 48 &&
                !resp.allSatisfy({ $0 == 0 }) {

                let parsed =
                    cnTunion_parseTripRecord(
                        resp,
                        fullLog: fullLog
                    )

                tripLogs.append(
                    contentsOf: parsed
                )
            }
        }

        var seenTrip =
            Set<String>()

        tripLogs =
            tripLogs.filter { log in

                let key =
                    "\(log.date.year ?? 0)-" +
                    "\(log.date.month ?? 0)-" +
                    "\(log.date.day ?? 0)-" +
                    "\(log.date.hour ?? 0)-" +
                    "\(log.date.minute ?? 0)-" +
                    "\(log.date.second ?? 0)|" +
                    "\(log.processType)|" +
                    "\(log.amount ?? 0)|" +
                    "\(log.balance)"

                if seenTrip.contains(key) {
                    return false
                }

                seenTrip.insert(key)

                return true
            }

        func dateValue(
            _ h: ResultHistory
        ) -> Date {

            Calendar.current.date(
                from: h.date
            ) ?? .distantPast
        }

        var computedBalance:
            Double? = nil

        if let anchor =
            tripLogs.max(
                by: {
                    dateValue($0) <
                    dateValue($1)
                }
            ) {

            let anchorDate =
                dateValue(anchor)

            var balance =
                anchor.balance

            let newerTransactions =
                transactionLogs
                    .filter {
                        dateValue($0) >
                        anchorDate
                    }
                    .sorted {
                        dateValue($0) <
                        dateValue($1)
                    }

            for t in newerTransactions {

                balance +=
                    t.amount ?? 0.0

                if let index =
                    transactionLogs.firstIndex(
                        where: {
                            dateValue($0) ==
                                dateValue(t) &&
                            $0.transactionId ==
                                t.transactionId
                        }
                    ) {

                    let old =
                        transactionLogs[index]

                    if !(
                        old.processType != 0x03 &&
                        abs(old.amount ?? 0.0) < 0.001
                    ) {

                        transactionLogs[index] =
                            ResultHistory(
                                processType:
                                    old.processType,
                                date:
                                    old.date,
                                balance:
                                    balance,
                                amount:
                                    old.amount,
                                lineIn:
                                    old.lineIn,
                                stationIn:
                                    old.stationIn,
                                lineOut:
                                    old.lineOut,
                                stationOut:
                                    old.stationOut,
                                transactionId:
                                    old.transactionId
                            )
                    }
                }
            }

            computedBalance =
                balance
        }

        var logs =
            transactionLogs + tripLogs

        logs.removeAll {
            $0.processType != 0x03 &&
            abs($0.amount ?? 0.0) < 0.001
        }

        logs.sort {

            let d1 =
                dateValue($0)

            let d2 =
                dateValue($1)

            if d1 != d2 {
                return d1 > d2
            }

            return
                $0.transactionId >
                $1.transactionId
        }

        fullLog?.append(
            "Parsed transaction records: \(transactionLogs.count)"
        )

        fullLog?.append(
            "Parsed trip records: \(tripLogs.count)"
        )

        fullLog?.append(
            "Final history count: \(logs.count)"
        )

        let computedBalanceText: String

        if let computedBalance {
            computedBalanceText = String(computedBalance)
        } else {
            computedBalanceText = "nil"
        }

        fullLog?.append(
            "Computed balance: \(computedBalanceText)"
        )

        return (
            logs.isEmpty ? nil : logs,
            computedBalance
        )
    }


    private func cnTunion_parseTransactionRecord(
        _ data: Data,
        fullLog: CNTRunionFullLog? = nil
    ) -> [ResultHistory] {

        let bytes = [UInt8](data)

        guard bytes.count >= 23 else {
            return []
        }

        if bytes.allSatisfy({ $0 == 0 }) {
            return []
        }

        fullLog?.appendData(
            "SFI18 Transaction Record",
            data
        )

        print(
            "Transaction Record Raw:",
            bytes
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")
        )

        let transactionSeq =
            (UInt16(bytes[0]) << 8) |
            UInt16(bytes[1])

        let amountRaw =
            (UInt32(bytes[5]) << 24) |
            (UInt32(bytes[6]) << 16) |
            (UInt32(bytes[7]) << 8) |
            UInt32(bytes[8])

        let processType =
            bytes[9]

        let amount: Double

        switch processType {

        case 0x01, 0x02:

            amount =
                Double(amountRaw) / 100.0

        case 0x06, 0x09:

            amount =
                -Double(amountRaw) / 100.0

        default:

            print(
                "Unknown SFI 0x18 process type:",
                String(
                    format: "%02X",
                    processType
                )
            )

            amount = 0.0
        }

        let date =
            cnTunion_decodeBCDDate(
                bytes[16...22]
            )

        print(
            "T-Union Transaction: " +
            "seq=\(transactionSeq), " +
            "type=\(String(format: "%02X", processType)), " +
            "amount=\(amount)"
        )

        fullLog?.append(
            "Transaction seq=\(transactionSeq) " +
            "type=\(String(format: "%02X", processType)) " +
            "amount=\(amount)"
        )

        if processType != 0x03 &&
            amount < 0.01 {
            return []
        }

        return [
            ResultHistory(
                processType:
                    processType,
                date:
                    date,
                balance:
                    0,
                amount:
                    amount,
                lineIn:
                    0,
                stationIn:
                    0,
                lineOut:
                    0,
                stationOut:
                    0,
                transactionId:
                    100000 +
                    Int(transactionSeq)
            )
        ]
    }


    private func cnTunion_parseTripRecord(
        _ data: Data,
        fullLog: CNTRunionFullLog? = nil
    ) -> [ResultHistory] {

        let bytes = [UInt8](data)

        guard bytes.count >= 48 else {
            return []
        }

        if bytes.allSatisfy({ $0 == 0 }) {
            return []
        }

        fullLog?.appendData(
            "SFI1E Trip Record",
            data
        )

        print(
            "Trip Record Raw:",
            bytes
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")
        )

        let processType =
            bytes[0]

        let amount: Double
        let balance: Double

        switch processType {

        case 0x04, 0x06:

            let amountRaw =
                (UInt32(bytes[17]) << 24) |
                (UInt32(bytes[18]) << 16) |
                (UInt32(bytes[19]) << 8) |
                UInt32(bytes[20])

            amount =
                -Double(amountRaw) / 100.0

            let balanceRaw =
                (UInt32(bytes[21]) << 24) |
                (UInt32(bytes[22]) << 16) |
                (UInt32(bytes[23]) << 8) |
                UInt32(bytes[24])

            balance =
                Double(
                    Int32(bitPattern: balanceRaw)
                ) / 100.0

        case 0x03:

            amount = 0

            let balanceRaw =
                (UInt32(bytes[21]) << 24) |
                (UInt32(bytes[22]) << 16) |
                (UInt32(bytes[23]) << 8) |
                UInt32(bytes[24])

            balance =
                Double(
                    Int32(bitPattern: balanceRaw)
                ) / 100.0

        default:

            print(
                "Unknown T-Union trip record type:",
                String(
                    format: "%02X",
                    processType
                )
            )

            fullLog?.append(
                String(
                    format:
                        "Unknown T-Union trip record type: %02X",
                    processType
                )
            )

            return []
        }

        let date =
            cnTunion_decodeBCDDate(
                bytes[25...31]
            )

        print(
            "T-Union Trip: " +
            "type=\(String(format: "%02X", processType)), " +
            "amount=\(amount), " +
            "balance=\(balance)"
        )

        fullLog?.append(
            "Trip type=\(String(format: "%02X", processType)) " +
            "amount=\(amount) " +
            "balance=\(balance)"
        )

        if processType != 0x03 &&
            amount < 0.01 {
            return []
        }

        return [
            ResultHistory(
                processType:
                    processType,
                date:
                    date,
                balance:
                    balance,
                amount:
                    amount,
                lineIn:
                    0,
                stationIn:
                    0,
                lineOut:
                    0,
                stationOut:
                    0,
                transactionId:
                    200000 +
                    (
                        Int(bytes[1]) << 8 |
                        Int(bytes[2])
                    )
            )
        ]
    }


    private func cnTunion_decodeBCDDate(
        _ bytes: ArraySlice<UInt8>
    ) -> DateComponents {

        func bcd(
            _ b: UInt8
        ) -> Int {

            Int(
                (b >> 4) * 10 +
                (b & 0x0F)
            )
        }

        let arr =
            Array(bytes)

        guard arr.count == 7 else {
            return DateComponents()
        }

        let year =
            bcd(arr[0]) * 100 +
            bcd(arr[1])

        let month =
            bcd(arr[2])

        let day =
            bcd(arr[3])

        let hour =
            bcd(arr[4])

        let minute =
            bcd(arr[5])

        let second =
            bcd(arr[6])

        return DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
    }
}
