import Foundation
import SwiftUI
import CoreNFC


let usClipper = CardInfo(
    logo: "usClipper",
    name: "cardList.usClipper",
    sortName: "cardList.usClipper.sortName",
    area: .us,
    countryCode: ["us"],
    description: String(localized: "cardList.usClipper.description"),
    scand_description: "",
    searchWords: ["clipper", "sanfrancisco", "bayarea"],
    scanOption: ScanOption(
        name: "usClipper",
        nameShort: "usClipper.short",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currencyType: .usd,
        converter: .usClipper,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance: 25.00,
            idm: "1234567890",
            type: "Clipper",
            history: [
                ResultHistory(
                    processType: 0x01,
                    date: sampleDay2,
                    balance: 25.00,
                    amount: 2.50,
                    lineIn: 0,
                    stationIn: 0,
                    lineOut: 0,
                    stationOut: 0,
                    transactionId: 1
                )
            ]
        )
)


extension NFCScannerModel {

    func usClipper_scan(
        _ tag: NFCTag,
        _ session: NFCTagReaderSession
    ) {

        guard case let .miFare(mifareTag) = tag else {
            session.invalidate(errorMessage: "Not MIFARE tag")
            return
        }

        print("Clipper scan started")

        print(
            "MIFARE family:",
            mifareTag.mifareFamily.rawValue
        )

        print(
            "Identifier:",
            mifareTag.identifier
                .map {
                    String(format: "%02X", $0)
                }
                .joined()
        )

        Task {

            guard
                mifareTag.mifareFamily == .desfire
            else {
                session.invalidate(
                    errorMessage: "Not DESFire tag"
                )
                return
            }

            guard
                await usClipper_selectApplication(
                    mifareTag
                )
            else {
                session.invalidate(
                    errorMessage: "Clipper application not found"
                )
                return
            }

            print(
                "Clipper application selected: 9011F2"
            )

            print(
                "===== Clipper RAW DUMP START ====="
            )

            let file1 =
                await usClipper_readFile(
                    mifareTag,
                    fileID: 0x01
                )

            let file2 =
                await usClipper_readFile(
                    mifareTag,
                    fileID: 0x02
                )

            let file4 =
                await usClipper_readFile(
                    mifareTag,
                    fileID: 0x04
                )

            let file8 =
                await usClipper_readFile(
                    mifareTag,
                    fileID: 0x08
                )

            let file0E =
                await usClipper_readFile(
                    mifareTag,
                    fileID: 0x0E
                )

            let file0F =
                await usClipper_readFile(
                    mifareTag,
                    fileID: 0x0F
                )

            print("===== Clipper RAW DUMP END =====")

            let serial =
                usClipper_parseSerial(
                    file8
                )

            let balance =
                usClipper_parseBalance(
                    file2
                )

            let expiryDate =
                usClipper_parseExpiryDate(
                    file1
                )

            let refills =
                usClipper_parseRefills(
                    file4
                )

            let trips =
                usClipper_parseTrips(
                    file0E
                )

            let history =
                usClipper_makeHistory(
                    trips: trips,
                    refills: refills,
                    currentBalance: balance
                )

            let info =
                ResultCardInfo(
                    idm: serial ?? "",
                    name: usClipper.name,
                    nameShort: usClipper.scanOption.nameShort,
                    currencyType: usClipper.scanOption.currencyType,
                    type: "Clipper",
                    serial: serial,
                    version: nil,
                    validDate: expiryDate
                )

            let finalBalance =
                balance ??
                history?.first?.balance

            await MainActor.run {

                self.result = Result(
                    balance: finalBalance,
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: usClipper.scanOption.converter,
                    isLastHide: false,
                    description: usClipper.scand_description,
                    savedAt: Date.now
                )

                session.invalidate()
            }
        }
    }


    private func usClipper_sendCommand(
        _ tag: NFCMiFareTag,
        _ command: Data
    ) async -> Data? {

        do {

            print(
                "DESFire Command:",
                command
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined(separator: " ")
            )

            let response =
                try await withCheckedThrowingContinuation {
                    (
                        continuation:
                            CheckedContinuation<Data, Error>
                    ) in

                    tag.sendMiFareCommand(
                        commandPacket: command
                    ) { result in

                        switch result {

                        case .success(let data):
                            continuation.resume(
                                returning: data
                            )

                        case .failure(let error):
                            continuation.resume(
                                throwing: error
                            )
                        }
                    }
                }

            print(
                "DESFire Response:",
                response
                    .map {
                        String(format: "%02X", $0)
                    }
                    .joined(separator: " ")
            )

            return response

        } catch {

            print(
                "DESFire command error:",
                error.localizedDescription
            )

            return nil
        }
    }


    private func usClipper_selectApplication(
        _ tag: NFCMiFareTag
    ) async -> Bool {

        let command =
            Data([
                0x5A,
                0xF2,
                0x11,
                0x90
            ])

        guard
            let response =
                await usClipper_sendCommand(
                    tag,
                    command
                ),
            response.last == 0x00
        else {
            return false
        }

        return true
    }


