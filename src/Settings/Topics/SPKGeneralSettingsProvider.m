#import "SPKStrings.h"
#import "SPKGeneralSettingsProvider.h"

#import "../../AssetUtils.h"
#import "../../Shared/Account/SPKAccountManager.h"
#import "../../Shared/ActionButton/ActionButtonCore.h"
#import "../../Shared/UI/SPKIGAlertPresenter.h"
#import "../../Utils.h"
#import "../SPKActionSectionIconPickerViewController.h"
#import "../SPKAppIconCatalog.h"
#import "../SPKAppIconPickerViewController.h"
#import "../SPKTopicSettingsSupport.h"

@implementation SPKGeneralSettingsProvider

+ (SPKSetting *)defaultMenuIconSetting {
    SPKActionSectionIconPickerViewController *controller =
        [[SPKActionSectionIconPickerViewController alloc] initWithSelectedIconName:SPKActionButtonOpenMenuIconName()
                                                                          onSelect:^(NSString *iconName) {
                                                                              SPKPreferenceSetObject(iconName.length > 0 ? iconName : @"action", @"general_action_btn_default_menu_icon");
                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:SPKActionButtonConfigurationDidChangeNotification object:nil];
                                                                          }];
    controller.title = SPKL(@"GENERAL_GENERAL_OPEN_MENU_ICON_TITLE");

    SPKSetting *setting = [SPKSetting navigationCellWithTitle:SPKL(@"GENERAL_GENERAL_OPEN_MENU_ICON_TITLE")
                                                     subtitle:@""
                                                         icon:SPKSettingsIcon(@"action")
                                               viewController:controller];
    // The row's icon mirrors the chosen glyph, so the (cryptic) catalog name is
    // redundant as accessory text — let the adaptive icon convey the selection.
    setting.iconProvider = ^UIImage * {
        return SPKSettingsIcon(SPKActionButtonOpenMenuIconName());
    };
    return setting;
}

+ (SPKSetting *)appIconSetting {
    SPKAppIconPickerViewController *controller = [[SPKAppIconPickerViewController alloc] initWithSelectedIdentifier:[SPKAppIconCatalog currentAppIconIdentifier]
                                                                                                           onSelect:nil];
    SPKSetting *setting = [SPKSetting navigationCellWithTitle:SPKL(@"GENERAL_GENERAL_APP_ICON_TITLE")
                                                     subtitle:@""
                                                         icon:SPKSettingsIcon(@"app")
                                               viewController:controller];
    setting.accessoryTextProvider = ^NSString * {
        SPKAppIconItem *currentIcon = [SPKAppIconCatalog currentAppIcon];
        return currentIcon.displayName.length > 0 ? currentIcon.displayName : @"Default";
    };
    return setting;
}

+ (SPKSetting *)perAccountSetting {
    SPKSetting *setting = [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_GENERAL_PER_ACCOUNT_SETTINGS_TITLE")
                                                     icon:SPKSettingsIcon(@"user_circle")
                                              defaultsKey:kSPKPrefPerAccountSettings];
    // Changes which key namespace every feature reads, and most enabled-state is
    // captured at hook install, so a restart applies it cleanly.
    setting.requiresRestart = YES;
    return setting;
}

+ (SPKSetting *)perAccountInfoSetting {
    return [SPKSetting buttonCellWithTitle:SPKL(@"ALERT_ACTION_HOW_WORKS")
                                  subtitle:nil
                                      icon:SPKSettingsIcon(@"info")
                                    action:^{
                                        NSString *message =
                                            SPKL(@"SETTINGS_GENERAL_EACH_LOGGED_ACCOUNT_GETS_OWN_SPARKLE_SETTINGS_NEWLY_SEEN_TEXT");

                                        [SPKIGAlertPresenter presentAlertFromViewController:topMostController()
                                                                                      title:SPKL(@"GENERAL_GENERAL_PER_ACCOUNT_SETTINGS_TITLE")
                                                                                    message:message
                                                                                    actions:@[ [SPKIGAlertAction actionWithTitle:SPKL(@"ALERT_ACTION_OK") style:SPKIGAlertActionStyleCancel handler:nil] ]];
                                    }];
}

