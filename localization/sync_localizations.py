import argparse
import csv
from io import StringIO
import json
import os
from pathlib import Path
from tempfile import NamedTemporaryFile

DIRECTORY = Path(__file__).resolve().parent
APP = DIRECTORY.parent / "iOS/TransitICScanner/TransitICScanner"
CATALOGS = (
    APP / "Localize/Localizable.xcstrings",
    APP / "CardDefine/cnTunion/cnTunion_cards.xcstrings",
)
LOCALES = ("en", "ja", "zh-Hans", "zh-Hant")
HEADER = ("key", "comment", *LOCALES)


def render_csv(strings):
    output = StringIO(newline="")
    writer = csv.writer(output, lineterminator="\n", quoting=csv.QUOTE_ALL)
    writer.writerow(HEADER)
    for key, entry in strings.items():
        localizations = entry.get("localizations", {})
        values = [
            localizations.get(locale, {}).get("stringUnit", {}).get("value", "")
            for locale in LOCALES
        ]
        writer.writerow([key, entry.get("comment", ""), *values])
    return output.getvalue()


def apply_csv(path, strings):
    changed_keys = 0
    seen = set()
    with path.open(encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file, strict=True)
        if tuple(next(reader, ())) != HEADER:
            raise ValueError(f"{path.name}: expected header {','.join(HEADER)}")
        for row in reader:
            location = f"{path.name}:{reader.line_num}"
            if len(row) != len(HEADER):
                raise ValueError(f"{location}: expected {len(HEADER)} columns")
            key, comment, *values = row
            if key in seen:
                raise ValueError(f"{location}: duplicate key {key!r}")
            seen.add(key)
            if not comment and not any(values):
                continue
            entry = strings.get(key)
            if entry is None:
                if not key.strip():
                    raise ValueError(f"{location}: new keys must contain non-whitespace characters")
                entry = strings[key] = {"extractionState": "manual"}
            if any(values) and entry.get("shouldTranslate") is False:
                raise ValueError(f"{location}: {key!r} is marked as non-translatable")
            changed = bool(comment) and entry.get("comment") != comment
            if changed:
                entry["comment"] = comment
            for locale, value in zip(LOCALES, values):
                if value == "":
                    continue
                localization = entry.setdefault("localizations", {}).setdefault(locale, {})
                if localization.get("stringUnit", {}).get("value") == value:
                    continue
                if "variations" in localization or "substitutions" in localization:
                    raise ValueError(f"{location}: edit structured translation {key!r} ({locale}) in Xcode")
                unit = localization.setdefault("stringUnit", {})
                unit.update(state="translated", value=value)
                changed = True
            changed_keys += changed
    return changed_keys


def write_text(path, content):
    with NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="", dir=path.parent, delete=False
    ) as file:
        temporary = Path(file.name)
        try:
            file.write(content)
            file.close()
            temporary.chmod(path.stat().st_mode & 0o777 if path.exists() else 0o644)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description="Sync translation CSVs with Xcode string catalogs.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--export", action="store_true", help="Regenerate both CSVs from the catalogs.")
    mode.add_argument("--dry-run", action="store_true", help="Validate both CSVs and report changes.")
    args = parser.parse_args()
    try:
        pending = []
        for path in CATALOGS:
            original = path.read_text(encoding="utf-8")
            data = json.loads(original)
            csv_path = DIRECTORY / path.with_suffix(".csv").name
            if args.export:
                pending.append((csv_path, render_csv(data["strings"]), len(data["strings"])))
                continue
            count = apply_csv(csv_path, data["strings"])
            content = json.dumps(data, ensure_ascii=False, indent=2, separators=(",", " : "))
            if original.endswith("\n"):
                content += "\n"
            pending.append((path, content, count))
        for path, content, count in pending:
            if args.export:
                write_text(path, content)
                action = "exported"
            elif args.dry_run:
                action = "would change"
            else:
                if count:
                    write_text(path, content)
                action = "updated"
            print(f"{path.name}: {count} keys {action}")
    except (OSError, ValueError, csv.Error) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
