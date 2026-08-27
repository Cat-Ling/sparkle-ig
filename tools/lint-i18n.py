#!/usr/bin/env python3
"""Strict source/catalog checks for Sparkle internationalization."""

from __future__ import annotations

import plistlib
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
BUNDLE = ROOT / "resources" / "Sparkle.bundle"
LOCALES = ("en", "ar", "de", "el", "es-ES", "fr", "hi", "it", "ja", "ko", "pt-BR", "ro", "ru", "tr", "uk", "vi", "zh-Hans")
SOURCE_SUFFIXES = {".m", ".mm", ".x", ".xm"}
STRING_RE = re.compile(r'^"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)";\s*$')
NORMAL_CALL_RE = re.compile(r'\bSPKL\(@"([A-Z][A-Z0-9_]*)"\)|\bSPKLC\(@"([A-Z][A-Z0-9_]*)"')
PLURAL_CALL_RE = re.compile(r'\bSPKLP\(@"([A-Z][A-Z0-9_]*)"')
PLACEHOLDER_RE = re.compile(r'%(?!%)(?:\d+\$)?[-+ #0\']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|j|z|t|L)?[@diuoxXfFeEgGaAcCsSp]')
BAD_KEY_RE = re.compile(r'^(?:FEAT_)|VIEWCONTROLLER|(?:^|_)SPK[A-Z0-9_]*CONTROLLER|_[0-9]+$|CONTEXT_[A-F0-9]+$')
UNSAFE_LINE_RE = re.compile(r'(?:isEqualToString|hasPrefix|hasSuffix|imageNamed|instagramIconNamed|menuIconNamed|menuSizedIcon|URLWithString|get(?:Bool|String|Double)Pref|forKey)\s*:\s*SPKL')
RAW_UI_RE = re.compile(r'(?:\.title|\.text|\.placeholder|\.accessibilityLabel|\.accessibilityHint|\.emptyTitle|\.emptySubtitle|\.infoText|\.successTitle|\.pickerTitle|\.masterTitle|\.finishTitleOverride|\btitle|\bmessage|\bsubtitle|\bheader|\bfooter)\s*[:=]\s*@"[^"\\]*[A-Za-z][^"\\]*"')
RAW_CHROME_RE = re.compile(
    r'SPKMediaChromeBottomBarButtonItem\(\s*@"[^"]+"\s*,\s*@"[^"\\]*[A-Za-z]'
    r'|SPKMediaChromeTopBarButtonItemWithTint\([^;]{0,500}?,\s*@"[^"\\]*[A-Za-z]"\s*\)'
    r'|SPKMediaChromeTopBarMenuButtonItem(?:WithTint)?\([^;]{0,500}?,\s*@"[^"\\]*[A-Za-z]"\s*\)',
    re.DOTALL,
)
# Dictionary literals feed menus, notification rows, progress stages and settings
# groups all over the tweak, so a raw value there is as user-visible as a property.
RAW_DICTIONARY_UI_RE = re.compile(
    r'@"(?:title|label|subtitle|stage|detail|caption|footer|header|message)"\s*:\s*@"[^"\\]*[A-Za-z][^"\\]*"'
)
RAW_ERROR_DESCRIPTION_RE = re.compile(r'NSLocalizedDescriptionKey\s*:\s*@"[^"\\]*[A-Za-z][^"\\]*"')
RAW_BULK_MENU_RE = re.compile(r'SPKBulkActionMenuElementForContext\([^;]{0,900}?,\s*@"[^"\\]*[A-Za-z]"\s*,\s*kSPK', re.DOTALL)
RAW_SELECTOR_UI_RE = re.compile(
    r'(?:WithTitle|\btitle|\bmessage|\bsubtitle|\bplaceholder|\bfooter|\bheader|accessibilityLabel|accessibilityHint)'
    r'\s*:\s*@"[^"\\]*[A-Za-z][^"\\]*"'
)
LOCALIZED_CALL_RE = re.compile(r'\bSPKL(?:C|P)?\(\s*@"[A-Z][A-Z0-9_]*"[^)]*\)')
RAW_LITERAL_RE = re.compile(r'@"((?:\\.|[^"\\])*)"')
C_UI_SINKS = {
    "SPKNotify": ((1, "raw user-facing notification title"), (2, "raw user-facing notification subtitle")),
    "SPKNotificationItem": ((1, "raw user-facing notification row title"),),
    "SPKAudioDMNotify": ((0, "raw user-facing notification title"), (1, "raw user-facing notification subtitle")),
    "SPKFFmpegError": ((0, "raw user-facing FFmpeg error message"),),
    "SPKDownloadError": ((1, "raw user-facing download error message"),),
    "SPKMediaSection": ((0, "raw user-facing media section title"),),
    "SPKTopicSection": ((0, "raw user-facing settings section title"), (2, "raw user-facing settings section footer")),
    "setProgress": ((1, "raw user-facing progress title"),),
    "report": ((1, "raw user-facing progress title"),),
    "fail": ((0, "raw user-facing failure title"), (1, "raw user-facing failure message")),
    "failImport": ((0, "raw user-facing import failure message"),),
}


