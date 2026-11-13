#!/usr/bin/env swift

import Foundation
import CoreFoundation

struct Replacement {
    let range: Range<String.Index>
    let value: String
}

func convertSimplifiedToTraditional(_ text: String) -> String {
    let result = NSMutableString(string: text)

    CFStringTransform(
        result,
        nil,
        "Hans-Hant" as CFString,
        false
    )

    return result as String
}

func encodeJSONString(_ value: String) -> String? {
    guard
        let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: [.fragmentsAllowed]
        )
    else {
        return nil
    }

    return String(data: data, encoding: .utf8)
}

func decodeJSONString(_ value: String) -> String? {
    guard let data = value.data(using: .utf8) else {
        return nil
    }

    return try? JSONDecoder().decode(String.self, from: data)
}

func skipWhitespace(
    _ source: String,
    _ index: String.Index,
    _ end: String.Index
) -> String.Index {
    var index = index

    while index < end {
        switch source[index] {
        case " ", "\t", "\r", "\n":
            index = source.index(after: index)
        default:
            return index
        }
    }

    return index
}

func findMatching(
    _ source: String,
    from start: String.Index,
    end: String.Index
) -> String.Index? {
    guard start < end else {
        return nil
    }

    let opening = source[start]

    let closing: Character

    switch opening {
    case "{":
        closing = "}"
    case "[":
        closing = "]"
    default:
        return nil
    }

    var depth = 0
    var index = start
    var inString = false
    var escaped = false

    while index < end {
        let character = source[index]

        if inString {
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                inString = false
            }

            index = source.index(after: index)
            continue
        }

        if character == "\"" {
            inString = true
        } else if character == opening {
            depth += 1
        } else if character == closing {
            depth -= 1

            if depth == 0 {
                return source.index(after: index)
            }
        }

        index = source.index(after: index)
    }

    return nil
}

func readJSONString(
    _ source: String,
    start: String.Index,
    end: String.Index
) -> (String, Range<String.Index>)? {
    guard start < end, source[start] == "\"" else {
        return nil
    }

    var index = source.index(after: start)
    var escaped = false

    while index < end {
        let character = source[index]

        if escaped {
            escaped = false
        } else if character == "\\" {
            escaped = true
        } else if character == "\"" {
            let valueEnd = source.index(after: index)
            let range = start..<valueEnd

            guard
                let value = decodeJSONString(
                    String(source[range])
                )
            else {
                return nil
            }

            return (value, range)
        }

        index = source.index(after: index)
    }

    return nil
}

func findMember(
    _ key: String,
    in objectRange: Range<String.Index>,
    source: String
) -> Range<String.Index>? {
    var index = source.index(
        after: objectRange.lowerBound
    )

    let end = objectRange.upperBound

    while index < end {
        index = skipWhitespace(
            source,
            index,
            end
        )

        if index >= end || source[index] == "}" {
            return nil
        }

        guard
            let (currentKey, keyRange) = readJSONString(
                source,
                start: index,
                end: end
            )
        else {
            return nil
        }

        index = keyRange.upperBound

        index = skipWhitespace(
            source,
            index,
            end
        )

        guard index < end, source[index] == ":" else {
            return nil
        }

        index = source.index(after: index)

        index = skipWhitespace(
            source,
            index,
            end
        )

        guard index < end else {
            return nil
        }

        let valueStart = index

        if source[index] == "{" || source[index] == "[" {
            guard
                let valueEnd = findMatching(
                    source,
                    from: index,
                    end: end
                )
            else {
                return nil
            }

            if currentKey == key {
                return valueStart..<valueEnd
            }

            index = valueEnd
        } else if source[index] == "\"" {
            guard
                let (_, valueRange) = readJSONString(
                    source,
                    start: index,
                    end: end
                )
            else {
                return nil
            }

            if currentKey == key {
                return valueRange
            }

            index = valueRange.upperBound
        } else {
            while index < end {
                let character = source[index]

                if character == "," || character == "}" {
                    break
                }

                index = source.index(after: index)
            }

            if currentKey == key {
                return valueStart..<index
            }
        }

        index = skipWhitespace(
            source,
            index,
            end
        )

        if index < end, source[index] == "," {
            index = source.index(after: index)
        }
    }

    return nil
}

