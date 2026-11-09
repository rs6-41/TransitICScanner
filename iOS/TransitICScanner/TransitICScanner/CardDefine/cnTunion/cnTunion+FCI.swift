import Foundation
import CoreNFC

// MARK: - China T-Union FCI・管理情報の解析
extension NFCScannerModel {

    func cnTunion_parseFCI(
        _ data: Data,
        fullLog: CNTRunionFullLog? = nil
    ) -> [UInt8] {

        var sfiList: [UInt8] = []

        let bytes = [UInt8](data)

        fullLog?.appendData(
            "FCI Parse Input",
            data
        )

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
                offset + numBytes < bytes.count
            else {
                return nil
            }

            var length = 0

            for i in 1...numBytes {
                length =
                    (length << 8) | Int(bytes[offset + i])
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

                guard
                    let (
                        length,
                        lengthBytes
                    ) = parseLength(index)
                else {
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
                    tag[0] == 0x94
                {

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

                            if sfi != 0 && !sfiList.contains(sfi) {

                                sfiList.append(sfi)
                            }
                        }
                    }
                }

                if tag.count == 1 {

                    let tagValue =
                        tag[0]

                    if tagValue == 0x6F || tagValue == 0xA5 || tagValue == 0xBF || tagValue == 0x70 {

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

        let result =
            sfiList
            .map {
                String($0)
            }
            .joined(separator: ", ")

        Log.debug(
            "Parsed SFIs from FCI:",
            result
        )

        fullLog?.append(
            "Parsed SFIs from FCI: \(result)"
        )

        return sfiList
    }

    func cnTunion_parseFCITag(
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
                offset + numberOfBytes < end
            else {
                return nil
            }

            var length = 0

            for i in 1...numberOfBytes {

                length =
                    (length << 8) | Int(bytes[offset + i])
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

                guard
                    let (
                        length,
                        lengthBytes
                    ) = parseLength(
                        index,
                        end
                    )
                else {
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
                    tag.count == 1 && (tag[0] == 0x6F || tag[0] == 0xA5 || tag[0] == 0x70 || tag[0] == 0xBF)

                if constructed {

                    if let result =
                        parseTLV(
                            index,
                            index + length
                        )
                    {

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

    func cnTunion_readManagementInfo(
        _ tag: APDUSend,
        fullLog: CNTRunionFullLog? = nil
    ) async -> Data? {

        let sfi: UInt8 = 0x17

        let p1 =
            UInt8(0x80 | sfi)

        let p2: UInt8 = 0x00

        let title =
            String(
                format:
                    "T-Union SFI 0x17 READ BINARY: CLA=00 INS=B0 P1=%02X P2=%02X Le=3C",
                p1,
                p2
            )

        Log.debug(title)

        fullLog?.append(title)

        guard
            let (
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
                cla: 0x00,
                fullLog: fullLog
            )
        else {

            Log.debug(
                "T-Union SFI 0x17 READ BINARY APDU failed"
            )

            fullLog?.append(
                "T-Union SFI 0x17 READ BINARY APDU failed"
            )

            return nil
        }

        let statusLog =
            String(
                format:
                    "T-Union SFI 0x17 READ BINARY: SW=%02X%02X LEN=%d",
                sw1,
                sw2,
                response.count
            )

        Log.debug(statusLog)

        fullLog?.append(statusLog)

        fullLog?.appendData(
            "T-Union SFI 0x17 RAW",
            response
        )

        guard sw1 == 0x90,
            sw2 == 0x00
        else {

            return nil
        }

        guard response.count >= 8 else {
            return nil
        }

        return response
    }

    func cnTunion_getCityCode(
        _ tag: APDUSend,
        fullLog: CNTRunionFullLog? = nil
    ) async -> String? {

        guard
            let data =
                await cnTunion_readManagementInfo(
                    tag,
                    fullLog: fullLog
                )
        else {

            Log.debug(
                "T-Union city code: SFI 0x17 could not be read"
            )

            fullLog?.append(
                "T-Union city code: SFI 0x17 could not be read"
            )

            return nil
        }

        let bytes = [UInt8](data)

        guard bytes.count >= 8 else {
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
            (UInt16(bytes[6]) << 8) | UInt16(bytes[7])

        let cityCode =
            String(
                format: "%04X",
                cityCodeRaw
            )

        Log.debug(
            "T-Union SFI 0x17 international code:",
            internationalCode
        )

        Log.debug(
            "T-Union SFI 0x17 province code:",
            provinceCode
        )

        Log.debug(
            String(
                format:
                    "T-Union SFI 0x17 city code: %02X %02X -> %04X",
                bytes[6],
                bytes[7],
                cityCodeRaw
            )
        )

        fullLog?.append(
            "International Code: \(internationalCode)"
        )

        fullLog?.append(
            "Province Code: \(provinceCode)"
        )

        fullLog?.append(
            "City Code: \(cityCode)"
        )

        if bytes.count >= 10 {

            let unionCardType =
                (UInt16(bytes[8]) << 8) | UInt16(bytes[9])

            Log.debug(
                String(
                    format:
                        "T-Union SFI 0x17 union card type: %04X",
                    unionCardType
                )
            )

            fullLog?.append(
                String(
                    format:
                        "Union Card Type: %04X",
                    unionCardType
                )
            )
        }

        if bytes.count >= 11 {

            Log.debug(
                String(
                    format:
                        "T-Union SFI 0x17 card type: %02X",
                    bytes[10]
                )
            )

            fullLog?.append(
                String(
                    format:
                        "Card Type: %02X",
                    bytes[10]
                )
            )
        }

        return cityCode
    }

    func cnTunion_getInfoFromFCI(
        _ fci: Data,
        tag: APDUSend,
        fullLog: CNTRunionFullLog? = nil
    ) async -> ResultCardInfo? {

        let cityCode =
            await cnTunion_getCityCode(
                tag,
                fullLog: fullLog
            ) ?? ""

        fullLog?.append(
            "City Code: \(cityCode)"
        )

        guard
            let metadata =
                cnTunion_parseFCITag(
                    fci,
                    targetTag: [0x9F, 0x0C]
                )
        else {

            Log.debug(
                "9F0C not found in FCI"
            )

            fullLog?.append(
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

        fullLog?.appendData(
            "9F0C",
            metadata
        )

        guard bytes.count >= 28 else {

            fullLog?.append(
                "9F0C metadata too short: \(bytes.count)"
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
            )
        {

            version =
                versionData
                .map {
                    String(format: "%02X", $0)
                }
                .joined()

            fullLog?.appendData(
                "9F08 Version",
                versionData
            )
        } else {

            fullLog?.append(
                "9F08 Version: not found"
            )
        }

        Log.debug(
            "T-Union card number:",
            cardNumber
        )

        Log.debug(
            "T-Union version:",
            version
        )

        Log.debug(
            "T-Union issue date:",
            issueDate
        )

        Log.debug(
            "T-Union expiry date:",
            expiryDate
        )

        Log.debug(
            "T-Union city code:",
            cityCode
        )

        fullLog?.append(
            "Card Number: \(cardNumber)"
        )

        fullLog?.append(
            "Version: \(version)"
        )

        fullLog?.append(
            "Issue Date: \(issueDate)"
        )

        fullLog?.append(
            "Expiry Date: \(expiryDate)"
        )

        let getIssueInfo = cnTunion_getIssueInfo(iin: String(cardNumber))

        return ResultCardInfo(
            idm: cardNumber,
            name: cnTunion.name,
            nameShort: cnTunion.scanOption.nameShort,
            currencyType: cnTunion.scanOption.currencyType,
            type: cityCode,
            serial: cardNumber,
            version: version,
            validDate:
                "\(issueDate)-\(expiryDate)",
            issueInfo: IssueInfo(
                region: cnTunion.area.rawValue, area: getIssueInfo.area, city: getIssueInfo.city,
                issuer: getIssueInfo.issuer)
        )
    }
}
