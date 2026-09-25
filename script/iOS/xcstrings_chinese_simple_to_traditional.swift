import Foundation
import CoreFoundation

struct Replacement {
    let range: Range<String.Index>
    let value: String
}

func simplifiedToTraditional(_ text: String) -> String {
    let mutable = NSMutableString(string: text)

    CFStringTransform(
        mutable,
        nil,
        "Hans-Hant" as CFString,
        false
    )

    return mutable as String
}

func jsonString(_ value: Any) -> String? {
    guard let value = value as? String else {
        return nil
    }

    return value
}

func escapedJSONString(_ value: String) throws -> String {
    let data = try JSONSerialization.data(
        withJSONObject: [value],
        options: []
    )

    guard var result = String(data: data, encoding: .utf8) else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 10,
            userInfo: [
                NSLocalizedDescriptionKey: "JSON文字列の生成に失敗しました"
            ]
        )
    }

    guard result.first == "[", result.last == "]" else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 11,
            userInfo: [
                NSLocalizedDescriptionKey: "JSON文字列の形式が不正です"
            ]
        )
    }

    result.removeFirst()
    result.removeLast()

    return result
}

func findStringValueRange(
    in source: String,
    key: String,
    from start: String.Index,
    to end: String.Index
) -> Range<String.Index>? {
    guard start < end else {
        return nil
    }

    let target: String

    do {
        target = try escapedJSONString(key)
    } catch {
        return nil
    }

    let searchRange = start..<end

    guard let keyRange = source.range(of: target, range: searchRange) else {
        return nil
    }

    guard let colonRange = source.range(
        of: ":",
        range: keyRange.upperBound..<end
    ) else {
        return nil
    }

    var valueStart = colonRange.upperBound

    while valueStart < end,
          source[valueStart].isWhitespace {
        valueStart = source.index(after: valueStart)
    }

    guard valueStart < end,
          source[valueStart] == "\"" else {
        return nil
    }

    let contentStart = source.index(after: valueStart)
    var current = contentStart
    var escaped = false

    while current < end {
        let character = source[current]

        if escaped {
            escaped = false
        } else if character == "\\" {
            escaped = true
        } else if character == "\"" {
            return contentStart..<current
        }

        current = source.index(after: current)
    }

    return nil
}

func findObjectRange(
    in source: String,
    containingKey key: String,
    from start: String.Index
) -> Range<String.Index>? {
    guard let keyJSON = try? escapedJSONString(key),
          let keyRange = source.range(of: keyJSON, range: start..<source.endIndex),
          let colonRange = source.range(
              of: ":",
              range: keyRange.upperBound..<source.endIndex
          ) else {
        return nil
    }

    var objectStart = colonRange.upperBound

    while objectStart < source.endIndex,
          source[objectStart].isWhitespace {
        objectStart = source.index(after: objectStart)
    }

    guard objectStart < source.endIndex,
          source[objectStart] == "{" else {
        return nil
    }

    var depth = 0
    var current = objectStart
    var inString = false
    var escaped = false

    while current < source.endIndex {
        let character = source[current]

        if inString {
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                inString = false
            }
        } else {
            if character == "\"" {
                inString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1

                if depth == 0 {
                    return objectStart...current
                }
            }
        }

        current = source.index(after: current)
    }

    return nil
}

