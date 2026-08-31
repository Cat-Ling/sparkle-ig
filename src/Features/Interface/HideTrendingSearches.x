#import "../../InstagramHeaders.h"
#import "../../Utils.h"
#import "../../App/SPKPerfMeter.h"
#import <objc/runtime.h>

static Class gSPKModernExploreChipBarClass = Nil;

static BOOL SPKIsLegacyExploreSearchPillBar(IGDSSegmentedPillBarView *bar) {
    Class exploreViewControllerClass = NSClassFromString(@"IGExploreViewController");
    return exploreViewControllerClass && [[bar delegate] isKindOfClass:exploreViewControllerClass];
}

static UIView *SPKTrendingSearchesBarForExploreController(IGExploreViewController *controller) {
    for (NSString *ivarName in @[ @"_chipBar", @"_nidoPillBar" ]) {
        Ivar ivar = class_getInstanceVariable([controller class], ivarName.UTF8String);
        if (!ivar)
            continue;
        id value = object_getIvar(controller, ivar);
        if ([value isKindOfClass:[UIView class]])
            return value;
    }
    return nil;
}

static void SPKHideTrendingSearchesBar(UIView *bar) {
    if (!bar)
        return;

    // Do not remove the bar or mark it hidden. The enabled-only sizeThatFits:
    // hooks collapse its navigation slot, while alpha prevents a stale frame
    // from briefly flashing during layout.
    bar.alpha = 0.0;
    bar.userInteractionEnabled = NO;
}

static void SPKApplyTrendingSearchesToExploreController(IGExploreViewController *controller) {
    UIView *bar = SPKTrendingSearchesBarForExploreController(controller);
    if (!bar)
        return;

    if ((gSPKModernExploreChipBarClass && [bar isKindOfClass:gSPKModernExploreChipBarClass]) ||
        [bar isKindOfClass:NSClassFromString(@"IGDSSegmentedPillBarView")]) {
        SPKHideTrendingSearchesBar(bar);
    }
}

static void SPKFindLiveExploreControllers(UIViewController *controller) {
    if (!controller)
        return;

    Class exploreClass = NSClassFromString(@"IGExploreViewController");
    if (exploreClass && [controller isKindOfClass:exploreClass])
        SPKApplyTrendingSearchesToExploreController((IGExploreViewController *)controller);
    if (controller.presentedViewController)
        SPKFindLiveExploreControllers(controller.presentedViewController);
    for (UIViewController *child in controller.childViewControllers)
        SPKFindLiveExploreControllers(child);
}

%group SPKHideTrendingSearchesLegacyHooks

%hook IGDSSegmentedPillBarView

- (void)didMoveToWindow {
    %orig;
    SPK_PERF_SCOPE(@"HideTrendingSearches.didMoveToWindow");
    if (SPKIsLegacyExploreSearchPillBar(self))
        SPKHideTrendingSearchesBar(self);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize result = %orig;
    if (SPKIsLegacyExploreSearchPillBar(self))
        result.height = 0.0;
    return result;
}

- (CGSize)sizeThatFits:(CGSize)size expanded:(BOOL)expanded {
    CGSize result = %orig;
    if (SPKIsLegacyExploreSearchPillBar(self))
        result.height = 0.0;
    return result;
}

%end
%end

%group SPKHideTrendingSearchesModernHooks

%hook IGExploreChipBarView

- (void)didMoveToWindow {
    %orig;
    if ([(UIView *)self window])
        SPKHideTrendingSearchesBar(self);
}

- (void)layoutSubviews {
    %orig;
    SPKHideTrendingSearchesBar(self);
}

- (void)configureWith:(id)topics {
    %orig;
    SPKHideTrendingSearchesBar(self);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize result = %orig;
    result.height = 0.0;
    return result;
}

- (CGSize)sizeThatFits:(CGSize)size expanded:(BOOL)expanded {
    CGSize result = %orig;
    result.height = 0.0;
    return result;
}

%end
%end

%group SPKHideTrendingSearchesExploreControllerHooks

%hook IGExploreViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    SPKApplyTrendingSearchesToExploreController(self);
}

- (void)viewDidLayoutSubviews {
    %orig;
    SPKApplyTrendingSearchesToExploreController(self);
}

%end
%end

void SPKInstallHideTrendingSearchesHooksIfEnabled(void) {
    // This feature is intentionally restart-gated. When disabled, no Explore
    // classes are hooked at all, leaving Instagram's chip-bar creation and
    // measurement path completely stock.
    if (![SPKUtils getBoolPref:@"interface_hide_trending_searches"])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKHideTrendingSearchesLegacyHooks);
        %init(SPKHideTrendingSearchesExploreControllerHooks);

        gSPKModernExploreChipBarClass = SPKResolveIGClass(@"IGExploreChipBar.IGExploreChipBarView", nil);
        if (gSPKModernExploreChipBarClass) {
            %init(SPKHideTrendingSearchesModernHooks,
                  IGExploreChipBarView = gSPKModernExploreChipBarClass);
        }

        SPKLog(@"General", @"[Sparkle HideTrendingSearches] hooks installed modernChipBar=%@",
               gSPKModernExploreChipBarClass ? NSStringFromClass(gSPKModernExploreChipBarClass) : @"missing");
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UIWindow *window in UIApplication.sharedApplication.windows)
                SPKFindLiveExploreControllers(window.rootViewController);
        });
    });
}
