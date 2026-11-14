//MARK: Clipper (San Francisco Bay Area)
import Foundation
import SwiftUI
import CoreNFC

let usClipper = CardInfo(
    logo: "usClipper",
    name: "cardList.usClipper",
    sortName: "cardList.usClipper.sortName",
    area: .us,
    countryCode: ["us"],
    prefectures: ["CA"],
    regionOption: nil,
    description: "cardList.usClipper.description",
    scannedDescription: "",
    searchWords: [
        "clipper", "くりっぱー", "クリッパー", "サンフランシスコ", "san francisco",
        "bay area", "california", "BART", "Muni", "Caltrain",
    ],
    scanOption: ScanOption(
        id: .usClipper,
        nameShort: "usClipper.short",
        scanType: .nfc,
        pollingOption: [.iso14443],
        felicaSystemCodes: nil,
        historyCount: 20,
        currencyType: .usd,
        converter: .usClipper,
        scrapingView: nil
    ),
    information: nil,
    sample: ResultSample(
        balance: 12.5,
        idm: "04A1B2C3D4E5F6",
        type: "",
        history: [
            // 乗車: processType4 = 事業者(16bit) << 16 | 交通種別(16bit)
            ResultHistory(
                processType: 0x02, processType4: 0x00040061, date: sampleDay3, balance: 12.5, amount: -2.85,
                lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0, transactionId: 2),
            // チャージ
            ResultHistory(
                processType: 0x01, processType4: 0x00040000, date: sampleDay2, balance: 15.35, amount: 20.0,
                lineIn: 0, stationIn: 0, lineOut: 0, stationOut: 0, transactionId: 1),
        ]
    )
)

/// DESFire ISO7816ラップ(CLA=0x90)のAPDU送信クロージャ。
/// .miFare(DESFire) でも .iso7816 でも同じ処理で読めるようにするための抽象化

/// 履歴の中間表現
struct ClipperEvent {
    let time: UInt32  // 1900-01-01 からの秒数
    let kind: UInt8  // 0x01 = チャージ, 0x02 = 乗車(トリップ)
    let amountCents: Int  // チャージ: +, 運賃: -
    let agency: UInt16
    let transport: UInt16
    let route: UInt16
    let stationIn: UInt16
    let stationOut: UInt16
    let seq: Int
}

private let clipperEpochOffset: TimeInterval = 2_208_988_800  // 1900-01-01 -> 1970-01-01
private let clipperAID = Data([0x90, 0x11, 0xF2])  // 0x9011F2 (実機ログ: GetApplicationIDs は 90 11 F2 の順)

private func clipperBe16(_ b: [UInt8], _ o: Int) -> UInt16 {
    (UInt16(b[o]) << 8) | UInt16(b[o + 1])
}

private func clipperBe32(_ b: [UInt8], _ o: Int) -> UInt32 {
    (UInt32(b[o]) << 24) | (UInt32(b[o + 1]) << 16) | (UInt32(b[o + 2]) << 8) | UInt32(b[o + 3])
}

private func clipperCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
    return cal
}

private func clipperComponents(_ seconds: UInt32) -> DateComponents {
    let date = Date(timeIntervalSince1970: TimeInterval(seconds) - clipperEpochOffset)
    return clipperCalendar().dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
}

extension NFCScannerModel {

    //MARK: スキャン
    func usClipperScan(_ tag: NFCTag, _ session: NFCTagReaderSession) {

        let send: APDUSend
        let identifier: Data

        switch tag {
        case .miFare(let t):
            Log.debug("Clipper: using NFCMiFareTag path")
            guard t.mifareFamily == .desfire else {
                session.invalidate(errorMessage: String(localized: "error.smartCardReader.notDESFire"))
                return
            }
            send = { cla, ins, p1, p2, data, le in
                let apdu = NFCISO7816APDU(
                    instructionClass: cla,
                    instructionCode: ins,
                    p1Parameter: p1,
                    p2Parameter: p2,
                    data: data,
                    expectedResponseLength: le
                )
                return try await withCheckedThrowingContinuation { continuation in
                    t.sendMiFareISO7816Command(apdu) { data, sw1, sw2, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: (data, sw1, sw2))
                        }
                    }
                }
            }
            identifier = t.identifier