    private func usClipper_readFile(
        _ tag: NFCMiFareTag,
        fileID: UInt8
    ) async -> Data? {

        let command =
            Data([
                0xBD,
                fileID,
                0x00,
                0x00,
                0x00,
                0xFF,
                0xFF,
                0xFF
            ])

        guard
            let response =
                await usClipper_sendCommand(
                    tag,
                    command
                )
        else {
            return nil
        }

        guard
            response.last == 0x00
        else {
            print(
                String(
                    format:
                        "Clipper File %02X read failed: status=%02X",
                    fileID,
                    response.last ?? 0
                )
            )

            return nil
        }

        let data =
            Data(
                response.dropLast()
            )

        print(
            String(
                format:
                    "Clipper File %02X:",
                fileID
            ),
            data
                .map {
                    String(format: "%02X", $0)
                }
                .joined(separator: " ")
        )

        return data
    }


    private func usClipper_parseSerial(
        _ data: Data?
    ) -> String? {

        guard
            let data,
            data.count >= 5
        else {
            return nil
        }

        let serial =
            data[1...4]
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

        print(
            "Clipper serial:",
            serial
        )

        return serial
    }


    private func usClipper_parseBalance(
        _ data: Data?
    ) -> Double? {

        guard
            let data,
            data.count >= 20
        else {
            return nil
        }

        let raw =
            (UInt16(data[18]) << 8) |
            UInt16(data[19])

        let signed =
            Int16(bitPattern: raw)

        let balance =
            Double(signed) / 100.0

        print(
            String(
                format:
                    "Clipper balance: %02X %02X -> %d -> %.2f",
                data[18],
                data[19],
                signed,
                balance
            )
        )

        return balance
    }


    private func usClipper_parseExpiryDate(
        _ data: Data?
    ) -> String? {

        guard
            let data,
            data.count >= 10
        else {
            return nil
        }

        let days =
            (UInt16(data[8]) << 8) |
            UInt16(data[9])

        let date =
            Date(
                timeIntervalSince1970:
                    Double(days) * 86400.0 -
                    2208988800.0
            )

        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "yyyy-MM-dd"

        formatter.locale =
            Locale(identifier: "en_US_POSIX")

        let result =
            formatter.string(
                from: date
            )

        print(
            "Clipper expiry date:",
            result
        )

        return result
    }


    private func usClipper_parseRefills(
        _ data: Data?
    ) -> [
        (
            date: Date,
            amount: Double,
            agency: Int,
            machineID: Int
        )
    ] {

        guard
            let data
        else {
            return []
        }

        let recordLength =
            32

        guard
            data.count >= recordLength
        else {
            return []
        }

        var result:
            [
                (
                    date: Date,
                    amount: Double,
                    agency: Int,
                    machineID: Int
                )
            ] = []

        var position =
            data.count -
            recordLength

        while position >= 0 {

            let record = data[position..<position + recordLength]

            let bytes =
                Array(record)

            let agency =
                (Int(bytes[2]) << 8) |
                Int(bytes[3])

            let timestampRaw =
                (UInt32(bytes[4]) << 24) |
                (UInt32(bytes[5]) << 16) |
                (UInt32(bytes[6]) << 8) |
                UInt32(bytes[7])

            let machineID =
                (Int(bytes[8]) << 24) |
                (Int(bytes[9]) << 16) |
                (Int(bytes[10]) << 8) |
                Int(bytes[11])

            let amountRaw =
                (Int(bytes[14]) << 8) |
                Int(bytes[15])

            if timestampRaw != 0 {

                let timestamp =
                    Double(timestampRaw) -
                    2208988800.0

                let date =
                    Date(
                        timeIntervalSince1970:
                            timestamp
                    )

                let amount =
                    Double(amountRaw) /
                    100.0

                result.append(
                    (
                        date:
                            date,
                        amount:
                            amount,
                        agency:
                            agency,
                        machineID:
                            machineID
                    )
                )
            }

            if position < recordLength {
                break
            }

            position -= recordLength
        }

        result.sort {
            $0.date >
            $1.date
        }

        return result
    }


