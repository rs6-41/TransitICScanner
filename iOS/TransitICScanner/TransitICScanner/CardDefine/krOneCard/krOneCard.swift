import Foundation
import CoreNFC
import SwiftUI

//MARK: One Card All Pass
//参考：https://github.com/metrodroid/metrodroid/wiki/South-Korea#d4100000030001

let krOneCard = CardInfo(
    logo: "krOneCard_tmoney",
    name: "cardList.krOneCard",
    sortName:"cardList.krOneCard.sortName",
    area: .kr,
    countryCode: ["kr"],
    prefectures: nil,
    regionOption: nil,
    description: String(localized:"cardList.krOneCard.description"),
    scand_description: "",
    searchWords: ["info.krOneCard.cardName.t-money","info.krOneCard.cardName.ezl","info.krOneCard.cardName.reil_plus","info.krOneCard.cardName.onepass","info.krOneCard.cardName.wowpass","cardList.krOneCard"],
    scanOption: ScanOption(
        id: .krOneCard,
        nameShort: "krOneCard.short",
        scanType: .nfc,
        pollingOption:[.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currencyType: .krw,
        converter:.krOneCard,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:10000.0,
            idm:"1041014985038535",
            type:"card.tmoney",
            history: [
            //TODO: 駅コード例を調べる（暫定的に全て1111）
            // 2: チャージ  残高15000ウォン チャージ10000ウォン 2025/19/23 19:21
            ResultHistory(processType: 0x02,date: sampleDay2,balance: 15000,amount: 10000,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 151),
            // 3: 利用 残高10000ウォン 利用5000ウォン 2026/1/3 12:58
            ResultHistory(processType: 0x01,date: sampleDay3,balance: 10000,amount: 5000,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 152),
            ]
        )
)

extension NFCScannerModel {
    func krOneCard_scan(_ tag: NFCTag, _ session: NFCTagReaderSession) {
        guard case let .iso7816(isoTag) = tag else {
            session.invalidate(errorMessage: String(localized: "error.smartCardReader.notISO7816"))
            return
        }
        let send: APDUSend = { cla, ins, p1, p2, data, le in
            let apdu = NFCISO7816APDU(
                instructionClass: cla,
                instructionCode: ins,
                p1Parameter: p1,
                p2Parameter: p2,
                data: data,
                expectedResponseLength: le
            )
            return try await isoTag.sendCommand(apdu: apdu)
        }

        Task {
            guard let result = await krOneCard_result(send) else {
                session.invalidate(errorMessage: String(localized: "error.smartCardReader.oneCardRead"))
                return
            }
            await MainActor.run {
                self.result = result
                session.invalidate()
            }
        }
    }

    func krOneCard_scanExternal(using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let send = manager.apduSender(for: card)
            guard let result = await krOneCard_result(send) else {
                throw ReaderError.message(String(localized: "error.smartCardReader.oneCardRead"))
            }
            return result
        }
        await MainActor.run { self.result = result }
    }

    private func krOneCard_result(_ send: APDUSend) async -> Result? {
        print("Korea OneCard scan started")
            // New Korea OneCard documented AID flow:
            // 1. Select Config DF: A0000004520001
            // 2. Parse FCI for tag 0x4F (main ADF AID) and tag 0x11 (balance APDU descriptor)
            // 3. Select main ADF (tag 0x4F if present, else fallback to D4100000030001)
            // 4. Use balance APDU descriptor if present, else use default documented balance APDU

            let configDFAID = Data([0xA0, 0x00, 0x00, 0x04, 0x52, 0x00, 0x01]) // A0000004520001
            let defaultOneCardADFAID = Data([0xD4, 0x10, 0x00, 0x00, 0x03, 0x00, 0x01])
            var selectedCardType = "Unknown"

            // Step 1: Select Config DF
            print("Selecting Config DF AID: \(configDFAID.map { String(format: "%02X", $0) }.joined())")
            guard let (configFCI, sw1, sw2) = await krOneCard_sendAPDU(send, ins: 0xA4, p1: 0x04, p2: 0x00, data: configDFAID, le: 256, cla: 0x00),
                  sw1 == 0x90 && sw2 == 0x00 else {
                return nil
            }

            // Step 2: Parse Config DF FCI for main ADF AID, balance APDU descriptor, and file descriptors
            let (mainAID, balanceAPDU, fileDescriptors) = krOneCard_parseConfigFCI(configFCI)
            if let mainAID = mainAID {
                print("Main ADF AID from Config FCI: \(mainAID.map { String(format: "%02X", $0) }.joined())")
            } else {
                print("No main ADF AID found in Config FCI, will fallback to default Korea OneCard ADF")
            }
            if let balanceAPDU = balanceAPDU {
                print(String(format: "Balance APDU Descriptor from Config FCI: CLA:%02X INS:%02X P1:%02X P2:%02X Le:%d", balanceAPDU.0, balanceAPDU.1, balanceAPDU.2, balanceAPDU.3, balanceAPDU.4))
            } else {
                print("No balance APDU descriptor found in Config FCI, will use default APDU")
            }

            // Step 3: Select main ADF
            let adfAID: Data = mainAID ?? defaultOneCardADFAID
            var krOneCard_cardTypeName = krOneCard_cardTypeName(for: adfAID)
            selectedCardType = krOneCard_cardTypeName.0
            var issuer:String? = krOneCard_cardTypeName.1
            print("Korea OneCard detected type: \(selectedCardType)")
            print("Selecting main ADF AID: \(adfAID.map { String(format: "%02X", $0) }.joined())")
            guard let (adfFCI, sw1b, sw2b) = await krOneCard_sendAPDU(send, ins: 0xA4, p1: 0x04, p2: 0x00, data: adfAID, le: 256, cla: 0x00),
                  sw1b == 0x90 && sw2b == 0x00 else {
                return nil
            }

            // Step 4: Get balance using descriptor if present, else default
            let balance = await krOneCard_getBalance(send, balanceAPDU)
            print("Final Korea OneCard balance value:", balance ?? -1)


            // Info/history using the selected ADF context and file descriptors
            let info = await krOneCard_getInfoWithSFI(adfFCI, cardTypeName: selectedCardType, issuer: issuer)
            let history = await krOneCard_readKnownRecords(send, fileDescriptors: fileDescriptors)

            print("===== Korea OneCard Result Debug =====")
            print("balance:", balance as Any)
            print("history count:", history?.count as Any)
            print("info:", info as Any)
            print("converter:", krOneCard.scanOption.converter as Any)
            print("================================")

            return Result(
                balance: balance ?? 0,
                isHistory: true,
                history: history ?? [],
                info: info,
                converter: krOneCard.scanOption.converter,
                isLastHide: false,
                description: krOneCard.scand_description,
                savedAt: Date.now
            )
    }

    // MARK: - APDU helpers

    private func krOneCard_sendAPDU(_ send: APDUSend, ins: UInt8, p1: UInt8, p2: UInt8, data: Data = Data(), le: Int = 256, cla: UInt8 = 0x00) async -> (Data, UInt8, UInt8)? {
        do {
            let dataHex = data.map { String(format: "%02X", $0) }.joined()
            print(String(format: "APDU Command: CLA:%02X INS:%02X P1:%02X P2:%02X Data:%@", cla, ins, p1, p2, dataHex))
            let (response, sw1, sw2) = try await send(cla, ins, p1, p2, data, le)
            let responseHex = response.map { String(format: "%02X", $0) }.joined()
            print(String(format: "APDU Response: SW1:%02X SW2:%02X Data:%@", sw1, sw2, responseHex))
            return (response, sw1, sw2)
        } catch {
            print("APDU error:", error.localizedDescription)
            return nil
        }
    }

    // MARK: - Parse Config DF FCI for main ADF and balance APDU descriptor

    /// Returns (mainAID, balanceAPDU) where:
    ///   mainAID: Data? (tag 0x4F, ADF AID)
    ///   balanceAPDU: (cla, ins, p1, p2, le) for balance APDU (tag 0x11, 5 bytes)
    private func krOneCard_parseConfigFCI(_ data: Data) -> (mainAID: Data?, balanceAPDU: (UInt8, UInt8, UInt8, UInt8, Int)?, fileDescriptors: [(fileType: UInt8, sfi: UInt8, maxLength: UInt16)]) {
        let bytes = [UInt8](data)
        var mainAID: Data? = nil
        var balanceAPDU: (UInt8, UInt8, UInt8, UInt8, Int)? = nil
        var descriptors: [(fileType: UInt8, sfi: UInt8, maxLength: UInt16)] = []

        func parseTLVs(_ bytes: [UInt8], _ start: Int, _ end: Int) {
            var idx = start
            while idx < end {
                guard idx < end else { break }
                // Parse tag (support multi-byte BER-TLV tag)
                var tagVal: Int = 0
                let firstTag = bytes[idx]
                idx += 1
                tagVal = Int(firstTag)
                if (firstTag & 0x1F) == 0x1F {
                    // Multi-byte tag
                    while idx < end {
                        let tagByte = bytes[idx]
                        tagVal = (tagVal << 8) | Int(tagByte)
                        idx += 1
                        if (tagByte & 0x80) == 0 { break }
                    }
                }
                // Parse length
                guard idx < end else { break }
                let firstLen = bytes[idx]
                var len = 0
                var lenBytes = 1
                if firstLen & 0x80 == 0 {
                    len = Int(firstLen)
                } else {
                    let num = Int(firstLen & 0x7F)
                    lenBytes = 1 + num
                    guard idx + num < end else { break }
                    len = 0
                    for i in 1...num {
                        len = (len << 8) + Int(bytes[idx + i])
                    }
                }
                idx += lenBytes
                guard idx + len <= end else { break }
                // Handle tags
                if tagVal == 0x4F && mainAID == nil {
                    mainAID = Data(bytes[idx..<idx+len])
                } else if tagVal == 0x11 && balanceAPDU == nil && len == 5 {
                    let b = bytes[idx..<idx+5]
                    balanceAPDU = (b[b.startIndex], b[b.startIndex+1], b[b.startIndex+2], b[b.startIndex+3], Int(b[b.startIndex+4]))
                } else if tagVal == 0x9F10 && len % 3 == 0 {
                    // 9F10 - parse each 3-byte descriptor
                    var j = 0
                    while j+2 < len {
                        let descriptor = [bytes[idx+j], bytes[idx+j+1], bytes[idx+j+2]]
                        let fileType = descriptor[0] >> 5
                        let sfi = descriptor[0] & 0x1F
                        let maxLength = (UInt16(descriptor[1]) << 8) | UInt16(descriptor[2])
                        print("9F10 Descriptor: fileType=\(fileType), SFI=\(sfi), maxLength=\(maxLength)")
                        descriptors.append((fileType, sfi, maxLength))
                        j += 3
                    }
                } else if (firstTag & 0x20) == 0x20 && len > 0 {
                    // Constructed TLV, recurse
                    parseTLVs(bytes, idx, idx+len)
                }
                idx += len
            }
        }
        parseTLVs(bytes, 0, bytes.count)
        return (mainAID, balanceAPDU, descriptors)
    }

    // MARK: - GET BALANCE (T-money documented flow)

    /// If apduDesc present, send exactly that APDU (cla, ins, p1, p2, le). Otherwise use default (CLA=0x90, INS=0x4C, P1=0x00, P2=0x00, Le=4).
    /// Returns balance as UInt32 (KRW, no division).
    private func krOneCard_getBalance(_ send: APDUSend, _ apduDesc: (UInt8, UInt8, UInt8, UInt8, Int)?) async -> Double? {
        let command = apduDesc ?? (0x90, 0x4C, 0x00, 0x00, 4)
        let (cla, ins, p1, p2, le) = command

        guard let (response, sw1, sw2) = await krOneCard_sendAPDU(
            send,
            ins: ins,
            p1: p1,
            p2: p2,
            data: Data(),
            le: le,
            cla: cla
        ) else {
            print("Korea OneCard balance APDU communication failed")
            return nil
        }

        guard sw1 == 0x90 && sw2 == 0x00 else {
            print(String(format: "Korea OneCard balance APDU failed SW=%02X%02X", sw1, sw2))
            return nil
        }

        print("===== Korea OneCard balance raw response =====")
        print("Length:", response.count)
        print("HEX:", response.map { String(format: "%02X", $0) }.joined(separator: " "))
        print("DEC:", response.map { String($0) }.joined(separator: " "))
        print("ASCII:", String(data: response, encoding: .ascii) ?? "nil")
        print("========================================")

        guard response.count >= 4 else {
            print("Korea OneCard balance response length invalid:", response.count)
            return nil
        }

        let bigEndianBalance = UInt32(response[0]) << 24 |
                                UInt32(response[1]) << 16 |
                                UInt32(response[2]) << 8 |
                                UInt32(response[3])

        let littleEndianBalance = UInt32(response[3]) << 24 |
                                  UInt32(response[2]) << 16 |
                                  UInt32(response[1]) << 8 |
                                  UInt32(response[0])

        print("Korea OneCard balance candidates: BE=\(bigEndianBalance) KRW LE=\(littleEndianBalance) KRW")

        if bigEndianBalance != 0 {
            return Double(bigEndianBalance)
        }

        if littleEndianBalance != 0 {
            return Double(littleEndianBalance)
        }

        print("Korea OneCard balance is zero. Keeping zero value because APDU succeeded.")
        return 0.0
    }

    // MARK: - Card type name mapping
    private func krOneCard_cardTypeName(for aid: Data) -> (String,String?) {
        let hex = aid.map { String(format: "%02X", $0) }.joined()

        switch hex {
        case "D4100000030001","D4100000030002","D4100000031010":
            return ("card.tmoney","issue.kr.issuer.tmoney")
        case "D4100000140001","D4100000031310","D4100000031210":
            return ("card.ezl","issue.kr.issuer.ezl")
        case "D4100000060001":
            return ("card.railplus","issue.kr.issuer.railplus")
        case "D4106509900020":
            return ("card.kcash","issue.kr.issuer.kcash")
        case "D4100000300001":
            return ("card.moiba","issue.kr.issuer.moiba")
        default:
            return ("",nil)
        }
    }

    // MARK: - Get Info from T-money ADF FCI (parse tag B0 after SELECT)
    private func krOneCard_getInfoWithSFI(_ adfFCI: Data, cardTypeName: String, issuer:String?) async -> ResultCardInfo? {
        print("===== Korea OneCard ADF FCI raw =====")
        print(adfFCI.map { String(format: "%02X", $0) }.joined(separator: " "))
        print("===============================")
        let purseInfo = krOneCard_findTLV(adfFCI, tag: 0xB0)
        guard let b0 = purseInfo else {
            return ResultCardInfo(
                idm: "",
                name: krOneCard.name,
                nameShort: krOneCard.scanOption.nameShort,
                currencyType: krOneCard.scanOption.currencyType,
                type: "",
                serial: nil,
                version: nil,
                validDate: nil,
                issueInfo: issueInfo(region:krOneCard.area.rawValue,issuer:issuer)
            )
        }
        // Published Korea OneCard B0 layout:
        // 0: CARDTYPE (1 byte)
        // 1: ALG (1 byte)
        // 2: VK (1 byte)
        // 3: IDCENTER (1 byte)
        // 4-11: CSN (8 bytes)
        // 12-16: IDTR (5 bytes)
        // 17-20: Issue date (4 bytes, BCD YYYYMMDD)
        // 21-24: Expiry date (4 bytes, BCD YYYYMMDD)
        // 25: USERCODE (1 byte)
        // 26: DISRATE (1 byte)
        // 27-30: BALMAX (4 bytes, UInt32 big-endian)
        let arr = [UInt8](b0)
        let cardType = arr.count > 0 ? String(format:"%02X", arr[0]) : ""
        let alg = arr.count > 1 ? String(format:"%02X", arr[1]) : ""
        let vk = arr.count > 2 ? String(format:"%02X", arr[2]) : ""
        let idCenter = arr.count > 3 ? String(format:"%02X", arr[3]) : ""
        let csn = arr.count >= 12 ? arr[4...11].map { String(format:"%02X", $0) }.joined() : ""
        let issueDate = arr.count >= 21 ? krOneCard_decodeBCDDateString(arr[17...20]) : nil
        let expiryDate = arr.count >= 25 ? krOneCard_decodeBCDDateString(arr[21...24]) : nil
        let userCode = arr.count > 25 ? String(format:"%02X", arr[25]) : nil
        let balMax: String? = arr.count >= 31 ? String((UInt32(arr[27]) << 24) | (UInt32(arr[28]) << 16) | (UInt32(arr[29]) << 8) | UInt32(arr[30])) : nil
        // Debug prints
        print("Korea OneCard B0 CARDTYPE: \(cardType)")
        print("Korea OneCard B0 ALG: \(alg)")
        print("Korea OneCard B0 VK: \(vk)")
        print("Korea OneCard B0 IDCENTER: \(idCenter)")
        print("Korea OneCard B0 CSN: \(csn)")
        print("Korea OneCard B0 Issue Date: \(issueDate ?? "nil")")
        print("Korea OneCard B0 Expiry Date: \(expiryDate ?? "nil")")
        print("Korea OneCard B0 USERCODE: \(userCode ?? "nil")")
        print("Korea OneCard B0 BALMAX: \(balMax ?? "nil")")
        let validity = [issueDate, expiryDate].compactMap{$0}.joined(separator:"-")
        return ResultCardInfo(
            idm: csn,
            name: krOneCard.name,
            nameShort: krOneCard.scanOption.nameShort,
            currencyType: krOneCard.scanOption.currencyType,
            type: cardTypeName,
            serial: csn.isEmpty ? nil : csn,
            version: cardType.isEmpty ? nil : cardType,
            validDate: validity.isEmpty ? nil : validity,
            issueInfo: issueInfo(region:krOneCard.area.rawValue,issuer:issuer)
        )
    }

    private func krOneCard_findTLV(_ data: Data, tag: UInt8) -> Data? {
        let bytes = [UInt8](data)

        func parse(_ start: Int, _ end: Int) -> Data? {
            var idx = start
            while idx < end {
                let t = bytes[idx]
                idx += 1
                guard idx < end else { break }

                var len = Int(bytes[idx])
                idx += 1
                if len & 0x80 != 0 {
                    let count = len & 0x7F
                    len = 0
                    for _ in 0..<count {
                        guard idx < end else { break }
                        len = (len << 8) | Int(bytes[idx])
                        idx += 1
                    }
                }

                guard idx + len <= end else { break }

                if t == tag {
                    return Data(bytes[idx..<idx + len])
                }

                if (t & 0x20) != 0 {
                    if let result = parse(idx, idx + len) {
                        return result
                    }
                }

                idx += len
            }
            return nil
        }

        return parse(0, bytes.count)
    }

    private func krOneCard_decodeBCDDateString(_ bytes: ArraySlice<UInt8>) -> String? {
        let arr = Array(bytes)
        guard arr.count == 4 else { return nil }
        func bcd(_ b: UInt8) -> Int {
            return Int((b >> 4) * 10 + (b & 0x0F))
        }
        let year = bcd(arr[0]) * 100 + bcd(arr[1])
        let month = bcd(arr[2])
        let day = bcd(arr[3])
        if year == 0 && month == 0 && day == 0 { return nil }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    // MARK: - Read T-money Transaction Records (proprietary GET RECORD and fallback SFI)
    private func krOneCard_readKnownRecords(_ send: APDUSend, fileDescriptors: [(fileType: UInt8, sfi: UInt8, maxLength: UInt16)]) async -> [ResultHistory]? {
        var logs: [ResultHistory] = []

        let recordLength = 52

        // KS X 6924 transaction history is stored in EFTRANS. Android implementations
        // expose it through SFI 4 (and sometimes mirrored SFI 5). The Config DF
        // descriptor SFI=3 is not the transaction record file on these cards.
        for sfi in [UInt8(4)] {
            print("Reading Korea OneCard transaction records SFI: \(sfi)")

            if sfi == 4 {
                let efTrans = Data([0x00, 0x03])
                _ = await krOneCard_sendAPDU(
                    send,
                    ins: 0xA4,
                    p1: 0x00,
                    p2: 0x0C,
                    data: efTrans,
                    le: 256,
                    cla: 0x00
                )
            }

            for record in 1...20 {
                let p2 = (sfi << 3) | 0x04

                var readResult = await krOneCard_sendAPDU(
                    send,
                    ins: 0xB2,
                    p1: UInt8(record),
                    p2: p2,
                    data: Data(),
                    le: recordLength,
                    cla: 0x00
                )

                if let (_, sw1, sw2) = readResult, sw1 == 0x6C {
                    readResult = await krOneCard_sendAPDU(
                        send,
                        ins: 0xB2,
                        p1: UInt8(record),
                        p2: p2,
                        data: Data(),
                        le: Int(sw2),
                        cla: 0x00
                    )
                }

                guard let (response, sw1, sw2) = readResult else {
                    continue
                }

                print("===== Korea OneCard READ RECORD raw =====")
                print("SFI: \(sfi) Record: \(record)")
                print("SW: \(String(format: "%02X%02X", sw1, sw2))")
                print("HEX: " + response.map { String(format: "%02X", $0) }.joined(separator: " "))
                print("===================================")

                guard sw1 == 0x90 && sw2 == 0x00 else {
                    continue
                }

                if let history = krOneCard_parseTransactionRecord(response) {
                    if !logs.contains(where: { $0.transactionId == history.transactionId && $0.date == history.date }) {
                        logs.append(history)
                    }
                }
            }
        }

        return logs.isEmpty ? [] : logs
    }

    // MARK: - Parse T-money Transaction Record
    /// Parse a T-money EFTRANS transaction record.
    /// Layout follows KS X 6924 EFTRANS: 46 byte record with type, balance, transaction number, fare, terminal ID and BCD timestamp.
    private func krOneCard_parseTransactionRecord(_ data: Data) -> ResultHistory? {
        let bytes = [UInt8](data)

        print("===== Korea OneCard transaction parse =====")
        print(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))
        print("====================================")
        guard bytes.count >= 46 else {
            print("Korea OneCard EFTRANS record too short: \(bytes.count) bytes")
            return nil
        }

        if bytes.allSatisfy({ $0 == 0 }) {
            return nil
        }

        let processType = bytes[0]

        let balance = Double((UInt32(bytes[2]) << 24) | (UInt32(bytes[3]) << 16) | (UInt32(bytes[4]) << 8) | UInt32(bytes[5]))
        let transactionId = Int((UInt32(bytes[6]) << 24) | (UInt32(bytes[7]) << 16) | (UInt32(bytes[8]) << 8) | UInt32(bytes[9]))
        let amount = Double((UInt32(bytes[10]) << 24) | (UInt32(bytes[11]) << 16) | (UInt32(bytes[12]) << 8) | UInt32(bytes[13]))
        let date = krOneCard_decodeBCDDate(bytes[26...32])

        print("Korea OneCard Transaction type=\(String(format: "%02X", processType)) amount=\(amount) balance=\(balance) transaction=\(transactionId) date=\(date)")

        return ResultHistory(
            processType: processType,
            date: date,
            balance: balance,
            amount: amount,
            lineIn: 0,
            stationIn: 0,
            lineOut: 0,
            stationOut: 0,
            transactionId: transactionId
        )
    }

    /// Helper: Decode 7-byte BCD date (YYYYMMDDhhmmss) to DateComponents
    private func krOneCard_decodeBCDDate(_ bytes: ArraySlice<UInt8>) -> DateComponents {
        func bcd(_ b: UInt8) -> Int {
            return Int((b >> 4) * 10 + (b & 0x0F))
        }
        let arr = Array(bytes)
        guard arr.count == 7 else { return DateComponents() }
        let year = bcd(arr[0]) * 100 + bcd(arr[1])
        let month = bcd(arr[2])
        let day = bcd(arr[3])
        let hour = bcd(arr[4])
        let minute = bcd(arr[5])
        let second = bcd(arr[6])
        return DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }
}
