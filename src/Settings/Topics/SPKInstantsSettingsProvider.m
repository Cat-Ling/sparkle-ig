#import "SPKStrings.h"
#import "SPKInstantsSettingsProvider.h"
#include <UIKit/UIKit.h>

#import "../../Shared/ActionButton/ActionButtonCore.h"
#import "../../Shared/ActionButton/SPKActionButtonConfiguration.h"
#import "../../Utils.h"
#import "../SPKPreferenceAvailability.h"
#import "../SPKSettingsViewController.h"
#import "../SPKTopicSettingsSupport.h"

static NSString *const kSPKInstantsActionButtonEnabledKey = @"instants_action_btn";

static NSArray *SPKInstantsSettingsSections(void);

@interface SPKInstantsSettingsViewController : SPKSettingsViewController
@end

@implementation SPKInstantsSettingsViewController
- (instancetype)init {
    return [super initWithTitle:SPKL(@"INSTANTS_CONFIRMATION_INSTANTS_TITLE") sections:SPKInstantsSettingsSections() reduceMargin:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self replaceSections:SPKInstantsSettingsSections()];
}
@end

static NSArray *SPKInstantsSettingsSections(void) {
    return @[
        SPKTopicSection(SPKL(@"FEED_ACTION_BUTTON_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_ACTION_BUTTON_INSTANTS_ACTION_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(@"action")
                                defaultsKey:kSPKInstantsActionButtonEnabledKey],
            SPKActionButtonDefaultActionNavigationSetting(SPKActionButtonSourceInstants),
            SPKActionButtonConfigurationNavigationSetting(SPKActionButtonSourceInstants, SPKL(@"INSTANTS_CONFIRMATION_INSTANTS_TITLE"), SPKActionButtonSupportedActionsForSource(SPKActionButtonSourceInstants), SPKActionButtonDefaultSectionsForSource(SPKActionButtonSourceInstants))
        ],
                        SPKL(@"FEED_ACTION_BUTTON_FOOTER")),
        SPKTopicSection(SPKL(@"INSTANTS_PRIVACY_HEADER"), @[
            [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_PRIVACY_ALLOW_SCREENSHOTS_TITLE")
                                       icon:SPKSettingsIcon(@"warning")
                                defaultsKey:@"instants_allow_screenshot"],
        ],
                        SPKL(@"INSTANTS_PRIVACY_FOOTER")),
        SPKTopicSection(SPKL(@"INSTANTS_CREATION_HEADER"), @[
            ({
                SPKSetting *s = [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_CREATION_DISABLE_INSTANTS_CREATION_TITLE") icon:SPKSettingsIcon(@"instants") defaultsKey:@"instants_disable_creation"];
                s.switchChangeHandler = ^(BOOL isOn) {
                    SPKPreferenceSetObject(@(isOn), @"instants_disable_creation");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SPKQuickSnapCreationPrefChangedNotification" object:nil];
                };
                s;
            }),
            [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_CREATION_SKIP_CAMERA_AFTER_INSTANTS_TITLE")
                                       icon:SPKSettingsIcon(@"camera")
                                defaultsKey:@"instants_skip_camera_after_viewing"],
            ({
                BOOL cameraControlAvailable = SPKPrefIsAvailable(@"instants_disable_camera_control");
                SPKSetting *s = [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_CREATION_DISABLE_CAMERA_CONTROL_TITLE")
                                                       subtitle:cameraControlAvailable ? @"" : SPKL(@"SETTINGS_INSTANTS_REQUIRES_IPHONE_CAMERA_CONTROL_TEXT")
                                                           icon:SPKSettingsSystemIcon(@"button.vertical.right.press", SPKSettingsCellIconPointSize, UIImageSymbolWeightSemibold)
                                                    defaultsKey:@"instants_disable_camera_control"];
                s;
            }),
        ],
                        SPKL(@"SETTINGS_INSTANTS_BLOCKS_INSTANT_CAPTURE_PHOTO_VIDEO_WITHOUT_DISABLING_RECEIVED_INSTANTS_TEXT")),
        SPKTopicSection(@"", @[
            // Same glyph the button itself wears: the global "Open Menu Icon" choice.
            [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_CREATION_CAMERA_VIEW_BUTTON_TITLE")
                                       icon:SPKSettingsIcon(SPKActionButtonOpenMenuIconName())
                                defaultsKey:@"instants_camera_btn"],
        ],
                        SPKL(@"INSTANTS_X_FOOTER")),
        SPKTopicSection(SPKL(@"FEED_CONFIRMATION_HEADER"), @[
            ({
                SPKSetting *s = [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_CONFIRMATION_CONFIRM_INSTANT_CAPTURE_TITLE")
                                                           icon:SPKSettingsIcon(@"instants_burst")
                                                    defaultsKey:@"instants_confirm_capture"];
                s.enabledProvider = ^BOOL {
                    return NO;
                };
                s;
            }),
            [SPKSetting switchCellWithTitle:SPKL(@"INSTANTS_CONFIRMATION_CONFIRM_INSTANT_REACTION_TITLE")
                                       icon:SPKSettingsIcon(@"reactions")
                                defaultsKey:@"instants_confirm_reaction"],
        ],
                        SPKL(@"SETTINGS_INSTANTS_ASKS_CONFIRMATION_SEND_CAPTURED_INSTANT_TEMPORARILY_UNAVAILABLE_N2_SHOWS_TEXT")),
    ];
}

@implementation SPKInstantsSettingsProvider

+ (UIViewController *)makeSettingsViewController {
    return [[SPKInstantsSettingsViewController alloc] init];
}

+ (SPKSetting *)rootSetting {
    SPKSetting *setting = [SPKSetting navigationCellWithTitle:SPKL(@"INSTANTS_CONFIRMATION_INSTANTS_TITLE")
                                                     subtitle:@""
                                                         icon:SPKSettingsIcon(@"instants")
                                               viewController:[[SPKInstantsSettingsViewController alloc] init]];
    setting.searchSectionsProvider = ^NSArray * {
        return SPKInstantsSettingsSections();
    };
    return SPKSettingApplyIconTint(setting, [SPKUtils SPKColor_InstagramPrimaryText]);
}

@end
