#!/usr/bin/env swift

import Foundation
import CoreFoundation

struct Replacement {
    let range: Range<String.Index>
    let value: String
}

enum ConverterError: LocalizedError {
    case invalidUTF8
    case invalidJSON
    case missingStrings
    case keyNotFound(String)
    case localizationsNotFound(String)
    case zhHantNotFound(String)
    case stringUnitNotFound(String)
    case stateOrValueNotFound(String)
    case invalidJSONString(String)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            return "ファイルをUTF-8として読み込めませんでした。"
        case .invalidJSON:
            return "xcstringsのJSON構造が不正です。"
        case .missingStrings:
            return "\"strings\" が見つかりません。"
        case .keyNotFound(let key):
            return "キー \"\(key)\" の位置を特定できませんでした。"
        case .localizationsNotFound(let key):
            return "キー \"\(key)\" の localizations を特定できませんでした。"
        case .zhHantNotFound(let key):
            return "キー \"\(key)\" の zh-Hant を特定できませんでした。"
        case .stringUnitNotFound(let key):
            return "キー \"\(key)\" の zh-Hant.stringUnit を特定できませんでした。"
        case .stateOrValueNotFound(let key):
            return "キー \"\(key)\" の state または value を特定できませんでした。"
        case .invalidJSONString(let value):
            return "JSON文字列を生成できませんでした: \(value)"
        case .writeFailed:
            return "ファイルの書き込みに失敗しました。"
        }
    }
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

func makeJSONString(_ value: String) throws -> String {
    let data = try JSONSerialization.data(
        withJSONObject: [value],
        options: []
    )

    guard let json = String(data: data, encoding: .utf8),
          json.count >= 2,
          json.first == "[",
          json.last == "]" else {
        throw ConverterError.invalidJSONString(value)
    }

    return String(json.dropFirst().dropLast())
}

func findJSONKey(
    _ key: String,
    in source: String,
    from start: String.Index,
    to end: String.Index
) throws -> Range<String.Index> {
    let encodedKey = try makeJSONString(key)

    guard let range = source.range(
        of: encodedKey,
        range: start..<end
    ) else {
        throw ConverterError.keyNotFound(key)
    }

    return range
}

func skipWhitespace(
    in source: String,
    from start: String.Index,
    to end: String.Index
) -> String.Index {
    var index = start

    while index < end && source[index].isWhitespace {
        index = source.index(after: index)
    }

    return index
}

func findObjectRange(
    containingKey key: String,
    in source: String,
    from start: String.Index,
    to end: String.Index
) throws -> Range<String.Index> {
    let keyRange = try findJSONKey(
        key,
        in: source,
        from: start,
        to: end
    )

    guard let colonRange = source.range(
        of: ":",
        range: keyRange.upperBound..<end
    ) else {
        throw ConverterError.keyNotFound(key)
    }

    let objectStart = skipWhitespace(
        in: source,
        from: colonRange.upperBound,
        to: end
    )

    guard objectStart < end,
          source[objectStart] == "{" else {
        throw ConverterError.keyNotFound(key)
    }

    var index = objectStart
    var depth = 0
    var insideString = false
    var escaped = false

    while index < end {
        let character = source[index]

        if insideString {
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                insideString = false
            }
        } else {
            switch character {
            case "\"":
                insideString = true

            case "{":
                depth += 1

            case "}":
                depth -= 1

                if depth == 0 {
                    let objectEnd = source.index(
                        after: index
                    )

                    return objectStart..<objectEnd
                }

            default:
                break
            }
        }

        index = source.index(after: index)
    }

    throw ConverterError.keyNotFound(key)
}

func findJSONStringValueRange(
    forKey key: String,
    in source: String,
    from start: String.Index,
    to end: String.Index
) throws -> Range<String.Index> {
    let keyRange = try findJSONKey(
        key,
        in: source,
        from: start,
        to: end
    )

    guard let colonRange = source.range(
        of: ":",
        range: keyRange.upperBound..<end
    ) else {
        throw ConverterError.invalidJSON
    }

    let valueStart = skipWhitespace(
        in: source,
        from: colonRange.upperBound,
        to: end
    )

    guard valueStart < end,
          source[valueStart] == "\"" else {
        throw ConverterError.invalidJSON
    }

    let contentStart = source.index(
        after: valueStart
    )

    var index = contentStart
    var escaped = false

    while index < end {
        let character = source[index]

        if escaped {
            escaped = false
        } else if character == "\\" {
            escaped = true
        } else if character == "\"" {
            return contentStart..<index
        }

        index = source.index(after: index)
    }

    throw ConverterError.invalidJSON
}

