
extension NFCScannerModel {

    func idKMT_scanExternal(using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let reader = KMTExternalAPDU(
                transmit: manager.apduSender(for: card)
            )

            let idmData = try await reader.send(
                0xCA,
                p1: 0x00,
                p2: 0x00,
                le: 256
            )

            guard idmData.count >= 8 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaIDm")
                )
            }

            let idm = idmData.prefix(8)
                .map { String(format: "%02X", $0) }
                .joined()

            let idBlocks = try await reader.readBlocks(
                service: [0x0B, 0x30],
                count: 1
            )

            guard let idBlock = idBlocks.first,
                  idBlock.count >= 16 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaInfoService")
                )
            }

            let balanceBlocks = try await reader.readBlocks(
                service: [0x17, 0x10],
                count: 1
            )

            guard let balanceBlock = balanceBlocks.first,
                  balanceBlock.count >= 16 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let historyCount = min(
                max(self.scanOption.historyCount, 0),
                20
            )

            let historyBlocks = try await reader.readBlocks(
                service: [0x0F, 0x20],
                count: historyCount,
                stopAtEmpty: true
            )

            guard let data = KMTData.parse(
                idBlock: idBlock,
                balanceBlock: balanceBlock,
                historyBlocks: historyBlocks
            ) else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let info = ResultCardInfo(
                idm: idm,
                name: idKMT.name,
                nameShort: idKMT.scanOption.nameShort,
                currencyType: idKMT.scanOption.currencyType,
                type: "card.KMT",
                serial: data.serialNumber,
                version: nil,
                validDate: nil,
                issueInfo: issueInfo(
                    region: idKMT.area.rawValue
                )
            )

            return Result(
                balance: Double(data.balance),
                isHistory: true,
                history: data.histories,
                info: info,
                converter: idKMT.scanOption.converter,
                isLastHide: true,
                description: idKMT.scand_description,
                savedAt: Date.now
            )
        }

        await MainActor.run {
            self.result = result
        }
    }
}

private struct KMTExternalAPDU {
    let transmit: APDUSend

    func send(
        _ ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data = Data(),
        le: Int = 0
    ) async throws -> Data {
        let (payload, sw1, sw2) = try await transmit(
            0xFF,
            ins,
            p1,
            p2,
            data,
            le
        )

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    format: String(
                        localized: "error.smartCardReader.felicaCommandFailed"
                    ),
                    Int(sw1),
                    Int(sw2)
                )
            )
        }

        return payload
    }

    func readBlocks(
        service: [UInt8],
        count: Int,
        stopAtEmpty: Bool = false
    ) async throws -> [Data] {
        guard count > 0 else {
            return []
        }

        let (_, sw1, sw2) = try await transmit(
            0xFF,
            0xA4,
            0x00,
            0x01,
            Data(service),
            0
        )

        guard sw1 == 0x90, sw2 == 0x00 else {
            throw ReaderError.message(
                String(
                    localized: "error.smartCardReader.felicaHistoryService"
                )
            )
        }

        var blocks: [Data] = []

        for index in 0..<count {
            let response = try await send(
                0xB0,
                p1: 0x00,
                p2: UInt8(index),
                le: 256
            )

            guard response.count >= 16 else {
                throw ReaderError.message(
                    String(localized: "error.smartCardReader.felicaBalance")
                )
            }

            let block = Data(response.prefix(16))

            if stopAtEmpty &&
                (block.allSatisfy { $0 == 0 } ||
                 block.allSatisfy { $0 == 0xFF }) {
                break
            }

            blocks.append(block)
        }

        return blocks
    }
}
