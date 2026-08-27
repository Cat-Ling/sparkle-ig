#import "SPKReelsSettingsProvider.h"
#import "SPKStrings.h"

#import "../../Features/Reels/HideReelsHeader.h"
#import "../../Shared/ActionButton/SPKActionButtonConfiguration.h"
#import "../SPKTopicSettingsSupport.h"

static NSString *const kSPKReelsActionButtonEnabledKey = @"reels_action_btn";

@implementation SPKReelsSettingsProvider

+ (SPKSetting *)rootSetting {
    return SPKTopicNavigationSetting(SPKL(@"REELS_TITLE"), @"reels", 24.0, @[
        SPKTopicSection(SPKL(@"FEED_ACTION_BUTTON_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_ACTION_BUTTON_REELS_ACTION_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"action")
                                defaultsKey:kSPKReelsActionButtonEnabledKey],
            SPKActionButtonDefaultActionNavigationSetting(SPKActionButtonSourceReels),
            SPKActionButtonConfigurationNavigationSetting(SPKActionButtonSourceReels, @"Reels", SPKActionButtonSupportedActionsForSource(SPKActionButtonSourceReels), SPKActionButtonDefaultSectionsForSource(SPKActionButtonSourceReels))
        ],
                        SPKL(@"FEED_ACTION_BUTTON_FOOTER")),
        SPKTopicSection(SPKL(@"GENERAL_BEHAVIOR_HEADER"), @[
            [SPKSetting menuCellWithTitle:SPKL(@"REELS_BEHAVIOR_TAP_CONTROLS_TITLE")
                                     icon:SPKSettingsIcon(@"play")
                                     menu:SPKReelsTapControlMenu()],
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_BEHAVIOR_SHOW_PROGRESS_SCRUBBER_TITLE")
                                       icon:SPKSettingsIcon(@"clock")
                                defaultsKey:@"reels_show_scrubber"],
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_BEHAVIOR_DISABLE_AUTO_UNMUTING_REELS_TITLE")
                                       icon:SPKSettingsIcon(@"volume_off")
                                defaultsKey:@"reels_disable_auto_unmute"
                            requiresRestart:YES],
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_BEHAVIOR_DISABLE_REELS_TAB_REFRESH_TITLE")
                                       icon:SPKSettingsIcon(@"arrow_cw")
                                defaultsKey:@"reels_disable_tab_refresh"]
        ],
                        SPKL(@"REELS_BEHAVIOR_FOOTER")),
        SPKTopicSection(SPKL(@"REELS_LIMITS_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_LIMITS_DISABLE_SCROLLING_REELS_TITLE")
                                       icon:SPKSettingsIcon(@"autoscroll")
                                defaultsKey:@"reels_disable_scrolling"
                            requiresRestart:YES],
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_LIMITS_PREVENT_DOOM_SCROLLING_TITLE")
                                       icon:SPKSettingsIcon(@"arrow_down")
                                defaultsKey:@"reels_prevent_doom_scroll"],
            [SPKSetting stepperCellWithTitle:SPKL(@"REELS_LIMITS_DOOM_SCROLLING_LIMIT_TITLE")
                                    subtitle:SPKL(@"REELS_LIMITS_ONLY_LOADS_SUBTITLE")
                                 defaultsKey:@"reels_doom_scroll_limit"
                                         min:1
                                         max:100
                                        step:1
                                       label:@"reels"
                               singularLabel:@"reel"]
        ],
                        SPKL(@"REELS_LIMITS_FOOTER")),
        SPKTopicSection(SPKL(@"FEED_LAYOUT_HEADER"), @[
            ({
                // The reels viewer keeps one navigation bar per session, so turning this off has
                // to reach the bar that is already built or it stays hidden until relaunch.
                SPKSetting *hideHeader = [SPKSetting switchCellWithTitle:SPKL(@"REELS_LAYOUT_HIDE_REELS_HEADER_TITLE")
                                                                    icon:SPKSettingsIcon(@"reels")
                                                             defaultsKey:@"reels_hide_header"];
                hideHeader.action = ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPKHideReelsHeaderDidChangeNotification
                                                                        object:nil];
                };
                hideHeader;
            }),
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_LAYOUT_HIDE_VIEWER_COMMENT_BAR_TITLE")
                                       icon:SPKSettingsIcon(@"comment")
                                defaultsKey:@"reels_hide_viewer_comment_bar"
                            requiresRestart:YES],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_LAYOUT_HIDE_REPOST_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"repost")
                                defaultsKey:@"reels_hide_repost_btn"
                            requiresRestart:YES]
        ],
                        SPKL(@"REELS_LAYOUT_FOOTER")),
        SPKTopicSection(SPKL(@"FEED_METRICS_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_METRICS_HIDE_LIKE_COUNT_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"reels_hide_like_count"],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_METRICS_HIDE_COMMENT_COUNT_TITLE")
                                       icon:SPKSettingsIcon(@"comment")
                                defaultsKey:@"reels_hide_comment_count"],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_METRICS_HIDE_REPOST_COUNT_TITLE")
                                       icon:SPKSettingsIcon(@"repost")
                                defaultsKey:@"reels_hide_repost_count"],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_METRICS_HIDE_RESHARE_COUNT_TITLE")
                                       icon:SPKSettingsIcon(@"messages")
                                defaultsKey:@"reels_hide_reshare_count"],
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_METRICS_HIDE_SAVE_COUNT_TITLE")
                                       icon:SPKSettingsIcon(@"save")
                                defaultsKey:@"reels_hide_save_count"]
        ],
                        nil),
        SPKTopicSection(SPKL(@"FEED_CONFIRMATION_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_CONFIRMATION_CONFIRM_LIKE_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"reels_confirm_like"],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_CONFIRMATION_CONFIRM_DOUBLE_TAP_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"reels_confirm_double_tap_like"],
            [SPKSetting switchCellWithTitle:SPKL(@"REELS_CONFIRMATION_CONFIRM_REEL_REFRESH_TITLE")
                                       icon:SPKSettingsIcon(@"arrow_cw")
                                defaultsKey:@"reels_confirm_refresh"],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_CONFIRMATION_CONFIRM_REPOST_TITLE")
                                       icon:SPKSettingsIcon(@"repost")
                                defaultsKey:@"reels_confirm_repost"]
        ],
                        SPKL(@"REELS_CONFIRMATION_FOOTER"))
    ]);
}

@end
