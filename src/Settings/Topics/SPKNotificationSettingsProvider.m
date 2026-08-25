#import "SPKStrings.h"
#import "SPKNotificationSettingsProvider.h"
#import "../../Shared/UI/SPKNotificationCenter.h"
#import "../../Utils.h"
#import "../SPKPreferenceAvailability.h"
#import "../SPKTopicSettingsSupport.h"

@implementation SPKNotificationSettingsProvider

+ (NSArray<NSDictionary *> *)spk_featureSectionsForHaptics:(BOOL)haptics {
    NSMutableArray<NSDictionary *> *sections = [NSMutableArray array];

    for (NSDictionary *sectionInfo in SPKNotificationPreferenceSections()) {
        NSMutableArray<SPKSetting *> *rows = [NSMutableArray array];
        for (NSDictionary *item in sectionInfo[@"items"] ?: @[]) {
            NSString *identifier = item[@"identifier"];
            NSString *title = item[@"title"] ?: SPKL(@"SETTINGS_NOTIFICATION_FEATURE_TEXT");
            NSString *iconName = item[@"iconName"] ?: @"info";
            SPKSetting *setting = [SPKSetting switchCellWithTitle:title
                                                         subtitle:@""
                                                             icon:SPKSettingsIcon(iconName)
                                                      defaultsKey:haptics ? SPKNotificationHapticDefaultsKey(identifier) : SPKNotificationDefaultsKey(identifier)];
            setting.userInfo = @{@"defaultValue" : @YES};
            [rows addObject:setting];
        }

        NSString *sectionTitle = sectionInfo[@"title"] ?: @"";
        [sections addObject:SPKTopicSection(sectionTitle, [rows copy], nil)];
    }

    return [sections copy];
}

+ (void)spk_showNextNotificationPreview {
    static NSUInteger toneIndex = 0;

    NSArray<NSDictionary *> *configs = @[
        @{
            @"title" : SPKL(@"SETTINGS_NOTIFICATION_SAVED_GALLERY_TEXT"),
            @"subtitle" : SPKL(@"SETTINGS_NOTIFICATION_NOTIFICATION_PREVIEW_SUCCESS_TONE_TEXT"),
            @"iconResource" : @"circle_check_filled",
            @"tone" : @(SPKNotificationToneSuccess)
        },
        @{
            @"title" : SPKL(@"SETTINGS_NOTIFICATION_SOMETHING_WENT_WRONG_TEXT"),
            @"subtitle" : SPKL(@"SETTINGS_NOTIFICATION_NOTIFICATION_PREVIEW_ERROR_TONE_TEXT"),
            @"iconResource" : @"error_filled",
            @"tone" : @(SPKNotificationToneError)
        },
        @{
            @"title" : SPKL(@"SETTINGS_NOTIFICATION_HEADS_UP_TEXT"),
            @"subtitle" : SPKL(@"SETTINGS_NOTIFICATION_NOTIFICATION_PREVIEW_INFO_TONE_TEXT"),
            @"iconResource" : @"info_filled",
            @"tone" : @(SPKNotificationToneInfo)
        }
    ];

    NSDictionary *config = configs[toneIndex % configs.count];
    toneIndex++;

    SPKNotify(kSPKNotificationSettingsClearCache,
              config[@"title"],
              config[@"subtitle"],
              config[@"iconResource"],
              [config[@"tone"] unsignedIntegerValue]);
}

+ (NSArray *)sections {
    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[
        SPKTopicSection(SPKL(@"NOTIFICATION_APPEARANCE_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"NOTIFICATION_APPEARANCE_GLOW_TITLE")
                                   subtitle:SPKL(@"NOTIFICATION_APPEARANCE_SHOW_GLOW_EFFECT_AROUND_NOTIFICATIONS_SUBTITLE")
                                defaultsKey:kSPKNotificationPillGlowEnabledKey],
            [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_CAPTURE_LIQUID_GLASS_TITLE")
                                   subtitle:(SPKPrefIsAvailable(kSPKNotificationPillLiquidGlassEnabledKey)
                                                 ? SPKL(@"SETTINGS_NOTIFICATION_RENDER_NOTIFICATIONS_IOS_LIQUID_GLASS_TEXT")
                                                 : SPKL(@"SETTINGS_NOTIFICATION_REQUIRES_IOS_LATER_TEXT"))
                                   defaultsKey:kSPKNotificationPillLiquidGlassEnabledKey],
            [SPKSetting menuCellWithTitle:SPKL(@"NOTIFICATION_APPEARANCE_DOWNLOAD_PROGRESS_TITLE")
                                 subtitle:@""
                                     menu:SPKNotificationProgressSubtitleStyleMenu()],
            [SPKSetting menuCellWithTitle:SPKL(@"NOTIFICATION_APPEARANCE_POSITION_TITLE")
                                 subtitle:@""
                                     menu:SPKNotificationPillPositionMenu()],
            [SPKSetting stepperCellWithTitle:SPKL(@"NOTIFICATION_APPEARANCE_DURATION_TITLE")
                                    subtitle:SPKL(@"NOTIFICATION_APPEARANCE_DISMISS_AFTER_SUBTITLE")
                                 defaultsKey:kSPKNotificationPillDurationKey
                                         min:0.5
                                         max:5.0
                                        step:0.25
                                       label:SPKL(@"NOTIFICATION_APPEARANCE_DURATION_UNIT")
                               singularLabel:@" second"]
        ],
                        nil),
        SPKTopicSection(SPKL(@"NOTIFICATION_PREVIEW_HEADER"), @[
            [SPKSetting buttonCellWithTitle:SPKL(@"NOTIFICATION_PREVIEW_TEST_NOTIFICATION_TITLE")
                                   subtitle:@""
                                       icon:nil
                                     action:^{
                                         [self spk_showNextNotificationPreview];
                                     }]
        ],
                        nil),
        SPKTopicSection(@"", @[
            [SPKSetting navigationCellWithTitle:SPKL(@"NOTIFICATION_PREVIEW_HAPTICS_TITLE")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"haptics")
                                    navSections:[self spk_featureSectionsForHaptics:YES]]
        ],
                        nil)
    ]];

    [sections addObjectsFromArray:[self spk_featureSectionsForHaptics:NO]];
    return [sections copy];
}

@end
