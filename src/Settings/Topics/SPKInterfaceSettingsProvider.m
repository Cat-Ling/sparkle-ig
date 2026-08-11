#import "SPKInterfaceSettingsProvider.h"
#import "../../Shared/UI/SPKChrome.h"
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
        SPKTopicSection(@"Notifications", @[
            [SPKSetting navigationCellWithTitle:@"Notifications"
                                       subtitle:nil
                                           icon:SPKSettingsIcon(@"notification")
                                    navSections:[SPKNotificationSettingsProvider sections]]
        ],
                        nil),
        SPKTopicSection(@"Tabs", @[
            [SPKSetting navigationCellWithTitle:@"Tab Editor"
                                       subtitle:nil
                                           icon:SPKSettingsIcon(@"edit")
                                 viewController:[[SPKTabEditorViewController alloc] init]],
        ],
                        @"Arrange the tab bar with a live preview. Changes are staged and applied together, then Instagram restarts."),
        SPKTopicSection(@"Explore & Search", @[
            [SPKSetting switchCellWithTitle:@"Hide Explore Posts Grid"
                                       icon:SPKSettingsIcon(@"explore_grid")
                                defaultsKey:@"interface_hide_explore_grid"],
            [SPKSetting switchCellWithTitle:@"Hide Trending Searches"
                                       icon:SPKSettingsIcon(@"trending")
                                defaultsKey:@"interface_hide_trending_searches"],
            [SPKSetting switchCellWithTitle:@"Open Clipboard Link"
                                       icon:SPKSettingsIcon(@"link")
                                defaultsKey:@"interface_open_clipboard_link"]
        ],
                        @"1. Hide the grid of suggested posts on the explore tab.\n"
                        @"2. Hide the trending searches under the explore search bar.\n"
                        @"3. Long press the Explore tab to open the Instagram URL in your clipboard."),
        SPKTopicSection(@"Capture", @[
            ({
                SPKSetting *s = [SPKSetting switchCellWithTitle:@"Hide UI on Capture"
                                                           icon:nil
                                                    defaultsKey:@"interface_hide_ui_on_capture"];
                s.switchChangeHandler = ^(BOOL isOn) {
                    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:@"interface_hide_ui_on_capture"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPKHideUIOnCapturePreferenceDidChangeNotification object:nil];
                };
                s;
            })
        ],
                        @"Redacts Sparkle UI elements from screenshots, screen recordings, and mirroring.")
    ]];

    {
        // Tab Bar Behavior is shared by both presentations: it configures the
        // scroll behavior of the (pill/glass) tab bar and is enabled whenever
        // the Liquid Glass pref is on.
        SPKSetting *(^tabBarBehaviorCell)(void) = ^SPKSetting * {
            SPKSetting *tabBarBehavior = [SPKSetting menuCellWithTitle:@"Tab Bar Behavior"
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
            SPKSetting *liquidGlass = [SPKSetting switchCellWithTitle:@"Liquid Glass"
                                                          defaultsKey:kSPKPrefInterfaceLiquidGlass
                                                      requiresRestart:YES];
            liquidGlass.switchValueProvider = ^BOOL {
                return [SPKUtils getBoolPref:kSPKPrefInterfaceLiquidGlass];
            };
            liquidGlass.switchChangeHandler = ^(BOOL isOn) {
                [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kSPKPrefInterfaceLiquidGlass];
                [SPKUtils showRestartConfirmation];
            };
            SPKSetting *progressiveBlur = [SPKSetting switchCellWithTitle:@"Progressive Blur"
                                                             defaultsKey:kSPKPrefInterfaceProgressiveBlur
                                                          requiresRestart:YES];

            [sections addObject:SPKTopicSection(@"Liquid Glass & Blur", @[
                          liquidGlass,
                          progressiveBlur,
                          tabBarBehaviorCell(),
                      ],
                                                @"1. Force-enable Instagram's native Liquid Glass UI.\n"
                                                @"2. Restore the native progressive navigation bar blur on scroll.\n"
                                                @"3. Configure how the tab bar behaves while scrolling.")];
        } else {
            // Pre-iOS 26 can't render the glass material, but the same tab bar
            // experiment gates still reshape the bar into the floating pill.
            // Expose that as a focused toggle sharing the Liquid Glass pref.
            SPKSetting *pillTabBar = [SPKSetting switchCellWithTitle:@"Pill-Shaped Tab Bar"
                                                        defaultsKey:kSPKPrefInterfaceLiquidGlass
                                                    requiresRestart:YES];
            pillTabBar.switchValueProvider = ^BOOL {
                return [SPKUtils getBoolPref:kSPKPrefInterfaceLiquidGlass];
            };
            pillTabBar.switchChangeHandler = ^(BOOL isOn) {
                [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kSPKPrefInterfaceLiquidGlass];
                [SPKUtils showRestartConfirmation];
            };

            [sections addObject:SPKTopicSection(@"Tab Bar", @[
                          pillTabBar,
                          tabBarBehaviorCell(),
                      ],
                                                @"Reshape the tab bar into the iOS 26-style floating pill. "
                                                @"The Liquid Glass material itself requires iOS 26, so on this "
                                                @"device only the pill shape is applied.")];
        }
    }

    return SPKTopicNavigationSetting(@"Interface", @"interface", 24.0, sections);
}

@end