def source_files() -> list[Path]:
    return sorted(p for p in SOURCE.rglob("*") if p.suffix.lower() in SOURCE_SUFFIXES)


def parse_strings(path: Path) -> tuple[dict[str, str], list[str]]:
    values: dict[str, str] = {}
    errors: list[str] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("/*"):
            continue
        match = STRING_RE.match(line)
        if not match:
            errors.append(f"{path.relative_to(ROOT)}:{line_number}: malformed .strings entry")
            continue
        key, value = match.groups()
        if key in values:
            errors.append(f"{path.relative_to(ROOT)}:{line_number}: duplicate key {key}")
        values[key] = value
    return values, errors


def placeholders(value: str) -> list[str]:
    return [re.sub(r'^%(?:\d+\$)?', "%", token) for token in PLACEHOLDER_RE.findall(value)]


def c_call_arguments(text: str, function_name: str):
    """Yield (offset, arguments) for balanced C-style calls to function_name."""
    call_re = re.compile(rf'\b{re.escape(function_name)}\s*\(')
    for match in call_re.finditer(text):
        arguments: list[str] = []
        argument_start = match.end()
        cursor = argument_start
        paren_depth = bracket_depth = brace_depth = 0
        quote: str | None = None
        escaped = False
        while cursor < len(text):
            character = text[cursor]
            following = text[cursor + 1] if cursor + 1 < len(text) else ""
            if quote:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == quote:
                    quote = None
                cursor += 1
                continue
            if character in ('"', "'"):
                quote = character
                cursor += 1
                continue
            if character == "/" and following == "/":
                newline = text.find("\n", cursor + 2)
                cursor = len(text) if newline < 0 else newline + 1
                continue
            if character == "/" and following == "*":
                comment_end = text.find("*/", cursor + 2)
                cursor = len(text) if comment_end < 0 else comment_end + 2
                continue
            if character == "(":
                paren_depth += 1
            elif character == ")":
                if paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                    arguments.append(text[argument_start:cursor].strip())
                    yield match.start(), arguments
                    break
                paren_depth -= 1
            elif character == "[":
                bracket_depth += 1
            elif character == "]":
                bracket_depth -= 1
            elif character == "{":
                brace_depth += 1
            elif character == "}":
                brace_depth -= 1
            elif character == "," and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                arguments.append(text[argument_start:cursor].strip())
                argument_start = cursor + 1
            cursor += 1


def contains_raw_user_text(argument: str) -> bool:
    without_localized_calls = LOCALIZED_CALL_RE.sub("", argument)
    for match in RAW_LITERAL_RE.finditer(without_localized_calls):
        value = match.group(1)
        if not re.search(r"[A-Za-z]", value):
            continue
        before = without_localized_calls[:match.start()].rstrip()
        after = without_localized_calls[match.end():].lstrip()
        if before.endswith("[") and after.startswith("]"):
            continue
        return True
    return False


def ignored_at_offset(text: str, offset: int) -> bool:
    line_start = text.rfind("\n", 0, offset) + 1
    line_end = text.find("\n", offset)
    if line_end < 0:
        line_end = len(text)
    return "SPK_I18N_IGNORE" in text[line_start:line_end]


