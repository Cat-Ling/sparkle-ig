#import "SPKStrings.h"
#import "SPKOnboardingViewController.h"

@implementation SPKOnboardingViewController

- (NSArray<SPKPagedSheetPage *> *)buildPages {
    return @[
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_ONBOARDING_WELCOME_SPARKLE_TEXT")
                                    body:SPKL(@"SETTINGS_ONBOARDING_EVERYTHING_LOVE_ABOUT_INSTAGRAM_CONTROLS_NEVER_GAVE_BUILT_RIGHT_TEXT")
                                    rows:nil],
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_ONBOARDING_WHAT_CAN_TEXT")
                                    body:@""
                                    rows:@[
                                        @{ @"icon": @"download", @"text": SPKL(@"SETTINGS_ONBOARDING_DOWNLOAD_ANYTHING_HIGH_QUALITY_TEXT") },
                                        @{ @"icon": @"sparkle_gallery", @"text": SPKL(@"SETTINGS_ONBOARDING_SAVE_MEDIA_PRIVATE_GALLERY_TEXT") },
                                        @{ @"icon": @"profile_analyzer", @"text": SPKL(@"SETTINGS_ONBOARDING_TRACK_FOLLOWERS_UNFOLLOWERS_PROFILE_CHANGES_TEXT") },
                                        @{ @"icon": @"channels", @"text": SPKL(@"SETTINGS_ONBOARDING_KEEP_MESSAGES_EVEN_AFTER_THEY_RE_DELETED_MESSAGE") },
                                        @{ @"icon": @"eye", @"text": SPKL(@"SETTINGS_ONBOARDING_CONTROL_READ_RECEIPTS_TYPING_STATUS_TEXT") },
                                        @{ @"icon": @"ads", @"text": SPKL(@"SETTINGS_ONBOARDING_GET_RID_ADS_ANNOYANCES_TEXT") },
                                        @{ @"icon": @"", @"text": SPKL(@"SETTINGS_ONBOARDING_SO_MUCH_MORE_TEXT") },
                                    ]],
        [SPKPagedSheetPage pageWithTitle:SPKL(@"SETTINGS_ONBOARDING_FIND_SPARKLE_ANYTIME_TEXT")
                                    body:SPKL(@"SETTINGS_ONBOARDING_CAN_OPEN_SPARKLE_SETTINGS_ANYTIME_TEXT")
                                    rows:@[
                                        @{ @"icon": @"hamburger", @"text": SPKL(@"SETTINGS_ONBOARDING_LONG_PRESSING_MENU_PROFILE_TEXT") },
                                        @{ @"icon": @"home", @"text": SPKL(@"SETTINGS_ONBOARDING_LONG_PRESSING_HOME_TAB_TEXT") },
                                        @{ @"icon": @"action", @"text": SPKL(@"SETTINGS_ONBOARDING_ENABLING_FEED_HEADER_BUTTON_HEADER") },
                                    ]],
    ];
}

@end
