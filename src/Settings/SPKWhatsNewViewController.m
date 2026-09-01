#import "SPKStrings.h"
#import "SPKWhatsNewViewController.h"
#import "../Tweak.h"

@implementation SPKWhatsNewViewController

// Release notes are curated from the conventional-commit log for the release range
// (see whats-new.sh). Feature rows carry a per-surface IG catalog glyph; fix rows
// share the `subtract` bullet so they read as one clean list. Icon names are
// SPKAssetUtils override keys — never SF Symbols. Keep in sync with README/FEATURES.
//
// Every content row is replaced wholesale each release. The keys name the change
// rather than its English wording, and the previous release's keys are deleted from
// every catalog, so a stale translation can never be reused for a different row.
- (NSArray<SPKPagedSheetPage *> *)buildPages {
    return @[
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_FIXES_IMPROVEMENTS_TEXT")
                                    body:[NSString stringWithFormat:SPKL(@"SETTINGS_WHATS_NEW_WHAT_S_NEW_VALUE_FORMAT"), SPKVersionString]
                                    rows:@[
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_SIDELOAD_MEDIA_TOOLS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_BUNDLE_ID_DISPLAY_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_INSTAGRAM_445_COMPATIBILITY_TEXT") },
                                    ]],
    ];
}

- (NSString *)finishButtonTitle {
    return SPKL(@"SETTINGS_WHATS_NEW_DONE_TEXT");
}

- (BOOL)allowsInteractiveDismiss {
    return YES;
}

@end
