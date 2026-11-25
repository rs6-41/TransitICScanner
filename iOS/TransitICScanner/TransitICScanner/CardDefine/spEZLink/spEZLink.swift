import CoreNFC
import CryptoTokenKit
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
            let trace = "nfc/" + UUID().uuidString
            do {
                let result = try await spEZLinkResult(using: spEZLinkTracedSender(send, trace: trace))
                completeScan(result, session: session)
            } catch {
                session.invalidate(errorMessage: error.localizedDescription)
            }
        }
    }

    func spEZLinkScanExternal(using manager: SmartCardManager) async throws {
        let scanID = UUID().uuidString
        for attempt in 1...3 {
            let trace = "pcsc/\(scanID)/\(attempt)"
            Log.debug("EZ-Link trace", trace, "session.begin")
            do {
                let scanned = try await manager.withCard { card in
                    Log.debug("EZ-Link trace", trace, "session.ready protocol=\(card.currentProtocol.rawValue)")
                    let send = spEZLinkTracedSender(manager.apduSender(for: card), trace: trace)
                    return try await spEZLinkResult(using: send)
                }
                Log.debug("EZ-Link trace", trace, "scan.ok records=\(scanned.history?.count ?? 0)")
                await MainActor.run { result = scanned }
                return
            } catch SPEZLinkReadError.retryable where attempt < 3 {
                Log.debug("EZ-Link trace", trace, "session.retry")
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                let failure = error as NSError
                Log.debug("EZ-Link trace", trace, "scan.failed domain=\(failure.domain) code=\(failure.code)")
                throw error
            }
        }
    }
}

private func spEZLinkTracedSender(_ send: @escaping APDUSend, trace: String) -> APDUSend {
    { cla, ins, p1, p2, payload, le in
        let command = String(format: "APDU=%02X%02X%02X%02X Lc=%d Le=%d", cla, ins, p1, p2, payload.count, le)
        let offset = ins == 0x32 ? payload.first.map { " offset=\($0)" } ?? "" : ""
        let start = ContinuousClock.now
        do {
            let response = try await send(cla, ins, p1, p2, payload, le)
            let (data, sw1, sw2) = response
            let status = String(format: "SW=%02X%02X bytes=%d", sw1, sw2, data.count)
            let elapsed = start.duration(to: .now)
            Log.debug("EZ-Link trace", trace, command + offset, status, "duration=\(elapsed)")
            if ins == 0x32, payload.isEmpty, sw1 == 0x90 {
                let bytes = Array(data)
                let isEZLinkPrefix = bytes.count >= 10 && bytes[8] == 0x10 && bytes[9] >> 4 == 0
                Log.debug(
                    "EZ-Link trace", trace, "purseHeader ezLinkPrefix=\(isEZLinkPrefix)",
                    "hasFixedFields=\(data.count >= SPEZLinkPurse.minimumResponseLength)")
            }
            return response
        } catch {
            let failure = error as NSError
            Log.debug("EZ-Link trace", trace, command + offset, "domain=\(failure.domain) code=\(failure.code)")
            throw error
        }
    }
}

private enum SPEZLinkReadError: LocalizedError {
    case retryable

    var errorDescription: String? {
        String(localized: "scanner.coreNFC.scanning.error.read")
    }
}

private func spEZLinkResult(using send: APDUSend) async throws -> ScanResult {
    let readError = ReaderError.message(String(localized: "scanner.coreNFC.scanning.error.read"))
    var (data, sw1, sw2) = try await spEZLinkReadPurse(using: send)
    if sw1 != 0x90 {
        let (_, selectSW1, selectSW2) = try await send(0x00, 0xA4, 0x00, 0x00, Data([0x40, 0x00]), 256)
        Log.debug(String(format: "EZ-Link SELECT SW=%02X%02X", selectSW1, selectSW2))
        if selectSW1 == 0x6F, selectSW2 == 0 {
            throw SPEZLinkReadError.retryable
        }
        guard selectSW1 == 0x90 else { throw readError }
        (data, sw1, sw2) = try await spEZLinkReadPurse(using: send)
    }
    Log.debug(String(format: "EZ-Link purse SW=%02X%02X bytes=%d", sw1, sw2, data.count))
    if sw2 == 0, sw1 == 0x6F || sw1 == 0x67 {
        throw SPEZLinkReadError.retryable
    }
    if sw1 == 0x90, data.count < SPEZLinkPurse.minimumResponseLength {
        throw SPEZLinkReadError.retryable
    }
    guard sw1 == 0x90, let purse = SPEZLinkPurse.parse(data) else { throw readError }

    let history: [ResultHistory]?
    do {
        let records = try await spEZLinkHistory(
            using: send, logfileRecordCount: purse.logfileRecordCount, readError: readError
        )
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

private func spEZLinkHistory(
    using send: APDUSend, logfileRecordCount: Int, readError: ReaderError
) async throws -> [ResultHistory] {
    let (first, sw1, sw2) = try await spEZLinkReadPurse(using: send, payload: Data([0]))
    Log.debug(String(format: "CEPAS history first page SW=%02X%02X length=%d", sw1, sw2, first.count))
    if sw1 == 0x6A, sw2 == 0x83 { return [] }
    guard sw1 == 0x90, let firstPage = SPEZLinkHistory.parse(first) else { throw readError }
    let recordsRead = first.count / 16
    Log.debug("EZ-Link history logfile record count:", logfileRecordCount)
    guard recordsRead > 0, logfileRecordCount == 0 || recordsRead < logfileRecordCount else { return firstPage }

    do {
        let (second, secondSW1, secondSW2) = try await spEZLinkReadPurse(
            using: send, payload: Data([UInt8(recordsRead)])
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
    let initial = try await send(0x90, 0x32, 0x03, 0x00, payload, 256)
    let (_, sw1, sw2) = initial
    if sw1 == 0x6C, sw2 != 0 {
        return try await send(0x90, 0x32, 0x03, 0x00, payload, Int(sw2))
    }
    guard payload.isEmpty, sw1 == 0x67, sw2 == 0 else { return initial }

    let response = try await send(0x90, 0x32, 0x03, 0x00, payload, 80)
    Log.debug(String(format: "EZ-Link purse Le=80 SW=%02X%02X bytes=%d", response.1, response.2, response.0.count))
    return response
}
