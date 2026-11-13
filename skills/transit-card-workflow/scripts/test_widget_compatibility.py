#!/usr/bin/env python3
"""Verify production Widget Codable names preserve the legacy App Group JSON."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = root / 'iOS/TransitICScanner'
model = (source / 'CardBalanceWidget/BalanceWidgetModel.swift').read_text()
model = 'struct BalanceWidgetModel:' + model.split('struct BalanceWidgetModel:', 1)[1].split(
    '/// Widget', 1
)[0]
area = (source / 'TransitICScanner/CardDefine/Area.swift').read_text()
currency = 'enum CurrencyType:' + area.split('enum CurrencyType:', 1)[1].split(
    '    func getLocalize', 1
)[0] + '}\n'
identity = (source / 'TransitICScanner/Utility/CardIdentity.swift').read_text()
checks = r'''
// Synthetic legacy wire data, not actual card information.
let legacy: [[String: Any]] = [[
    "DisplayName": "Fixture card", "balance": 123.45, "currencyType": "usd",
    "idm": "SYNTHETIC-WIDGET-ID", "icon": "placeholderCard", "savedAt": 0.0
]]
let payload = try JSONSerialization.data(withJSONObject: legacy)
var models = try JSONDecoder().decode([BalanceWidgetModel].self, from: payload)
assert(models.count == 1)
assert(models[0].displayName == "Fixture card")
assert(models[0].balance == 123.45 && models[0].currencyType == .usd)
assert(models[0].idm == "SYNTHETIC-WIDGET-ID" && models[0].icon == "placeholderCard")
assert(models[0].savedAt == Date(timeIntervalSinceReferenceDate: 0))
let encoded = try JSONEncoder().encode(models)
let wire = try JSONSerialization.jsonObject(with: encoded) as! [[String: Any]]
assert(NSDictionary(dictionary: wire[0]).isEqual(to: legacy[0]))
assert(wire[0]["displayName"] == nil && wire[0]["DisplayName"] != nil)
models[0].displayName = "Edited fixture"
let updated = try JSONEncoder().encode(models)
let updatedWire = try JSONSerialization.jsonObject(with: updated) as! [[String: Any]]
assert(updatedWire[0]["DisplayName"] as? String == "Edited fixture")
let decoded = try JSONDecoder().decode([BalanceWidgetModel].self, from: updated)
assert(decoded == models)
let minimal = Data("[{\"idm\":\"SYNTHETIC-MINIMAL-ID\"}]".utf8)
let optional = try JSONDecoder().decode([BalanceWidgetModel].self, from: minimal)[0]
assert(optional.displayName == nil && optional.balance == nil && optional.savedAt == nil)
assert(optional.currencyType == nil && optional.icon == nil)
var legacyCard = optional
legacyCard.icon = "idKMT"
assert(legacyCard.iconAssetName == "idKAI")
assert(legacyCard.icon == "idKMT") // Reading an old icon does not rewrite persisted JSON.
assert(models[0].iconAssetName == "placeholderCard")
assert(optional.iconAssetName == nil)
print("Widget legacy JSON compatibility checks passed")
'''
with tempfile.TemporaryDirectory(prefix='widget-compatibility-') as tmp:
    path = Path(tmp)
    (path / 'main.swift').write_text('import Foundation\n' + identity + currency + model + checks)
    subprocess.run([
        'xcrun', 'swiftc', '-module-cache-path', str(path / 'cache'),
        str(path / 'main.swift'), '-o', str(path / 'tests'),
    ], check=True)
    subprocess.run([str(path / 'tests')], check=True)