func findTopLevelEntries(
    source: String,
    stringsRange: Range<String.Index>
) -> [(String, Range<String.Index>)] {
    var results: [(String, Range<String.Index>)] = []

    var index = source.index(
        after: stringsRange.lowerBound
    )

    let end = stringsRange.upperBound

    while index < end {
        index = skipWhitespace(
            source,
            index,
            end
        )

        if index >= end || source[index] == "}" {
            break
        }

        guard
            let (key, keyRange) = readJSONString(
                source,
                start: index,
                end: end
            )
        else {
            break
        }

        index = keyRange.upperBound

        index = skipWhitespace(
            source,
            index,
            end
        )

        guard index < end, source[index] == ":" else {
            break
        }

        index = source.index(after: index)

        index = skipWhitespace(
            source,
            index,
            end
        )

        guard index < end, source[index] == "{" else {
            break
        }

        guard
            let objectEnd = findMatching(
                source,
                from: index,
                end: end
            )
        else {
            break
        }

        results.append(
            (
                key,
                index..<objectEnd
            )
        )

        index = objectEnd

        index = skipWhitespace(
            source,
            index,
            end
        )

        if index < end, source[index] == "," {
            index = source.index(after: index)
        }
    }

    return results
}

func process(
    source: String
) throws -> (String, Int, Int) {
    guard
        let data = source.data(using: .utf8),
        let root = try JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any],
        let strings = root["strings"] as? [String: Any]
    else {
        throw NSError(
            domain: "XCStrings",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "xcstringsのJSON構造が不正です。"
            ]
        )
    }

    guard
        let stringsKeyRange = source.range(
            of: "\"strings\""
        )
    else {
        throw NSError(
            domain: "XCStrings",
            code: 2,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "stringsを特定できませんでした。"
            ]
        )
    }

    var stringsValueStart = stringsKeyRange.upperBound

    stringsValueStart = skipWhitespace(
        source,
        stringsValueStart,
        source.endIndex
    )

    guard
        stringsValueStart < source.endIndex,
        source[stringsValueStart] == ":"
    else {
        throw NSError(
            domain: "XCStrings",
            code: 3,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "stringsの値を特定できませんでした。"
            ]
        )
    }

    stringsValueStart = source.index(
        after: stringsValueStart
    )

    stringsValueStart = skipWhitespace(
        source,
        stringsValueStart,
        source.endIndex
    )

    guard
        stringsValueStart < source.endIndex,
        source[stringsValueStart] == "{"
    else {
        throw NSError(
            domain: "XCStrings",
            code: 4,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "stringsがオブジェクトではありません。"
            ]
        )
    }

    guard
        let stringsValueEnd = findMatching(
            source,
            from: stringsValueStart,
            end: source.endIndex
        )
    else {
        throw NSError(
            domain: "XCStrings",
            code: 5,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "stringsの終端を特定できませんでした。"
            ]
        )
    }

    let stringsRange = stringsValueStart..<stringsValueEnd

    let entries = findTopLevelEntries(
        source: source,
        stringsRange: stringsRange
    )

    var replacements: [Replacement] = []
    var checked = 0
    var converted = 0

    for (key, entryRange) in entries {
        checked += 1

        guard
            let entry = strings[key] as? [String: Any],
            let localizations = entry["localizations"] as? [String: Any],
            let zhHans = localizations["zh-Hans"] as? [String: Any],
            let zhHant = localizations["zh-Hant"] as? [String: Any],
            let zhHansUnit = zhHans["stringUnit"] as? [String: Any],
            let zhHantUnit = zhHant["stringUnit"] as? [String: Any],
            let zhHansValue = zhHansUnit["value"] as? String,
            let zhHantState = zhHantUnit["state"] as? String
        else {
            continue
        }

        guard zhHantState == "needs_review" else {
            continue
        }

        guard
            let localizationsRange = findMember(
                "localizations",
                in: entryRange,
                source: source
            ),
            let zhHantRange = findMember(
                "zh-Hant",
                in: localizationsRange,
                source: source
            ),
            let stringUnitRange = findMember(
                "stringUnit",
                in: zhHantRange,
                source: source
            ),
            let stateRange = findMember(
                "state",
                in: stringUnitRange,
                source: source
            ),
            let valueRange = findMember(
                "value",
                in: stringUnitRange,
                source: source
            )
        else {
            continue
        }

        let convertedValue = convertSimplifiedToTraditional(
            zhHansValue
        )

        guard
            let encodedState = encodeJSONString(
                "translated"
            ),
            let encodedValue = encodeJSONString(
                convertedValue
            )
        else {
            continue
        }

        replacements.append(
            Replacement(
                range: stateRange,
                value: encodedState
            )
        )

        replacements.append(
            Replacement(
                range: valueRange,
                value: encodedValue
            )
        )

        converted += 1
    }

    guard !replacements.isEmpty else {
        return (
            source,
            checked,
            0
        )
    }

    var result = source

    for replacement in replacements.sorted(
        by: {
            $0.range.lowerBound > $1.range.lowerBound
        }
    ) {
        result.replaceSubrange(
            replacement.range,
            with: replacement.value
        )
    }

    return (
        result,
        checked,
        converted
    )
}

