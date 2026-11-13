#!/usr/bin/env python3
"""Read-only checks for selected flat xcstrings entries and format arguments.

Variations/substitutions are reported for manual review; they are never flattened.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys

FORMAT = re.compile(
    r'%%|%(?:(?P<position>[1-9]\d*)\$)?'
    r'(?P<format>[-+#0]*\d*(?:\.\d+)?(?:hh|ll|[hlqztjL])?[@diuoxXfFeEgGaAcCsSp])'
)


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'Duplicate JSON key: {key}')
        result[key] = value
    return result


def placeholder_signature(value):
    signature = Counter()
    modes = set()
    sequential = 0
    for match in FORMAT.finditer(value):
        if match.group() == '%%':
            signature[(0, '%%')] += 1
            continue
        position = match.group('position')
        modes.add('position' if position else 'sequence')
        sequential += 1
        signature[(int(position) if position else sequential, match.group('format'))] += 1
    if len(modes) > 1:
        raise ValueError('Mixed positional and sequential format arguments')
    return signature


def validate(catalog, keys, source_language, languages):
    errors, manual = [], []
    strings = catalog.get('strings')
    if not isinstance(strings, dict):
        return ['Catalog strings must be an object'], []
    for key in keys:
        entry = strings.get(key)
        if not isinstance(entry, dict):
            errors.append(f'{key}: missing entry')
            continue
        if 'comment' in entry and not isinstance(entry['comment'], str):
            errors.append(f'{key}: comment must be a string directly under the key')
        localizations = entry.get('localizations', {})
        if not isinstance(localizations, dict):
            errors.append(f'{key}: localizations must be an object')
            continue
        signatures = {}
        for language in dict.fromkeys([source_language, *languages]):
            localization = localizations.get(language)
            if not isinstance(localization, dict):
                errors.append(f'{key}/{language}: missing localization')
                continue
            if 'comment' in localization:
                errors.append(f'{key}/{language}: move comment directly under the key')
            if 'variations' in localization or 'substitutions' in localization:
                manual.append(f'{key}/{language}: review variation/substitution structure and arguments')
                continue
            unit = localization.get('stringUnit')
            if not isinstance(unit, dict) or not isinstance(unit.get('value'), str) or not unit['value']:
                errors.append(f'{key}/{language}: missing nonempty stringUnit.value')
                continue
            if 'comment' in unit:
                errors.append(f'{key}/{language}: move stringUnit comment directly under the key')
            if unit.get('state') != 'translated':
                errors.append(f'{key}/{language}: state is not translated')
            if re.search(r'%(?:\d+\$)?[-+#0]*(?:\*|\d*\.\*)', unit['value']):
                manual.append(f'{key}/{language}: dynamic format width/precision needs manual review')
                continue
            try:
                signatures[language] = placeholder_signature(unit['value'])
            except ValueError as error:
                errors.append(f'{key}/{language}: {error}')
        if source_language in signatures:
            for language, signature in signatures.items():
                if signature != signatures[source_language]:
                    errors.append(f'{key}/{language}: format arguments differ from {source_language}')
    return errors, manual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', type=Path, required=True)
    parser.add_argument('--source-language', required=True)
    parser.add_argument('--keys', nargs='+', required=True)
    parser.add_argument('--languages', nargs='+', help='Defaults to locales already in the catalog')
    args = parser.parse_args()
    try:
        catalog = json.loads(args.catalog.read_text(), object_pairs_hook=unique_object)
        if not isinstance(catalog, dict):
            raise ValueError('Catalog root must be an object')
        strings = catalog.get('strings', {})
        if not isinstance(strings, dict):
            raise ValueError('Catalog strings must be an object')
        languages = args.languages or sorted({
            locale for entry in strings.values() if isinstance(entry, dict)
            for locale in entry.get('localizations', {})
        })
        errors, manual = validate(catalog, args.keys, args.source_language, languages)
    except (OSError, ValueError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1
    for error in errors:
        print('ERROR: ' + error, file=sys.stderr)
    for item in manual:
        print('MANUAL: ' + item, file=sys.stderr)
    if errors:
        return 1
    if manual:
        return 2
    print(f'Checked {len(args.keys)} keys; translations and format arguments agree')
    return 0


if __name__ == '__main__':
    sys.exit(main())
