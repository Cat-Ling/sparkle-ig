#import "SPKStrings.h"
#import "SPKWhatsNewViewController.h"
#import "../Tweak.h"

@implementation SPKWhatsNewViewController

// Release notes are curated from the conventional-commit log for the release range
// (see whats-new.sh). Feature rows carry a per-surface IG catalog glyph; fix rows
// share the `subtract` bullet so they read as one clean list. Icon names are
// SPKAssetUtils override keys — never SF Symbols. Keep in sync with README/FEATURES.
- (NSArray<SPKPagedSheetPage *> *)buildPages {
    return @[
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_NEW_FEATURES_TEXT")
                                    body:[NSString stringWithFormat:SPKL(@"SETTINGS_WHATS_NEW_WHAT_S_NEW_VALUE_FORMAT"), SPKVersionString]
                                    rows:@[
                                        @{ @"icon": @"sparkle_gallery", @"text": SPKL(@"SETTINGS_WHATS_NEW_IMPORT_MEDIA_INTO_GALLERY_FILES_REGRAM_VAULT_TEXT") },
                                        @{ @"icon": @"folder", @"text": SPKL(@"SETTINGS_WHATS_NEW_BROWSE_EVERY_GALLERY_FILE_ONCE_WITHOUT_ENTERING_FOLDERS_TEXT") },
                                        @{ @"icon": @"crop", @"text": SPKL(@"SETTINGS_WHATS_NEW_CROP_ROTATE_FLIP_VIDEO_FINER_TRIMMING_TEXT") },
                                        @{ @"icon": @"instants", @"text": SPKL(@"SETTINGS_WHATS_NEW_UPLOAD_ANY_MEDIA_INSTANT_TEXT") },
                                        @{ @"icon": @"instants_burst", @"text": SPKL(@"SETTINGS_WHATS_NEW_BROWSE_INSTANTS_SAVED_GROUPED_PERSON_TEXT") },
                                        @{ @"icon": @"download", @"text": SPKL(@"SETTINGS_WHATS_NEW_AUTO_SAVE_STORIES_VIEW_ONCE_MESSAGES_INSTANTS_VIEW_MESSAGE") },
                                        @{ @"icon": @"external_link", @"text": SPKL(@"SETTINGS_WHATS_NEW_PROFILES_POSTS_REELS_OPEN_REAL_INSTAGRAM_PAGES_TEXT") },
                                    ]],
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_MORE_EXPLORE_TEXT")
                                    body:@""
                                    rows:@[
                                        @{ @"icon": @"hd_check_filled", @"text": SPKL(@"SETTINGS_WHATS_NEW_REFINED_PHOTO_QUALITY_TIERS_4K_FETCHING_TEXT") },
                                        @{ @"icon": @"folder", @"text": SPKL(@"SETTINGS_WHATS_NEW_SAVE_DOWNLOADS_INTO_CUSTOM_PHOTOS_ALBUM_TEXT") },
                                        @{ @"icon": @"pinch", @"text": SPKL(@"SETTINGS_WHATS_NEW_PINCH_ZOOM_INTO_VIDEOS_FULL_SCREEN_PREVIEW_TEXT") },
                                        @{ @"icon": @"messages", @"text": SPKL(@"SETTINGS_WHATS_NEW_REFINED_MESSAGES_ONLY_MODE_MESSAGE") },
                                        @{ @"icon": @"story_preview", @"text": SPKL(@"SETTINGS_WHATS_NEW_SEE_MESSAGE_PREVIEWS_LONG_PRESSING_CHAT_MESSAGE") },
                                        @{ @"icon": @"sticker", @"text": SPKL(@"SETTINGS_WHATS_NEW_UPLOAD_VIDEOS_STORY_STICKERS_PHOTOS_SPARKLE_GALLERY_TEXT") },
                                        @{ @"icon": @"calendar", @"text": SPKL(@"SETTINGS_WHATS_NEW_SEE_POST_S_DATE_ACTION_BUTTON_MENU_ACTION") },
                                        @{ @"icon": @"profile_analyzer", @"text": SPKL(@"SETTINGS_WHATS_NEW_SWIPE_DELETE_SINGLE_CHANGE_PROFILE_ANALYZER_TEXT") },
                                        @{ @"icon": @"filter", @"text": SPKL(@"SETTINGS_WHATS_NEW_SORT_FILTER_SEARCH_GALLERY_PICKER_ACROSS_FOLDERS_TEXT") },
                                        @{ @"text": SPKL(@"SETTINGS_WHATS_NEW_PLENTY_MORE_TEXT") },
                                    ]],
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_WHATS_NEW_FIXES_IMPROVEMENTS_TEXT")
                                    body:@""
                                    rows:@[
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_FIXED_LONG_STANDING_FREEZE_MADE_APP_CRAWL_AFTER_FEW_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_NOTIFICATIONS_NOW_INSTANT_DON_T_DUPLICATE_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_MUCH_FASTER_GALLERY_INSTANT_OPENING_SMOOTHER_PICKER_FAR_LESS_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_STORY_PREVIEW_INBOX_REFRESH_WORK_AGAIN_LATEST_INSTAGRAM_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_INSTANTS_NOW_DOWNLOAD_AUTO_SAVE_FULL_RESOLUTION_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_POLL_VOTE_COUNTS_NOW_RESPECT_HIDE_UI_CAPTURE_TEXT") },
                                        @{ @"icon": @"subtract", @"text": SPKL(@"SETTINGS_WHATS_NEW_SAFE_MODE_NOW_EXPLAINS_ITSELF_OFFERS_TURN_ITSELF_OFF_TEXT") },
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
