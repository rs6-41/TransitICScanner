import UIKit
import SwiftUI
@preconcurrency import CoreNFC
public import Combine

// 参考：https://qiita.com/treastrain/items/d54ef2c2abbcd40fb9f1
// 参考：https://github.com/metrodroid/metrodroid/wiki/FeliCa


struct ScanError {
    var code: NFCReaderError.Code?
    var message:String
}


final class NFCScannerModel: NSObject,ObservableObject, NFCTagReaderSessionDelegate {
    
    @Published var scanError:ScanError? = nil
    @Published var scanOption: ScanOption
    @Published var sessionActive: Bool = false
    @Published var result:Result? = nil
    
    var session: NFCTagReaderSession?
    var currentTag: NFCTag?
    
    init(scanOption: ScanOption) {
        self.scanOption = scanOption
        super.init()
    }
    
    //リーダーセッションの設定
    func readerSetup() {
        self.scanError = nil

        let configuration: NFCTagReaderSession.Configuration

        if scanOption.felicaSystemCodes != nil {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption,
                feliCaSystemCodes: scanOption.felicaSystemCodes ?? []
            )
        } else {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption
            )
        }

        self.session = NFCTagReaderSession(configuration: configuration, delegate: self)
        let cardName = scanOption.nameShort
        self.session?.alertMessage = String(
            format: String(localized: "scanner.coreNFC.scan.message"),
            Localize(cardName)
        )
        self.session?.begin()
    }
    
    // セッションがアクティブになった時
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        DispatchQueue.main.async {
            self.sessionActive = true
        }
    }
    
    // 読み取り後
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.sessionActive = false
            self.session = nil

            if let readerError = error as? NFCReaderError {
                if readerError.code.rawValue != 200 {
                    let error = "NFCReaderError\ncode: \(readerError.code.rawValue)\n\(readerError.localizedDescription)"
                    print(error)
                    self.scanError = ScanError(code: readerError.code, message: error)
                }
            } else {
                let error = "Unknown Error\n\(error.localizedDescription)"
                print(error)
                self.scanError = ScanError(code: .readerSessionInvalidationErrorSessionTerminatedUnexpectedly, message: error)
            }
        }
    }
    
    // 読み取り成功後
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("tagReaderSession(_:didDetect:)")
        print("Detected tags: \(tags)")

        self.currentTag = tags.first
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected")
            return
        }

        // Inserted debug information for detected tag
        switch tag {
        case .miFare(let miFareTag):
            print("Detected NFCMiFareTag")
            print("Identifier: \(miFareTag.identifier.map { String(format: "%02X", $0) }.joined())")
            print("Family: \(miFareTag.mifareFamily.rawValue)")
            if let historical = miFareTag.historicalBytes {
                print("Historical: \(historical.map { String(format: "%02X", $0) }.joined(separator: " "))")
            }
        case .iso7816(let tag):

            print("Detected ISO7816")

            print(
                "initialSelectedAID:",
                tag.initialSelectedAID
            )

            print(
                "identifier:",
                tag.identifier
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined()
            )

            if let historicalBytes = tag.historicalBytes {
                print(
                    "historicalBytes:",
                    historicalBytes
                        .map {
                            String(format: "%02X", $0)
                        }
                        .joined(separator: " ")
                )
            }

            if let applicationData = tag.applicationData {
                print(
                    "applicationData:",
                    applicationData
                        .map {
                            String(format: "%02X", $0)
                        }
                        .joined(separator: " ")
                )
            }

            print(
                "proprietaryApplicationDataCoding:",
                tag.proprietaryApplicationDataCoding
            )
        case .feliCa:
            print("Detected FeliCa")
        case .iso15693:
            print("Detected ISO15693")
        @unknown default:
            print("Detected unknown tag")
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            print("connect callback")

            if let error {
                print("Connect error:", error)
                DispatchQueue.main.async {
                    self.session?.invalidate(errorMessage: error.localizedDescription)
                }
                return
            }
            print("connect success")

            DispatchQueue.main.async {
                Task { @MainActor in
                    self.session?.alertMessage = String(localized: "scanner.coreNFC.scanning.message")
                    await self.switchCard(name: self.scanOption.name, tag, session)
                }
            }
        }
    }
    
}

extension NFCScannerModel {
    /// Dispatches scans to a reader-specific transport while keeping the
    /// card parser and result model owned by the scanner.
    func scanWithExternalReader(using manager: SmartCardManager) async throws {
        switch scanOption.name {
        case "jpIC", "jpIC_SAPICA", "jpIC_IruCa", "jpIC_icsca":
            try await scanFeliCaExternal(using: manager)
        case "hkOctopus":
            try await scanOctopusExternal(using: manager)
        case "usClipper":
            try await usClipper_scanExternal(using: manager)
        case "krOneCard":
            try await krOneCard_scanExternal(using: manager)
        case "cnTunion":
            try await cnTunion_scanExternal(using: manager)
        case "twICash":
            try await twICash_scanExternal(using: manager)
        default:
            throw ReaderError.message(
                String(localized: "cardList.reader.unsupported")
            )
        }
    }

