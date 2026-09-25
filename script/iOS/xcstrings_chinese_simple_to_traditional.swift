#!/usr/bin/env swift

import Foundation
import CoreFoundation

struct Replacement {
    let range: Range<String.Index>
    let value: String
}

enum ScriptError: Error {
    case invalidArguments
    case fileReadFailed
    case invalidJSON
    case invalidStructure
    case writeFailed
}

func jsonEncodedString(_ value: String) -> String? {
    guard
        let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: [.fragmentsAllowed]
        ),
        let result = String(data: data, encoding: .utf8)
    else {
        return nil
    }

    return result
}

func decodeJSONString(_ value: String) -> String? {
    guard let data = value.data(using: .utf8) else {
        return nil
    }

    return try? JSONDecoder().decode(String.self, from: data)
}

func convertSimplifiedToTraditional(_ value: String) -> String {
    let result = NSMutableString(string: value)

    CFStringTransform(
        result,
        nil,
        "Hans-Hant" as CFString,
        false
    )

    return result as String
}

func skipWhitespace(
    _ source: String,
    _ index: String.Index,
    _ end: String.Index
) -> String.Index {
    var index = index

    while index < end {
        switch source[index] {
        case " ", "\t", "\n", "\r":
            index = source.index(after: index)
        default:
            return index
        }
    }

    return index
}

func findMatchingObject(
    _ source: String,
    from start: String.Index,
    to end: String.Index
) -> String.Index? {
    guard source[start] == "{" else {
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
        } else if character == "{" {
            depth += 1
        } else if character == "}" {
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
    from start: String.Index,
    to end: String.Index
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

            guard let value = decodeJSONString(String(source[range])) else {
                return nil
            }

            return (value, range)
        }

        index = source.index(after: index)
    }

    return nil
}

func findObjectValue(
    _ source: String,
    key: String,
    in objectRange: Range<String.Index>
) -> Range<String.Index>? {
    var index = objectRange.lowerBound
    let end = objectRange.upperBound

    guard index < end, source[index] == "{" else {
        return nil
    }

    index = source.index(after: index)

    while index < end {
        index = skipWhitespace(source, index, end)

        if index >= end || source[index] == "}" {
            return nil
        }

        guard
            let (currentKey, keyRange) = readJSONString(
                source,
                from: index,
                to: end
            )
        else {
            return nil
        }

        index = keyRange.upperBound
        index = skipWhitespace(source, index, end)

        guard index < end, source[index] == ":" else {
            return nil
        }

        index = source.index(after: index)
        index = skipWhitespace(source, index, end)

        guard index < end else {
            return nil
        }

        if currentKey == key {
            if source[index] == "\"" {
                guard
                    let (_, valueRange) = readJSONString(
                        source,
                        from: index,
                        to: end
                    )
                else {
                    return nil
                }

                return valueRange
            }

            if source[index] == "{" {
                guard
                    let valueEnd = findMatchingObject(
                        source,
                        from: index,
                        to: end
                    )
                else {
                    return nil
                }

                return index..<valueEnd
            }

            return nil
        }

        if source[index] == "{" {
            guard
                let valueEnd = findMatchingObject(
                    source,
                    from: index,
                    to: end
                )
            else {
                return nil
            }

            index = valueEnd
        } else if source[index] == "\"" {
            guard
                let (_, valueRange) = readJSONString(
                    source,
                    from: index,
                    to: end
                )
            else {
                return nil
            }

            index = valueRange.upperBound
        } else {
            while index < end {
                if source[index] == "," {
                    break
                }

                if source[index] == "}" {
                    break
                }

                index = source.index(after: index)
            }
        }

        index = skipWhitespace(source, index, end)

        if index < end, source[index] == "," {
            index = source.index(after: index)
        }
    }

    return nil
}

func findStringsObject(
    _ source: String
) -> Range<String.Index>? {
    guard
        let rootData = source.data(using: .utf8),
        let root = try? JSONSerialization.jsonObject(
            with: rootData,
            options: []
        ) as? [String: Any],
        root["strings"] != nil
    else {
        return nil
    }

    var index = source.startIndex
    let end = source.endIndex

    while index < end {
        index = skipWhitespace(source, index, end)

        guard index < end else {
            return nil
        }

        guard
            let (key, keyRange) = readJSONString(
                source,
                from: index,
                to: end
            )
        else {
            return nil
        }

        index = keyRange.upperBound
        index = skipWhitespace(source, index, end)

        guard index < end, source[index] == ":" else {
            return nil
        }

        index = source.index(after: index)
        index = skipWhitespace(source, index, end)

        if key == "strings" {
            guard index < end, source[index] == "{" else {
                return nil
            }

            guard
                let objectEnd = findMatchingObject(
                    source,
                    from: index,
                    to: end
                )
            else {
                return nil
            }

            return index..<objectEnd
        }

        if index < end, source[index] == "{" {
            guard
                let objectEnd = findMatchingObject(
                    source,
                    from: index,
                    to: end
                )
            else {
                return nil
            }

            index = objectEnd
        } else if index < end, source[index] == "\"" {
            guard
                let (_, valueRange) = readJSONString(
                    source,
                    from: index,
                    to: end
                )
            else {
                return nil
            }

            index = valueRange.upperBound
        } else {
            while index < end, source[index] != "," {
                if source[index] == "}" {
                    break
                }

                index = source.index(after: index)
            }
        }

        index = skipWhitespace(source, index, end)

        if index < end, source[index] == "," {
            index = source.index(after: index)
        }
    }

    return nil
}

