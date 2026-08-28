#import "SPKStrings.h"
#import "SPKAutoSaveSettingsViewController.h"

#import "../../Settings/SPKSetting.h"
#import "../../Settings/SPKTopicSettingsSupport.h"
#import "../../Utils.h"
#import "../Instants/SPKInstantsAutoSave.h"
#import "../MediaDownload/SPKMediaFFmpeg.h"
#import "../Messages/SPKDirectAutoSave.h"
#import "../Stories/SPKStoryAutoSave.h"
#import "SPKAutoSave.h"
#import "SPKAutoSaveStoriesSettingsViewController.h"

@implementation SPKAutoSaveSettingsViewController

+ (NSDictionary *)destinationSection {
    BOOL toPhotos = SPKAutoSaveDestination() == SPKDownloadDestinationPhotos;
    SPKSetting *destination = [SPKSetting menuCellWithTitle:SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_SAVE_TITLE")
                                                       icon:SPKSettingsIcon(toPhotos ? @"photo_gallery" : @"sparkle_gallery")
                                                       menu:SPKAutoSaveDestinationMenu()];

    destination.helpText = SPKL(@"AUTO_SAVE_DESTINATION_HELP");

    return SPKTopicSection(SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_DESTINATION_HEADER"), @[ destination ], nil);
}

+ (NSDictionary *)qualitySection {
    BOOL ffmpegAvailable = [SPKMediaFFmpeg isAvailable];

    SPKSetting *videoQuality = [SPKSetting menuCellWithTitle:SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_VIDEO_QUALITY_TITLE")
                                                    subtitle:(ffmpegAvailable ? @"" : SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_REQUIRES_FFMPEGKIT_TEXT"))
                                                        icon:SPKSettingsIcon(@"video")
                                                        menu:SPKAutoSaveVideoQualityMenu()];
    videoQuality.userInfo = @{@"enabled" : @(ffmpegAvailable)};
    videoQuality.helpText = SPKL(@"AUTO_SAVE_VIDEO_QUALITY_HELP");

    return SPKTopicSection(SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_QUALITY_HEADER"), @[
        SPKSettingWithHelp([SPKSetting menuCellWithTitle:SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_PHOTO_QUALITY_TITLE")
                                     icon:SPKSettingsIcon(@"photo")
                                     menu:SPKAutoSavePhotoQualityMenu()],
                           SPKL(@"AUTO_SAVE_PHOTO_QUALITY_HELP")),
        videoQuality,
    ],
                           nil);
}

+ (NSDictionary *)feedbackSection {
    return SPKTopicSection(SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_HISTORY_HEADER"), @[
        SPKSettingWithHelp([SPKSetting switchCellWithTitle:SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_KEEP_DOWNLOAD_HISTORY_TITLE")
                                       icon:SPKSettingsIcon(@"history")
                                defaultsKey:kSPKAutoSaveKeepHistoryKey],
                           SPKL(@"AUTO_SAVE_KEEP_HISTORY_HELP")),
    ],
                           nil);
}

+ (SPKSetting *)surfaceRowWithTitle:(NSString *)title
                               icon:(NSString *)icon
                            summary:(NSString *)summary
                     surfaceClass:(Class)surfaceClass {
    SPKSetting *row = [SPKSetting navigationCellWithTitle:title
                                                 subtitle:@""
                                                     icon:SPKSettingsIcon(icon)
                                           viewController:[[surfaceClass alloc] init]];
    row.userInfo = @{@"accessoryText" : summary};
    row.searchSectionsProvider = ^NSArray * {
        return [surfaceClass searchSections];
    };
    row.helpText = SPKL(@"AUTO_SAVE_SURFACE_ROW_HELP");
    return row;
}

+ (NSDictionary *)surfacesSection {
    return SPKTopicSection(SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_SURFACES_HEADER"), @[
        [self surfaceRowWithTitle:SPKL(@"STORIES_OTHER_STORIES_TITLE")
                             icon:@"story"
                          summary:SPKStoryAutoSaveSettingsSummary()
                     surfaceClass:[SPKAutoSaveStoriesSettingsViewController class]],
        [self surfaceRowWithTitle:SPKL(@"MESSAGES_CONFIRMATION_MESSAGES_TITLE")
                             icon:@"messages"
                          summary:SPKDirectAutoSaveSettingsSummary()
                     surfaceClass:[SPKAutoSaveMessagesSettingsViewController class]],
        [self surfaceRowWithTitle:SPKL(@"INSTANTS_CONFIRMATION_INSTANTS_TITLE")
                             icon:@"instants"
                          summary:SPKInstantsAutoSaveSettingsSummary()
                     surfaceClass:[SPKAutoSaveInstantsSettingsViewController class]],
    ],
                           nil);
}

+ (NSArray *)contentSections {
    return @[
        [self surfacesSection],
        [self destinationSection],
        [self qualitySection],
        [self feedbackSection],
    ];
}

+ (NSArray *)searchSections {
    return [self contentSections];
}

- (instancetype)init {
    return [super initWithTitle:SPKL(@"AUTO_SAVE_AUTO_SAVE_SETTINGS_AUTO_SAVE_HEADER") sections:[[self class] contentSections] reduceMargin:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Refresh the per-surface summary accessory after editing a surface page.
    [self replaceSections:[[self class] contentSections]];
}

- (void)menuChanged:(UICommand *)command {
    [super menuChanged:command];
    // The Save To row's icon reflects the destination, so the row has to be rebuilt --
    // the built-in path only full-rebuilds pages that have hiddenProvider rows.
    if ([command.propertyList[@"defaultsKey"] isEqualToString:kSPKAutoSaveDestinationKey])
        [self replaceSections:[[self class] contentSections]];
}

@end
