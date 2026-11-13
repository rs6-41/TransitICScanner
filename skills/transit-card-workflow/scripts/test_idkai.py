#!/usr/bin/env python3
"""Run the production KMT byte parser against synthetic regression fixtures.

Uses Foundation on macOS; fixtures are artificial bytes, not real card records.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = root / 'iOS/TransitICScanner/TransitICScanner'
parser = (source / 'CardDefine/idKAI/idKAI.swift').read_text().split('struct KAIData {', 1)[1]
model = (source / 'Result/ResultModel.swift').read_text().split('struct ResultHistory:', 1)[1].split('extension ResultHistory', 1)[0]
reader_source = (source / 'CardDefine/idKAI/idKAI.swift').read_text()
reader_methods = reader_source.split('    func idKAIReadHistoryBlocks(', 1)[1].split('    func idKAIInfo(', 1)[0]
protocol = (source / 'Scan/FeliCa/FeliCaTagReading.swift').read_text().split('protocol FeliCaTagReading {', 1)[1].split('/// CoreNFC', 1)[0]
reader = 'protocol FeliCaTagReading {' + protocol + '\nfinal class NFCScannerModel {\nfunc idKAIReadHistoryBlocks(' + reader_methods + '\n}\n'
reader += r'''
enum Log { static func debug(_ text: String) {} }
final class TestTag: FeliCaTagReading {
    let currentIDm = Data(repeating: 0, count: 8)
    var reads = 0
    var response = Data(repeating: 1, count: 16)
    func readWithoutEncryption(serviceCodeList: [Data], blockList: [Data],
        completionHandler: @escaping @Sendable (Int, Int, [Data], (any Error)?) -> Void) {
        reads += 1
        assert(serviceCodeList == [Data([0x0F, 0x20])])
        assert(blockList == [Data([0x80, UInt8(reads - 1)])])
        completionHandler(0, 0, [response], nil)
    }
}
'''
checks = r'''
let id = Data("1234567890123456".utf8)
let balance = Data([0x78,0x56,0x34,0x12, 1,2,3,4, 0,0,0,0,0, 1,2,3])
// Timestamp/amount/gate/type/sequence exercise both byte orders.
let record = Data([0x30,0,0,0, 0,0,0x12,0x34, 0x56,0x78, 0,0, 1, 1,2,3])
func parse(_ b: Data = balance, _ h: [Data] = [record]) -> KAIData {
    KAIData.parse(idBlock: id, balanceBlock: b, historyBlocks: h)!
}
let parsed = parse()
assert(parsed.serialNumber == "1234567890123456")
assert(parsed.balance == 0x12345678)
assert(parsed.lastTransactionAmount == 0x04030201)
assert(parsed.transactionCounter == 0x010203)
let history = parsed.histories[0]
assert(history.balance == 0x1234 && history.transactionId == 0x010203)
assert(history.lineOut == 0x56 && history.stationOut == 0x78)
assert(history.date.year != nil && history.date.minute != nil)
// Slices retain nonzero indices: decoding must match unsliced input.
let slicedBalance = (Data([0xFF]) + balance).dropFirst()
let slicedRecord = (Data([0xFF]) + record).dropFirst()
assert(slicedBalance.startIndex != 0 && slicedRecord.startIndex != 0)
assert(parse(slicedBalance, [slicedRecord]).histories == parsed.histories)
assert(parse(slicedBalance).balance == parsed.balance)
assert(KAIData.parse(idBlock: Data(), balanceBlock: balance, historyBlocks: []) == nil)
assert(KAIData.parse(idBlock: id, balanceBlock: Data(repeating: 0, count: 15), historyBlocks: []) == nil)
assert(parse(balance, [Data(), Data(repeating: 0, count: 15)]).histories.isEmpty)
var unknown = record
unknown[12] = 255
assert(parse(balance, [unknown]).histories[0].balance == -0x1234)
var invalid = record
invalid[8] = 0; invalid[9] = 0
assert(parse(balance, [invalid, record]).histories.count == 1)
let scanner = NFCScannerModel()
let tag = TestTag()
let service = Data([0x0F, 0x20])
let negative = await scanner.idKAIReadHistoryBlocks(tag, service: service, maxCount: -1)
assert(negative.isEmpty && tag.reads == 0)
let excessive = await scanner.idKAIReadHistoryBlocks(tag, service: service, maxCount: Int.max)
assert(excessive.count == 20 && tag.reads == 20)
for length in [0, 15, 17] {
    tag.reads = 0
    tag.response = Data(repeating: 1, count: length)
    let malformed = await scanner.idKAIReadBlocks(tag, service: service, blocks: [0])
    assert(malformed == nil)
}
for byte: UInt8 in [0, 255] {
    tag.reads = 0
    tag.response = Data(repeating: byte, count: 16)
    let empty = await scanner.idKAIReadHistoryBlocks(tag, service: service, maxCount: 20)
    assert(empty.isEmpty && tag.reads == 1)
}
print("KAI parser and reader regression checks passed")
'''
with tempfile.TemporaryDirectory(prefix='idkai-tests-') as tmp:
    path = Path(tmp)
    (path / 'main.swift').write_text('import Foundation\nstruct ResultHistory:' + model + '\nstruct KAIData {' + parser + reader + checks)
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(path / 'cache'), str(path / 'main.swift'), '-o', str(path / 'tests')], check=True)
    subprocess.run([str(path / 'tests')], check=True)
