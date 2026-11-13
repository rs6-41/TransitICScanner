import SwiftUI
import Foundation
import Combine
import CoreNFC

final class CardItemsStore: ObservableObject {
    @Published var cardItems: [CardInfo] = []
}

let cardItemsStore = CardItemsStore()

let devCards: [CardInfo] = [
    spFlashPay
]

let featureCards: [CardInfo] = []

let relCards: [CardInfo] = [
    jpIC, cnTunion, hkOctopus, twICash, twEasyCard_old, krOneCard,
    jpIC_icsca, jpDoCard, jpOKICA, jpIC_SAPICA, jpIC_IruCa, jpRapica, jpNplus,
    usClipper,
    idKAI,
]

extension NFCScannerModel {
    /// CoreNFC で検出したタグを、カード定義ごとの読取処理へ振り分ける。
    /// `CardID` を網羅的に switch するため、カード追加時の分岐漏れはコンパイルエラーになる。
    func switchCard(id: CardID, _ tag: NFCTag, _ session: NFCTagReaderSession) async {
        switch id {
        case .jpIC, .jpIC_SAPICA, .jpIC_IruCa, .jpIC_icsca,
            .hkOctopus, .jpNplus, .jpOKICA, .jpDoCard, .jpRapica, .idKAI:
            scanFeliCa(id: id, tag, session)
        case .cnTunion:
            self.cnTunionScan(tag, session)
        case .krOneCard:
            self.krOneCardScan(tag, session)
        case .twICash:
            self.twICashScan(tag, session)
        case .usClipper:
            self.usClipperScan(tag, session)
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
            .hkOctopus, .jpNplus, .jpOKICA, .jpDoCard, .jpRapica, .idKAI:
            try await scanFeliCaExternal(id: id, using: manager)
        case .usClipper:
            try await usClipperScanExternal(using: manager)
        case .krOneCard:
            try await krOneCardScanExternal(using: manager)
        case .cnTunion:
            try await cnTunionScanExternal(using: manager)
        case .twICash:
            try await twICashScanExternal(using: manager)
        case .twEasyCard_old, .spFlashPay:
            throw ReaderError.message(
                String(localized: "cardList.reader.unsupported")
            )
        }
    }

    // MARK: - FeliCa 共通

    /// FeliCa カードの読取処理。内蔵リーダーと外部リーダーで同じ実装を使う。
    /// 読み取りに失敗した場合は nil を返す。
    func readFeliCa(id: CardID, _ felicaTag: any FeliCaTagReading) async -> ScanResult? {
        switch id {
        case .jpIC, .jpIC_SAPICA, .jpIC_IruCa, .jpIC_icsca:
            await jpICRead(felicaTag, cardID: id)
        case .hkOctopus:
            await hkOctopusRead(felicaTag)
        case .jpNplus:
            await jpNplusRead(felicaTag)
        case .jpOKICA:
            await jpOKICARead(felicaTag)
        case .jpDoCard:
            await jpDoCardRead(felicaTag)
        case .jpRapica:
            await jpRapicaRead(felicaTag)
        case .idKAI:
            await idKAIRead(felicaTag)
        case .cnTunion, .krOneCard, .twICash, .usClipper,
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
            guard
                let result = await self.readFeliCa(
                    id: id,
                    CoreNFCFeliCaTag(tag: felicaTag)
                )
            else {
                session.invalidate(
                    errorMessage: String(localized: "scanner.coreNFC.scanning.error.read")
                )
                return
            }

            self.completeScan(result, session: session)
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
