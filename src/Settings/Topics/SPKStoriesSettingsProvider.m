#import "SPKStrings.h"
#import "SPKStoriesSettingsProvider.h"

#import "../../Shared/ActionButton/SPKActionButtonConfiguration.h"
#import "../../Shared/Stories/SPKStoryContext.h"
#import "../../Utils.h"
#import "../SPKSettingsViewController.h"
#import "../SPKTopicSettingsSupport.h"
static NSString *const kSPKStoriesActionButtonEnabledKey = @"stories_action_btn";

static NSDictionary *SPKStoriesSeenReceiptsSection(void);
static NSArray *SPKStoriesSettingsSections(void);

@interface SPKStoriesSettingsViewController : SPKSettingsViewController
@end

@implementation SPKStoriesSettingsViewController
- (instancetype)init {
    return [super initWithTitle:SPKL(@"STORIES_OTHER_STORIES_TITLE") sections:SPKStoriesSettingsSections() reduceMargin:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self replaceSections:SPKStoriesSettingsSections()];
}

- (void)switchChanged:(UISwitch *)sender {
    SPKSetting *row = [self settingForSender:sender];
    [super switchChanged:sender];
    if ([row.defaultsKey isEqualToString:@"stories_manual_seen"]) {
        [self replaceSections:SPKStoriesSettingsSections()];
    }
}
@end

static NSDictionary *SPKStoriesSeenReceiptsSection(void) {
    BOOL manualSeen = [SPKUtils getBoolPref:@"stories_manual_seen"];
    NSString *footer = manualSeen
                           ? SPKL(@"SETTINGS_STORIES_STORIES_NOT_MARKED_SEEN_AUTOMATICALLY_EXCEPT_USERS_EXCLUDED_USERS_TEXT")
                           : SPKL(@"SETTINGS_STORIES_STORIES_USE_INSTAGRAM_S_NORMAL_SEEN_BEHAVIOR_EXCEPT_USERS_TEXT");
    SPKSetting *manualSeenList = [SPKSetting navigationCellWithTitle:SPKStoryManualSeenListTitle(manualSeen)
                                                            subtitle:@""
                                                                icon:SPKSettingsIcon(@"users")
                                                      viewController:SPKStoryManualSeenListViewController()];
    manualSeenList.userInfo = @{@"accessoryText" : [NSString stringWithFormat:@"%lu", (unsigned long)SPKStoryManualSeenUserList(manualSeen).count]};

    // The auto-seen triggers only do anything while manual seen is on. Keep their
    // stored value but lock the cells when manual seen is off.
    SPKSetting *markSeenOnLike = [SPKSetting switchCellWithTitle:SPKL(@"STORIES_GENERAL_MARK_SEEN_LIKE_TITLE") icon:SPKSettingsIcon(@"heart") defaultsKey:@"stories_mark_seen_on_like"];
    SPKSetting *markSeenOnReply = [SPKSetting switchCellWithTitle:SPKL(@"STORIES_GENERAL_MARK_SEEN_REPLY_TITLE") icon:SPKSettingsIcon(@"reply") defaultsKey:@"stories_mark_seen_on_reply"];
    markSeenOnLike.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"stories_manual_seen"];
    };
    markSeenOnReply.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"stories_manual_seen"];
    };

    return SPKTopicSection(SPKL(@"STORIES_SEEN_RECEIPTS_HEADER"), @[
        [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_MESSAGING_MANUALLY_MARK_SEEN_TITLE")
                                   icon:SPKSettingsIcon(@"eye")
                            defaultsKey:@"stories_manual_seen"],
        markSeenOnLike,
        markSeenOnReply,
        manualSeenList,
    ],
                           footer);
}

