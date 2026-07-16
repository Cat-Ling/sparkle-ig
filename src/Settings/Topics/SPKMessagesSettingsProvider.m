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
    return [super initWithTitle:@"Activity Notifications" sections:SPKActivityNotificationsSettingsSections() reduceMargin:NO];
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

    SPKSetting *notifyOnline = [SPKSetting switchCellWithTitle:@"Online" icon:SPKSettingsIcon(@"circle_check_filled") defaultsKey:@"msgs_presence_notify_online"];
    SPKSetting *notifyOffline = [SPKSetting switchCellWithTitle:@"Offline" icon:SPKSettingsIcon(@"circle_xmark_filled") defaultsKey:@"msgs_presence_notify_offline"];
    SPKSetting *notifyTyping = [SPKSetting switchCellWithTitle:@"Typing" icon:SPKSettingsIcon(@"keyboard") defaultsKey:@"msgs_presence_notify_typing"];
    SPKSetting *notifyRead = [SPKSetting switchCellWithTitle:@"Read" icon:SPKSettingsIcon(@"eye") defaultsKey:@"msgs_presence_notify_read"];
    SPKSetting *mirrorToNotificationCenter = [SPKSetting switchCellWithTitle:@"Notify Outside the App"
                                                                       icon:SPKSettingsIcon(@"notifications")
                                                                defaultsKey:@"msgs_presence_mirror_notification_center"];
    for (SPKSetting *setting in @[ notifyOnline, notifyOffline, notifyTyping, notifyRead, mirrorToNotificationCenter ])
        setting.enabledProvider = masterEnabled;

    SPKSetting *trackedUsers = [SPKSetting navigationCellWithTitle:@"Tracked Users"
                                                          subtitle:@""
                                                              icon:SPKSettingsIcon(@"users")
                                                    viewController:SPKPresenceListViewController()];
    trackedUsers.userInfo = @{ @"accessoryText" : [NSString stringWithFormat:@"%lu", (unsigned long)SPKPresenceUserList().count] };
    trackedUsers.enabledProvider = masterEnabled;

    SPKSetting *accurateStatus = [SPKSetting switchCellWithTitle:@"Accurate Active Status"
                                                            icon:SPKSettingsIcon(@"check")
                                                     defaultsKey:@"msgs_presence_accurate_status"];
    SPKSetting *refreshInterval = [SPKSetting stepperCellWithTitle:@"Refresh Interval"
                                                          subtitle:@"Refresh every %@ %@"
                                                              icon:SPKSettingsIcon(@"clock")
                                                       defaultsKey:@"msgs_presence_refresh_interval"
                                                               min:10
                                                               max:300
                                                              step:5
                                                             label:@"seconds"
                                                     singularLabel:@"second"];
    refreshInterval.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_presence_accurate_status"];
    };

    return @[
        SPKTopicSection(@"", @[
            [SPKSetting switchCellWithTitle:@"Activity Notifications"
                                       icon:SPKSettingsIcon(@"activity")
                                defaultsKey:@"msgs_presence_notifications"],
        ],
                        @"Master switch for tracked-user activity alerts.\n\n"
                        @"Activity events only arrive while Instagram is running and stop when iOS suspends it."),
        SPKTopicSection(@"Notifications", @[
            notifyOnline,
            notifyOffline,
            notifyTyping,
            notifyRead,
        ],
                        @"1. Notifies you when a tracked user comes online.\n"
                        @"2. Notifies you when a tracked user goes offline.\n"
                        @"3. Notifies you when a tracked user starts typing.\n"
                        @"4. Notifies you when a tracked user reads a message you sent."),
        SPKTopicSection(@"", @[
            mirrorToNotificationCenter,
        ],
                        @"Sends a push notification when Instagram is not in front. In the app, Sparkle uses a pill instead."),
        SPKTopicSection(@"Tracking", @[
            trackedUsers,
            [SPKSetting navigationCellWithTitle:@"Activity Diagnostics"
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"info")
                                 viewController:SPKPresenceDiagnosticsViewController()],
        ],
                        @"1. Manage the users tracked by this Instagram account. Lists are never shared between accounts.\n"
                        @"2. Inspect Instagram's live activity state and clear Sparkle's transition memory and cooldowns."),
        SPKTopicSection(@"Accuracy", @[
            accurateStatus,
            refreshInterval,
        ],
                        @"1. Removes Instagram's activity grace period and refreshes its native status more often.\n"
                        @"2. Controls the refresh frequency. Shorter intervals update sooner and use more battery.")
    ];
}

