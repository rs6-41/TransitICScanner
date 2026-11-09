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
    scannedDescription: "",
    searchWords: ["zhongguojiaotonglianhe"],
    scanOption: ScanOption(
        id: .cnTunion,
        nameShort: "cnTunion.short",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currencyType: .rmb,
        converter: .cnTunion,
        scrapingView: nil
    ),
    information: nil,
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
                ),
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
        let hex =
            data
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
        let hex =
            bytes
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
                errorMessage: String(localized: "error.smartCardReader.notISO7816")
            )
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

        let fullLog = CNTRunionFullLog()

        fullLog.append(
            "===== T-UNION FULL LOG START ====="
        )

        fullLog.append(
            "Scan Date: \(Date.now)"
        )

        Log.debug("T-Union scan started")

        fullLog.append(
            "T-Union scan started"
        )

        let identifierHex = isoTag.identifier
            .map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

        Log.debug(
            "ISO7816 identifier:",
            identifierHex
        )

        fullLog.append(
            "ISO7816 identifier [\(isoTag.identifier.count) bytes]: \(identifierHex)"
        )

        let aid = isoTag.initialSelectedAID

        if aid.isEmpty {

            Log.debug(
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

            Log.debug(
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

            Log.debug(
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

            Log.debug(
                "Historical Bytes: nil"
            )
        }

        if let applicationData = isoTag.applicationData {

            fullLog.appendData(
                "Application Data",
                applicationData
            )

            Log.debug(
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

            Log.debug(
                "Application Data: nil"
            )
        }

        fullLog.append("")
        fullLog.append(
            "===== ASYNC SCAN START ====="
        )

        Task { @MainActor [self] in
            await cnTunion_scanAsync(
                send,
                session: session,
                fullLog: fullLog
            )
        }
    }

    func cnTunion_scanExternal(using manager: SmartCardManager) async throws {
        try await manager.withCard { card in
            let fullLog = CNTRunionFullLog()
            fullLog.append("===== T-UNION FULL LOG START =====")
            fullLog.append("Scan Date: \(Date.now)")
            fullLog.append("T-Union scan started with external reader")

            await cnTunion_scanAsync(
                manager.apduSender(for: card),
                session: nil,
                fullLog: fullLog
            )
        }
    }

    @MainActor
    func cnTunion_scanAsync(
        _ send: APDUSend,
        session: NFCTagReaderSession?,
        fullLog: CNTRunionFullLog
    ) async {

        let aids: [Data] = [
            Data([
                0xA0, 0x00, 0x00, 0x06,
                0x32, 0x01, 0x01, 0x05,
            ]),
            Data([
                0xA0, 0x00, 0x00, 0x06,
                0x32, 0x01, 0x01, 0x06,
            ]),
            Data([
                0x32, 0x50, 0x41, 0x59,
                0x2E, 0x53, 0x59, 0x53,
                0x2E, 0x44, 0x44, 0x46,
                0x30, 0x31,
            ]),
        ]

        fullLog.append(
            "===== AID SELECTION ====="
        )

        var fciData: Data? = nil

        for aid in aids {

            let aidHex =
                aid
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")

            Log.debug(
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
                send,
                ins: 0xA4,
                p1: 0x04,
                p2: 0x00,
                data: aid,
                le: 256,
                cla: 0x00,
                fullLog: fullLog
            ),
                sw1 == 0x90,
                sw2 == 0x00
            {

                fciData = response

                Log.debug(
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

                Log.debug(
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

            session?.invalidate(
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

        Log.debug(
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
            send,
            ins: 0xB0,
            p1: managementP1,
            p2: 0x00,
            data: Data(),
            le: 0x3C,
            cla: 0x00,
            fullLog: fullLog
        ) {

            let hex =
                response
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

            Log.debug(log)
            fullLog.append(log)
        }

        let transactionP2 =
            UInt8((0x18 << 3) | 0x04)

        Log.debug(
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

            guard
                let (
                    response,
                    sw1,
                    sw2
                ) = await cnTunion_sendAPDU(
                    send,
                    ins: 0xB2,
                    p1: UInt8(record),
                    p2: transactionP2,
                    le: 256,
                    cla: 0x00,
                    fullLog: fullLog
                )
            else {

                Log.debug(
                    "SFI18 record=\(record) APDU_FAILED"
                )

                fullLog.append(
                    "SFI18 record=\(record) APDU_FAILED"
                )

                continue
            }

            let hex =
                response
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

            Log.debug(log)
            fullLog.append(log)

            if sw1 == 0x6A && sw2 == 0x83 {
                break
            }
        }

        let tripP2 =
            UInt8((0x1E << 3) | 0x04)

        Log.debug(
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

            guard
                let (
                    response,
                    sw1,
                    sw2
                ) = await cnTunion_sendAPDU(
                    send,
                    ins: 0xB2,
                    p1: UInt8(record),
                    p2: tripP2,
                    le: 256,
                    cla: 0x00,
                    fullLog: fullLog
                )
            else {

                Log.debug(
                    "SFI1E record=\(record) APDU_FAILED"
                )

                fullLog.append(
                    "SFI1E record=\(record) APDU_FAILED"
                )

                continue
            }

            let hex =
                response
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

            Log.debug(log)
            fullLog.append(log)

            if sw1 == 0x6A && sw2 == 0x83 {
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
                send,
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
                tag: send,
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
            send,
            fullLog: fullLog
        )

        let balance =
            computedBalance ?? history?.first(
                where: {
                    $0.balance != 0
                }
            )?.balance ?? rawBalance

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

        let result = ScanResult(
            balance: balance,
            isHistory: true,
            history: history,
            info: info,
            converter: cnTunion.scanOption.converter,
            isLastHide: false,
            description: cnTunion.scannedDescription,
            savedAt: Date.now,
            fullLog: fullLog.text
        )

        if let session {
            await self.completeScan(result, session: session)
        } else {
            await MainActor.run {
                self.result = result
            }
        }
    }
}