func processFile(at url: URL) throws {
    let originalData = try Data(contentsOf: url)

    guard let source = String(
        data: originalData,
        encoding: .utf8
    ) else {
        throw ConverterError.invalidUTF8
    }

    guard let jsonData = source.data(using: .utf8),
          let root = try JSONSerialization.jsonObject(
              with: jsonData,
              options: []
          ) as? [String: Any] else {
        throw ConverterError.invalidJSON
    }

    guard let strings = root["strings"] as? [String: Any] else {
        throw ConverterError.missingStrings
    }

    guard let stringsRange = try? findObjectRange(
        containingKey: "strings",
        in: source,
        from: source.startIndex,
        to: source.endIndex
    ) else {
        throw ConverterError.missingStrings
    }

    var replacements: [Replacement] = []
    var convertedKeys: [String] = []

    for (key, rawStringObject) in strings {
        guard let stringObject = rawStringObject as? [String: Any],
              let localizations = stringObject["localizations"] as? [String: Any],
              let zhHans = localizations["zh-Hans"] as? [String: Any],
              let zhHant = localizations["zh-Hant"] as? [String: Any],
              let zhHansUnit = zhHans["stringUnit"] as? [String: Any],
              let zhHantUnit = zhHant["stringUnit"] as? [String: Any],
              let sourceValue = zhHansUnit["value"] as? String,
              let state = zhHantUnit["state"] as? String else {
            continue
        }

        guard state == "needs_review" else {
            continue
        }

        let stringObjectRange: Range<String.Index>

        do {
            stringObjectRange = try findObjectRange(
                containingKey: key,
                in: source,
                from: stringsRange.lowerBound,
                to: stringsRange.upperBound
            )
        } catch {
            throw ConverterError.keyNotFound(key)
        }

        let localizationsRange: Range<String.Index>

        do {
            localizationsRange = try findObjectRange(
                containingKey: "localizations",
                in: source,
                from: stringObjectRange.lowerBound,
                to: stringObjectRange.upperBound
            )
        } catch {
            throw ConverterError.localizationsNotFound(key)
        }

        let zhHantRange: Range<String.Index>

        do {
            zhHantRange = try findObjectRange(
                containingKey: "zh-Hant",
                in: source,
                from: localizationsRange.lowerBound,
                to: localizationsRange.upperBound
            )
        } catch {
            throw ConverterError.zhHantNotFound(key)
        }

        let stringUnitRange: Range<String.Index>

        do {
            stringUnitRange = try findObjectRange(
                containingKey: "stringUnit",
                in: source,
                from: zhHantRange.lowerBound,
                to: zhHantRange.upperBound
            )
        } catch {
            throw ConverterError.stringUnitNotFound(key)
        }

        let stateRange: Range<String.Index>

        let valueRange: Range<String.Index>

        do {
            stateRange = try findJSONStringValueRange(
                forKey: "state",
                in: source,
                from: stringUnitRange.lowerBound,
                to: stringUnitRange.upperBound
            )

            valueRange = try findJSONStringValueRange(
                forKey: "value",
                in: source,
                from: stringUnitRange.lowerBound,
                to: stringUnitRange.upperBound
            )
        } catch {
            throw ConverterError.stateOrValueNotFound(key)
        }

        let convertedValue = simplifiedToTraditional(
            sourceValue
        )

        let escapedConvertedValue = try makeJSONString(
            convertedValue
        )

        let escapedTranslatedState = try makeJSONString(
            "translated"
        )

        replacements.append(
            Replacement(
                range: valueRange,
                value: escapedConvertedValue
            )
        )

        replacements.append(
            Replacement(
                range: stateRange,
                value: escapedTranslatedState
            )
        )

        convertedKeys.append(key)
    }

    guard !replacements.isEmpty else {
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

    guard let outputData = result.data(using: .utf8) else {
        throw ConverterError.writeFailed
    }

    let temporaryURL = url.appendingPathExtension(
        "tmp-\(UUID().uuidString)"
    )

    defer {
        try? FileManager.default.removeItem(
            at: temporaryURL
        )
    }

    try outputData.write(
        to: temporaryURL,
        options: [.atomic]
    )

    let verifyData = try Data(
        contentsOf: temporaryURL
    )

    guard let verifyJSON = try? JSONSerialization.jsonObject(
        with: verifyData,
        options: []
    ) else {
        throw ConverterError.invalidJSON
    }

    _ = verifyJSON

    _ = try FileManager.default.replaceItemAt(
        url,
        withItemAt: temporaryURL
    )

    print("変換完了: \(convertedKeys.count) 件")

    for key in convertedKeys.sorted() {
        print("  \(key)")
    }
}

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    print("使用方法:")
    print("  swift xcstrings_chinese_simple_to_traditional.swift Localizable.xcstrings")
    exit(1)
}

let fileURL = URL(
    fileURLWithPath: arguments[1]
)

do {
    try processFile(
        at: fileURL
    )
} catch {
    print("エラー: \(error.localizedDescription)")
    exit(1)
}