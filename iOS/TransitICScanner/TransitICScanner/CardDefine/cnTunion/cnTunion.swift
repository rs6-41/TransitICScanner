import Foundation
import SwiftUI
import CoreNFC


let cnTunion = CardInfo(
    logo: "cnTunion_beijing",
    name: "cardList.cnTunion",
    sortName:"cardList.cnTunion.sortName",
    area: .cn,
    countryCode: ["cn","hk","mo"],
    description: String(localized:"cardList.cnTunion.description"),
    scand_description: "",
    searchWords: ["zhongguojiaotonglianhe"],
    scanOption: ScanOption(
        name: "cnTunion",
        nameShort: String(localized:"cnTunion.short"),
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
            balance:295.0,
            idm:"03102469381485733939",
            type:"北京一卡通",
            history: [
            //TODO: 駅コード例を調べる（暫定的に全て1111）
            // 2: 100RMB チャージ 残高300RMB 2025/19/23 19:21
            ResultHistory(processType: 0x02,date: sampleDay2,balance: 300,amount: 100,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 151),
            // 3: 5RMB 改札 残高295RMB 2026/1/3 12:58
            ResultHistory(processType: 0x04,date: sampleDay3,balance: 295,amount: 15,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 152),
            ]
        )
)

extension NFCScannerModel {

