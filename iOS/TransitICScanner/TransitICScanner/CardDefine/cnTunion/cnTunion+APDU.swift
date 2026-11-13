import Foundation
import CoreNFC

// MARK: - China T-Union APDU送受信
extension NFCScannerModel {

    func cnTunionSendAPDU(
        _ tag: APDUSend,
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

        let commandHex =
            data
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

        Log.debug(commandLog)

        fullLog?.append(commandLog)

        do {

            let (
                response,
                sw1,
                sw2
            ) = try await tag(cla, ins, p1, p2, data, le)

            let responseHex =
                response
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

            Log.debug(responseLog)

            fullLog?.append(responseLog)

            return (
                response,
                sw1,
                sw2
            )

        } catch {

            let errorLog =
                "APDU error: \(error.localizedDescription)"

            Log.debug(errorLog)

            fullLog?.append(errorLog)

            return nil
        }
    }
}