@interface SPKMessagesSettingsViewController : SPKSettingsViewController
@end

@implementation SPKMessagesSettingsViewController
- (instancetype)init {
    return [super initWithTitle:@"Messages" sections:SPKMessagesSettingsSections() reduceMargin:NO];
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
    SPKSetting *seenOnSend = [SPKSetting switchCellWithTitle:@"Mark Seen on Message Send" icon:SPKSettingsIcon(@"messages") defaultsKey:@"msgs_seen_on_send"];
    SPKSetting *seenOnReply = [SPKSetting switchCellWithTitle:@"Mark Seen on Message Reply" icon:SPKSettingsIcon(@"reply") defaultsKey:@"msgs_seen_on_reply"];
    SPKSetting *seenOnReaction = [SPKSetting switchCellWithTitle:@"Mark Seen on Reaction" icon:SPKSettingsIcon(@"reactions") defaultsKey:@"msgs_seen_on_reaction"];
    SPKSetting *seenOnTyping = [SPKSetting switchCellWithTitle:@"Mark Seen on Typing" icon:SPKSettingsIcon(@"keyboard") defaultsKey:@"msgs_seen_on_typing"];
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
    SPKSetting *seenButtonPosition = SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:@"Seen Button Position"
                                                                                              icon:SPKSettingsIcon(@"arrow_up")
                                                                                              menu:SPKSeenButtonPositionMenu()],
                                                                     SPKSettingsIcon(@"arrow_up"));
    seenButtonPosition.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_seen"];
    };

    // Advancing after a manual seen only applies while visual manual seen is on.
    SPKSetting *advanceVisual = [SPKSetting switchCellWithTitle:@"Advance After Manual Seen" icon:SPKSettingsIcon(@"autoscroll") defaultsKey:@"msgs_advance_visual_on_seen"];
    advanceVisual.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:@"msgs_manual_visual_seen"];
    };

    // Tri-state control for reformatting the chat-header last-active presence
    // label: Off / Smart / Date & Time.
    SPKSetting *lastActiveFormat = SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:@"Last Active"
                                                                                            icon:SPKSettingsIcon(@"clock")
                                                                                            menu:SPKLastActiveFormatMenu()],
                                                                   SPKSettingsIcon(@"clock"));

    // Extends the action button to the full-screen viewer for permanent chat media
    // (camera-roll photos/videos, chat-menu media), replacing IG's native Save.
    // Only meaningful while the master action button toggle is on.
    SPKSetting *chatMediaActionButton = [SPKSetting switchCellWithTitle:@"Also Show on Chat Media"
                                                                  icon:SPKSettingsIcon(@"photo")
                                                           defaultsKey:kSPKMessagesActionButtonChatMediaKey];
    chatMediaActionButton.enabledProvider = ^BOOL {
        return [SPKUtils getBoolPref:kSPKMessagesActionButtonEnabledKey];
    };

    SPKSetting *activityNotifications = [SPKSetting navigationCellWithTitle:@"Activity Notifications"
                                                                   subtitle:@""
                                                                       icon:SPKSettingsIcon(@"activity")
                                                             viewController:[[SPKActivityNotificationsSettingsViewController alloc] init]];
    activityNotifications.userInfo = @{ @"accessoryText" : SPKPresenceSettingsSummary() };
    activityNotifications.searchSectionsProvider = ^NSArray * {
        return SPKActivityNotificationsSettingsSections();
    };

    return @[
        SPKTopicSection(@"Action Button", @[
            [SPKSetting switchCellWithTitle:@"Messages Action Button"
                                       icon:SPKSettingsIcon(@"action")
                                defaultsKey:kSPKMessagesActionButtonEnabledKey],
            chatMediaActionButton,
            SPKActionButtonDefaultActionNavigationSetting(SPKActionButtonSourceDirect),
            SPKActionButtonConfigurationNavigationSetting(SPKActionButtonSourceDirect, @"Messages", SPKActionButtonSupportedActionsForSource(SPKActionButtonSourceDirect), SPKActionButtonDefaultSectionsForSource(SPKActionButtonSourceDirect))
        ],
                        @"Choose what tapping the action button does. Long press opens the full menu.\n"
                        @"\"Also Show on Chat Media\" adds it to camera-roll photos and videos opened in a chat."),
        SPKTopicSection(@"Messaging", @[
            [SPKSetting switchCellWithTitle:@"Unlock Message Preview"
                                       icon:SPKSettingsIcon(@"story_preview")
                                defaultsKey:@"msgs_unlock_preview"],
            [SPKSetting switchCellWithTitle:@"Manually Mark Seen"
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"msgs_manual_seen"],
            seenButtonPosition,
            seenOnSend,
            seenOnReply,
            seenOnReaction,
            seenOnTyping,
            manualSeenList,
        ],
                        manualSeen ? @"1. Unlock \"Message Preview\": the chat long-press menu shows the actual chat preview without marking the messages as seen.\n"
                                     @"2. Prevents automatic seen receipts and adds an eye button to mark chats as seen.\n"
                                     @"3. Places the seen button in the top nav bar, or as a draggable bubble above the composer within thumb reach (scroll to snap it back).\n"
                                     @"4. Marks a chat as seen when you send a message.\n"
                                     @"5. Marks a chat as seen when you reply.\n"
                                     @"6. Marks a chat as seen when you react.\n"
                                     @"7. Marks a chat as seen when you start typing a reply.\n\n"
                                     @"Excluded Chats keep Instagram's normal seen behavior. Manage them from the eye button, an inbox long press, or the list above."
                                   : @"1. Unlock \"Message Preview\": the chat long-press menu shows the actual chat preview without marking the messages as seen.\n"
                                     @"2. Prevents automatic seen receipts and adds an eye button to mark chats as seen.\n"
                                     @"3. Places the seen button in the top nav bar, or as a draggable bubble above the composer within thumb reach (scroll to snap it back).\n"
                                     @"4. Marks a chat as seen when you send a message.\n"
                                     @"5. Marks a chat as seen when you reply.\n"
                                     @"6. Marks a chat as seen when you react.\n"
                                     @"7. Marks a chat as seen when you start typing a reply.\n\n"
                                     @"Included Chats require the eye button or the auto-seen triggers above. Manage them from the eye button, an inbox long press, or the list above."),
        SPKTopicSection(@"Activity", @[
            activityNotifications,
        ],
                        @"Configure tracked users, activity events, background notifications, diagnostics, and active-status accuracy."),
        SPKTopicSection(@"Deleted Messages", @[
            [SPKSetting switchCellWithTitle:@"Keep Deleted Messages"
                                       icon:SPKSettingsIcon(@"undo_circle")
                                defaultsKey:@"msgs_keep_deleted"],
            [SPKSetting switchCellWithTitle:@"Confirm Inbox Refresh"
                                       icon:SPKSettingsIcon(@"arrow_cw")
                                defaultsKey:@"msgs_confirm_refresh"],
            [SPKSetting switchCellWithTitle:@"Log Deleted Messages"
                                       icon:SPKSettingsIcon(@"logs")
                                defaultsKey:@"msgs_deleted_log"],
            [SPKSetting switchCellWithTitle:@"Log Removed Reactions"
                                       icon:SPKSettingsIcon(@"reactions")
                                defaultsKey:@"msgs_deleted_log_reactions"],
            [SPKSetting switchCellWithTitle:@"Respect Seen Chat List"
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"msgs_deleted_log_respect_seen_list"],
            [SPKSetting navigationCellWithTitle:@"View Deleted Messages"
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"channels")
                                 viewController:[SPKDeletedMessagesViewController new]],
        ],
                        @"1. Preserves remotely unsent messages in the chat, marked with an undo-circle indicator.\n"
                        @"2. Asks before refreshing the inbox, which reloads threads and drops preserved messages.\n"
                        @"3. Records message content before removal and keeps view-once/view-twice media until cleared.\n"
                        @"4. Also logs reactions that are removed.\n"
                        @"5. Skips log capture and unsent notifications for chats in your manual-seen include/exclude list.\n"
                        @"6. Opens the captured deleted-message logs."),
        SPKTopicSection(@"Interface", @[
            lastActiveFormat,
            [SPKSetting switchCellWithTitle:@"Hide Typing Status"
                                       icon:SPKSettingsIcon(@"keyboard")
                                defaultsKey:@"msgs_disable_typing"],
            [SPKSetting switchCellWithTitle:@"Hide Reels Blend Button"
                                       icon:SPKSettingsIcon(@"blend")
                                defaultsKey:@"msgs_hide_reels_blend"],
            [SPKSetting switchCellWithTitle:@"Hide Audio Call Button"
                                       icon:SPKSettingsIcon(@"call")
                                defaultsKey:@"msgs_hide_audio_call_btn"],
            [SPKSetting switchCellWithTitle:@"Hide Video Call Button"
                                       icon:SPKSettingsIcon(@"video")
                                defaultsKey:@"msgs_hide_video_call_btn"],
            [SPKSetting switchCellWithTitle:@"Hide Flag Button"
                                       icon:SPKSettingsIcon(@"flag")
                                defaultsKey:@"msgs_hide_flag_btn"],
            [SPKSetting switchCellWithTitle:@"No Suggested Chats"
                                       icon:SPKSettingsIcon(@"question")
                                defaultsKey:@"msgs_hide_suggested_chats"],
        ],
                        @"1. Shows the exact time someone was last active in the chat header (\"Active at 1:15 AM\") instead of a relative label (\"Active 2h ago\"). "
                        @"\"Smart\" uses the time alone for today and adds the date for older days; \"Date & Time\" always shows both. Only reformats presence Instagram already shows.\n"
                        @"2. Stops sending your typing indicator to others.\n"
                        @"3. Removes the Reels Blend button from the inbox.\n"
                        @"4. Hides the audio call button in the chat header.\n"
                        @"5. Hides the video call button in the chat header.\n"
                        @"6. Hides the flag button in the chat header.\n"
                        @"7. Removes suggested chats from the inbox."),
        SPKTopicSection(@"Visual Messages", @[
            [SPKSetting switchCellWithTitle:@"Manually Mark Seen"
                                       icon:SPKSettingsIcon(@"eye")
                                defaultsKey:@"msgs_manual_visual_seen"],
            advanceVisual,
            [SPKSetting switchCellWithTitle:@"Stop Auto Advance"
                                       icon:SPKSettingsIcon(@"autoscroll")
                                defaultsKey:@"msgs_stop_visual_auto_advance"],
            [SPKSetting switchCellWithTitle:@"Disable View-Once Limitations"
                                       icon:SPKSettingsIcon(@"view_once")
                                defaultsKey:@"msgs_disable_view_once"],
            [SPKSetting switchCellWithTitle:@"Disable Screenshot Detection"
                                       icon:SPKSettingsIcon(@"warning")
                                defaultsKey:@"msgs_disable_screenshot_detection"]
        ],
                        @"1. Prevents automatic seen receipts and adds a button to mark the chat as seen.\n"
                        @"2. Moves to the next visual item when available or dismisses.\n"
                        @"3. Keeps the current visual message on screen instead of auto-advancing when it ends.\n"
                        @"4. View-once messages behave like normal visual messages.\n"
                        @"5. Allows screen capture of visual messages."),
        SPKTopicSection(@"Vanish Mode", @[
            [SPKSetting switchCellWithTitle:@"Disable Swipe-Up Gesture"
                                       icon:SPKSettingsIcon(@"arrow_up")
                                defaultsKey:@"msgs_disable_vanish_swipe_up"],
            [SPKSetting switchCellWithTitle:@"Disable Screenshot Detection"
                                       icon:SPKSettingsIcon(@"warning")
                                defaultsKey:@"msgs_hide_vanish_screenshot"],
        ],
                        @"1. Disable the gesture that enables vanish mode.\n"
                        @"2. Allows screen capture while vanish mode is active."),
        SPKTopicSection(@"Notes", @[
            [SPKSetting switchCellWithTitle:@"Hide Notes Tray"
                                       icon:SPKSettingsIcon(@"notes")
                                defaultsKey:@"msgs_hide_notes_tray"],
            [SPKSetting switchCellWithTitle:@"Hide Friends Map"
                                       icon:SPKSettingsIcon(@"map")
                                defaultsKey:@"msgs_hide_friends_map"],
            SPKAudioGatedSwitch(@"Download Notes Audio", SPKSettingsIcon(@"audio"), @"msgs_download_notes_audio"),
            [SPKSetting switchCellWithTitle:@"Copy Note Text"
                                       icon:SPKSettingsIcon(@"copy")
                                defaultsKey:@"msgs_copy_note_text"]
        ],
                        @"Long-press a note in the tray to download its audio or copy its text. Each action only appears when the note has that content."),
        SPKTopicSection(@"Audio", @[
            SPKAudioGatedSwitch(@"Download Voice Messages", SPKSettingsIcon(@"audio_download"), @"msgs_download_audio_messages"),
            [SPKSetting switchCellWithTitle:@"Upload Audio"
                                       icon:SPKSettingsIcon(@"audio_upload")
                                defaultsKey:@"msgs_upload_audio_messages"],
            [SPKSetting switchCellWithTitle:@"Trim Before Sending"
                                       icon:SPKSettingsIcon(@"trim")
                                defaultsKey:@"msgs_audio_upload_trim"]
        ],
                        @"1. Adds audio actions to supported voice/audio message views.\n"
                        @"2. Adds an option to the composer plus (+) menu that sends the selected audio or video as a voice message.\n"
                        @"3. When uploading, offers to trim the audio before sending it."),
        SPKTopicSection(@"Media", @[
            [SPKSetting switchCellWithTitle:@"Upload Photo from Gallery"
                                       icon:SPKSettingsIcon(@"photo")
                                defaultsKey:@"msgs_upload_gallery_media"],
            [SPKSetting switchCellWithTitle:@"Show GIF Title"
                                       icon:SPKSettingsIcon(@"info")
                                defaultsKey:@"msgs_gif_title"]
        ],
                        @"1. Adds an option to the composer plus (+) menu that sends a photo from the Sparkle Gallery into the chat.\n"
                        @"2. Long-press a GIF message for its name and channel, then tap to copy. Direct stores no name for a GIF, so this asks giphy.com about it; the answer is reused for the rest of the session."),
        SPKTopicSection(@"Confirmation", @[
            [SPKSetting switchCellWithTitle:@"Confirm Audio Call"
                                       icon:SPKSettingsIcon(@"call")
                                defaultsKey:kSPKMessagesAudioCallConfirmKey],
            [SPKSetting switchCellWithTitle:@"Confirm Video Call"
                                       icon:SPKSettingsIcon(@"video")
                                defaultsKey:kSPKMessagesVideoCallConfirmKey],
            [SPKSetting switchCellWithTitle:@"Confirm Double Tap"
                                       icon:SPKSettingsIcon(@"heart")
                                defaultsKey:@"msgs_confirm_double_tap"],
            [SPKSetting switchCellWithTitle:@"Confirm Reactions"
                                       icon:SPKSettingsIcon(@"reactions")
                                defaultsKey:@"msgs_confirm_reaction"],
            [SPKSetting switchCellWithTitle:@"Confirm Voice Messages"
                                       icon:SPKSettingsIcon(@"voice")
                                defaultsKey:@"msgs_confirm_voice_msg"],
            [SPKSetting switchCellWithTitle:@"Confirm Follow Requests"
                                       icon:SPKSettingsIcon(@"user_request")
                                defaultsKey:@"msgs_confirm_follow_request"],
            [SPKSetting switchCellWithTitle:@"Confirm Vanish Mode"
                                       icon:SPKSettingsIcon(@"vanish")
                                defaultsKey:@"msgs_confirm_vanish_mode"],
            [SPKSetting switchCellWithTitle:@"Confirm Changing Theme"
                                       icon:SPKSettingsIcon(@"palette")
                                defaultsKey:@"msgs_confirm_theme_change"]
        ],
                        @"Shows confirmation alerts before the selected message actions are sent.")
    ];
}

@implementation SPKMessagesSettingsProvider

+ (SPKSetting *)rootSetting {
    SPKSetting *setting = [SPKSetting navigationCellWithTitle:@"Messages"
                                                     subtitle:@""
                                                         icon:SPKSettingsIcon(@"messages")
                                               viewController:[[SPKMessagesSettingsViewController alloc] init]];
    setting.searchSectionsProvider = ^NSArray * {
        return SPKMessagesSettingsSections();
    };
    return SPKSettingApplyIconTint(setting, [SPKUtils SPKColor_InstagramPrimaryText]);
}

@end
