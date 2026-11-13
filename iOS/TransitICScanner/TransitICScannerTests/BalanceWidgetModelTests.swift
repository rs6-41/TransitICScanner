import Foundation
import Testing

@testable import TransitICScanner

/// App Group内のWidget用JSON（`DisplayName` キー等）が既存契約のまま読み書きできることを確認する。
/// 値はすべて合成データで、実カードの情報ではない。
struct BalanceWidgetModelTests {
    private let legacyJSON = Data(
        """
        [{"DisplayName":"Fixture card","balance":123.45,"currencyType":"usd",\
        "idm":"SYNTHETIC-WIDGET-ID","icon":"placeholderCard","savedAt":0}]
        """.utf8
    )

    @Test func decodesLegacyJSONKeys() throws {
        let models = try JSONDecoder().decode([BalanceWidgetModel].self, from: legacyJSON)

        #expect(models.count == 1)
        #expect(models[0].displayName == "Fixture card")
        #expect(models[0].balance == 123.45)
        #expect(models[0].currencyType == .usd)
        #expect(models[0].idm == "SYNTHETIC-WIDGET-ID")
        #expect(models[0].savedAt == Date(timeIntervalSinceReferenceDate: 0))
    }

    @Test func encodesWithLegacyDisplayNameKey() throws {
        var models = try JSONDecoder().decode([BalanceWidgetModel].self, from: legacyJSON)
        models[0].displayName = "Edited fixture"

        let encoded = try JSONEncoder().encode(models)
        let wire = try #require(JSONSerialization.jsonObject(with: encoded) as? [[String: Any]])

        #expect(wire[0]["DisplayName"] as? String == "Edited fixture")
        #expect(wire[0]["displayName"] == nil)
        #expect(try JSONDecoder().decode([BalanceWidgetModel].self, from: encoded) == models)
    }

    @Test func decodesMinimalJSONWithOptionalFieldsMissing() throws {
        let minimal = Data(#"[{"idm":"SYNTHETIC-MINIMAL-ID"}]"#.utf8)
        let model = try #require(try JSONDecoder().decode([BalanceWidgetModel].self, from: minimal).first)

        #expect(model.displayName == nil)
        #expect(model.balance == nil)
        #expect(model.currencyType == nil)
        #expect(model.iconAssetName == nil)
    }

    @Test func legacyIconResolvesAssetWithoutRewritingStoredValue() {
        let model = BalanceWidgetModel(idm: "SYNTHETIC-ICON-ID", icon: "idKMT")

        #expect(model.iconAssetName == "idKAI")
        #expect(model.icon == "idKMT")
    }
}
