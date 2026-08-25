#import "SPKStrings.h"
#import "SPKMessagesSettingsProvider.h"

#import "../../Features/Messages/AccurateActiveStatus.h"
#import "../../Features/Messages/DeletedMessagesLog/SPKDeletedMessagesViewController.h"
#import "../../Shared/ActionButton/SPKActionButtonConfiguration.h"
#import "../../Shared/Messages/SPKDirectSeenContext.h"
#import "../../Shared/Messages/SPKPresenceTracking.h"
#import "../../Utils.h"
#import "../SPKSettingsViewController.h"
#import "../SPKTopicSettingsSupport.h"

static NSString *const kSPKMessagesActionButtonEnabledKey = @"msgs_action_btn";
static NSString *const kSPKMessagesActionButtonChatMediaKey = @"msgs_action_btn_chat_media";
static NSString *const kSPKMessagesAudioCallConfirmKey = @"msgs_confirm_audio_call";
static NSString *const kSPKMessagesVideoCallConfirmKey = @"msgs_confirm_video_call";

static NSArray *SPKMessagesSettingsSections(void);
static NSArray *SPKActivityNotificationsSettingsSections(void);

// A switch cell that stays visible but is disabled while the "Audio Downloads"
// master toggle is off (keeping its stored value).
static SPKSetting *SPKAudioGatedSwitch(NSString *title, UIImage *icon, NSString *defaultsKey) {
    SPKSetting *setting = [SPKSetting switchCellWithTitle:title icon:icon defaultsKey:defaultsKey];
    setting.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"downloads_audio_enabled"];
    };
    return setting;
}

@interface SPKActivityNotificationsSettingsViewController : SPKSettingsViewController
@end