func processFile(at url: URL) throws {
    let data = try Data(contentsOf: url)

    guard let source = String(data: data, encoding: .utf8) else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "UTF-8として読み込めませんでした"
            ]
        )
    }

    guard let jsonData = source.data(using: .utf8) else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 2,
            userInfo: [
                NSLocalizedDescriptionKey: "JSONデータを生成できませんでした"
            ]
        )
    }

    guard let root = try JSONSerialization.jsonObject(
        with: jsonData,
        options: []
    ) as? [String: Any] else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 3,
            userInfo: [
                NSLocalizedDescriptionKey: "xcstringsのルート構造が不正です"
            ]
        )
    }

    guard let strings = root["strings"] as? [String: Any] else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 4,
            userInfo: [
                NSLocalizedDescriptionKey: "\"strings\" が見つかりません"
            ]
        )
    }

    var replacements: [Replacement] = []

    for (key, value) in strings {
        guard let stringObject = value as? [String: Any],
              let localizations = stringObject["localizations"] as? [String: Any],
              let zhHans = localizations["zh-Hans"] as? [String: Any],
              let zhHant = localizations["zh-Hant"] as? [String: Any],
              let zhHansUnit = zhHans["stringUnit"] as? [String: Any],
              let zhHantUnit = zhHant["stringUnit"] as? [String: Any],
              let sourceValue = zhHansUnit["value"] as? String,
              let state = zhHantUnit["state"] as? String,
              state == "needs_review" else {
            continue
        }

        guard let stringObjectRange = findObjectRange(
            in: source,
            containingKey: key,
            from: source.startIndex
        ) else {
            throw NSError(
                domain: "XCStringsConverter",
                code: 5,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "キー \"\(key)\" の位置を特定できませんでした"
                ]
            )
        }

        let stringObjectEnd = source.index(
            after: stringObjectRange.upperBound
        )

        guard let localizationsRange = findObjectRange(
            in: source,
            containingKey: "localizations",
            from: stringObjectRange.lowerBound
        ) else {
            throw NSError(
                domain: "XCStringsConverter",
                code: 6,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "キー \"\(key)\" の localizations を特定できませんでした"
                ]
            )
        }

        let localizationsEnd = source.index(
            after: localizationsRange.upperBound
        )

        guard let zhHantRange = findObjectRange(
            in: source,
            containingKey: "zh-Hant",
            from: localizationsRange.lowerBound
        ),
        zhHantRange.upperBound < localizationsRange.upperBound else {
            throw NSError(
                domain: "XCStringsConverter",
                code: 7,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "キー \"\(key)\" の zh-Hant を特定できませんでした"
                ]
            )
        }

        let zhHantEnd = source.index(after: zhHantRange.upperBound)

        guard let stringUnitRange = findObjectRange(
            in: source,
            containingKey: "stringUnit",
            from: zhHantRange.lowerBound
        ),
        stringUnitRange.upperBound < zhHantEnd else {
            throw NSError(
                domain: "XCStringsConverter",
                code: 8,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "キー \"\(key)\" の zh-Hant.stringUnit を特定できませんでした"
                ]
            )
        }

        let stringUnitEnd = source.index(after: stringUnitRange.upperBound)

        guard let stateRange = findStringValueRange(
            in: source,
            key: "state",
            from: stringUnitRange.lowerBound,
            to: stringUnitEnd
        ),
        let valueRange = findStringValueRange(
            in: source,
            key: "value",
            from: stringUnitRange.lowerBound,
            to: stringUnitEnd
        ) else {
            throw NSError(
                domain: "XCStringsConverter",
                code: 9,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "キー \"\(key)\" の state/value を特定できませんでした"
                ]
            )
        }

        let converted = simplifiedToTraditional(sourceValue)
        let escapedConverted = try escapedJSONString(converted)

        replacements.append(
            Replacement(
                range: valueRange,
                value: escapedConverted
            )
        )

        replacements.append(
            Replacement(
                range: stateRange,
                value: try escapedJSONString("translated")
            )
        )
    }

    if replacements.isEmpty {
        print("変換対象はありませんでした。")
        return
    }

    var result = source

    let sortedReplacements = replacements.sorted {
        $0.range.lowerBound > $1.range.lowerBound
    }

    for replacement in sortedReplacements {
        result.replaceSubrange(
            replacement.range,
            with: replacement.value
        )
    }

    let temporaryURL = url.appendingPathExtension("tmp")

    guard let outputData = result.data(using: .utf8) else {
        throw NSError(
            domain: "XCStringsConverter",
            code: 12,
            userInfo: [
                NSLocalizedDescriptionKey: "出力データの生成に失敗しました"
            ]
        )
    }

    try outputData.write(
        to: temporaryURL,
        options: [.atomic]
    )

    _ = try Data(contentsOf: temporaryURL)

    try FileManager.default.replaceItemAt(
        url,
        withItemAt: temporaryURL
    )

    print("変換完了: \(replacements.count / 2) 件")
}

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    print("使用方法:")
    print("  xcstrings-converter Localizable.xcstrings")
    exit(1)
}

let url = URL(fileURLWithPath: arguments[1])

do {
    try processFile(at: url)
} catch {
    print("エラー: \(error.localizedDescription)")
    exit(1)
}