func main() throws {
    guard CommandLine.arguments.count == 2 else {
        print("使用方法:")
        print("swift xcstrings_chinese_simple_to_traditional.swift Localizable.xcstrings")
        return
    }

    let path = CommandLine.arguments[1]

    guard
        let source = try? String(
            contentsOfFile: path,
            encoding: .utf8
        )
    else {
        print("エラー: ファイルを読み込めませんでした。")
        return
    }

    let (
        result,
        checked,
        converted
    ) = try process(
        source: source
    )

    print("確認した項目数: \(checked)")

    guard converted > 0 else {
        print("変換対象はありませんでした。")
        return
    }

    guard
        let resultData = result.data(using: .utf8),
        (try? JSONSerialization.jsonObject(
            with: resultData,
            options: []
        )) != nil
    else {
        print("エラー: 変換後のJSONが不正です。")
        return
    }

    let fileManager = FileManager.default
    let backupPath = path + ".backup"
    let temporaryPath = path + ".tmp"

    if fileManager.fileExists(atPath: temporaryPath) {
        try fileManager.removeItem(
            atPath: temporaryPath
        )
    }

    try result.write(
        toFile: temporaryPath,
        atomically: true,
        encoding: .utf8
    )

    if fileManager.fileExists(atPath: backupPath) {
        try fileManager.removeItem(
            atPath: backupPath
        )
    }

    try fileManager.copyItem(
        atPath: path,
        toPath: backupPath
    )

    do {
        try fileManager.removeItem(
            atPath: path
        )

        try fileManager.moveItem(
            atPath: temporaryPath,
            toPath: path
        )
    } catch {
        if fileManager.fileExists(atPath: temporaryPath) {
            try? fileManager.removeItem(
                atPath: temporaryPath
            )
        }

        if !fileManager.fileExists(atPath: path),
            fileManager.fileExists(atPath: backupPath)
        {
            try? fileManager.copyItem(
                atPath: backupPath,
                toPath: path
            )
        }

        throw error
    }

    print("変換完了: \(converted) 件")
}

do {
    try main()
} catch {
    print("エラー: \(error)")
    exit(1)
}