def main() -> int:
    errors: list[str] = []
    normal_uses: Counter[str] = Counter()
    plural_uses: Counter[str] = Counter()

    for path in source_files():
        text = path.read_text(encoding="utf-8")
        for match in NORMAL_CALL_RE.finditer(text):
            normal_uses[match.group(1) or match.group(2)] += 1
        for match in PLURAL_CALL_RE.finditer(text):
            plural_uses[match.group(1)] += 1
        for pattern, description in (
            (RAW_CHROME_RE, "raw user-facing chrome label"),
            (RAW_BULK_MENU_RE, "raw user-facing bulk-menu title"),
            (RAW_SELECTOR_UI_RE, "raw user-facing selector argument"),
            (RAW_DICTIONARY_UI_RE, "raw user-facing dictionary value"),
            (RAW_ERROR_DESCRIPTION_RE, "raw user-facing error description"),
        ):
            for match in pattern.finditer(text):
                if "SPK_I18N_IGNORE" not in match.group(0) and not ignored_at_offset(text, match.start()):
                    line_number = text.count("\n", 0, match.start()) + 1
                    errors.append(f"{path.relative_to(ROOT)}:{line_number}: {description}")
        for function_name, positions in C_UI_SINKS.items():
            for offset, arguments in c_call_arguments(text, function_name):
                for position, description in positions:
                    if position < len(arguments) and contains_raw_user_text(arguments[position]):
                        line_number = text.count("\n", 0, offset) + 1
                        if not ignored_at_offset(text, offset):
                            errors.append(f"{path.relative_to(ROOT)}:{line_number}: {description}")
        for line_number, line in enumerate(text.splitlines(), 1):
            if UNSAFE_LINE_RE.search(line):
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: localized value used as an internal identifier or comparison")
            if RAW_UI_RE.search(line) and "SPK_I18N_IGNORE" not in line and '@"\\u' not in line:
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: raw user-facing UI string")

    english: dict[str, str] | None = None
    english_plurals: dict[str, object] | None = None
    for locale in LOCALES:
        strings_path = BUNDLE / f"{locale}.lproj" / "Localizable.strings"
        plural_path = BUNDLE / f"{locale}.lproj" / "Localizable.stringsdict"
        if not strings_path.exists() or not plural_path.exists():
            errors.append(f"{locale}: missing Localizable.strings or Localizable.stringsdict")
            continue
        values, parse_errors = parse_strings(strings_path)
        errors.extend(parse_errors)
        try:
            with plural_path.open("rb") as stream:
                plurals = plistlib.load(stream)
        except Exception as exc:
            errors.append(f"{plural_path.relative_to(ROOT)}: invalid plist: {exc}")
            continue

        if english is None:
            english = values
            english_plurals = plurals
        else:
            missing = sorted(set(english) - set(values))
            stray = sorted(set(values) - set(english))
            if missing or stray:
                errors.append(f"{locale}: catalog parity failure; missing={missing[:5]} stray={stray[:5]}")
            missing_plural = sorted(set(english_plurals or {}) - set(plurals))
            stray_plural = sorted(set(plurals) - set(english_plurals or {}))
            if missing_plural or stray_plural:
                errors.append(f"{locale}: plural parity failure; missing={missing_plural[:5]} stray={stray_plural[:5]}")

        for key, value in values.items():
            if BAD_KEY_RE.search(key):
                errors.append(f"{locale}: non-semantic key {key}")
            if english is not None and key in english and placeholders(value) != placeholders(english[key]):
                errors.append(f"{locale}: placeholder mismatch for {key}: {placeholders(value)} != {placeholders(english[key])}")
        for key, entry in plurals.items():
            rule = entry.get("count", {}) if isinstance(entry, dict) else {}
            if entry.get("NSStringLocalizedFormatKey") != "%#@count@" or rule.get("NSStringFormatSpecTypeKey") != "NSStringPluralRuleType":
                errors.append(f"{locale}: invalid plural definition for {key}")
            if "other" not in rule:
                errors.append(f"{locale}: plural {key} lacks an other form")
            for category, value in rule.items():
                if category.startswith("NSString"):
                    continue
                if len(placeholders(str(value))) != 1:
                    errors.append(f"{locale}: plural {key}/{category} must contain exactly one numeric placeholder")

    english = english or {}
    english_plurals = english_plurals or {}
    missing = sorted(set(normal_uses) - set(english))
    unused = sorted(set(english) - set(normal_uses))
    missing_plural = sorted(set(plural_uses) - set(english_plurals))
    unused_plural = sorted(set(english_plurals) - set(plural_uses))
    if missing:
        errors.append(f"source keys missing from catalogs: {missing[:20]}")
    if unused:
        errors.append(f"unused catalog keys: {unused[:20]} ({len(unused)} total)")
    if missing_plural:
        errors.append(f"source plural keys missing from stringsdict: {missing_plural}")
    if unused_plural:
        errors.append(f"unused plural keys: {unused_plural}")

    if errors:
        print("i18n lint failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"i18n lint passed: {len(english)} strings, {len(english_plurals)} plural keys, {len(LOCALES)} locales")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
