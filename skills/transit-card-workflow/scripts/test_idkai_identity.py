#!/usr/bin/env python3
"""Verify idKAI identifiers/catalog/assets and legacy saved-card compatibility."""
from pathlib import Path
import json
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = root / 'iOS/TransitICScanner/TransitICScanner'
identity = (source / 'Utility/CardIdentity.swift').read_text()
card_model = (source / 'Scan/CardModel.swift').read_text()
card_id = 'enum CardID:' + card_model.split('enum CardID:', 1)[1].split('struct ScanOption', 1)[0]
converter = (source / 'CardDefine/ConverterType.swift').read_text()
converter = 'enum ConverterType:' + converter.split('enum ConverterType:', 1)[1].split(
    '    @MainActor\n    func cardInfo', 1
)[0] + '}\n'
result_model = (source / 'Result/ResultModel.swift').read_text()
area = (source / 'CardDefine/City/Area.swift').read_text()
saved = (source / 'Result/SaveData/ResultSave.swift').read_text()
saved = '@Model\nfinal class SavedCard {' + saved.split('@Model\nfinal class SavedCard {', 1)[1].split(
    '\nenum ResultSave {', 1
)[0]

# Every key referenced by the canonical card definition must be translated.
catalog = json.loads((source / 'Localize/Localizable.xcstrings').read_text())['strings']
definition = (source / 'CardDefine/idKAI/idKAI.swift').read_text()
keys = set(re.findall(r'"((?:cardList\.idKAI|idKAI\.|card\.idKAI)[^"]*)"', definition))
assert keys == {
    'cardList.idKAI', 'cardList.idKAI.sortName', 'cardList.idKAI.description',
    'idKAI.short', 'idKAI.scand.description', 'card.idKAI',
}
for key in keys:
    for language in ('en', 'ja', 'zh-Hans', 'zh-Hant'):
        assert catalog[key]['localizations'][language]['stringUnit']['value'], (key, language)
assert not any('idKMT' in key or key == 'card.KMT' for key in catalog)
asset = source / 'Assets.xcassets/Logo/Card/idKAI.imageset'
for entry in json.loads((asset / 'Contents.json').read_text())['images']:
    if 'filename' in entry:
        assert (asset / entry['filename']).is_file()
assert not (asset.parent / 'idKMT.imageset').exists()

checks = r'''
assert(CardID(rawValue: "idKMT") == .idKAI)
assert(ConverterType(rawValue: "idKMT") == .idKAI)
assert(CardID(rawValue: "idKAI") == .idKAI)
assert(ConverterType(rawValue: "idKAI") == .idKAI)
assert(CardID.idKAI.rawValue == "idKAI")
assert(ConverterType.idKAI.rawValue == "idKAI")
assert(CardID.allCases.filter { $0 == .idKAI }.count == 1)
assert(ConverterType.allCases.filter { $0 == .idKAI }.count == 1)
for value in CardID.allCases { assert(CardID(rawValue: value.rawValue) == value) }
for value in ConverterType.allCases { assert(ConverterType(rawValue: value.rawValue) == value) }
assert(CardID(rawValue: "invalid-card") == nil)
assert(ConverterType(rawValue: "invalid-card") == nil)
assert(CardIdentity.assetName("jpIC_suica") == "jpIC_suica")
assert(CardIdentity.localizationKey("unrelated.idKMT") == "unrelated.idKMT")
assert(CardIdentity.localizationKey("idKMT.scand.description") == "idKAI.scand.description")
assert(CardIdentity.localizationKey("cardList.idKMT.sortName") == "cardList.idKAI.sortName")
assert(CardIdentity.localizationKey("cardList.idKMT.description") == "cardList.idKAI.description")

let container = try ModelContainer(
    for: SavedCard.self, SavedHistory.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
)
let context = ModelContext(container)
let legacy = SavedCard(
    idm: "SYNTHETIC-KAI-ID", name: "cardList.idKMT", nameShort: "idKMT.short",
    displayName: "User name containing idKMT", iconName: "idKMT", currency: "idr",
    type: "card.KMT", balance: 4567, isLastHide: true,
    cardDescription: "idKMT.scand.description", converterTypeRaw: "idKMT",
    savedAt: Date(timeIntervalSinceReferenceDate: 0)
)
context.insert(legacy)
let history = SavedHistory(
    processType: 1, processType4: 0, date: DateComponents(year: 2026, month: 1, day: 2),
    balance: 100, amount: nil, lineIn: 0, stationIn: 0, lineOut: 0x12,
    stationOut: 0x34, transactionId: 42, mappingID: ""
)
legacy.histories = [history]
try context.save()
let restored = try context.fetch(FetchDescriptor<SavedCard>()).first!
let result = restored.result()
assert(restored.nameKey == "cardList.idKAI" && restored.nameShortKey == "idKAI.short")
assert(restored.iconAssetName == "idKAI")
assert(result.info?.name == "cardList.idKAI" && result.info?.nameShort == "idKAI.short")
assert(result.info?.type == "card.idKAI" && result.info?.iconName == "idKAI")
assert(result.info?.displayName == "User name containing idKMT")
assert(result.balance == 4567 && result.history?.count == 1)
assert(result.history?[0].transactionId == 42 && result.history?[0].balance == 100)
assert(result.converter == .idKAI && result.converterTypeRaw == "idKAI")
assert(result.description == "idKAI.scand.description" && result.isLastHide)
// Projection must not change persisted properties or require a schema migration.
assert(restored.name == "cardList.idKMT" && restored.converterTypeRaw == "idKMT")
assert(restored.iconName == "idKMT" && restored.type == "card.KMT")
print("idKAI identifiers, localization/assets and legacy SwiftData checks passed")
'''
with tempfile.TemporaryDirectory(prefix='idkai-identity-') as tmp:
    path = Path(tmp)
    (path / 'main.swift').write_text(
        'import SwiftData\nimport SwiftUI\n' + identity + area + card_id + converter
        + result_model + saved + checks
    )
    subprocess.run([
        'xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', str(path / 'cache'),
        str(path / 'main.swift'), '-o', str(path / 'tests'),
    ], check=True)
    subprocess.run([str(path / 'tests')], check=True)