@implementation SPKActivityNotificationsSettingsViewController
- (instancetype)init {
    return [super initWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFICATIONS_TITLE") sections:SPKActivityNotificationsSettingsSections() reduceMargin:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self replaceSections:SPKActivityNotificationsSettingsSections()];
}

- (void)switchChanged:(UISwitch *)sender {
    SPKSetting *row = [self settingForSender:sender];
    [super switchChanged:sender];
    if ([row.defaultsKey isEqualToString:@"msgs_presence_notifications"]) {
        if (SPKPresenceNotificationsEnabled())
            SPKPresenceRequestNotificationAuthorization();
        [self replaceSections:SPKActivityNotificationsSettingsSections()];
    }
    if ([row.defaultsKey isEqualToString:@"msgs_presence_accurate_status"])
        SPKRefreshAccurateActiveStatusScheduler();
}

- (void)stepperChanged:(UIStepper *)sender {
    SPKSetting *row = [self settingForSender:sender];
    [super stepperChanged:sender];
    if ([row.defaultsKey isEqualToString:@"msgs_presence_refresh_interval"])
        SPKRefreshAccurateActiveStatusScheduler();
}
@end

static NSArray *SPKActivityNotificationsSettingsSections(void) {
    BOOL (^masterEnabled)(void) = ^BOOL {
        return SPKPresenceNotificationsEnabled();
    };

    SPKSetting *notifyOnline = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFY_ONLINE_TITLE") icon:SPKSettingsIcon(@"circle_check_filled") defaultsKey:@"msgs_presence_notify_online"];
    SPKSetting *notifyOffline = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFY_OFFLINE_TITLE") icon:SPKSettingsIcon(@"circle_xmark_filled") defaultsKey:@"msgs_presence_notify_offline"];
    SPKSetting *notifyTyping = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFY_TYPING_TITLE") icon:SPKSettingsIcon(@"keyboard") defaultsKey:@"msgs_presence_notify_typing"];
    SPKSetting *notifyRead = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFY_READ_TITLE") icon:SPKSettingsIcon(@"eye") defaultsKey:@"msgs_presence_notify_read"];
    SPKSetting *mirrorToNotificationCenter = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFY_OUTSIDE_APP_TITLE")
                                                                       icon:SPKSettingsIcon(@"notifications")
                                                                defaultsKey:@"msgs_presence_mirror_notification_center"];
    for (SPKSetting *setting in @[ notifyOnline, notifyOffline, notifyTyping, notifyRead, mirrorToNotificationCenter ])
        setting.enabledProvider = masterEnabled;

    SPKSetting *trackedUsers = [SPKSetting navigationCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_TRACKED_USERS_TITLE")
                                                          subtitle:@""
                                                              icon:SPKSettingsIcon(@"users")
                                                    viewController:SPKPresenceListViewController()];
    trackedUsers.userInfo = @{ @"accessoryText" : [NSString stringWithFormat:@"%lu", (unsigned long)SPKPresenceUserList().count] };
    trackedUsers.enabledProvider = masterEnabled;

    SPKSetting *accurateStatus = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_ACCURATE_STATUS_TITLE")
                                                            icon:SPKSettingsIcon(@"check")
                                                     defaultsKey:@"msgs_presence_accurate_status"];
    SPKSetting *refreshInterval = [SPKSetting stepperCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_REFRESH_INTERVAL_TITLE")
                                                          subtitle:SPKL(@"MESSAGES_ACTIVITY_REFRESH_INTERVAL_SUBTITLE")
                                                              icon:SPKSettingsIcon(@"clock")
                                                       defaultsKey:@"msgs_presence_refresh_interval"
                                                               min:10
                                                               max:300
                                                              step:5
                                                             label:SPKL(@"MESSAGES_ACTIVITY_REFRESH_INTERVAL_UNIT_PLURAL")
                                                     singularLabel:SPKL(@"MESSAGES_ACTIVITY_REFRESH_INTERVAL_UNIT_SINGULAR")];
    refreshInterval.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_presence_accurate_status"];
    };

    return @[
        SPKTopicSection(@"", @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFICATIONS_TITLE")
                                       icon:SPKSettingsIcon(@"activity")
                                defaultsKey:@"msgs_presence_notifications"],
        ],
                        SPKL(@"MESSAGES_ACTIVITY_MASTER_SWITCH_FOOTER")),
        SPKTopicSection(SPKL(@"MESSAGES_ACTIVITY_NOTIFICATIONS_HEADER"), @[
            notifyOnline,
            notifyOffline,
            notifyTyping,
            notifyRead,
        ],
                        SPKL(@"MESSAGES_ACTIVITY_NOTIFICATIONS_FOOTER")),
        SPKTopicSection(@"", @[
            mirrorToNotificationCenter,
        ],
                        SPKL(@"MESSAGES_ACTIVITY_MIRROR_NOTIFICATION_CENTER_FOOTER")),
        SPKTopicSection(SPKL(@"MESSAGES_ACTIVITY_TRACKING_HEADER"), @[
            trackedUsers,
            [SPKSetting navigationCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_DIAGNOSTICS_TITLE")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"info")
                                 viewController:SPKPresenceDiagnosticsViewController()],
        ],
                        SPKL(@"MESSAGES_ACTIVITY_TRACKING_FOOTER")),
        SPKTopicSection(SPKL(@"MESSAGES_ACTIVITY_ACCURACY_HEADER"), @[
            accurateStatus,
            refreshInterval,
        ],
                        SPKL(@"MESSAGES_ACTIVITY_ACCURACY_FOOTER"))
    ];
}

@interface SPKMessagesSettingsViewController : SPKSettingsViewController
@end

@implementation SPKMessagesSettingsViewController
- (instancetype)init {
    return [super initWithTitle:SPKL(@"MESSAGES_CONFIRMATION_MESSAGES_TITLE") sections:SPKMessagesSettingsSections() reduceMargin:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self replaceSections:SPKMessagesSettingsSections()];
}

- (void)switchChanged:(UISwitch *)sender {
    SPKSetting *row = [self settingForSender:sender];
    [super switchChanged:sender];
    if ([row.defaultsKey isEqualToString:@"msgs_manual_seen"] ||
        [row.defaultsKey isEqualToString:@"msgs_manual_visual_seen"]) {
        [self replaceSections:SPKMessagesSettingsSections()];
    }
}
@end

