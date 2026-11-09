
import SwiftUI
import Foundation
import Combine
import CoreNFC

final class CardItemsStore: ObservableObject {
    @Published var cardItems: [CardInfo] = []
}

let cardItemsStore = CardItemsStore()

let devCards: [CardInfo] = [
    spFlashPay, idKMT
]

let featureCards: [CardInfo] = []

let relCards: [CardInfo] = [
    jpIC, jpIC_SAPICA, jpIC_IruCa, cnTunion, hkOctopus, krOneCard,
    twICash, jpNplus, jpIC_icsca, twEasyCard_old, jpDoCard, jpOKICA,
    usClipper, jpRapica
]

extension NFCScannerModel {
    /// CoreNFC で検出したタグを、カード定義ごとの読取処理へ振り分ける。
    /// `CardID` を網羅的に switch するため、カード追加時の分岐漏れはコンパイルエラーになる。
    func switchCard(id: CardID, _ tag: NFCTag, _ session: NFCTagReaderSession) async {
        switch id {
        case .jpIC, .jpIC_SAPICA, .jpIC_IruCa, .jpIC_icsca,
             .hkOctopus, .jpNplus, .jpOKICA, .jpDoCard, .jpRapica:
            scanFeliCa(id: id, tag, session)
        case .cnTunion:
            self.cnTunion_scan(tag, session)
        case .krOneCard:
            self.krOneCard_scan(tag, session)
        case .twICash:
            self.twICash_scan(tag, session)
        case .usClipper:
            self.usClipper_scan(tag, session)
        case .idKMT:
            self.idKMT_scan(tag, session)
        case .twEasyCard_old:
            // スクレイピングで取得するため NFC 読取はない
            return
        case .spFlashPay:
            // 開発中（読取処理未実装）
            session.invalidate(
                errorMessage: String(localized: "scanner.scan.message.undefinedName")
            )
        }
    }

    /// 外部リーダー(PC/SC)での読取を、カード定義ごとの処理へ振り分ける。
    func scanWithExternalReader(using manager: SmartCardManager) async throws {
        let id = scanOption.id

        switch id {
        case .jpIC, .jpIC_SAPICA, .jpIC_IruCa, .jpIC_icsca,
             .hkOctopus, .jpNplus, .jpOKICA, .jpDoCard, .jpRapica:
            try await scanFeliCaExternal(id: id, using: manager)
        case .usClipper:
            try await usClipper_scanExternal(using: manager)
        case .krOneCard:
            try await krOneCard_scanExternal(using: manager)
        case .cnTunion:
            try await cnTunion_scanExternal(using: manager)
        case .twICash:
            try await twICash_scanExternal(using: manager)
        case .idKMT:
            try await idKMT_scanExternal(using: manager)
        case .twEasyCard_old, .spFlashPay:
            throw ReaderError.message(
                String(localized: "cardList.reader.unsupported")
            )
        }
    }

    // MARK: - FeliCa 共通

    /// FeliCa カードの読取処理。内蔵リーダーと外部リーダーで同じ実装を使う。
    /// 読み取りに失敗した場合は nil を返す。
    func readFeliCa(id: CardID, _ felicaTag: any FeliCaTagReading) async -> Result? {
        switch id {
        case .jpIC, .jpIC_SAPICA, .jpIC_IruCa, .jpIC_icsca:
            await jpIC_read(felicaTag, cardID: id)
        case .hkOctopus:
            await hkOctopus_read(felicaTag)
        case .jpNplus:
            await jpNplus_read(felicaTag)
        case .jpOKICA:
            await jpOKICA_read(felicaTag)
        case .jpDoCard:
            await jpDoCard_read(felicaTag)
        case .jpRapica:
            await jpRapica_read(felicaTag)
        case .cnTunion, .krOneCard, .twICash, .usClipper, .idKMT,
             .twEasyCard_old, .spFlashPay:
            nil
        }
    }

