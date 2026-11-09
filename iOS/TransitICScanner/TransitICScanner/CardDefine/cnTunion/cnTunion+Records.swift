import Foundation
import CoreNFC

// MARK: - China T-Union 残高・取引記録の解析
extension NFCScannerModel {

    func cnTunion_getBalanceFallback(
        _ tag: APDUSend,
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

        Log.debug(
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


    func cnTunion_readKnownRecords(
        _ tag: APDUSend,
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


    func cnTunion_parseTransactionRecord(
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

        Log.debug(
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

            Log.debug(
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

        Log.debug(
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


    func cnTunion_parseTripRecord(
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

        Log.debug(
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

            Log.debug(
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

        Log.debug(
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


    func cnTunion_decodeBCDDate(
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
