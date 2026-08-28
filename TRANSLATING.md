# Translating Sparkle

Sparkle ships its own localization bundle because it runs inside Instagram and cannot use Instagram's main localization table. Corrections to an existing language and complete new translations are both welcome.

## Status of the shipped catalogs

English is the source language and the only one written by hand. All 16 other catalogs were produced in bulk by machine translation and none has been reviewed by a native speaker.

Treat them accordingly. Known failure modes that have already been found and fixed once include help text generated from the catalog key instead of the English value, one generic sentence reused across dozens of unrelated settings, and Instagram product terms left in English in some strings while being translated in others. Similar problems very likely remain in languages nobody has read yet.

Two consequences for contributors:

- A correction to an existing string does not need justification. If it reads wrong to you as a speaker of that language, it probably is wrong.
- When correcting a catalog, compare against the English value rather than against neighbouring translated strings. The neighbours are not a reliable style reference, and copying them has already propagated at least one error.

If you only want to report a correction, use **Help Translate Sparkle** at the bottom of the language sheet, opened with the Translate button in Sparkle Settings. Include the language, the current text, the corrected text, and where it appears. You do not need to edit any code.

## Add a new language

1. Choose the canonical Apple/BCP 47 localization identifier for the language, such as `nl`, `es-ES`, `pt-BR`, or `zh-Hans`.
2. Copy `resources/Sparkle.bundle/en.lproj` to `resources/Sparkle.bundle/<locale>.lproj`. Translate both `Localizable.strings` and `Localizable.stringsdict`.
3. Add the locale to:
   - `+[SPKStrings supportedLanguages]` in `src/Shared/i18n/SPKStrings.m`
   - the endonym map in `src/Settings/SPKLanguagePicker.m`
   - `LOCALES` in `tools/lint-i18n.py`
4. Add the language to the supported-language lists in `README.md` and `FEATURES.md`.
5. Credit the translator in `README.md` and the in-app About page if they want public attribution.

Every catalog is sorted by key, so a new entry belongs in its alphabetical position rather than at the end of the file. Keep the same key order in all shipped languages.

Translate values only. Do not rename catalog keys, preference keys, selectors, identifiers, asset names, URLs, or other runtime signals. Preserve placeholders exactly, including their types and positional markers (`%@`, `%ld`, `%lu`, `%1$@`, and similar). Keep escape sequences and line breaks intentional.

Use natural grammar and capitalization for the target language rather than copying English title case. The English value and semantic key provide context, but the translated wording should sound native. For plural entries, provide the plural categories required by the target language in `Localizable.stringsdict`; do not build plurals by appending a suffix.

## Validate a contribution

Run these checks before opening a pull request:

```sh
plutil -lint resources/Sparkle.bundle/<locale>.lproj/Localizable.strings
plutil -lint resources/Sparkle.bundle/<locale>.lproj/Localizable.stringsdict
python3 tools/lint-i18n.py
git diff --check
make -j4
```

The i18n linter checks catalog parity, unused keys, unsafe localization calls, raw user-interface strings, placeholder parity, and plural definitions. It must pass for all shipped languages.

When possible, also test the explicit language and **System Default** on a device after restarting Instagram. Check settings, alerts, Action Button menus, Gallery, downloads, notifications, dates, plural-heavy screens, and accessibility labels. Right-to-left languages should also be checked for layout and navigation direction.