    /// Reads FeliCa cards through readers that expose the card as an
    /// ISO 7816 smart card (the `FFCA` / `FFA4` / `FFB0` command set).
    private func scanFeliCaExternal(using manager: SmartCardManager) async throws {
        try await manager.withCard { card in
            let transmit = manager.apduSender(for: card)

            func send(_ cla: UInt8, _ ins: UInt8, _ p1: UInt8, _ p2: UInt8,
                      _ data: Data = Data(), _ le: Int = 0) async throws -> Data {
                let (payload, sw1, sw2) = try await transmit(cla, ins, p1, p2, data, le)
                guard sw1 == 0x90, sw2 == 0x00 else {
                    throw ReaderError.message(String(format: String(localized:
                        "error.smartCardReader.felicaCommandFailed"), Int(sw1), Int(sw2)))
                }
                return payload
            }

            // The transport APDU returns IDm followed by SW1/SW2.
            let idmData = try await send(0xFF, 0xCA, 0x00, 0x00, Data(), 256)
            guard idmData.count >= 8 else {
                throw ReaderError.message(String(localized: "error.smartCardReader.felicaIDm"))
            }
            let idm = idmData.prefix(8).map { String(format: "%02X", $0) }.joined()

            let serviceCode: [UInt8]
            let converter: ConverterType
            let cardName: String
            let shortName: String
            let currency: currencyType
            let isOctopus = self.scanOption.name == "hkOctopus"
            if isOctopus {
                // Octopus purse service 0x0117, encoded little-endian.
                serviceCode = [0x17, 0x01]
                converter = hkOctopus.scanOption.converter
                cardName = hkOctopus.name
                shortName = hkOctopus.scanOption.nameShort
                currency = hkOctopus.scanOption.currencyType
            } else {
                // Suica-compatible information service 0x008B.
                serviceCode = [0x8B, 0x00]
                converter = self.scanOption.converter
                cardName = jpIC.name
                shortName = self.scanOption.nameShort
                currency = self.scanOption.currencyType
            }

            func selectService(_ service: [UInt8]) async throws -> (Bool, UInt8, UInt8) {
                let response = try await transmit(
                    0xFF, 0xA4, 0x00, 0x01,
                    // The reader's FeliCa service-select APDU has no Le byte:
                    // e.g. FFA40001028B00.
                    // `apduSender` adds the Lc byte, so pass only the two
                    // service-code bytes as payload.
                    Data(service), 0
                )
                return (response.1 == 0x90 && response.2 == 0x00, response.1, response.2)
            }

            let infoSelection = try await selectService(serviceCode)
            guard infoSelection.0 else {
                throw ReaderError.message(String(format: String(localized:
                    "error.smartCardReader.felicaInfoService"),
                    Int(infoSelection.1), Int(infoSelection.2)))
            }
            let purse = try await send(0xFF, 0xB0, 0x00, 0x00, Data(), 256)
            guard purse.count >= 16 else {
                throw ReaderError.message(String(localized: "error.smartCardReader.felicaBalance"))
            }

            let balance: Double
            if isOctopus {
                let raw = purse.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
                // Octopus purse value uses tenths of HKD and includes HK$50 deposit.
                balance = Double(max(Int64(raw) - 500, 0)) / 10.0
            } else {
                balance = Double(Int(purse[11]) | (Int(purse[12]) << 8))
            }

            var history: [ResultHistory] = []
            if !isOctopus {
                let historySelection = try await selectService([0x0F, 0x09])
                guard historySelection.0 else {
                    throw ReaderError.message(String(format: String(localized:
                        "error.smartCardReader.felicaHistoryService"),
                        Int(historySelection.1), Int(historySelection.2)))
                }
                for index in 0..<min(max(self.scanOption.historyCount, 0), 19) {
                    let block = try await send(
                        0xFF, 0xB0, 0x00, UInt8(index), Data(), 256
                    )
                    guard block.count >= 16 else { break }
                    let bytes = [UInt8](block.prefix(16))
                    let rawDate = UInt16(bytes[4]) << 8 | UInt16(bytes[5])
                    guard rawDate != 0 else { break }
                    let date = DateComponents(
                        year: Int((rawDate >> 9) & 0x7F) + 2000,
                        month: Int((rawDate >> 5) & 0x0F),
                        day: Int(rawDate & 0x1F)
                    )
                    let transactionBalance = Double(Int(bytes[10]) | (Int(bytes[11]) << 8))
                    history.append(ResultHistory(
                        processType: bytes[1], date: date,
                        balance: transactionBalance, amount: nil,
                        lineIn: bytes[6], stationIn: bytes[7],
                        lineOut: bytes[8], stationOut: bytes[9],
                        transactionId: Int(bytes[13]) << 8 | Int(bytes[14])
                    ))
                }
            }

            let info = ResultCardInfo(
                idm: idm, name: cardName, nameShort: shortName,
                currencyType: currency,
                type: isOctopus ? "" : "card.suica",
                serial: nil, version: nil, validDate: nil,
                issueInfo: issueInfo(region: isOctopus ? hkOctopus.area.rawValue : jpIC.area.rawValue)
            )
            let result = Result(
                balance: balance, isHistory: !isOctopus,
                history: isOctopus ? nil : history, info: info,
                converter: converter, isLastHide: !isOctopus,
                description: isOctopus ? hkOctopus.scand_description : jpIC.scand_description,
                savedAt: Date.now
            )
            await MainActor.run { self.result = result }
        }
    }

    private func scanOctopusExternal(using manager: SmartCardManager) async throws {
        try await scanFeliCaExternal(using: manager)
    }
}

extension Data {
    func toIntReversed(_ startIndex: Int, _ endIndex: Int) -> Int {
        var s = 0
        for (n, i) in (startIndex...endIndex).enumerated() {
            s += Int(self[i]) << (n * 8)
        }
        return s
    }
}
