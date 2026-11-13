import Testing

@testable import TransitICScanner

/// Issue #118で統一した `idKAI` と、旧バージョンが保存した `idKMT` の互換性を確認する。
struct CardIdentityTests {
    @Test func canonicalIDResolvesLegacyKAIIdentifier() {
        #expect(CardIdentity.canonicalID("idKMT") == "idKAI")
        #expect(CardIdentity.canonicalID("idKAI") == "idKAI")
        #expect(CardIdentity.canonicalID("jpIC_SAPICA") == "jpIC_SAPICA")
    }

    @Test(
        arguments: [
            ("cardList.idKMT", "cardList.idKAI"),
            ("cardList.idKMT.sortName", "cardList.idKAI.sortName"),
            ("cardList.idKMT.description", "cardList.idKAI.description"),
            ("idKMT.short", "idKAI.short"),
            ("idKMT.scand.description", "idKAI.scand.description"),
            ("card.KMT", "card.idKAI"),
        ]
    )
    func localizationKeyResolvesLegacyKeys(legacyKey: String, currentKey: String) {
        #expect(CardIdentity.localizationKey(legacyKey) == currentKey)
        #expect(CardIdentity.localizationKey(currentKey) == currentKey)
    }

    @Test func assetNameResolvesLegacyImage() {
        #expect(CardIdentity.assetName("idKMT") == "idKAI")
        #expect(CardIdentity.assetName("placeholderCard") == "placeholderCard")
    }
}
