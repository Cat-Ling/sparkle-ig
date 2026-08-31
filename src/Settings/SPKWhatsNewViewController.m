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
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_NEW_FEATURES_TEXT")
                                    body:[NSString stringWithFormat:SPKL(@"SETTINGS_WHATS_NEW_WHAT_S_NEW_VALUE_FORMAT"), SPKVersionString]
                                    rows:@[
                                        @{ @"icon": @"interface", @"text": SPKL(@"SETTINGS_WHATS_NEW_TAB_EDITOR_TEXT") },
                                        @{ @"icon": @"save", @"text": SPKL(@"SETTINGS_WHATS_NEW_SAVED_TAB_TEXT") },
                                        @{ @"icon": @"translate", @"text": SPKL(@"SETTINGS_WHATS_NEW_LANGUAGE_PACKS_TEXT") },
                                        @{ @"icon": @"text", @"text": SPKL(@"SETTINGS_WHATS_NEW_APP_FONT_TEXT") },
                                        @{ @"icon": @"activity", @"text": SPKL(@"SETTINGS_WHATS_NEW_ACTIVITY_NOTIFICATIONS_TEXT") },
                                        @{ @"icon": @"highlights", @"text": SPKL(@"SETTINGS_WHATS_NEW_RESURFACED_HIGHLIGHTS_TEXT") },
                                        @{ @"icon": @"mention", @"text": SPKL(@"SETTINGS_WHATS_NEW_STORY_MENTIONS_BADGE_TEXT") },
                                        @{ @"icon": @"volume_off", @"text": SPKL(@"SETTINGS_WHATS_NEW_STORY_AUDIO_TOGGLE_TEXT") },
                                    ]],
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_MORE_EXPLORE_TEXT")
                                    body:@""
                                    rows:@[
                                        @{ @"icon": @"filter", @"text": SPKL(@"SETTINGS_WHATS_NEW_STORY_VIEWER_FILTERS_TEXT") },
                                        @{ @"icon": @"gif", @"text": SPKL(@"SETTINGS_WHATS_NEW_GIF_TITLES_TEXT") },
                                        @{ @"icon": @"instants_burst", @"text": SPKL(@"SETTINGS_WHATS_NEW_INSTANT_VIDEO_CONFIRM_TEXT") },
                                        @{ @"icon": @"download", @"text": SPKL(@"SETTINGS_WHATS_NEW_INSTANT_AUTO_SAVE_TOGGLE_TEXT") },
                                        @{ @"icon": @"copy", @"text": SPKL(@"SETTINGS_WHATS_NEW_PREVIEW_TEXT_SELECTION_TEXT") },
                                        @{ @"icon": @"comment", @"text": SPKL(@"SETTINGS_WHATS_NEW_REELS_COMMENT_BAR_TEXT") },
                                        @{ @"icon": @"user_following", @"text": SPKL(@"SETTINGS_WHATS_NEW_NATIVE_FOLLOW_BUTTON_TEXT") },
                                        @{ @"text": SPKL(@"SETTINGS_WHATS_NEW_PLENTY_MORE_TEXT") },
                                    ]],
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_FIXES_IMPROVEMENTS_TEXT")
                                    body:@""
                                    rows:@[
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_STORY_SEEN_STATE_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_DUPLICATE_STORY_MENTIONS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_IG_MENUS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_MESSAGE_SUBMENUS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_REACTION_CRASH_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_PROFILE_REELS_SCROLL_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_HIDDEN_CHROME_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_GALLERY_BACKUP_IMPORT_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_UNFOLLOW_CONFIRM_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_SIDELOAD_NOTIFICATIONS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_INFO_SHEETS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_AUDIO_WAVEFORM_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIX_COPIED_LINK_TRACKING_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_OTHER_BUG_FIXES_UI_IMPROVEMENTS_TEXT") },
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