+ (SPKSetting *)rootSetting {
    SPKSetting *clearCacheSetting = [SPKSetting buttonCellWithTitle:SPKL(@"GENERAL_GENERAL_CLEAR_CACHE_TITLE")
                                                           subtitle:@""
                                                               icon:SPKSettingsIcon(@"trash")
                                                             action:^(void) {
                                                                 unsigned long long freedBytes = [SPKUtils cleanCacheReturningFreedBytes];
                                                                 NSString *subtitle = freedBytes > 0
                                                                                          ? [NSString stringWithFormat:@"Freed %@", [NSByteCountFormatter stringFromByteCount:(long long)freedBytes countStyle:NSByteCountFormatterCountStyleFile]]
                                                                                          : SPKL(@"SETTINGS_GENERAL_CACHE_ALREADY_EMPTY_TEXT");
                                                                 SPKNotify(kSPKNotificationSettingsClearCache, SPKL(@"SETTINGS_GENERAL_CACHE_CLEARED_TEXT"), subtitle, @"circle_check_filled", SPKNotificationToneForIconResource(@"circle_check_filled"));
                                                             }];
    clearCacheSetting.tintColor = [SPKUtils SPKColor_InstagramDestructive];
    clearCacheSetting.iconTintColor = [SPKUtils SPKColor_InstagramDestructive];
    clearCacheSetting.accessoryTextProvider = ^NSString * {
        return [SPKUtils formattedCacheSize];
    };

    return SPKTopicNavigationSetting(SPKL(@"GENERAL_TITLE"), @"settings", 24.0, @[
        SPKTopicSection(SPKL(@"GENERAL_ACCOUNTS_HEADER"), @[
            [self perAccountSetting],
            [self perAccountInfoSetting]
        ],
                        SPKL(@"GENERAL_ACCOUNTS_FOOTER")),
        SPKTopicSection(SPKL(@"GENERAL_BEHAVIOR_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"ALERT_ACTION_COPY_TEXT")
                                       icon:SPKSettingsIcon(@"text")
                                defaultsKey:@"general_copy_text"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_BEHAVIOR_HIDE_RECENT_SEARCHES_TITLE")
                                       icon:SPKSettingsIcon(@"search")
                                defaultsKey:@"general_hide_recent_searches"
                            requiresRestart:YES],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_BEHAVIOR_COPY_LINKS_WITHOUT_TRACKING_TITLE")
                                       icon:SPKSettingsIcon(@"user_unfollow")
                                defaultsKey:@"general_strip_share_link_tracking"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_BEHAVIOR_HOLD_SEND_COPY_LINK_TITLE")
                                       icon:SPKSettingsIcon(@"link")
                                defaultsKey:@"general_hold_send_copy_link"],
        ],
                        SPKL(@"SETTINGS_GENERAL_LONG_PRESS_TEXT_FIELDS_ACROSS_APP_COPY_N2_HIDE_TEXT")),
        SPKTopicSection(SPKL(@"GENERAL_SHARING_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SHARING_HIDE_CREATE_GROUP_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"group")
                                defaultsKey:@"general_hide_create_group"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SHARING_CONFIRM_CREATE_GROUP_TITLE")
                                       icon:SPKSettingsIcon(@"group")
                                defaultsKey:@"general_confirm_create_group"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SHARING_CONFIRM_SENDING_POST_TITLE")
                                       icon:SPKSettingsIcon(@"messages")
                                defaultsKey:@"general_confirm_send"],
        ],
                        SPKL(@"SETTINGS_GENERAL_HIDE_CREATE_GROUP_BUTTON_INSTAGRAM_SEND_SHARE_SHEET_N2_TEXT")),
        SPKTopicSection(SPKL(@"GENERAL_RECOMMENDATIONS_HEADER"), @[
            [SPKSetting navigationCellWithTitle:SPKL(@"GENERAL_ADS_HEADER")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"ads")
                                    navSections:@[
                                        SPKTopicSection(SPKL(@"GENERAL_ADS_HEADER"), @[
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_FEED_ADS_TITLE")
                                                                defaultsKey:@"general_hide_ads_feed"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_STORY_ADS_TITLE")
                                                                defaultsKey:@"general_hide_ads_stories"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_REELS_ADS_TITLE")
                                                                defaultsKey:@"general_hide_ads_reels"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_EXPLORE_ADS_TITLE")
                                                                defaultsKey:@"general_hide_ads_explore"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_REELS_SHOPPING_CTA_TITLE")
                                                                defaultsKey:@"general_hide_reels_shopping_cta"]
                                        ],
                                                        nil)
                                    ]],
            [SPKSetting navigationCellWithTitle:SPKL(@"GENERAL_ADS_META_AI_TITLE")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"meta_ai")
                                    navSections:@[
                                        SPKTopicSection(@"", @[
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_DIRECT_TITLE")
                                                                defaultsKey:@"general_hide_meta_ai_msgs"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_EXPLORE_SEARCH_TITLE")
                                                                defaultsKey:@"general_hide_meta_ai_explore"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_COMMENTS_TITLE")
                                                                defaultsKey:@"general_hide_meta_ai_comments"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_CREATION_TOOLS_TITLE")
                                                                defaultsKey:@"general_hide_meta_ai_creation"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_ADS_HIDE_GLOBAL_AI_CHROME_TITLE")
                                                                defaultsKey:@"general_hide_meta_ai_global"]
                                        ],
                                                        SPKL(@"GENERAL_RECOMMENDATIONS_FOOTER"))
                                    ]],
            [SPKSetting navigationCellWithTitle:SPKL(@"GENERAL_ADS_SUGGESTED_USERS_TITLE")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"users")
                                    navSections:@[
                                        SPKTopicSection(SPKL(@"GENERAL_ADS_SUGGESTED_USERS_TITLE"), @[
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_FEED_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_feed"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_REELS_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_reels"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_DIRECT_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_msgs"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_SEARCH_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_search"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_PROFILE_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_profile"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_ACTIVITY_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_activity"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_FOLLOW_LIST_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_follow_lists"],
                                            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_SUGGESTED_USERS_HIDE_SUBSCRIPTION_SUGGESTIONS_TITLE")
                                                                defaultsKey:@"general_hide_suggested_users_subscriptions"]
                                        ],
                                                        nil)
                                    ]]
        ],
                        SPKL(@"GENERAL_SUGGESTED_USERS_FOOTER")),
        SPKTopicSection(SPKL(@"GENERAL_MEDIA_PREVIEW_MENU_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_MEDIA_PREVIEW_MENU_SHOW_MEDIA_INFO_TITLE")
                                       icon:SPKSettingsIcon(@"info")
                                defaultsKey:@"general_preview_show_metadata"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_MEDIA_PREVIEW_MENU_SHOW_DATE_MENU_TITLE")
                                       icon:SPKSettingsIcon(@"calendar")
                                defaultsKey:@"general_action_btn_show_date"],
        ],
                        SPKL(@"SETTINGS_GENERAL_OVERLAY_AUTHOR_POST_DATE_EXPANDED_PHOTO_PREVIEW_N2_SHOW_TEXT")),
        SPKTopicSection(SPKL(@"GENERAL_COMMENTS_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_COPY_COMMENT_TITLE")
                                       icon:SPKSettingsIcon(@"copy")
                                defaultsKey:@"general_comments_copy_text"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_COMMENT_MEDIA_ACTIONS_TITLE")
                                       icon:SPKSettingsIcon(@"action")
                                defaultsKey:@"general_comments_media_actions"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_SHOW_GIF_TITLE_TITLE")
                                       icon:SPKSettingsIcon(@"info")
                                defaultsKey:@"general_comments_gif_title"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_UPLOAD_PHOTO_GALLERY_TITLE")
                                       icon:SPKSettingsIcon(@"photo")
                                defaultsKey:@"general_comments_gallery_upload"]
        ],
                        SPKL(@"SETTINGS_GENERAL_ADDS_COPY_ACTION_COMMENT_MENUS_N2_ADDS_PHOTOS_SHARE_ACTION")),
        SPKTopicSection(@"", @[
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_SWIPE_CLOSE_COMMENTS_TITLE")
                                       icon:SPKSettingsIcon(@"left_right")
                                defaultsKey:@"general_comments_swipe_close"],
            SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:SPKL(@"GENERAL_COMMENTS_SWIPE_DIRECTION_TITLE") icon:SPKSettingsIcon(@"left_right") menu:SPKSwipeCloseCommentsDirectionMenu()], SPKSettingsIcon(@"left_right")),
        ],
                        SPKL(@"GENERAL_X_FOOTER")),
        SPKTopicSection(@"", @[
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_CONFIRM_COMMENT_LIKE_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"general_comments_confirm_like"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_HIDE_COMMENT_SHOPPING_TITLE")
                                       icon:SPKSettingsIcon(@"shopping_bag")
                                defaultsKey:@"general_comments_hide_shopping"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_HIDE_GIFTS_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"gift")
                                defaultsKey:@"general_comments_hide_gifts_button"],
        ],
                        SPKL(@"SETTINGS_GENERAL_SHOWS_CONFIRMATION_ALERT_BEFORE_LIKING_COMMENT_N2_REMOVES_COMMERCE_TEXT")),
        SPKTopicSection(SPKL(@"ALERT_ACTION_STORAGE"), @[
            clearCacheSetting,
            [SPKSetting menuCellWithTitle:SPKL(@"GENERAL_STORAGE_AUTO_CLEAR_CACHE_TITLE")
                                     icon:SPKSettingsIcon(@"clock")
                                     menu:SPKCacheAutoClearMenu()]
        ],
                        SPKL(@"GENERAL_STORAGE_FOOTER")),
        SPKTopicSection(SPKL(@"GENERAL_APP_HEADER"), @[
            [self appIconSetting],
            [self defaultMenuIconSetting],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_APP_DISABLE_APP_HAPTICS_TITLE")
                                       icon:SPKSettingsIcon(@"haptics")
                                defaultsKey:@"general_disable_haptics"]
        ],
                        SPKL(@"GENERAL_APP_FOOTER")),
    ]);
}

@end
