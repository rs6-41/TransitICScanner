import CoreNFC
import Foundation

let spEZLink = CardInfo(
    logo: "spEZLink",
    name: "cardList.spEZLink",
    sortName: "cardList.spEZLink",
    area: .sg,
    countryCode: ["sg"],
    prefectures: nil,
    regionOption: nil,
    description: "cardList.spEZLink.description",
    scannedDescription: "",
    searchWords: ["EZ-Link", "EZLink", "CEPAS"],
    scanOption: ScanOption(
        id: .spEZLink,
        nameShort: "cardList.spEZLink",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 32,
        currencyType: .sgd,
        converter: .spEZLink,
        scrapingView: nil
    ),
    information: nil,
    sample: nil
)

extension NFCScannerModel {
    func spEZLinkScan(_ tag: NFCTag, _ session: NFCTagReaderSession) {
        guard case let .iso7816(isoTag) = tag else {
            session.invalidate(errorMessage: String(localized: "error.smartCardReader.notISO7816"))
            return
        }
        let send: APDUSend = { cla, ins, p1, p2, data, le in
            let apdu = NFCISO7816APDU(
                instructionClass: cla, instructionCode: ins, p1Parameter: p1, p2Parameter: p2,
                data: data, expectedResponseLength: le
            )
            return try await withCheckedThrowingContinuation { continuation in
                isoTag.sendCommand(apdu: apdu) { data, sw1, sw2, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (data, sw1, sw2))
                    }
                }
            }
        }

        Task { @MainActor in
            do {
                let result = try await spEZLinkResult(using: send)
                completeScan(result, session: session)
            } catch {
                session.invalidate(errorMessage: error.localizedDescription)
            }
        }
    }

    func spEZLinkScanExternal(using manager: SmartCardManager) async throws {
        let scanned = try await manager.withCard { card in
            try await spEZLinkResult(using: manager.apduSender(for: card))
        }
        await MainActor.run { result = scanned }
    }
}

private func spEZLinkResult(using send: APDUSend) async throws -> ScanResult {
    let readError = ReaderError.message(String(localized: "scanner.coreNFC.scanning.error.read"))
    var (data, sw1, _) = try await spEZLinkReadPurse(using: send)
    if sw1 != 0x90 {
        let (_, selectSW1, _) = try await send(0x00, 0xA4, 0x00, 0x00, Data([0x40, 0x00]), 256)
        guard selectSW1 == 0x90 else { throw readError }
        (data, sw1, _) = try await spEZLinkReadPurse(using: send)
    }
    guard sw1 == 0x90, let purse = SPEZLinkPurse.parse(data) else { throw readError }

    let history: [ResultHistory]?
    do {
        let records = try await spEZLinkHistory(using: send, readError: readError)
        history = SPEZLinkHistory.calculatingBalances(records, currentBalanceCents: purse.balanceCents)
    } catch {
        Log.debug("CEPAS history could not be read")
        history = nil
    }

    let name = spEZLink.name
    let info = ResultCardInfo(idm: purse.can, name: name, nameShort: name, currencyType: .sgd, type: "")
    return ScanResult(
        balance: Double(purse.balanceCents) / 100,
        isHistory: history != nil,
        history: history,
        info: info,
        converter: .spEZLink,
        isLastHide: true,
        description: ""
    )
}

private func spEZLinkHistory(using send: APDUSend, readError: ReaderError) async throws -> [ResultHistory] {
    let (first, sw1, sw2) = try await spEZLinkReadPurse(using: send, payload: Data([0]))
    Log.debug(String(format: "CEPAS history first page SW=%02X%02X length=%d", sw1, sw2, first.count))
    if sw1 == 0x6A, sw2 == 0x83 { return [] }
    guard sw1 == 0x90, let firstPage = SPEZLinkHistory.parse(first) else { throw readError }
    guard !first.isEmpty else { return firstPage }

    do {
        let (second, secondSW1, secondSW2) = try await spEZLinkReadPurse(
            using: send, payload: Data([UInt8(first.count / 16)])
        )
        Log.debug(String(format: "CEPAS history second page SW=%02X%02X length=%d", secondSW1, secondSW2, second.count))
        if secondSW1 == 0x90, let secondPage = SPEZLinkHistory.parse(second) {
            return firstPage + secondPage
        }
    } catch {
        Log.debug("CEPAS history second page could not be read")
    }
    return firstPage
}

private func spEZLinkReadPurse(
    using send: APDUSend, payload: Data = Data()
) async throws -> (Data, UInt8, UInt8) {
    let (data, sw1, sw2) = try await send(0x90, 0x32, 0x03, 0x00, payload, 256)
    if sw1 == 0x6C, sw2 != 0 {
        return try await send(0x90, 0x32, 0x03, 0x00, payload, Int(sw2))
    }
    return (data, sw1, sw2)
}