static NSArray *SPKMessagesSettingsSections(void) {
    BOOL manualSeen = [SPKUtils getBoolPref:@"msgs_manual_seen"];
    SPKSetting *manualSeenList = [SPKSetting navigationCellWithTitle:SPKDirectManualSeenListTitle(manualSeen)
                                                            subtitle:@""
                                                                icon:SPKSettingsIcon(@"users")
                                                      viewController:SPKDirectManualSeenListViewController()];
    manualSeenList.userInfo = @{@"accessoryText" : [NSString stringWithFormat:@"%lu", (unsigned long)SPKDirectManualSeenThreadCount(manualSeen)]};

    // Auto-seen triggers only act while manual seen is on. Keep their stored value
    // but lock the cells when manual seen is off.
    SPKSetting *seenOnSend = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_GENERAL_MARK_SEEN_MESSAGE_SEND_TITLE") icon:SPKSettingsIcon(@"messages") defaultsKey:@"msgs_seen_on_send"];
    SPKSetting *seenOnReply = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_GENERAL_MARK_SEEN_MESSAGE_REPLY_TITLE") icon:SPKSettingsIcon(@"reply") defaultsKey:@"msgs_seen_on_reply"];
    SPKSetting *seenOnReaction = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_GENERAL_MARK_SEEN_REACTION_TITLE") icon:SPKSettingsIcon(@"reactions") defaultsKey:@"msgs_seen_on_reaction"];
    SPKSetting *seenOnTyping = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_GENERAL_MARK_SEEN_TYPING_TITLE") icon:SPKSettingsIcon(@"keyboard") defaultsKey:@"msgs_seen_on_typing"];
    seenOnSend.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_seen"];
    };
    seenOnReply.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_seen"];
    };
    seenOnReaction.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_seen"];
    };
    seenOnTyping.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_seen"];
    };

    // Chooses where the manual-seen eye button lives: the top nav bar, or a
    // draggable bubble above the composer. Only meaningful while manual seen is on.
    // Up/Down arrows mirror the placement on both the menu items and the cell.
    SPKSetting *seenButtonPosition = SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:SPKL(@"MESSAGES_GENERAL_SEEN_BUTTON_POSITION_TITLE")
                                                                                              icon:SPKSettingsIcon(@"arrow_up")
                                                                                              menu:SPKSeenButtonPositionMenu()],
                                                                     SPKSettingsIcon(@"arrow_up"));
    seenButtonPosition.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_seen"];
    };

    // Advancing after a manual seen only applies while visual manual seen is on.
    SPKSetting *advanceVisual = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_GENERAL_ADVANCE_AFTER_MANUAL_SEEN_TITLE") icon:SPKSettingsIcon(@"autoscroll") defaultsKey:@"msgs_advance_visual_on_seen"];
    advanceVisual.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_visual_seen"];
    };

    // Tri-state control for reformatting the chat-header last-active presence
    // label: Off / Smart / Date & Time.
    SPKSetting *lastActiveFormat = SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:SPKL(@"MESSAGES_GENERAL_LAST_ACTIVE_TITLE")
                                                                                            icon:SPKSettingsIcon(@"clock")
                                                                                            menu:SPKLastActiveFormatMenu()],
                                                                   SPKSettingsIcon(@"clock"));

    // Extends the action button to the full-screen viewer for permanent chat media
    // (camera-roll photos/videos, chat-menu media), replacing IG's native Save.
    // Only meaningful while the master action button toggle is on.
    SPKSetting *chatMediaActionButton = [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_GENERAL_ALSO_SHOW_CHAT_MEDIA_TITLE")
                                                                  icon:SPKSettingsIcon(@"photo")
                                                           defaultsKey:kSPKMessagesActionButtonChatMediaKey];
    chatMediaActionButton.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:kSPKMessagesActionButtonEnabledKey];
    };

    SPKSetting *activityNotifications = [SPKSetting navigationCellWithTitle:SPKL(@"MESSAGES_ACTIVITY_NOTIFICATIONS_TITLE")
                                                                   subtitle:@""
                                                                       icon:SPKSettingsIcon(@"activity")
                                                             viewController:[[SPKActivityNotificationsSettingsViewController alloc] init]];
    activityNotifications.userInfo = @{ @"accessoryText" : SPKPresenceSettingsSummary() };
    activityNotifications.searchSectionsProvider = ^NSArray * {
        return SPKActivityNotificationsSettingsSections();
    };

    return @[
        SPKTopicSection(SPKL(@"FEED_ACTION_BUTTON_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_ACTION_BUTTON_MESSAGES_ACTION_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"action")
                                defaultsKey:kSPKMessagesActionButtonEnabledKey],
            chatMediaActionButton,
            SPKActionButtonDefaultActionNavigationSetting(SPKActionButtonSourceDirect),
            SPKActionButtonConfigurationNavigationSetting(SPKActionButtonSourceDirect, SPKL(@"MESSAGES_CONFIRMATION_MESSAGES_TITLE"), SPKActionButtonSupportedActionsForSource(SPKActionButtonSourceDirect), SPKActionButtonDefaultSectionsForSource(SPKActionButtonSourceDirect))
        ],
                        SPKL(@"SETTINGS_MESSAGES_CHOOSE_WHAT_TAPPING_ACTION_BUTTON_LONG_PRESS_OPENS_FULL_ACTION")),
        SPKTopicSection(SPKL(@"MESSAGES_MESSAGING_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_MESSAGING_UNLOCK_MESSAGE_PREVIEW_TITLE")
                                       icon:SPKSettingsIcon(@"story_preview")
                                defaultsKey:@"msgs_unlock_preview"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_MESSAGING_MANUALLY_MARK_SEEN_TITLE")
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"msgs_manual_seen"],
            seenButtonPosition,
            seenOnSend,
            seenOnReply,
            seenOnReaction,
            seenOnTyping,
            manualSeenList,
        ],
                        manualSeen ? SPKL(@"SETTINGS_MESSAGES_UNLOCK_MESSAGE_PREVIEW_CHAT_LONG_PRESS_MENU_SHOWS_ACTUAL_MESSAGE")
                                   : SPKL(@"MESSAGES_MANUAL_SEEN_INCLUDED_CHATS_FOOTER")),
        SPKTopicSection(SPKL(@"MESSAGES_ACTIVITY_HEADER"), @[
            activityNotifications,
        ],
                        SPKL(@"MESSAGES_ACTIVITY_FOOTER")),
        SPKTopicSection(SPKL(@"ALERT_ACTION_DELETED_MESSAGES"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_DELETED_MESSAGES_KEEP_DELETED_MESSAGES_TITLE")
                                       icon:SPKSettingsIcon(@"undo_circle")
                                defaultsKey:@"msgs_keep_deleted"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_DELETED_MESSAGES_CONFIRM_INBOX_REFRESH_TITLE")
                                       icon:SPKSettingsIcon(@"arrow_cw")
                                defaultsKey:@"msgs_confirm_refresh"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_DELETED_MESSAGES_LOG_DELETED_MESSAGES_TITLE")
                                       icon:SPKSettingsIcon(@"logs")
                                defaultsKey:@"msgs_deleted_log"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_DELETED_MESSAGES_LOG_REMOVED_REACTIONS_TITLE")
                                       icon:SPKSettingsIcon(@"reactions")
                                defaultsKey:@"msgs_deleted_log_reactions"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_DELETED_MESSAGES_RESPECT_SEEN_CHAT_LIST_TITLE")
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"msgs_deleted_log_respect_seen_list"],
            [SPKSetting navigationCellWithTitle:SPKL(@"MESSAGES_DELETED_MESSAGES_VIEW_DELETED_MESSAGES_TITLE")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"channels")
                                 viewController:[SPKDeletedMessagesViewController new]],
        ],
                        SPKL(@"SETTINGS_MESSAGES_PRESERVES_REMOTELY_UNSENT_MESSAGES_CHAT_MARKED_UNDO_CIRCLE_INDICATOR_MESSAGE")),
        SPKTopicSection(SPKL(@"INTERFACE_TITLE"), @[
            lastActiveFormat,
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_INTERFACE_HIDE_TYPING_STATUS_TITLE")
                                       icon:SPKSettingsIcon(@"keyboard")
                                defaultsKey:@"msgs_disable_typing"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_INTERFACE_HIDE_REELS_BLEND_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"blend")
                                defaultsKey:@"msgs_hide_reels_blend"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_INTERFACE_HIDE_AUDIO_CALL_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"call")
                                defaultsKey:@"msgs_hide_audio_call_btn"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_INTERFACE_HIDE_VIDEO_CALL_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"video")
                                defaultsKey:@"msgs_hide_video_call_btn"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_INTERFACE_HIDE_FLAG_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"flag")
                                defaultsKey:@"msgs_hide_flag_btn"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_INTERFACE_NO_SUGGESTED_CHATS_TITLE")
                                       icon:SPKSettingsIcon(@"question")
                                defaultsKey:@"msgs_hide_suggested_chats"],
        ],
                        SPKL(@"SETTINGS_MESSAGES_SHOWS_EXACT_TIME_SOMEONE_LAST_ACTIVE_CHAT_HEADER_ACTIVE_TEXT")),
        SPKTopicSection(SPKL(@"MESSAGES_VISUAL_MESSAGES_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_MESSAGING_MANUALLY_MARK_SEEN_TITLE")
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"msgs_manual_visual_seen"],
            advanceVisual,
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_VISUAL_MESSAGES_STOP_AUTO_ADVANCE_TITLE")
                                       icon:SPKSettingsIcon(@"autoscroll")
                                defaultsKey:@"msgs_stop_visual_auto_advance"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_VISUAL_MESSAGES_DISABLE_VIEW_ONCE_LIMITATIONS_TITLE")
                                       icon:SPKSettingsIcon(@"view_once")
                                defaultsKey:@"msgs_disable_view_once"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_VANISH_MODE_DISABLE_SCREENSHOT_DETECTION_TITLE")
                                       icon:SPKSettingsIcon(@"warning")
                                defaultsKey:@"msgs_disable_screenshot_detection"]
        ],
                        SPKL(@"SETTINGS_MESSAGES_PREVENTS_AUTOMATIC_SEEN_RECEIPTS_ADDS_BUTTON_MARK_CHAT_SEEN_TEXT")),
        SPKTopicSection(SPKL(@"MESSAGES_VANISH_MODE_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_VANISH_MODE_DISABLE_SWIPE_UP_GESTURE_TITLE")
                                       icon:SPKSettingsIcon(@"arrow_up")
                                defaultsKey:@"msgs_disable_vanish_swipe_up"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_VANISH_MODE_DISABLE_SCREENSHOT_DETECTION_TITLE")
                                       icon:SPKSettingsIcon(@"warning")
                                defaultsKey:@"msgs_hide_vanish_screenshot"],
        ],
                        SPKL(@"SETTINGS_MESSAGES_DISABLE_GESTURE_ENABLES_VANISH_MODE_N2_ALLOWS_SCREEN_CAPTURE_TEXT")),
        SPKTopicSection(SPKL(@"MESSAGES_NOTES_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_NOTES_HIDE_NOTES_TRAY_TITLE")
                                       icon:SPKSettingsIcon(@"notes")
                                defaultsKey:@"msgs_hide_notes_tray"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_NOTES_HIDE_FRIENDS_MAP_TITLE")
                                       icon:SPKSettingsIcon(@"map")
                                defaultsKey:@"msgs_hide_friends_map"],
            SPKAudioGatedSwitch(SPKL(@"SETTINGS_MESSAGES_DOWNLOAD_NOTES_AUDIO_TEXT"), SPKSettingsIcon(@"audio"), @"msgs_download_notes_audio"),
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_NOTES_COPY_NOTE_TEXT_TITLE")
                                       icon:SPKSettingsIcon(@"copy")
                                defaultsKey:@"msgs_copy_note_text"]
        ],
                        SPKL(@"MESSAGES_NOTES_FOOTER")),
        SPKTopicSection(SPKL(@"MESSAGES_DIRECT_MESSAGE_MENU_AUDIO_TITLE"), @[
            SPKAudioGatedSwitch(SPKL(@"SETTINGS_MESSAGES_DOWNLOAD_VOICE_MESSAGES_MESSAGE"), SPKSettingsIcon(@"audio_download"), @"msgs_download_audio_messages"),
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_AUDIO_UPLOAD_AUDIO_TITLE")
                                       icon:SPKSettingsIcon(@"audio_upload")
                                defaultsKey:@"msgs_upload_audio_messages"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_AUDIO_TRIM_BEFORE_SENDING_TITLE")
                                       icon:SPKSettingsIcon(@"trim")
                                defaultsKey:@"msgs_audio_upload_trim"]
        ],
                        SPKL(@"SETTINGS_MESSAGES_ADDS_AUDIO_ACTIONS_SUPPORTED_VOICE_AUDIO_MESSAGE_VIEWS_N2_ACTION")),
        SPKTopicSection(SPKL(@"FEED_MEDIA_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_UPLOAD_PHOTO_GALLERY_TITLE")
                                       icon:SPKSettingsIcon(@"photo")
                                defaultsKey:@"msgs_upload_gallery_media"],
            [SPKSetting switchCellWithTitle:SPKL(@"GENERAL_COMMENTS_SHOW_GIF_TITLE_TITLE")
                                       icon:SPKSettingsIcon(@"info")
                                defaultsKey:@"msgs_gif_title"]
        ],
                        SPKL(@"SETTINGS_MESSAGES_ADDS_OPTION_COMPOSER_PLUS_MENU_SENDS_PHOTO_SPARKLE_GALLERY_TEXT")),
        SPKTopicSection(SPKL(@"FEED_CONFIRMATION_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_AUDIO_CALL_TITLE")
                                       icon:SPKSettingsIcon(@"call")
                                defaultsKey:kSPKMessagesAudioCallConfirmKey],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_VIDEO_CALL_TITLE")
                                       icon:SPKSettingsIcon(@"video")
                                defaultsKey:kSPKMessagesVideoCallConfirmKey],
            [SPKSetting switchCellWithTitle:SPKL(@"FEED_CONFIRMATION_CONFIRM_DOUBLE_TAP_TITLE")
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"msgs_confirm_double_tap"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_REACTIONS_TITLE")
                                       icon:SPKSettingsIcon(@"reactions")
                                defaultsKey:@"msgs_confirm_reaction"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_VOICE_MESSAGES_TITLE")
                                       icon:SPKSettingsIcon(@"voice")
                                defaultsKey:@"msgs_confirm_voice_msg"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_FOLLOW_REQUESTS_TITLE")
                                       icon:SPKSettingsIcon(@"user_request")
                                defaultsKey:@"msgs_confirm_follow_request"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_VANISH_MODE_TITLE")
                                       icon:SPKSettingsIcon(@"vanish")
                                defaultsKey:@"msgs_confirm_vanish_mode"],
            [SPKSetting switchCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_CONFIRM_CHANGING_THEME_TITLE")
                                       icon:SPKSettingsIcon(@"palette")
                                defaultsKey:@"msgs_confirm_theme_change"]
        ],
                        SPKL(@"MESSAGES_CONFIRMATION_FOOTER"))
    ];
}

@implementation SPKMessagesSettingsProvider

+ (SPKSetting *)rootSetting {
    SPKSetting *setting = [SPKSetting navigationCellWithTitle:SPKL(@"MESSAGES_CONFIRMATION_MESSAGES_TITLE")
                                                     subtitle:@""
                                                         icon:SPKSettingsIcon(@"messages")
                                               viewController:[[SPKMessagesSettingsViewController alloc] init]];
    setting.searchSectionsProvider = ^NSArray * {
        return SPKMessagesSettingsSections();
    };
    return SPKSettingApplyIconTint(setting, [SPKUtils SPKColor_InstagramPrimaryText]);
}

@end
