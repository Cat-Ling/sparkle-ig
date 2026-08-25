#import "SPKStrings.h"
#import "SPKInterfaceSettingsProvider.h"
#import "../../Shared/Fonts/SPKFontManager.h"
#import "../../Shared/UI/SPKChrome.h"
#import "../SPKFontPickerViewController.h"
#import "../../Utils.h"
#import "../SPKPreferenceAvailability.h"
#import "../SPKPreferences.h"
#import "../SPKTopicSettingsSupport.h"
#import "../../Shared/Navigation/SPKTabConfiguration.h"
#import "../SPKTabEditorViewController.h"
#import "SPKNotificationSettingsProvider.h"

@implementation SPKInterfaceSettingsProvider

+ (SPKSetting *)rootSetting {
    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[
        SPKTopicSection(SPKL(@"INTERFACE_NOTIFICATIONS_HEADER"), @[
            [SPKSetting navigationCellWithTitle:SPKL(@"INTERFACE_NOTIFICATIONS_HEADER")
                                       subtitle:nil
                                           icon:SPKSettingsIcon(@"notification")
                                    navSections:[SPKNotificationSettingsProvider sections]]
        ],
                        nil),
        SPKTopicSection(SPKL(@"INTERFACE_TABS_HEADER"), @[
            [SPKSetting navigationCellWithTitle:SPKL(@"INTERFACE_TABS_TAB_EDITOR_TITLE")
                                       subtitle:nil
                                           icon:SPKSettingsIcon(@"edit")
                                 viewController:[[SPKTabEditorViewController alloc] init]],
        ],
                        SPKL(@"INTERFACE_NOTIFICATIONS_FOOTER")),
        SPKTopicSection(SPKL(@"INTERFACE_APPEARANCE_HEADER"), @[
            ({
                SPKSetting *appFont = [SPKSetting navigationCellWithTitle:SPKL(@"FONT_APP_FONT_TITLE")
                                                                 subtitle:nil
                                                                     icon:SPKSettingsIcon(@"text")
                                                           viewController:[[SPKFontPickerViewController alloc] init]];
                appFont.accessoryTextProvider = ^NSString * {
                    return [SPKFontManager selectedFamilyName] ?: SPKL(@"FONT_DEFAULT_ROW_TITLE");
                };
                appFont;
            }),
        ],
                        SPKL(@"INTERFACE_APPEARANCE_FOOTER")),
        SPKTopicSection(SPKL(@"INTERFACE_EXPLORE_SEARCH_HEADER"), @[
            ({
                SPKSetting *s = [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_EXPLORE_SEARCH_HIDE_EXPLORE_POSTS_GRID_TITLE")
                                                           icon:SPKSettingsIcon(@"explore_grid")
                                                    defaultsKey:@"interface_hide_explore_grid"];
                s.switchChangeHandler = ^(BOOL isOn) {
                    SPKPreferenceSetObject(@(isOn), @"interface_hide_explore_grid");
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPKHideExploreGridPreferenceDidChangeNotification object:nil];
                };
                s;
            }),
            [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_EXPLORE_SEARCH_HIDE_TRENDING_SEARCHES_TITLE")
                                       icon:SPKSettingsIcon(@"trending")
                                defaultsKey:@"interface_hide_trending_searches"
                            requiresRestart:YES],
            [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_EXPLORE_SEARCH_OPEN_CLIPBOARD_LINK_TITLE")
                                       icon:SPKSettingsIcon(@"link")
                                defaultsKey:@"interface_open_clipboard_link"]
        ],
                        SPKL(@"SETTINGS_INTERFACE_HIDE_GRID_SUGGESTED_POSTS_EXPLORE_TAB_N2_HIDE_TRENDING_TEXT")),
        SPKTopicSection(SPKL(@"INTERFACE_CAPTURE_HEADER"), @[
            ({
                SPKSetting *s = [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_CAPTURE_HIDE_UI_CAPTURE_TITLE")
                                                           icon:nil
                                                    defaultsKey:@"interface_hide_ui_on_capture"];
                s.switchChangeHandler = ^(BOOL isOn) {
                    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:@"interface_hide_ui_on_capture"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPKHideUIOnCapturePreferenceDidChangeNotification object:nil];
                };
                s;
            })
        ],
                        SPKL(@"INTERFACE_CAPTURE_FOOTER"))
    ]];

    {
        // Tab Bar Behavior is shared by both presentations: it configures the
        // scroll behavior of the (pill/glass) tab bar and is enabled whenever
        // the Liquid Glass pref is on.
        SPKSetting *(^tabBarBehaviorCell)(void) = ^SPKSetting * {
            SPKSetting *tabBarBehavior = [SPKSetting menuCellWithTitle:SPKL(@"INTERFACE_CAPTURE_TAB_BAR_BEHAVIOR_TITLE")
                                                                  icon:nil
                                                                  menu:SPKLiquidGlassTabBarStateMenu()];
            tabBarBehavior.defaultsKey = kSPKPrefInterfaceLiquidGlassTabBarMode;
            tabBarBehavior.enabledProvider = ^BOOL {
                return [SPKUtils getBoolPref:kSPKPrefInterfaceLiquidGlass];
            };
            return tabBarBehavior;
        };

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"26.0")) {
            // Full Liquid Glass: real glass material, progressive blur, tab bar.
            SPKSetting *liquidGlass = [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_CAPTURE_LIQUID_GLASS_TITLE")
                                                          defaultsKey:kSPKPrefInterfaceLiquidGlass
                                                      requiresRestart:YES];
            liquidGlass.switchValueProvider = ^BOOL {
                return [SPKUtils getBoolPref:kSPKPrefInterfaceLiquidGlass];
            };
            liquidGlass.switchChangeHandler = ^(BOOL isOn) {
                [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kSPKPrefInterfaceLiquidGlass];
                [SPKUtils showRestartConfirmation];
            };
            SPKSetting *progressiveBlur = [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_CAPTURE_PROGRESSIVE_BLUR_TITLE")
                                                             defaultsKey:kSPKPrefInterfaceProgressiveBlur
                                                          requiresRestart:YES];

            [sections addObject:SPKTopicSection(SPKL(@"INTERFACE_LIQUID_GLASS_BLUR_HEADER"), @[
                          liquidGlass,
                          progressiveBlur,
                          tabBarBehaviorCell(),
                      ],
                                                SPKL(@"SETTINGS_INTERFACE_FORCE_ENABLE_INSTAGRAM_S_NATIVE_LIQUID_GLASS_UI_N2_TEXT"))];
        } else {
            // Pre-iOS 26 can't render the glass material, but the same tab bar
            // experiment gates still reshape the bar into the floating pill.
            // Expose that as a focused toggle sharing the Liquid Glass pref.
            SPKSetting *pillTabBar = [SPKSetting switchCellWithTitle:SPKL(@"INTERFACE_LIQUID_GLASS_BLUR_PILL_SHAPED_TAB_BAR_TITLE")
                                                        defaultsKey:kSPKPrefInterfaceLiquidGlass
                                                    requiresRestart:YES];
            pillTabBar.switchValueProvider = ^BOOL {
                return [SPKUtils getBoolPref:kSPKPrefInterfaceLiquidGlass];
            };
            pillTabBar.switchChangeHandler = ^(BOOL isOn) {
                [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kSPKPrefInterfaceLiquidGlass];
                [SPKUtils showRestartConfirmation];
            };

            [sections addObject:SPKTopicSection(SPKL(@"INTERFACE_TAB_BAR_HEADER"), @[
                          pillTabBar,
                          tabBarBehaviorCell(),
                      ],
                                                SPKL(@"INTERFACE_TAB_BAR_FOOTER"))];
        }
    }

    return SPKTopicNavigationSetting(SPKL(@"INTERFACE_TITLE"), @"interface", 24.0, sections);
}

@end