    func cnTunion_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession
    ) {
        guard case let .iso7816(isoTag) = tag else {
            session.invalidate(errorMessage: "Not ISO7816 tag")
            return
        }

        print("T-Union scan started")

        print(
            "ISO7816 identifier:",
            isoTag.identifier
                .map { String(format: "%02X", $0) }
                .joined()
        )

        let aid = isoTag.initialSelectedAID

        if aid.isEmpty {
            print("Initial Selected AID: empty")
        } else {
            print(
                "Initial Selected AID:",
                aid.utf8
                    .map { String(format: "%02X", $0) }
                    .joined()
            )
        }

        print(
            "Historical Bytes:",
            isoTag.historicalBytes?
                .map { String(format: "%02X", $0) }
                .joined() ?? "nil"
        )

        print(
            "Application Data:",
            isoTag.applicationData?
                .map { String(format: "%02X", $0) }
                .joined() ?? "nil"
        )

        Task {
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

            var fciData: Data? = nil

            for aid in aids {
                print(
                    "Selecting AID:",
                    aid
                        .map { String(format: "%02X", $0) }
                        .joined()
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
                    cla: 0x00
                ),
                sw1 == 0x90,
                sw2 == 0x00 {
                    fciData = response

                    print(
                        "Selected AID:",
                        aid
                            .map { String(format: "%02X", $0) }
                            .joined()
                    )

                    break
                } else {
                    print(
                        "Failed to select AID:",
                        aid
                            .map { String(format: "%02X", $0) }
                            .joined()
                    )
                }
            }

            guard let fci = fciData else {
                session.invalidate(
                    errorMessage: "T-Union application not found"
                )
                return
            }

            print("===== T-Union RAW DUMP START =====")

            let managementP1 =
                UInt8(0x80 | 0x17)

            print(
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
                cla: 0x00
            ) {
                let hex = response
                    .map { String(format: "%02X", $0) }
                    .joined(separator: " ")

                print(
                    String(
                        format:
                            "SFI17 SW=%02X%02X LEN=%d EXPECTED=%d RAW=%@",
                        sw1,
                        sw2,
                        response.count,
                        0x3C,
                        hex
                    )
                )
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
                    cla: 0x00
                ) else {
                    print(
                        "SFI18 record=\(record) APDU_FAILED"
                    )
                    continue
                }

                let hex = response
                    .map { String(format: "%02X", $0) }
                    .joined(separator: " ")

                print(
                    "SFI18 record=\(record) " +
                    "SW=\(String(format: "%02X%02X", sw1, sw2)) " +
                    "LEN=\(response.count) " +
                    "EXPECTED=23 " +
                    "RAW=\(hex)"
                )

                if sw1 == 0x6A && sw2 == 0x83 {
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
                    cla: 0x00
                ) else {
                    print(
                        "SFI1E record=\(record) APDU_FAILED"
                    )
                    continue
                }

                let hex = response
                    .map { String(format: "%02X", $0) }
                    .joined(separator: " ")

                print(
                    "SFI1E record=\(record) " +
                    "SW=\(String(format: "%02X%02X", sw1, sw2)) " +
                    "LEN=\(response.count) " +
                    "EXPECTED=48 " +
                    "RAW=\(hex)"
                )

                if sw1 == 0x6A && sw2 == 0x83 {
                    break
                }
            }

            print("===== T-Union RAW DUMP END =====")

            _ = cnTunion_parseFCI(fci)

            let rawBalance =
                await cnTunion_getBalanceFallback(isoTag)

            let info =
                await cnTunion_getInfoFromFCI(
                    fci,
                    tag: isoTag
                )

            let (
                history,
                computedBalance
            ) = await cnTunion_readKnownRecords(
                isoTag
            )

            let balance =
                computedBalance ??
                history?.first(
                    where: {
                        $0.balance != 0
                    }
                )?.balance ??
                rawBalance

            await MainActor.run {
                self.result = Result(
                    balance: balance,
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: cnTunion.scanOption.converter,
                    isLastHide: false,
                    description: cnTunion.scand_description,
                    savedAt: Date.now
                )

                session.invalidate()
            }
        }
    }

    private func cnTunion_sendAPDU(
        _ tag: NFCISO7816Tag,
        ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data = Data(),
        le: Int = 256,
        cla: UInt8 = 0x00
    ) async -> (Data, UInt8, UInt8)? {

        let apdu = NFCISO7816APDU(
            instructionClass: cla,
            instructionCode: ins,
            p1Parameter: p1,
            p2Parameter: p2,
            data: data,
            expectedResponseLength: le
        )

        do {
            let dataHex = data
                .map { String(format: "%02X", $0) }
                .joined()

            print(
                String(
                    format:
                        "APDU Command: CLA:%02X INS:%02X P1:%02X P2:%02X Data:%@",
                    cla,
                    ins,
                    p1,
                    p2,
                    dataHex
                )
            )

            let (
                response,
                sw1,
                sw2
            ) = try await tag.sendCommand(
                apdu: apdu
            )

            let responseHex = response
                .map { String(format: "%02X", $0) }
                .joined()

            print(
                String(
                    format:
                        "APDU Response: SW1:%02X SW2:%02X Data:%@",
                    sw1,
                    sw2,
                    responseHex
                )
            )

            return (
                response,
                sw1,
                sw2
            )
        } catch {
            print(
                "APDU error:",
                error.localizedDescription
            )

            return nil
        }
    }

    private func cnTunion_parseFCI(
        _ data: Data
    ) -> [UInt8] {

        var sfiList: [UInt8] = []
        let bytes = [UInt8](data)

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

        print(
            "Parsed SFIs from FCI:",
            sfiList
                .map { String($0) }
                .joined(separator: ", ")
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
        _ tag: NFCISO7816Tag
    ) async -> Data? {

        let sfi: UInt8 = 0x17

        let p1 =
            UInt8(
                0x80 | sfi
            )

        let p2: UInt8 = 0x00

        print(
            String(
                format:
                    "T-Union SFI 0x17 READ BINARY: " +
                    "CLA=00 INS=B0 P1=%02X P2=%02X Le=3C",
                p1,
                p2
            )
        )

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
            cla: 0x00
        ) else {

            print(
                "T-Union SFI 0x17 READ BINARY APDU failed"
            )

            return nil
        }

        print(
            String(
                format:
                    "T-Union SFI 0x17 READ BINARY: " +
                    "SW=%02X%02X LEN=%d",
                sw1,
                sw2,
                response.count
            )
        )

        print(
            "T-Union SFI 0x17 RAW:",
            response
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")
        )

        guard sw1 == 0x90,
              sw2 == 0x00 else {

            print(
                String(
                    format:
                        "T-Union SFI 0x17 READ BINARY failed: SW=%02X%02X",
                    sw1,
                    sw2
                )
            )

            return nil
        }

        guard response.count >= 8 else {

            print(
                "T-Union SFI 0x17 data too short:",
                response.count
            )

            return nil
        }

        return response
    }

    private func cnTunion_getCityCode(
        _ tag: NFCISO7816Tag
    ) async -> String? {

        guard let data =
            await cnTunion_readManagementInfo(
                tag
            ) else {

            print(
                "T-Union city code: SFI 0x17 could not be read"
            )

            return nil
        }

        let bytes = [UInt8](data)

        guard bytes.count >= 8 else {

            print(
                "T-Union city code: invalid SFI 0x17 length"
            )

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
        }

        if bytes.count >= 11 {

            print(
                String(
                    format:
                        "T-Union SFI 0x17 card type: %02X",
                    bytes[10]
                )
            )
        }

        return cityCode
    }

    private func cnTunion_getInfoFromFCI(
        _ fci: Data,
        tag: NFCISO7816Tag
    ) async -> ResultCardInfo? {

        let cityCode =
            await cnTunion_getCityCode(tag) ?? ""

        guard let metadata =
            cnTunion_parseFCITag(
                fci,
                targetTag: [0x9F, 0x0C]
            ) else {

            print(
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

        print(
            "T-Union 9F0C:",
            bytes
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")
        )

        guard bytes.count >= 28 else {

            print(
                "9F0C metadata too short:",
                bytes.count
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

        return ResultCardInfo(
            idm: cardNumber,
            name: cnTunion.name,
            nameShort: cnTunion.scanOption.nameShort,
            currencyType: cnTunion.scanOption.currencyType,
            type: cityCode,
            serial: cardNumber,
            version: version,
            validDate:
                "\(issueDate)-\(expiryDate)"
        )
    }

    private func cnTunion_getBalanceFallback(
        _ tag: NFCISO7816Tag
    ) async -> Double? {

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
            cla: 0x80
        ),
        sw1 == 0x90,
        sw2 == 0x00,
        resp.count >= 4 else {

            return nil
        }

        let value =
            (UInt32(resp[0]) << 24) |
            (UInt32(resp[1]) << 16) |
            (UInt32(resp[2]) << 8) |
            UInt32(resp[3])

        print(
            String(
                format:
                    "Balance decode: %02X %02X %02X %02X -> %u / 100 = %.2f",
                resp[0],
                resp[1],
                resp[2],
                resp[3],
                value,
                Double(value) / 100.0
            )
        )

        return Double(value) / 100.0
    }

    private func cnTunion_readKnownRecords(
        _ tag: NFCISO7816Tag
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
                cla: 0x00
            ) else {
                continue
            }

            if sw1 == 0x90 &&
                sw2 == 0x00 &&
                resp.count >= 23 &&
                !resp.allSatisfy({ $0 == 0 }) {

                transactionLogs.append(
                    contentsOf:
                        cnTunion_parseTransactionRecord(
                            resp
                        )
                )
            }
        }

        let tripP2 =
            UInt8(
                (0x1E << 3) | 0x04
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
                cla: 0x00
            ) else {
                continue
            }

            if sw1 == 0x90 &&
                sw2 == 0x00 &&
                resp.count >= 48 &&
                !resp.allSatisfy({ $0 == 0 }) {

                tripLogs.append(
                    contentsOf:
                        cnTunion_parseTripRecord(
                            resp
                        )
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

        return (
            logs.isEmpty ? nil : logs,
            computedBalance
        )
    }

    private func cnTunion_parseTransactionRecord(
        _ data: Data
    ) -> [ResultHistory] {

        let bytes = [UInt8](data)

        guard bytes.count >= 23 else {
            return []
        }

        if bytes.allSatisfy({ $0 == 0 }) {
            return []
        }

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
        _ data: Data
    ) -> [ResultHistory] {

        let bytes = [UInt8](data)

        guard bytes.count >= 48 else {
            return []
        }

        if bytes.allSatisfy({ $0 == 0 }) {
            return []
        }

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