func findTopLevelEntries(
    _ source: String,
    stringsRange: Range<String.Index>
) -> [(String, Range<String.Index>)] {
    var results: [(String, Range<String.Index>)] = []

    var index = source.index(
        after: stringsRange.lowerBound
    )

    let end = stringsRange.upperBound

    while index < end {
        index = skipWhitespace(source, index, end)

        if index >= end || source[index] == "}" {
            break
        }

        guard
            let (key, keyRange) = readJSONString(
                source,
                from: index,
                to: end
            )
        else {
            break
        }

        index = keyRange.upperBound
        index = skipWhitespace(source, index, end)

        guard index < end, source[index] == ":" else {
            break
        }

        index = source.index(after: index)
        index = skipWhitespace(source, index, end)

        guard index < end, source[index] == "{" else {
            break
        }

        guard
            let objectEnd = findMatchingObject(
                source,
                from: index,
                to: end
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
        index = skipWhitespace(source, index, end)

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
        root["strings"] is [String: Any]
    else {
        throw ScriptError.invalidJSON
    }

    guard
        let stringsRange = findStringsObject(source)
    else {
        throw ScriptError.invalidStructure
    }

    let entries = findTopLevelEntries(
        source,
        stringsRange: stringsRange
    )

    var replacements: [Replacement] = []
    var checked = 0
    var converted = 0

    for (_, entryRange) in entries {
        checked += 1

        guard
            let localizationsRange = findObjectValue(
                source,
                key: "localizations",
                in: entryRange
            )
        else {
            continue
        }

        guard
            let zhHansRange = findObjectValue(
                source,
                key: "zh-Hans",
                in: localizationsRange
            )
        else {
            continue
        }

        guard
            let zhHantRange = findObjectValue(
                source,
                key: "zh-Hant",
                in: localizationsRange
            )
        else {
            continue
        }

        guard
            let zhHansUnitRange = findObjectValue(
                source,
                key: "stringUnit",
                in: zhHansRange
            )
        else {
            continue
        }

        guard
            let zhHantUnitRange = findObjectValue(
                source,
                key: "stringUnit",
                in: zhHantRange
            )
        else {
            continue
        }

        guard
            let zhHansValueRange = findObjectValue(
                source,
                key: "value",
                in: zhHansUnitRange
            ),
            let zhHantStateRange = findObjectValue(
                source,
                key: "state",
                in: zhHantUnitRange
            ),
            let zhHantValueRange = findObjectValue(
                source,
                key: "value",
                in: zhHantUnitRange
            )
        else {
            continue
        }

        guard
            let zhHansValue = decodeJSONString(
                String(source[zhHansValueRange])
            ),
            let zhHantState = decodeJSONString(
                String(source[zhHantStateRange])
            )
        else {
            continue
        }

        guard zhHantState == "needs_review" else {
            continue
        }

        let convertedValue = convertSimplifiedToTraditional(
            zhHansValue
        )

        guard
            let encodedState = jsonEncodedString("needs_review"),
            let encodedValue = jsonEncodedString(convertedValue)
        else {
            continue
        }

        replacements.append(
            Replacement(
                range: zhHantStateRange,
                value: encodedState
            )
        )

        replacements.append(
            Replacement(
                range: zhHantValueRange,
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
        throw ScriptError.invalidArguments
    }

    let path = CommandLine.arguments[1]

    guard
        let source = try? String(
            contentsOfFile: path,
            encoding: .utf8
        )
    else {
        throw ScriptError.fileReadFailed
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
        throw ScriptError.invalidJSON
    }

    let backupPath = path + ".backup"
    let temporaryPath = path + ".tmp"

    let fileManager = FileManager.default

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

        if
            !fileManager.fileExists(atPath: path),
            fileManager.fileExists(atPath: backupPath)
        {
            try? fileManager.copyItem(
                atPath: backupPath,
                toPath: path
            )
        }

        throw ScriptError.writeFailed
    }

    print("変換完了: \(converted) 件")
}

do {
    try main()
} catch {
    print("エラー: \(error)")
    exit(1)
}