static NSArray *SPKStoriesSettingsSections(void) {
    return @[
        SPKTopicSection(SPKL(@"FEED_ACTION_BUTTON_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_ACTION_BUTTON_STORIES_ACTION_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"action")
                                defaultsKey:kSPKStoriesActionButtonEnabledKey],
            SPKActionButtonDefaultActionNavigationSetting(SPKActionButtonSourceStories),
            SPKActionButtonConfigurationNavigationSetting(SPKActionButtonSourceStories, SPKL(@"STORIES_OTHER_STORIES_TITLE"), SPKActionButtonSupportedActionsForSource(SPKActionButtonSourceStories), SPKActionButtonDefaultSectionsForSource(SPKActionButtonSourceStories))
        ],
                        SPKL(@"SETTINGS_STORIES_ADD_ACTION_BUTTON_ABOVE_BOTTOM_STORY_BAR_N2_CHOOSE_ACTION")),
        SPKStoriesSeenReceiptsSection(), SPKTopicSection(SPKL(@"STORIES_STORY_NAVIGATION_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_VISUAL_MESSAGES_STOP_AUTO_ADVANCE_TITLE")
                                       icon:SPKSettingsIcon(@"autoscroll")
                                defaultsKey:@"stories_stop_auto_advance"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_STORY_NAVIGATION_ADVANCE_EYE_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"stories_advance_on_manual_seen"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_STORY_NAVIGATION_ADVANCE_STORY_LIKE_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"stories_advance_on_like_seen"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_STORY_NAVIGATION_ADVANCE_STORY_REPLY_TITLE")
                                       icon:SPKSettingsIcon(@"reply")
                                defaultsKey:@"stories_advance_on_reply_seen"],
        ],
                                                         SPKL(@"SETTINGS_STORIES_PREVENT_AUTOMATICALLY_MOVING_NEXT_STORY_N2_MOVE_NEXT_STORY_TEXT")),
        SPKTopicSection(SPKL(@"STORIES_CONFIRMATIONS_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_CONFIRMATION_CONFIRM_LIKE_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"stories_confirm_like"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_CONFIRMATIONS_CONFIRM_QUICK_REACTION_TITLE")
                                       icon:SPKSettingsIcon(@"reactions")
                                defaultsKey:@"stories_confirm_quick_reaction"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_CONFIRMATIONS_CONFIRM_STICKER_INTERACTION_TITLE")
                                       icon:SPKSettingsIcon(@"sticker")
                                defaultsKey:@"stories_confirm_sticker"]
        ],
                        SPKL(@"SETTINGS_STORIES_SHOW_CONFIRMATION_ALERT_TRY_LIKE_STORY_N2_SHOW_CONFIRMATION_TEXT")),
        
        SPKTopicSection(SPKL(@"STORIES_INSTAGRAM_PLUS_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_INSTAGRAM_PLUS_UNLOCK_STORY_PREVIEW_TITLE")
                                       icon:SPKSettingsIcon(@"story_preview")
                                defaultsKey:@"stories_unlock_preview"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_INSTAGRAM_PLUS_HIDE_INSTAGRAM_PLUS_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"aura")
                                defaultsKey:@"stories_hide_ig_plus_button"]
        ],
                        SPKL(@"SETTINGS_STORIES_UNLOCK_STORY_PREVIEW_STORY_LONG_PRESS_MENU_SHOWS_ACTUAL_TEXT")),

        SPKTopicSection(SPKL(@"INSTANTS_CREATION_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_CREATION_ALLOW_VIDEOS_PHOTO_STICKER_TITLE")
                                       icon:SPKSettingsIcon(@"video")
                                defaultsKey:@"stories_allow_video_sticker"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_CREATION_SHOW_GALLERY_UPLOAD_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"sparkle_gallery")
                                defaultsKey:@"stories_gallery_upload_sticker"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_CREATION_USE_DETAILED_COLOR_PICKER_TITLE")
                                       icon:SPKSettingsIcon(@"eyedropper")
                                defaultsKey:@"stories_detailed_color_picker"]
        ],
                        SPKL(@"SETTINGS_STORIES_ALLOW_SELECTING_VIDEOS_LIBRARY_STORY_PHOTO_STICKER_N2_USE_TEXT")),

        SPKTopicSection(SPKL(@"STORIES_OTHER_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_OTHER_SEARCH_VIEWER_LIST_TITLE")
                                       icon:SPKSettingsIcon(@"search")
                                defaultsKey:@"stories_search_viewer_list"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_OTHER_HIDE_JOIN_TRENDING_TITLE")
                                       icon:SPKSettingsIcon(@"arrow_up_right")
                                defaultsKey:@"stories_hide_join_trending"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_OTHER_HIDE_RECENT_HIGHLIGHTS_TITLE")
                                       icon:SPKSettingsIcon(@"highlights")
                                defaultsKey:@"stories_hide_recent_highlights"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_OTHER_SHOW_STORY_MENTIONS_TITLE")
                                       icon:SPKSettingsIcon(@"mention")
                                defaultsKey:@"stories_mentions_btn"],
            [SPKSetting switchCellWithTitle:SPKL(@"STORIES_OTHER_SHOW_POLL_VOTE_COUNTS_TITLE")
                                       icon:SPKSettingsIcon(@"poll")
                                defaultsKey:@"stories_poll_vote_counts"],
        ],
                        SPKL(@"SETTINGS_STORIES_ADD_SEARCH_BUTTON_STORY_S_VIEWER_LIST_SEARCH_NAME_TEXT"))
    ];
}

@implementation SPKStoriesSettingsProvider

+ (SPKSetting *)rootSetting {
    SPKSetting *setting = [SPKSetting navigationCellWithTitle:SPKL(@"STORIES_OTHER_STORIES_TITLE")
                                                     subtitle:@""
                                                         icon:SPKSettingsIcon(@"story")
                                               viewController:[[SPKStoriesSettingsViewController alloc] init]];
    setting.searchSectionsProvider = ^NSArray * {
        return SPKStoriesSettingsSections();
    };
    return SPKSettingApplyIconTint(setting, [SPKUtils SPKColor_InstagramPrimaryText]);
}

@end