        case .iso7816(let t):
            Log.debug("Clipper: using NFCISO7816Tag path, initialSelectedAID:", t.initialSelectedAID)
            send = { cla, ins, p1, p2, data, le in
                let apdu = NFCISO7816APDU(
                    instructionClass: cla,
                    instructionCode: ins,
                    p1Parameter: p1,
                    p2Parameter: p2,
                    data: data,
                    expectedResponseLength: le
                )
                return try await withCheckedThrowingContinuation { continuation in
                    t.sendCommand(apdu: apdu) { data, sw1, sw2, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: (data, sw1, sw2))
                        }
                    }
                }
            }
            identifier = t.identifier

        default:
            session.invalidate(errorMessage: String(localized: "error.smartCardReader.notDESFire"))
            return
        }

        Task {
            guard let result = await usClipperResult(send, identifier: identifier) else {
                session.invalidate(errorMessage: String(localized: "error.smartCardReader.clipperRead"))
                return
            }

            await self.completeScan(result, session: session)
        }
    }

    func usClipperScanExternal(using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let send = manager.apduSender(for: card)
            guard let result = await usClipperResult(send, identifier: Data()) else {
                throw ReaderError.message(String(localized: "error.smartCardReader.clipperRead"))
            }
            return result
        }

        await MainActor.run { self.result = result }
    }

    private func usClipperResult(
        _ send: APDUSend,
        identifier: Data
    ) async -> ScanResult? {
        guard await clipperCommand(send, ins: 0x5A, data: clipperAID) != nil,
            let balanceData = await clipperReadFile(send, file: 0x02),
            balanceData.count >= 20
        else {
            return nil
        }

        let balanceCents = Int(Int16(bitPattern: clipperBe16([UInt8](balanceData), 18)))
        let history = await clipperHistory(
            send,
            currentBalanceCents: balanceCents,
            limit: scanOption.historyCount
        )
        let info = await clipperInfo(send, identifier: identifier)
        return ScanResult(
            balance: Double(balanceCents) / 100.0,
            isHistory: true,
            history: history,
            info: info,
            converter: usClipper.scanOption.converter,
            isLastHide: false,
            description: usClipper.scannedDescription,
            savedAt: Date.now
        )
    }

    //MARK: 履歴
    // File 0x4 (チャージ) / File 0xE (トリップ): 32byteレコード
    func clipperHistory(
        _ send: APDUSend,
        currentBalanceCents: Int,
        limit: Int
    ) async -> [ResultHistory]? {

        var events: [ClipperEvent] = []

        // チャージ: [2-3]事業者 [4-7]時刻 [8-11]機械ID [14-15]金額(セント)
        if let data = await clipperReadFile(send, file: 0x04) {
            for (i, r) in clipperRecords(data).enumerated() {
                let time = clipperBe32(r, 4)
                guard time != 0 else { continue }
                events.append(
                    ClipperEvent(
                        time: time,
                        kind: 0x01,
                        amountCents: Int(clipperBe16(r, 14)),
                        agency: clipperBe16(r, 2),
                        transport: 0,
                        route: 0,
                        stationIn: 0,
                        stationOut: 0,
                        seq: 100_000 + i
                    ))
            }
        }

        // トリップ: [2-3]事業者 [6-7]運賃(セント) [12-15]入場時刻 [16-19]出場時刻 [30-31]交通種別
        // File 0xE は標準ファイル(512byte = 32byte x 16件)。未使用枠は先頭が 0x10 で時刻 0
        // タップオフ有りの交通機関は「入場のみ(仮運賃=最大運賃)」と「出場あり(確定運賃)」の
        // 2レコードが同じ入場時刻で残るため、確定済みがある場合は入場のみ側を除外する
        // トリップ: File 0x0E
        if let data = await clipperReadFile(send, file: 0x0E) {
            var parsed: [(event: ClipperEvent, hasExit: Bool)] = []

            let records = clipperRecords(data).reversed()

            for (i, r) in records.enumerated() {
                guard r.count >= 32 else { continue }

                let entry = clipperBe32(r, 12)
                let exit = clipperBe32(r, 16)

                guard entry != 0 else { continue }

                let agency = clipperBe16(r, 2)

                guard agency != 0 else { continue }

                let event = ClipperEvent(
                    time: entry,
                    kind: 0x02,
                    amountCents: -Int(clipperBe16(r, 6)),
                    agency: agency,
                    transport: clipperBe16(r, 30),
                    route: clipperBe16(r, 28),
                    stationIn: clipperBe16(r, 20),
                    stationOut: clipperBe16(r, 22),
                    seq: 200_000 + i
                )

                if let index = parsed.firstIndex(where: {
                    $0.event.time == event.time
                }) {
                    if parsed[index].hasExit {
                        continue
                    }

                    parsed.remove(at: index)
                }

                parsed.append(
                    (
                        event: event,
                        hasExit: exit != 0
                    ))
            }

            events.append(contentsOf: parsed.map { $0.event })
        }

        guard !events.isEmpty else { return nil }

        // 新しい順
        events.sort { $0.time != $1.time ? $0.time > $1.time : $0.seq < $1.seq }

        // 現在残額から遡って各時点の残額(そのイベント後)を算出
        var running = currentBalanceCents
        var logs: [ResultHistory] = []

        for e in events {
            logs.append(
                ResultHistory(
                    processType: e.kind,
                    processType4: (UInt32(e.agency) << 16) | UInt32(e.transport),
                    date: clipperComponents(e.time),
                    balance: Double(running) / 100.0,
                    amount: Double(e.amountCents) / 100.0,
                    // 路線ID(16bit) は lineIn=上位8bit / lineOut=下位8bit に分けて渡す
                    // 駅ID(16bit) は下位8bitのみ (BARTなど実在の駅IDは8bitに収まる)
                    lineIn: UInt8(e.route >> 8),
                    stationIn: UInt8(truncatingIfNeeded: e.stationIn),
                    lineOut: UInt8(truncatingIfNeeded: e.route),
                    stationOut: UInt8(truncatingIfNeeded: e.stationOut),
                    transactionId: e.seq
                )
            )
            running -= e.amountCents
        }

        return Array(logs.prefix(max(limit, 1)))
    }

    //MARK: カード情報
    // File 0x8: [1-4]シリアル / File 0x1: [8-9]有効期限(1900-01-01からの日数)
    func clipperInfo(
        _ send: APDUSend,
        identifier: Data
    ) async -> ResultCardInfo? {

        let uid = identifier.map { String(format: "%02X", $0) }.joined()

        var serial: String? = nil
        if let d = await clipperReadFile(send, file: 0x08), d.count >= 5 {
            serial = String(clipperBe32([UInt8](d), 1))
        }

        // 日数は暦日そのもの(タイムゾーンなし)なので、UTCで年月日に直してから
        // 端末のタイムゾーンの 0:00 にして Date 化する (日付がずれないように)
        var expiry: Date? = nil
        if let d = await clipperReadFile(send, file: 0x01), d.count >= 10 {
            let days = clipperBe16([UInt8](d), 8)
            let utcDate = Date(timeIntervalSince1970: TimeInterval(days) * 86_400 - clipperEpochOffset)
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(identifier: "UTC") ?? .current
            let ymd = utc.dateComponents([.year, .month, .day], from: utcDate)
            expiry = Calendar(identifier: .gregorian).date(from: ymd)
        }

        return ResultCardInfo(
            idm: uid,
            name: usClipper.name,
            nameShort: usClipper.scanOption.nameShort,
            currencyType: usClipper.scanOption.currencyType,
            type: "",
            serial: serial,
            version: nil,
            validDate: nil,
            issueInfo: IssueInfo(
                region: usClipper.area.rawValue,
                area: "locate.prefecture.CA",
                city: "locate.city.CA.SF",
                issuer: "issue.us.california.issuer.clipper",
                expiry: expiry
            )
        )
    }

    //MARK: DESFire共通処理
    /// 32byteごとのレコードに分割 (空/全FFは除外)
    private func clipperRecords(_ data: Data) -> [[UInt8]] {
        let bytes = [UInt8](data)
        return stride(from: 0, to: bytes.count - 31, by: 32)
            .map { Array(bytes[$0..<$0 + 32]) }
            .filter { r in
                !r.allSatisfy { $0 == 0x00 } && !r.allSatisfy { $0 == 0xFF }
            }
    }

    /// ファイル全体を読む。GetFileSettings(0xF5) で種別を調べ、種別に合ったコマンドを使う
    /// (実機: 0x1/0x2/0x5/0x6/0x8/0xE/0xF = 標準・バックアップ, 0x4 = サイクリックレコード)
    private func clipperReadFile(
        _ send: APDUSend,
        file: UInt8
    ) async -> Data? {
        // [ファイル番号][オフセット 3byte][長さ 3byte] (0 = 全体)
        let params = Data([file, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        var order: [UInt8] = [0xBD, 0xBB]
        if let settings = await clipperCommand(send, ins: 0xF5, data: Data([file])),
            let type = settings.first
        {
            switch type {
            case 0x00, 0x01: order = [0xBD]
            case 0x03, 0x04: order = [0xBB]
            case 0x02: return await clipperCommand(send, ins: 0x6C, data: Data([file]))
            default: break
            }
        }

        for ins in order {
            if let d = await clipperCommand(send, ins: ins, data: params) {
                return d
            }
        }
        return nil
    }

    /// DESFireネイティブコマンドをISOラップ(CLA 0x90)で送信。0xAF(続きあり)は自動で連結する
    private func clipperCommand(
        _ send: APDUSend,
        ins: UInt8,
        data: Data = Data()
    ) async -> Data? {

        var out = Data()
        var code = ins
        var payload = data

        for _ in 0..<32 {
            let result: (Data, UInt8, UInt8)
            do {
                result = try await send(
                    0x90,
                    code,
                    0x00,
                    0x00,
                    payload,
                    256
                )
            } catch {
                Log.debug(String(format: "Clipper APDU INS=%02X error:", code), error)
                return nil
            }

            let (resp, sw1, sw2) = result
            Log.debug(String(format: "Clipper APDU INS=%02X SW=%02X%02X LEN=%d", code, sw1, sw2, resp.count))

            guard sw1 == 0x91 else {
                return nil
            }

            out.append(resp)

            if sw2 == 0xAF {
                code = 0xAF
                payload = Data()
                continue
            }

            return sw2 == 0x00 ? out : nil
        }

        return nil
    }
}