    private func usClipper_parseTrips(
        _ data: Data?
    ) -> [
        (
            date: Date,
            exitDate: Date?,
            fare: Double,
            agency: Int,
            stationIn: Int,
            stationOut: Int,
            route: Int,
            transport: Int
        )
    ] {

        guard
            let data
        else {
            return []
        }

        let recordLength =
            32

        guard
            data.count >= recordLength
        else {
            return []
        }

        var result:
            [
                (
                    date: Date,
                    exitDate: Date?,
                    fare: Double,
                    agency: Int,
                    stationIn: Int,
                    stationOut: Int,
                    route: Int,
                    transport: Int
                )
            ] = []

        var position =
            data.count -
            recordLength

        while position >= 0 {

            let record = data[position..<position + recordLength]

            let bytes =
                Array(record)

            let agency =
                (Int(bytes[2]) << 8) |
                Int(bytes[3])

            guard agency != 0 else {

                if position < recordLength {
                    break
                }

                position -= recordLength
                continue
            }

            let fareRaw =
                (Int(bytes[6]) << 8) |
                Int(bytes[7])

            let timestampRaw =
                (UInt32(bytes[12]) << 24) |
                (UInt32(bytes[13]) << 16) |
                (UInt32(bytes[14]) << 8) |
                UInt32(bytes[15])

            let exitTimestampRaw =
                (UInt32(bytes[16]) << 24) |
                (UInt32(bytes[17]) << 16) |
                (UInt32(bytes[18]) << 8) |
                UInt32(bytes[19])

            let stationIn =
                (Int(bytes[20]) << 8) |
                Int(bytes[21])

            let stationOut =
                (Int(bytes[22]) << 8) |
                Int(bytes[23])

            let route =
                (Int(bytes[28]) << 8) |
                Int(bytes[29])

            let transport =
                (Int(bytes[30]) << 8) |
                Int(bytes[31])

            guard
                timestampRaw >= 2208988800
            else {

                if position < recordLength {
                    break
                }

                position -= recordLength
                continue
            }

            let timestamp =
                Double(timestampRaw) -
                2208988800.0

            let date =
                Date(
                    timeIntervalSince1970:
                        timestamp
                )

            let exitDate:
                Date?

            if exitTimestampRaw != 0 {

                let exitTimestamp =
                    Double(exitTimestampRaw) -
                    2208988800.0

                exitDate =
                    Date(
                        timeIntervalSince1970:
                            exitTimestamp
                    )

            } else {

                exitDate = nil
            }

            result.append(
                (
                    date:
                        date,
                    exitDate:
                        exitDate,
                    fare:
                        Double(fareRaw) / 100.0,
                    agency:
                        agency,
                    stationIn:
                        stationIn,
                    stationOut:
                        stationOut,
                    route:
                        route,
                    transport:
                        transport
                )
            )

            if position < recordLength {
                break
            }

            position -= recordLength
        }

        result.sort {
            $0.date >
            $1.date
        }

        var merged:
            [
                (
                    date: Date,
                    exitDate: Date?,
                    fare: Double,
                    agency: Int,
                    stationIn: Int,
                    stationOut: Int,
                    route: Int,
                    transport: Int
                )
            ] = []

        for trip in result {

            if let index =
                merged.firstIndex(
                    where: {
                        $0.date == trip.date
                    }
                ) {

                if
                    merged[index].exitDate == nil,
                    trip.exitDate != nil
                {
                    merged[index] =
                        trip
                }

            } else {

                merged.append(
                    trip
                )
            }
        }

        return merged
    }


    private func usClipper_makeHistory(
        trips:
            [
                (
                    date: Date,
                    exitDate: Date?,
                    fare: Double,
                    agency: Int,
                    stationIn: Int,
                    stationOut: Int,
                    route: Int,
                    transport: Int
                )
            ],
        refills:
            [
                (
                    date: Date,
                    amount: Double,
                    agency: Int,
                    machineID: Int
                )
            ],
        currentBalance: Double?
    ) -> [ResultHistory]? {

        guard
            !trips.isEmpty ||
            !refills.isEmpty
        else {
            return nil
        }

        var all:
            [
                (
                    date: Date,
                    amount: Double,
                    type: UInt8,
                    stationIn: Int,
                    stationOut: Int,
                    transactionID: Int
                )
            ] = []

        for trip in trips {

            all.append(
                (
                    date:
                        trip.date,
                    amount:
                        -trip.fare,
                    type:
                        0x04,
                    stationIn:
                        trip.stationIn,
                    stationOut:
                        trip.stationOut,
                    transactionID:
                        Int(
                            trip.date.timeIntervalSince1970
                        )
                )
            )
        }

        for refill in refills {

            all.append(
                (
                    date:
                        refill.date,
                    amount:
                        refill.amount,
                    type:
                        0x02,
                    stationIn:
                        0,
                    stationOut:
                        0,
                    transactionID:
                        Int(
                            refill.date.timeIntervalSince1970
                        )
            )
                )
        }

        all.sort {
            $0.date >
            $1.date
        }

        var balance =
            currentBalance ?? 0.0

        var history:
            [ResultHistory] = []

        for item in all {

            history.append(
                ResultHistory(
                    processType:
                        item.type,
                    date:
                        Calendar.current.dateComponents(
                            [
                                .year,
                                .month,
                                .day,
                                .hour,
                                .minute,
                                .second
                            ],
                            from:
                                item.date
                        ),
                    balance:
                        balance,
                    amount:
                        item.amount,
                    lineIn:
                        0,
                    stationIn:
                        UInt8(item.stationIn),
                    lineOut:
                        0,
                    stationOut:
                        UInt8(item.stationOut),
                    transactionId:
                        item.transactionID
                )
            )

            balance -=
                item.amount
        }

        return history
    }
}
