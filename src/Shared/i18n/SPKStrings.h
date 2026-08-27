#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Localized-string lookup for Sparkle.
///
/// Sparkle runs INSIDE Instagram's process, so `NSLocalizedString` (which reads
/// `[NSBundle mainBundle]` = Instagram) would never find our strings. Everything
/// here loads from Sparkle's OWN bundle instead.
///
/// Migration is `genstrings`-compatible: the `SPKLocalizedString(key, comment)`
/// function has the same shape as `NSLocalizedString`, so the base table is
/// generated with:  `genstrings -s SPKLocalizedString -o en.lproj **/*.{m,mm,x,xm}`
///
/// Keys are SEMANTIC (e.g. `FEED_LAYOUT_HIDE_STORIES_TRAY_TITLE`), matching the
/// a stable-key convention — stable when English copy is reworded, no paragraph-
/// length footer keys, no homograph collisions. `en.lproj` is the source of truth
/// for English and is kept complete by CI, so lookup falls back active → English;
/// the raw key is only ever returned if `en.lproj` itself is missing the key (a bug
/// the completeness linter catches).
FOUNDATION_EXPORT NSString *SPKLocalizedString(NSString *key, NSString *_Nullable comment);
FOUNDATION_EXPORT NSString *SPKLocalizedPlural(NSString *key, NSInteger count);

/// Shorthand for call sites. Use stable semantic keys, never English source text.
/// Example: `SPKL(@"COMMON_ACTION_CANCEL")`.
#define SPKL(key)            SPKLocalizedString((key), nil)
#define SPKLC(key, comment)  SPKLocalizedString((key), (comment))
#define SPKLP(key, count)    SPKLocalizedPlural((key), (count))

@interface SPKStrings : NSObject

/// Look up `key` in the active language, falling back active → English → key.
+ (NSString *)localized:(NSString *)key;

/// Look up `key` in one shipped language. Intended for migrations which need
/// to recognize previously persisted localized defaults.
+ (NSString *)localized:(NSString *)key forLanguage:(NSString *)language;

/// nil = follow the system/Instagram language. Otherwise a shipped code
/// (e.g. @"de", @"pt-BR"). Persisted in Sparkle's prefs; refreshes the cache.
@property (class, nonatomic, copy, nullable) NSString *languageOverride;

/// Language codes Sparkle actually ships an `<code>.lproj` for (always includes @"en").
+ (NSArray<NSString *> *)availableLanguages;

/// Stable, explicitly ordered list used by the language picker.
+ (NSArray<NSString *> *)supportedLanguages;

/// Resolve a requested language identifier to a shipped localization.
+ (nullable NSString *)matchAvailable:(NSString *)requested;

/// Effective shipped language after applying the explicit override, Instagram's
/// preferred localization, the system language, and the English fallback.
+ (NSString *)activeLanguage;

@end

NS_ASSUME_NONNULL_END