    private func scanFeliCa(id: CardID, _ tag: NFCTag, _ session: NFCTagReaderSession) {
        guard case let .feliCa(felicaTag) = tag else {
            session.invalidate(
                errorMessage: String(localized: "scanner.coreNFC.error.notfeliCa")
            )
            return
        }

        Task { @MainActor in
            guard let result = await self.readFeliCa(
                id: id,
                CoreNFCFeliCaTag(tag: felicaTag)
            ) else {
                session.invalidate(
                    errorMessage: String(localized: "scanner.coreNFC.scanning.error.read")
                )
                return
            }

            self.result = result
            session.alertMessage = String(localized: "scanner.coreNFC.scanning.done")
            session.invalidate()
        }
    }

    private func scanFeliCaExternal(id: CardID, using manager: SmartCardManager) async throws {
        let result = try await manager.withCard { card in
            let felicaTag = try await ExternalFeliCaTag.connect(
                transmit: manager.apduSender(for: card)
            )

            guard let result = await self.readFeliCa(id: id, felicaTag) else {
                throw ReaderError.message(
                    String(localized: "scanner.coreNFC.scanning.error.read")
                )
            }

            return result
        }

        await MainActor.run {
            self.result = result
        }
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

enum ConverterType: String, CaseIterable {
    case jpIC
    case jpIC_SAPICA
    case jpIC_IruCa
    case cnTunion
    case hkOctopus
    case krOneCard
    case twICash
    case jpNplus
    case twEasyCard_old
    case usClipper
    case jpDoCard
    case jpIC_icsca
    case jpOKICA
    case jpRapica
    case idKMT

    func cardInfo(_ info: ResultCardInfo) -> DisplayCardInfo {
        switch self {
        case .jpIC:
            jpIC_Converter.cardInfo(info)
        case .jpIC_SAPICA:
            jpIC_Converter.cardInfo(info)
        case .jpIC_IruCa:
            jpIC_Converter.cardInfo(info)
        case .cnTunion:
            cnTunion_Converter.cardInfo(info)
        case .hkOctopus:
            hkOctopus_Converter.cardInfo(info)
        case .krOneCard:
            krOneCard_Converter.cardInfo(info)
        case .twICash:
            twICash_Converter.cardInfo(info)
        case .jpNplus:
            jpNplus_Converter.cardInfo(info)
        case .twEasyCard_old:
            twEasyCard_old_Converter.cardInfo(info)
        case .usClipper:
            usClipper_Converter.cardInfo(info)
        case .jpDoCard:
            jpDoCard_Converter.cardInfo(info)
        case .jpIC_icsca:
            jpIC_Converter.cardInfo(info)
        case .jpOKICA:
            jpOKICA_Converter.cardInfo(info)
        case .jpRapica:
            jpRapica_Converter.cardInfo(info)
        case .idKMT:
            idKMT_Converter.cardInfo(info)
        }
    }

    func history(_ item: ResultHistory) -> DisplayHistory {
        switch self {
        case .jpIC:
            jpIC_Converter.history(item)
        case .jpIC_SAPICA:
            jpIC_Converter.history(item)
        case .jpIC_IruCa:
            jpIC_Converter.history(item)
        case .cnTunion:
            cnTunion_Converter.history(item)
        case .hkOctopus:
            hkOctopus_Converter.history(item)
        case .krOneCard:
            krOneCard_Converter.history(item)
        case .twICash:
            twICash_Converter.history(item)
        case .jpNplus:
            jpNplus_Converter.history(item)
        case .twEasyCard_old:
            twEasyCard_old_Converter.history(item)
        case .usClipper:
            usClipper_Converter.history(item)
        case .jpDoCard:
            jpDoCard_Converter.history(item)
        case .jpIC_icsca:
            jpIC_Converter.history(item)
        case .jpOKICA:
            jpOKICA_Converter.history(item)
        case .jpRapica:
            jpRapica_Converter.history(item)
        case .idKMT:
            idKMT_Converter.history(item)
        }
    }
}
