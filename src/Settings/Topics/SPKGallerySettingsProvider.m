#import "SPKStrings.h"
#import "SPKGallerySettingsProvider.h"
#import "../SPKSetting.h"
#import "../SPKTopicSettingsSupport.h"

#import "../../Shared/Gallery/SPKGallerySettingsViewController.h"
#import "../../Shared/Gallery/SPKGalleryViewController.h"
#import "../../Utils.h"

@implementation SPKGallerySettingsProvider

+ (SPKSetting *)rootSetting {
    SPKSetting *gallerySettings = [SPKSetting navigationCellWithTitle:SPKL(@"GALLERY_GENERAL_GALLERY_SETTINGS_TITLE")
                                                             subtitle:nil
                                                                 icon:SPKSettingsIcon(@"settings")
                                                       viewController:[[SPKGallerySettingsViewController alloc] init]];
    gallerySettings.searchSectionsProvider = ^NSArray * {
        return [SPKGallerySettingsViewController searchSections];
    };

    return SPKTopicNavigationSetting(SPKL(@"GALLERY_TITLE"), @"sparkle_gallery", 24.0, @[
        SPKTopicSection(SPKL(@"GALLERY_ACCESS_HEADER"), @[
            [SPKSetting buttonCellWithTitle:SPKL(@"ALERT_ACTION_OPEN_GALLERY")
                                       subtitle:@""
                                           icon:SPKSettingsIcon(@"sparkle_gallery")
                                         action:^(void) {
                                             [SPKGalleryViewController presentGallery];
                                         }],
            SPKSettingWithHelp(SPKSettingApplySelectedMenuIcon([SPKSetting menuCellWithTitle:SPKL(@"GALLERY_ACCESS_QUICK_GALLERY_ACCESS_TITLE") icon:SPKSettingsIcon(@"circle_off") menu:SPKGalleryShortcutTargetMenu()], SPKSettingsIcon(@"circle_off")),
                               SPKL(@"GALLERY_ACCESS_QUICK_ACCESS_HELP"))
        ],
                        nil),
        SPKTopicSection(SPKL(@"DATA_GENERAL_SETTINGS_TITLE"), @[
            gallerySettings
        ],
                        nil)
    ]);
}

@end
