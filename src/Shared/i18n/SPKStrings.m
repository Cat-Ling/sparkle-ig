#import "SPKStrings.h"
#import "../../Utils.h"
#import "../SPKResourceBundle.h"

// Persisted directly because this preference is intentionally device-global,
// unlike Sparkle's account-scoped feature preferences.
static NSString *const kSPKLanguageOverrideKey = @"interface_language";
static NSString *const kSPKStringsTable = @"Localizable";

@implementation SPKStrings

+ (nullable NSBundle *)resourceBundle {
    return SPKResourceBundle();
}

#pragma mark - Language resolution

+ (NSArray<NSString *> *)availableLanguages {
    static NSArray<NSString *> *langs = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray<NSString *> *found = [NSMutableArray arrayWithObject:@"en"];
        NSBundle *bundle = [self resourceBundle];
        if (bundle) {
            NSArray<NSString *> *lprojs = [bundle pathsForResourcesOfType:@"lproj" inDirectory:nil];
            for (NSString *p in lprojs) {
                NSString *code = [[p lastPathComponent] stringByDeletingPathExtension];
                if (code.length > 0 && ![found containsObject:code] &&
                    ![code isEqualToString:@"Base"]) {
                    [found addObject:code];
                }
            }
        }
        langs = [found copy];
    });
    return langs;
}

+ (NSArray<NSString *> *)supportedLanguages {
    return @[ @"en", @"ar", @"de", @"el", @"es-ES", @"fr", @"hi", @"it", @"ja", @"ko", @"pt-BR", @"ro", @"ru", @"tr", @"uk", @"vi", @"zh-Hans" ];
}

/// Best shipped code for a requested locale id, e.g. "de-DE"→"de", "pt"→"pt-BR",
/// "zh-Hans-CN"→"zh-Hans". Returns nil if nothing matches.
+ (nullable NSString *)matchAvailable:(NSString *)requested {
    if (requested.length == 0) return nil;
    NSArray<NSString *> *available = [self availableLanguages];
    // 1. exact (case-insensitive)
    for (NSString *code in available) {
        if ([code caseInsensitiveCompare:requested] == NSOrderedSame) return code;
    }
    // 2. script-qualified match, e.g. requested "zh-Hans-CN" vs available "zh-Hans"
    for (NSString *code in available) {
        if ([[requested lowercaseString] hasPrefix:[[code lowercaseString] stringByAppendingString:@"-"]])
            return code;
    }
    // 3. base-language match, e.g. requested "de-DE" or "pt" vs available "de"/"pt-BR"
    NSString *base = [[requested componentsSeparatedByString:@"-"] firstObject].lowercaseString;
    for (NSString *code in available) {  // prefer an exact base like "de"
        if ([code.lowercaseString isEqualToString:base]) return code;
    }
    for (NSString *code in available) {  // then a regional variant like "pt-BR"
        if ([code.lowercaseString hasPrefix:[base stringByAppendingString:@"-"]]) return code;
    }
    return nil;
}

+ (NSString *)activeLanguage {
    NSString *override = [self languageOverride];
    if (override.length > 0) {
        NSString *m = [self matchAvailable:override];
        if (m) return m;
    }
    NSMutableOrderedSet<NSString *> *preferences = [NSMutableOrderedSet orderedSet];
    [preferences addObjectsFromArray:NSBundle.mainBundle.preferredLocalizations ?: @[]];
    [preferences addObjectsFromArray:NSLocale.preferredLanguages ?: @[]];
    for (NSString *pref in preferences) {
        NSString *m = [self matchAvailable:pref];
        if (m) return m;
    }
    return @"en";
}

#pragma mark - Override pref

+ (nullable NSString *)languageOverride {
    NSString *value = [NSUserDefaults.standardUserDefaults stringForKey:kSPKLanguageOverrideKey];
    return value.length > 0 && ![value isEqualToString:@"auto"] ? value : nil;
}

+ (void)setLanguageOverride:(nullable NSString *)langCode {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (langCode.length > 0) {
        [d setObject:langCode forKey:kSPKLanguageOverrideKey];
    } else {
        [d removeObjectForKey:kSPKLanguageOverrideKey];
    }
    [self flushCaches];
}

#pragma mark - Lookup

/// Cache of language-code → its .lproj sub-bundle. Reset when the override changes.
+ (NSMutableDictionary<NSString *, NSBundle *> *)lprojCache {
    static NSMutableDictionary *cache = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSMutableDictionary dictionary]; });
    return cache;
}

+ (void)flushCaches {
    @synchronized (self) { [[self lprojCache] removeAllObjects]; }
}

+ (nullable NSBundle *)lprojBundleForLanguage:(NSString *)lang {
    if (lang.length == 0) return nil;
    @synchronized (self) {
        NSBundle *cached = [self lprojCache][lang];
        if (cached) return cached;
        NSBundle *root = [self resourceBundle];
        NSString *path = [root pathForResource:lang ofType:@"lproj"];
        NSBundle *b = path ? [NSBundle bundleWithPath:path] : nil;
        if (b) [self lprojCache][lang] = b;
        return b;
    }
}

+ (NSString *)localized:(NSString *)key {
    if (key.length == 0) return key;

    // active language, then English fallback
    NSBundle *active = [self lprojBundleForLanguage:[self activeLanguage]];
    if (active) {
        NSString *v = [active localizedStringForKey:key value:@"MISS" table:kSPKStringsTable];
        if (![v isEqualToString:@"MISS"]) return v;
    }
    NSBundle *en = [self lprojBundleForLanguage:@"en"];
    if (en) {
        NSString *v = [en localizedStringForKey:key value:@"MISS" table:kSPKStringsTable];
        if (![v isEqualToString:@"MISS"]) return v;
    }
    // Catastrophic fallback. The linter guarantees English contains every key.
    return key;
}

@end

NSString *SPKLocalizedString(NSString *key, NSString *comment) {
    (void)comment; // consumed by `genstrings`, not at runtime
    return [SPKStrings localized:key];
}

NSString *SPKLocalizedPlural(NSString *key, NSInteger count) {
    NSString *format = [SPKStrings localized:key];
    return [NSString localizedStringWithFormat:format, count];
}
