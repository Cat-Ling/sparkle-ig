#import "SPKStrings.h"
#import "SPKDownloadsSettingsViewController.h"

#import "../../App/SPKStartupHooks.h"
#import "../../AssetUtils.h"
#import "../../Settings/SPKSetting.h"
#import "../../Settings/SPKTopicSettingsSupport.h"
#import "../../Utils.h"
#import "../AutoSave/SPKAutoSaveSettingsViewController.h"
#import "../MediaDownload/SPKMediaFFmpeg.h"
#import "../MediaDownload/SPKMediaQualityManager.h"
#import "SPKDownloadTypes.h"

@implementation SPKDownloadsSettingsViewController

+ (UIMenu *)audioPageDefaultActionMenu {
    NSArray<NSDictionary *> *items = @[
        @{@"title" : SPKL(@"ALERT_ACTION_SAVE_AUDIO_FILES"), @"value" : @"files", @"icon" : @"audio_download"},
        @{@"title" : SPKL(@"ALERT_ACTION_SHARE_AUDIO"), @"value" : @"share", @"icon" : @"share"},
        @{@"title" : SPKL(@"ALERT_ACTION_SAVE_AUDIO_GALLERY"), @"value" : @"gallery", @"icon" : @"sparkle_gallery"},
        @{@"title" : SPKL(@"ALERT_ACTION_PLAY_AUDIO"), @"value" : @"play", @"icon" : @"play"},
        @{@"title" : SPKL(@"ALERT_ACTION_COPY_AUDIO_DOWNLOAD_URL"), @"value" : @"copy_url", @"icon" : @"link"},
        @{@"title" : SPKL(@"FEED_HEADER_ACTION_BUTTON_OPEN_MENU_TEXT"), @"value" : @"none", @"icon" : @"action"}
    ];
    NSMutableArray<UICommand *> *commands = [NSMutableArray array];
    for (NSDictionary *item in items) {
        [commands addObject:[UICommand commandWithTitle:item[@"title"]
                                                  image:[SPKAssetUtils menuIconNamed:item[@"icon"]]
                                                 action:@selector(menuChanged:)
                                           propertyList:@{@"defaultsKey" : @"downloads_audio_page_default_action", @"value" : item[@"value"], @"iconName" : item[@"icon"]}]];
    }
    return [UIMenu menuWithChildren:commands];
}

