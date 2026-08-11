#import "SPKOnboardingViewController.h"

@implementation SPKOnboardingViewController

- (NSArray<SPKPagedSheetPage *> *)buildPages {
    return @[
        [SPKPagedSheetPage pageWithTitle:@"Welcome to Sparkle"
                                    body:@"Everything you love about Instagram, with the controls it never gave you — built right in for a seamless experience."
                                    rows:nil],
        [SPKPagedSheetPage pageWithTitle:@"What you can do"
                                    body:@""
                                    rows:@[
                                        @{ @"icon": @"download", @"text": @"Download anything in high quality" },
                                        @{ @"icon": @"sparkle_gallery", @"text": @"Save media to a private Gallery" },
                                        @{ @"icon": @"profile_analyzer", @"text": @"Track followers, unfollowers, and profile changes" },
                                        @{ @"icon": @"channels", @"text": @"Keep messages even after they're deleted" },
                                        @{ @"icon": @"eye", @"text": @"Control read receipts and typing status" },
                                        @{ @"icon": @"ads", @"text": @"Get rid of ads and annoyances" },
                                        @{ @"icon": @"", @"text": @"... and so much more!" },
                                    ]],
        [SPKPagedSheetPage pageWithTitle:@"Find Sparkle anytime"
                                    body:@"You can open Sparkle settings anytime by:"
                                    rows:@[
                                        @{ @"icon": @"hamburger", @"text": @"Long pressing the menu on your profile" },
                                        @{ @"icon": @"home", @"text": @"Long pressing the Home tab" },
                                        @{ @"icon": @"action", @"text": @"Enabling the feed header button" },
                                    ]],
    ];
}

@end
