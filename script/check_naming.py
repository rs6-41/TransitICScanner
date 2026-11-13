#!/usr/bin/env python3
"""Check ASCII Swift declaration names against the shared AGENTS.md rules.

This supplements swift-format; it is not a Swift parser or a semantic linter.
Only tracked/non-ignored source files are checked, including newly renamed files.
"""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CARD_DEFINITIONS = 'iOS/TransitICScanner/TransitICScanner/CardDefine/'
LEGACY_NAMES = {
    CARD_DEFINITIONS + 'jpIC/jpIC.swift': {'jpIC_SAPICA', 'jpIC_IruCa', 'jpIC_icsca'},
    CARD_DEFINITIONS + 'twEasyCard_old/twEasyCard_old.swift': {'twEasyCard_old'},
}
TYPE_KINDS = {'struct', 'class', 'enum', 'protocol', 'typealias'}
DECLARATION = re.compile(r'\b(struct|class(?!\s+(?:func|var|let)\b)|enum|protocol|typealias|func|let|var)\s+([A-Za-z_]\w*)')


def mask_comments_and_strings(source):
    """Mask strings/comments, preserving line numbers; support nested comments."""
    pattern = re.compile(r'//[^\n]*|/\*|#+"{1,3}|"""|"')
    result = list(source)
    offset = 0
    while match := pattern.search(source, offset):
        start = match.start()
        opening = match.group()
        end = match.end()
        if opening == '/*':
            depth = 1
            while depth and end < len(source):
                marker = re.search(r'/\*|\*/', source[end:])
                if marker is None:
                    end = len(source)
                    break
                depth += 1 if marker.group() == '/*' else -1
                end += marker.end()
        elif not opening.startswith('//'):
            hashes = len(opening) - len(opening.lstrip('#'))
            quotes = opening[hashes:]
            closing = quotes + '#' * hashes
            while end < len(source):
                if source.startswith('\\' + '#' * hashes, end):
                    end += 2 + hashes
                elif source.startswith(closing, end):
                    end += len(closing)
                    break
                else:
                    end += 1
        for index in range(start, min(end, len(source))):
            if source[index] != '\n':
                result[index] = ' '
        offset = end
    return ''.join(result)


def main():
    paths = subprocess.check_output(
        ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--', '*.swift'],
        cwd=ROOT,
    ).decode().split('\0')
    errors = []
    count = 0
    for relative_path in sorted(set(filter(None, paths))):
        path = ROOT / relative_path
        if not path.is_file():
            continue
        count += 1
        source = mask_comments_and_strings(path.read_text())
        for match in DECLARATION.finditer(source):
            kind, name = match.groups()
            if name == '_' or name in LEGACY_NAMES.get(relative_path, set()):
                continue
            expected = r'[A-Z][A-Za-z0-9]*' if kind in TYPE_KINDS else r'[a-z][A-Za-z0-9]*'
            if not re.fullmatch(expected, name):
                line = source.count('\n', 0, match.start()) + 1
                errors.append(f'{relative_path}:{line}: {kind} {name}: violates AGENTS.md')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'Swift declaration naming checks passed ({count} files)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