+ (NSArray *)contentSections {
    BOOL ffmpegAvailable = [SPKMediaFFmpeg isAvailable];
    if (!ffmpegAvailable) {
        // No FFmpeg = no DASH merge for ANY account, so this is a hard global
        // constraint, not a per-account choice. Write it globally (direct).
        [[NSUserDefaults standardUserDefaults] setObject:@"high_ignore_dash" forKey:@"downloads_video_quality"];
    }

    SPKSetting *videoQualitySetting = [SPKSetting menuCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_DEFAULT_VIDEO_QUALITY_TITLE")
                                                           subtitle:(ffmpegAvailable ? @"" : SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_REQUIRES_FFMPEGKIT_TEXT"))
                                                           icon:SPKSettingsIcon(@"video")
                                                               menu:SPKMediaVideoQualityMenu()];
    videoQualitySetting.userInfo = @{@"enabled" : @(ffmpegAvailable)};

    SPKSetting *encodingSettings = [SPKSetting navigationCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_ENCODING_SETTINGS_TITLE")
                                                              subtitle:(ffmpegAvailable ? @"" : SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_REQUIRES_FFMPEGKIT_TEXT"))
                                                              icon:SPKSettingsIcon(@"settings")
                                                        viewController:[SPKMediaQualityManager encodingSettingsViewController]];
    encodingSettings.userInfo = @{@"enabled" : @(ffmpegAvailable)};
    encodingSettings.searchSectionsProvider = ^NSArray * {
        return [SPKMediaQualityManager encodingSettingsSearchSections];
    };

    SPKSetting *encodingLogs = [SPKSetting navigationCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_VIEW_ENCODING_LOGS_TITLE")
                                                          subtitle:@""
                                                              icon:SPKSettingsIcon(@"logs")
                                                    viewController:[SPKMediaFFmpeg logsViewController]];
    encodingLogs.userInfo = @{@"enabled" : @YES};

    NSString *qualityFooter = ffmpegAvailable
        ? SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_REQUEST_4K_IMAGE_CANDIDATES_MIMICKING_WEB_BROWSER_EXTRA_CALL_TEXT")
        : SPKL(@"DOWNLOADS_QUALITY_OPTIONS_FOOTER");

    SPKSetting *autoSave = [SPKSetting navigationCellWithTitle:SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_AUTO_SAVE_HEADER")
                                                      subtitle:@""
                                                          icon:SPKSettingsIcon(@"download")
                                                viewController:[SPKAutoSaveSettingsViewController new]];
    autoSave.searchSectionsProvider = ^NSArray * {
        return [SPKAutoSaveSettingsViewController searchSections];
    };

    return @[
        SPKTopicSection(SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_AUTO_SAVE_HEADER"), @[ autoSave ],
                        SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_AUTOMATICALLY_DOWNLOAD_MEDIA_VIEW_FOOTER")),
        SPKTopicSection(SPKL(@"GENERAL_BEHAVIOR_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_DETECT_DUPLICATE_DOWNLOADS_TITLE")
                                       icon:SPKSettingsIcon(@"duplicate")
                                defaultsKey:kSPKDownloadDetectDuplicatesKey],
            [SPKSetting stepperCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_PARALLEL_DOWNLOADS_TITLE")
                                    subtitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_VALUE_CONCURRENT_VALUE_SUBTITLE")
                                        icon:SPKSettingsIcon(@"parallel")
                                 defaultsKey:kSPKDownloadMaxConcurrentKey
                                         min:1
                                         max:4
                                        step:1
                                       label:SPKL(@"SETTINGS_STORAGE_USAGE_DOWNLOADS_TEXT")
                               singularLabel:@"download"],
            [SPKSetting stepperCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_HISTORY_LIMIT_TITLE")
                                    subtitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_VALUE_SAVED_VALUE_SUBTITLE")
                                        icon:SPKSettingsIcon(@"history")
                                 defaultsKey:kSPKDownloadHistoryLimitKey
                                         min:50
                                         max:1000
                                        step:50
                                       label:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_ENTRIES_TEXT")
                               singularLabel:@"entry"],
            ({
                SPKSetting *toggle = [SPKSetting switchCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_SAVE_CUSTOM_ALBUM_TITLE")
                                                                icon:SPKSettingsIcon(@"photo_gallery")
                                                         defaultsKey:@"downloads_photos_album_enabled"];
                toggle.reloadsTableOnSwitchChange = YES;
                toggle;
            }),
            ({
                SPKSetting *album = [SPKSetting textFieldCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_ALBUM_NAME_TITLE")
                                                           placeholder:SPKL(@"ABOUT_INFORMATION_SPARKLE_TITLE")
                                                          keyboardType:UIKeyboardTypeDefault
                                                           defaultsKey:@"downloads_photos_album"];
                album.icon = SPKSettingsIcon(@"folder");
                album.enabledProvider = ^BOOL {
                    return [SPKUtils getBoolPref:@"downloads_photos_album_enabled"];
                };
                album;
            }),
        ],
                        SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_CHECK_BEFORE_DOWNLOADING_SKIP_MEDIA_ALREADY_SAVED_GALLERY_CHECKS_TEXT")),
        SPKTopicSection(SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_QUALITY_HEADER"), @[
            ({
                SPKSetting *toggle = [SPKSetting switchCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_FETCH_4K_IMAGES_TITLE")
                                                                icon:SPKSettingsIcon(@"web")
                                                         defaultsKey:@"downloads_fetch_4k_images"];
                toggle.switchChangeHandler = ^(BOOL isOn) {
                    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:SPKEffectivePreferenceKey(@"downloads_fetch_4k_images")];
                    if (!isOn) {
                        NSString *qualityKey = SPKEffectivePreferenceKey(@"downloads_photo_quality");
                        NSString *quality = [[NSUserDefaults standardUserDefaults] stringForKey:qualityKey];
                        if ([quality isEqualToString:@"max"]) {
                            [[NSUserDefaults standardUserDefaults] setObject:@"high" forKey:qualityKey];
                        }
                    }
                };
                toggle.reloadsTableOnSwitchChange = YES;
                toggle;
            }),
            [SPKSetting switchCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_ENHANCED_MEDIA_RESOLUTION_TITLE")
                                       icon:SPKSettingsIcon(@"hd")
                                defaultsKey:@"downloads_enhanced_media_resolution"],
            [SPKSetting menuCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_DEFAULT_PHOTO_QUALITY_TITLE")
                                     icon:SPKSettingsIcon(@"photo")
                                     menu:SPKMediaPhotoQualityMenu()],
            videoQualitySetting,
            encodingSettings,
            encodingLogs
        ],
                        qualityFooter),
        [self audioSection]
    ];
}

// The "Audio Downloads" master toggle gates every other audio action tweak-wide.
// The dependent cells stay visible (and keep their stored value) but are disabled
// while the master is off.
+ (NSDictionary *)audioSection {
    BOOL (^audioEnabled)(void) = ^BOOL {
        return [SPKUtils getBoolPref:@"downloads_audio_enabled"];
    };

    SPKSetting *master = [SPKSetting switchCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_AUDIO_DOWNLOADS_TITLE") icon:SPKSettingsIcon(@"audio_download") defaultsKey:@"downloads_audio_enabled"];
    master.switchChangeHandler = ^(BOOL isOn) {
        [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:SPKEffectivePreferenceKey(@"downloads_audio_enabled")];
        if (isOn)
            SPKInstallEnabledFeatureHooks();
    };
    master.reloadsTableOnSwitchChange = YES; // grey out / re-enable the dependents live

    SPKSetting *pageButton = [SPKSetting switchCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_AUDIO_PAGE_BUTTON_TITLE") icon:SPKSettingsIcon(@"audio_page") defaultsKey:@"downloads_audio_page_button"];
    pageButton.enabledProvider = audioEnabled;

    SPKSetting *pageDefault = SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_AUDIO_PAGE_DEFAULT_ACTION_TITLE") icon:SPKSettingsIcon(@"action") menu:[self audioPageDefaultActionMenu]], SPKSettingsIcon(@"action"));
    pageDefault.enabledProvider = audioEnabled;

    return SPKTopicSection(SPKL(@"MESSAGES_DIRECT_MESSAGE_MENU_AUDIO_TITLE"), @[ master, pageButton, pageDefault ],
                           SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_ADDS_AUDIO_ACTIONS_AUDIO_PAGES_MEDIA_ACTION_BUTTONS_FOOTER"));
}

+ (NSArray *)searchSections {
    return [self contentSections];
}

- (instancetype)init {
    return [super initWithTitle:SPKL(@"DOWNLOADS_DOWNLOADS_SETTINGS_DOWNLOADS_SETTINGS_TEXT") sections:[[self class] contentSections] reduceMargin:NO];
}

@end
