#import "../../Utils.h"
#import "../../App/SPKStabilityGuard.h"
#import "../../AssetUtils.h"
#import "../../Shared/Account/SPKAccountManager.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "../../App/SPKPerfMeter.h"

static const void *kSPKSavedTabIntentPendingKey = &kSPKSavedTabIntentPendingKey;
static const void *kSPKSavedTabFallbackHostKey = &kSPKSavedTabFallbackHostKey;
static const void *kSPKSavedTabButtonKey = &kSPKSavedTabButtonKey;
static const void *kSPKSavedTabButtonIdentityKey = &kSPKSavedTabButtonIdentityKey;
static const void *kSPKSavedTabOriginalImagesKey = &kSPKSavedTabOriginalImagesKey;
static const void *kSPKSavedTabOriginalLabelKey = &kSPKSavedTabOriginalLabelKey;

static NSUInteger spk_savedTabRoutingBypassGeneration = 0;
static NSTimeInterval spk_savedTabRoutingBypassDeadline = 0;

static BOOL SPKSavedTabRoutingBypassActive(void) {
    return spk_savedTabRoutingBypassDeadline > NSDate.timeIntervalSinceReferenceDate;
}

extern "C" void SPKBeginSavedTabRoutingBypass(void) {
    NSUInteger generation = ++spk_savedTabRoutingBypassGeneration;
    spk_savedTabRoutingBypassDeadline = NSDate.timeIntervalSinceReferenceDate + 2.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (spk_savedTabRoutingBypassGeneration == generation) {
            spk_savedTabRoutingBypassDeadline = 0;
        }
    });
}

extern "C" void SPKEndSavedTabRoutingBypass(void) {
    ++spk_savedTabRoutingBypassGeneration;
    spk_savedTabRoutingBypassDeadline = 0;
}

static BOOL SPKReplacesReelsWithSaved(void) {
    return [SPKUtils getBoolPref:@"interface_replace_reels_with_saved"];
}

static BOOL SPKSavedTabPreferenceMayEnable(void) {
    NSString *baseKey = @"interface_replace_reels_with_saved";
    NSDictionary<NSString *, id> *preferences = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;
    for (NSString *key in preferences) {
        if (([key isEqualToString:baseKey] || [key hasSuffix:[@"_" stringByAppendingString:baseKey]]) &&
            [preferences[key] respondsToSelector:@selector(boolValue)] &&
            [preferences[key] boolValue]) {
            return YES;
        }
    }
    return NO;
}

static BOOL SPKIsReelsSurface(IGMainAppSurfaceIntent *surface) {
    return [surface isKindOfClass:%c(IGMainAppSurfaceIntent)] &&
           [[surface tabStringFromSurfaceIntent] isEqualToString:@"CLIPS"];
}

static BOOL SPKIsSavedViewController(UIViewController *controller) {
    NSString *className = NSStringFromClass(controller.class);
    return [className containsString:@"SavedMediaCollectionsViewController"] ||
           [className containsString:@"IGSavedMediaViewController"];
}

static UINavigationController *SPKNativeSavedNavigationController(IGTabBarController *controller) {
    id manager = [SPKUtils getIvarForObj:controller name:"_viewControllerManager"];
    SEL selector = NSSelectorFromString(@"savedCollectionsNavigationController");
    if (!manager || ![manager respondsToSelector:selector])
        return nil;

    id candidate = ((id (*)(id, SEL))objc_msgSend)(manager, selector);
    return [candidate isKindOfClass:[UINavigationController class]] ? candidate : nil;
}

// Called from -layoutSubviews of every tab bar button, so the identifier match
// (which allocates a lowercased copy) is resolved once and cached. A button with
// no identifier yet is not cached: the answer is not knowable until Instagram
// sets one, and the tab bar controller tags the real button by ivar anyway.
static BOOL SPKIsReelsTabButton(IGTabBarButton *button) {
    if (objc_getAssociatedObject(button, kSPKSavedTabButtonKey))
        return YES;

    NSNumber *cachedIdentity = objc_getAssociatedObject(button, kSPKSavedTabButtonIdentityKey);
    if (cachedIdentity)
        return cachedIdentity.boolValue;

    NSString *identifier = button.accessibilityIdentifier;
    if (identifier.length == 0)
        return NO;

    NSString *normalized = identifier.lowercaseString;
    BOOL isReelsButton = [normalized containsString:@"reels"] || [normalized containsString:@"clips"];
    objc_setAssociatedObject(button, kSPKSavedTabButtonIdentityKey, @(isReelsButton), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return isReelsButton;
}

static UIImage *SPKSavedTabImage(BOOL filledImage) {
    static UIImage *outline;
    static UIImage *filled;
    if (filledImage) {
        if (!filled) {
            filled = [[SPKAssetUtils instagramIconNamed:@"save_filled" pointSize:24.0]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        return filled;
    }

    if (!outline) {
        outline = [[SPKAssetUtils instagramIconNamed:@"save" pointSize:24.0]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return outline;
}

static void SPKRememberOriginalTabImage(UIButton *button, UIControlState state, UIImage *image) {
    if (!image || image == SPKSavedTabImage(NO) || image == SPKSavedTabImage(YES))
        return;

    NSMutableDictionary<NSNumber *, UIImage *> *originalImages = objc_getAssociatedObject(button, kSPKSavedTabOriginalImagesKey);
    if (!originalImages) {
        originalImages = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(button, kSPKSavedTabOriginalImagesKey, originalImages, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    originalImages[@(state)] = image;
}

static void SPKConfigureSavedTabButtonInstance(UIButton *button) {
    if (![button isKindOfClass:[UIButton class]])
        return;

    objc_setAssociatedObject(button, kSPKSavedTabButtonKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIControlState states[] = {
        UIControlStateNormal,
        UIControlStateHighlighted,
        UIControlStateSelected,
        UIControlStateSelected | UIControlStateHighlighted,
    };

    if (!SPKReplacesReelsWithSaved()) {
        NSDictionary<NSNumber *, UIImage *> *originalImages = objc_getAssociatedObject(button, kSPKSavedTabOriginalImagesKey);
        for (NSUInteger index = 0; index < sizeof(states) / sizeof(states[0]); index++) {
            UIControlState state = states[index];
            UIImage *originalImage = originalImages[@(state)];
            if (originalImage && [button imageForState:state] != originalImage) {
                [button setImage:originalImage forState:state];
            }
        }
        NSString *originalLabel = objc_getAssociatedObject(button, kSPKSavedTabOriginalLabelKey);
        if (originalLabel && [button.accessibilityLabel isEqualToString:@"Saved"]) {
            button.accessibilityLabel = originalLabel;
        }
        return;
    }

    if (!objc_getAssociatedObject(button, kSPKSavedTabOriginalLabelKey) &&
        button.accessibilityLabel.length > 0 &&
        ![button.accessibilityLabel isEqualToString:@"Saved"]) {
        objc_setAssociatedObject(button, kSPKSavedTabOriginalLabelKey, button.accessibilityLabel, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    for (NSUInteger index = 0; index < sizeof(states) / sizeof(states[0]); index++) {
        UIControlState state = states[index];
        SPKRememberOriginalTabImage(button, state, [button imageForState:state]);
    }

    UIImage *outline = SPKSavedTabImage(NO);
    UIImage *filled = SPKSavedTabImage(YES);

    if (outline && [button imageForState:UIControlStateNormal] != outline) {
        [button setImage:outline forState:UIControlStateNormal];
    }
    if (outline && [button imageForState:UIControlStateHighlighted] != outline) {
        [button setImage:outline forState:UIControlStateHighlighted];
    }
    if (filled && [button imageForState:UIControlStateSelected] != filled) {
        [button setImage:filled forState:UIControlStateSelected];
    }
    if (filled && [button imageForState:UIControlStateSelected | UIControlStateHighlighted] != filled) {
        [button setImage:filled forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    if (![button.accessibilityLabel isEqualToString:@"Saved"]) {
        button.accessibilityLabel = @"Saved";
    }
}

static void SPKConfigureSavedTabButton(IGTabBarController *controller) {
    UIButton *button = [SPKUtils getIvarForObj:controller name:"_discoverVideoButton"];
    SPKConfigureSavedTabButtonInstance(button);
}

// Containment only. -presentedViewController resolves through the ancestor chain,
// so every child would re-walk the same presented subtree and the sweep would cost
// exponential time on a deep hierarchy. The tab bar controller is never inside a
// presentation, so there is nothing down there to find anyway.
static IGTabBarController *SPKFindTabBarController(UIViewController *controller) {
    if (!controller)
        return nil;
    if ([controller isKindOfClass:%c(IGTabBarController)])
        return (IGTabBarController *)controller;

    for (UIViewController *child in controller.childViewControllers) {
        IGTabBarController *childMatch = SPKFindTabBarController(child);
        if (childMatch)
            return childMatch;
    }
    return nil;
}

static void SPKConfigureExistingSavedTabButton(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]])
            continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            IGTabBarController *controller = SPKFindTabBarController(window.rootViewController);
            if (controller) {
                SPKConfigureSavedTabButton(controller);
                return;
            }
        }
    }

    IGTabBarController *controller = SPKFindTabBarController(UIApplication.sharedApplication.keyWindow.rootViewController);
    SPKConfigureSavedTabButton(controller);
}

static void SPKScheduleSavedTabButtonReconciliation(void) {
    SPKConfigureExistingSavedTabButton();
    for (NSNumber *delay in @[ @0.25, @1.0 ]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            SPKConfigureExistingSavedTabButton();
        });
    }
}

static void SPKFinishSavedTabIntent(UINavigationController *navigationController, NSUInteger attempt) {
    UIViewController *top = navigationController.topViewController;
    if (SPKIsSavedViewController(top)) {
        if (objc_getAssociatedObject(navigationController, kSPKSavedTabFallbackHostKey) &&
            navigationController.viewControllers.count != 1) {
            [navigationController setViewControllers:@[ top ] animated:NO];
        }
        objc_setAssociatedObject(navigationController, kSPKSavedTabIntentPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (attempt >= 12) {
        SPKLog(@"TabBar", @"[Sparkle] Timed out waiting for Instagram's Saved controller");
        objc_setAssociatedObject(navigationController, kSPKSavedTabIntentPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SPKFinishSavedTabIntent(navigationController, attempt + 1);
    });
}

static void SPKOpenSavedInFallbackNavigationController(IGTabBarController *tabBarController,
                                                        UINavigationController *navigationController) {
    if (!navigationController || SPKIsSavedViewController(navigationController.topViewController))
        return;
    if (objc_getAssociatedObject(navigationController, kSPKSavedTabIntentPendingKey))
        return;

    // -fb_intentHandler is a stored per-controller association rather than
    // something every controller carries, so it answers nil unless something
    // installed a handler on that exact object. Newer builds set one on the tab's
    // navigation controller; IG 410 sets none anywhere reachable from this stack
    // (its -fb_fallbackIntentHandlingAncestorVC chain and the tab bar controller
    // were both checked on device and came back empty), so the URL route below is
    // the only way in there. That is expected, not a failure worth a line per tap.
    id<FBIntentHandler> handler = [navigationController respondsToSelector:@selector(fb_intentHandler)]
                                      ? [navigationController fb_intentHandler]
                                      : nil;
    if (![handler respondsToSelector:@selector(handleIntent:)]) {
        static dispatch_once_t noticeToken;
        dispatch_once(&noticeToken, ^{
            SPKLog(@"TabBar", @"[Sparkle] Saved intent handler unavailable; using instagram://saved for this session");
        });
        id userSession = [SPKUtils getIvarForObj:tabBarController name:"_userSession"];
        Class urlHandlerClass = NSClassFromString(@"IGURLHandler");
        SEL openSelector = NSSelectorFromString(@"openInternalURL:presentationConfig:controller:animated:userSession:annotation:");
        if ([urlHandlerClass respondsToSelector:openSelector]) {
            BOOL opened = ((BOOL (*)(id, SEL, id, id, id, BOOL, id, id))objc_msgSend)(urlHandlerClass,
                                                                                       openSelector,
                                                                                       [NSURL URLWithString:@"instagram://saved"],
                                                                                       nil,
                                                                                       navigationController,
                                                                                       NO,
                                                                                       userSession,
                                                                                       nil);
            if (opened) {
                objc_setAssociatedObject(navigationController, kSPKSavedTabIntentPendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(navigationController, kSPKSavedTabFallbackHostKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                SPKFinishSavedTabIntent(navigationController, 0);
            }
        }
        return;
    }

    Class targetClass = NSClassFromString(@"IGSaveHomeIntentTarget");
    id target = [targetClass alloc];
    SEL currentInitializer = NSSelectorFromString(@"initWithEntryModule:selectedTab:");
    if ([target respondsToSelector:currentInitializer]) {
        target = ((id (*)(id, SEL, id, id))objc_msgSend)(target, currentInitializer, @"tab_bar", nil);
    } else {
        SEL legacyInitializer = NSSelectorFromString(@"initWithEntryModule:");
        if ([target respondsToSelector:legacyInitializer]) {
            target = ((id (*)(id, SEL, id))objc_msgSend)(target, legacyInitializer, @"tab_bar");
        } else {
            target = nil;
        }
    }

    if (!target) {
        SPKLog(@"TabBar", @"[Sparkle] Unable to construct Instagram's Saved intent target");
        return;
    }

    objc_setAssociatedObject(navigationController, kSPKSavedTabIntentPendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(navigationController, kSPKSavedTabFallbackHostKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ((void (*)(id, SEL, id))objc_msgSend)(handler, @selector(handleIntent:), target);
    SPKFinishSavedTabIntent(navigationController, 0);
}

static void SPKEnsureSavedTabDestination(IGTabBarController *controller) {
    if (!SPKReplacesReelsWithSaved())
        return;

    UINavigationController *nativeSavedNavigationController = SPKNativeSavedNavigationController(controller);
    if (nativeSavedNavigationController)
        return;

    UIViewController *selected = controller.selectedViewController;
    UINavigationController *navigationController = [selected isKindOfClass:[UINavigationController class]]
                                                       ? (UINavigationController *)selected
                                                       : [controller discoverVideoNavigationController];
    SPKOpenSavedInFallbackNavigationController(controller, navigationController);
}

// Shared bookkeeping for the -_setSelectedTabBarSurface: overloads. The shorter
// one forwards to the longer on newer builds, so the work is keyed to the
// outermost call and runs exactly once per selection.
typedef struct {
    BOOL bypassesSaved;
    BOOL selectsSaved;
    BOOL isOutermost;
} SPKSavedTabSelection;

static NSUInteger spk_savedTabSelectionDepth = 0;

static SPKSavedTabSelection SPKBeginSavedTabSelection(IGMainAppSurfaceIntent *surface) {
    BOOL isReelsSurface = SPKIsReelsSurface(surface);
    BOOL bypassesSaved = isReelsSurface && SPKSavedTabRoutingBypassActive();
    SPKSavedTabSelection selection = {
        .bypassesSaved = bypassesSaved,
        .selectsSaved = isReelsSurface && !bypassesSaved && SPKReplacesReelsWithSaved(),
        .isOutermost = (spk_savedTabSelectionDepth == 0),
    };
    spk_savedTabSelectionDepth++;
    return selection;
}

static void SPKFinishSavedTabSelection(IGTabBarController *controller, SPKSavedTabSelection selection) {
    if (spk_savedTabSelectionDepth > 0) {
        spk_savedTabSelectionDepth--;
    }
    if (!selection.isOutermost)
        return;

    if (selection.bypassesSaved) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            SPKEndSavedTabRoutingBypass();
        });
    }
    if (selection.selectsSaved) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SPKConfigureSavedTabButton(controller);
            SPKEnsureSavedTabDestination(controller);
        });
    }
}

static NSString *SPKSelectorForLaunchTabPreference(NSString *preference) {
    if ([preference isEqualToString:@"feed"])
        return @"_timelineButtonPressed";
    if ([preference isEqualToString:@"reels"])
        return @"_discoverVideoButtonPressed";
    if ([preference isEqualToString:@"inbox"])
        return @"_directInboxButtonPressed";
    if ([preference isEqualToString:@"explore"])
        return @"_exploreButtonPressed";
    if ([preference isEqualToString:@"profile"])
        return @"_profileButtonPressed";
    return nil;
}

static NSString *SPKSelectorForSurfaceIntent(IGMainAppSurfaceIntent *surface) {
    if (!surface || ![surface isKindOfClass:%c(IGMainAppSurfaceIntent)])
        return nil;
    NSString *tab = [surface tabStringFromSurfaceIntent];
    if ([tab isEqualToString:@"FEED"])
        return @"_timelineButtonPressed";
    if ([tab isEqualToString:@"CLIPS"])
        return @"_discoverVideoButtonPressed";
    if ([tab isEqualToString:@"DIRECT"])
        return @"_directInboxButtonPressed";
    if ([tab isEqualToString:@"SEARCH"])
        return @"_exploreButtonPressed";
    if ([tab isEqualToString:@"PROFILE"])
        return @"_profileButtonPressed";
    return nil;
}

BOOL isSurfaceShown(IGMainAppSurfaceIntent *surface) {
    if (SPKStabilityGuardIsSafeStartupMode()) {
        return YES;
    }
    BOOL isShown = YES;

    // Feed
    if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"FEED"] && [SPKUtils getBoolPref:@"interface_hide_feed_tab"]) {
        isShown = NO;
    }

    // Reels
    else if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"CLIPS"] && [SPKUtils getBoolPref:@"interface_hide_reels_tab"]) {
        isShown = NO;
    }

    // Messages
    else if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"DIRECT"] && [SPKUtils getBoolPref:@"interface_hide_msgs_tab"]) {
        isShown = NO;
    }

    // Explore
    else if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"SEARCH"] && [SPKUtils getBoolPref:@"interface_hide_explore_tab"]) {
        isShown = NO;
    }

    // Profile
    else if ([[surface tabStringFromSurfaceIntent] isEqualToString:@"PROFILE"] && [SPKUtils getBoolPref:@"interface_hide_profile_tab"]) {
        isShown = NO;
    }

    // Create
    else if ([(NSNumber *)[surface valueForKey:@"_subtype"] unsignedIntegerValue] == 3 && [SPKUtils getBoolPref:@"interface_hide_create_tab"]) {
        isShown = NO;
    }

    return isShown;
}

NSArray *filterSurfacesArray(NSArray *surfaces) {
    NSMutableArray *filteredSurfaces = [NSMutableArray array];

    for (IGMainAppSurfaceIntent *surface in surfaces) {
        if (![surface isKindOfClass:%c(IGMainAppSurfaceIntent)])
            break;

        if (isSurfaceShown(surface)) {
            [filteredSurfaces addObject:surface];
        }
    }

    return filteredSurfaces;
}

static BOOL SPKIsMessagesOnlyMode(void) {
    BOOL msgsVisible = ![SPKUtils getBoolPref:@"interface_hide_msgs_tab"];
    BOOL feedHidden = [SPKUtils getBoolPref:@"interface_hide_feed_tab"];
    BOOL exploreHidden = [SPKUtils getBoolPref:@"interface_hide_explore_tab"];
    BOOL reelsHidden = [SPKUtils getBoolPref:@"interface_hide_reels_tab"];
    BOOL profileHidden = [SPKUtils getBoolPref:@"interface_hide_profile_tab"];
    
    BOOL usesClassic = [[SPKUtils getStringPref:@"interface_nav_order"] isEqualToString:@"classic"];
    BOOL createHidden = !usesClassic || [SPKUtils getBoolPref:@"interface_hide_create_tab"];
    
    return msgsVisible && feedHidden && exploreHidden && reelsHidden && profileHidden && createHidden;
}

///////////////////////////////////////////////

// Installed separately from the rest of the navigation hooks: this one runs on
// every layout pass of every tab bar button, so users who only reordered or hid
// tabs should not pay for it.
//
// -layoutSubviews is the only re-entry point worth hooking here. The obvious
// alternatives, -setImage:forState: and -setAccessibilityIdentifier:, are
// inherited from UIButton/UIView rather than implemented by IGTabBarButton, and
// hooking a method a class only inherits does not reliably bind. Re-applying the
// icon on the next layout pass covers the same ground: whenever Instagram puts
// its own image back, the pass that follows swaps it out again.
%group SPKSavedTabButtonHooks

%hook IGTabBarButton
- (void)layoutSubviews {
    %orig;
    if (SPKIsReelsTabButton(self)) {
        SPKConfigureSavedTabButtonInstance(self);
    }
}
%end

%end

%group SPKNavigationHooks

%hook IGTabBarControllerSwipeCoordinator
- (id)initWithSurfaces:(id)surfaces parentViewController:(id)controller enableHaptics:(_Bool)haptics launcherSet:(id)set {
    // Removes the surface from the main swipeable app collection view
    return %orig(filterSurfacesArray(surfaces), controller, haptics, set);
}
%end

%hook IGTabBarController
- (void)viewDidLoad {
    %orig;
    NSArray *surfaces = [SPKUtils getIvarForObj:self name:"_tabBarSurfaces"];
    if (surfaces) {
        [SPKUtils setIvarForObj:self name:"_tabBarSurfaces" value:filterSurfacesArray(surfaces)];
    }
    SPKConfigureSavedTabButton(self);
}

- (void)_createAndConfigureReelsButtonIfNeeded {
    %orig;
    SPKConfigureSavedTabButton(self);
}

- (id)navigationViewControllerForAppSurfaceIntent:(IGMainAppSurfaceIntent *)surface {
    if (SPKReplacesReelsWithSaved() &&
        !SPKSavedTabRoutingBypassActive() &&
        SPKIsReelsSurface(surface)) {
        UINavigationController *savedNavigationController = SPKNativeSavedNavigationController(self);
        if (savedNavigationController)
            return savedNavigationController;
    }
    return %orig;
}

- (void)_discoverVideoButtonPressed {
    if (!SPKReplacesReelsWithSaved()) {
        %orig;
        return;
    }

    NSArray *surfaces = [SPKUtils getIvarForObj:self name:"_tabBarSurfaces"];
    IGMainAppSurfaceIntent *reelsSurface = nil;
    for (IGMainAppSurfaceIntent *surface in surfaces) {
        if (SPKIsReelsSurface(surface)) {
            reelsSurface = surface;
            break;
        }
    }

    if (!reelsSurface) {
        %orig;
        return;
    }

    [self setSelectedTabBarSurface:reelsSurface animated:YES];
    SPKConfigureSavedTabButton(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        SPKEnsureSavedTabDestination(self);
    });
}

- (void)_setSelectedTabBarSurface:(IGMainAppSurfaceIntent *)surface
                   isTabBarAction:(BOOL)isTabBarAction
                         animated:(BOOL)animated
                 navigationAction:(NSUInteger)navigationAction
                skipMainFeedFetch:(BOOL)skipMainFeedFetch {
    SPKSavedTabSelection selection = SPKBeginSavedTabSelection(surface);
    %orig;
    SPKFinishSavedTabSelection(self, selection);
}

// IG added a second overload carrying a trailing animateIndicator:, and call
// sites use whichever they were written against. Both have to do the same
// bookkeeping or the routing bypass is never torn down on the newer path.
- (void)_setSelectedTabBarSurface:(IGMainAppSurfaceIntent *)surface
                   isTabBarAction:(BOOL)isTabBarAction
                         animated:(BOOL)animated
                 navigationAction:(NSUInteger)navigationAction
                skipMainFeedFetch:(BOOL)skipMainFeedFetch
                  animateIndicator:(BOOL)animateIndicator {
    SPKSavedTabSelection selection = SPKBeginSavedTabSelection(surface);
    %orig;
    SPKFinishSavedTabSelection(self, selection);
}

- (void)viewDidLayoutSubviews {
    %orig;
    SPK_PERF_SCOPE(@"Navigation.viewDidLayoutSubviews");
    if (SPKStabilityGuardIsSafeStartupMode()) {
        return;
    }
    if ([SPKUtils getBoolPref:@"interface_hide_tab_bar_in_messages_only"] && SPKIsMessagesOnlyMode()) {
        self.tabBar.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;

    static BOOL appliedLaunchTab = NO;
    if (appliedLaunchTab)
        return;
    appliedLaunchTab = YES;

    NSString *launchPref = [SPKUtils getStringPref:@"interface_launch_tab"];
    NSString *selectorName = SPKSelectorForLaunchTabPreference(launchPref);

    NSArray *rawSurfaces = [SPKUtils getIvarForObj:self name:"_tabBarSurfaces"];
    NSArray *enabledSurfaces = filterSurfacesArray(rawSurfaces);

    BOOL feedHidden = [SPKUtils getBoolPref:@"interface_hide_feed_tab"];

    if ([launchPref isEqualToString:@"default"]) {
        BOOL feedIsEnabled = NO;
        for (IGMainAppSurfaceIntent *s in enabledSurfaces) {
            if ([[s tabStringFromSurfaceIntent] isEqualToString:@"FEED"]) {
                feedIsEnabled = YES;
                break;
            }
        }
        if ((!feedIsEnabled || feedHidden) && enabledSurfaces.count > 0) {
            selectorName = SPKSelectorForSurfaceIntent(enabledSurfaces.firstObject);
        } else if (feedHidden) {
            // Fallback preference check if surface array is unavailable
            if (![SPKUtils getBoolPref:@"interface_hide_msgs_tab"]) {
                selectorName = @"_directInboxButtonPressed";
            } else if (![SPKUtils getBoolPref:@"interface_hide_reels_tab"]) {
                selectorName = @"_discoverVideoButtonPressed";
            } else if (![SPKUtils getBoolPref:@"interface_hide_explore_tab"]) {
                selectorName = @"_exploreButtonPressed";
            } else if (![SPKUtils getBoolPref:@"interface_hide_profile_tab"]) {
                selectorName = @"_profileButtonPressed";
            }
        }
    } else if (selectorName.length > 0) {
        BOOL chosenIsEnabled = NO;
        for (IGMainAppSurfaceIntent *s in enabledSurfaces) {
            NSString *sel = SPKSelectorForSurfaceIntent(s);
            if ([sel isEqualToString:selectorName]) {
                chosenIsEnabled = YES;
                break;
            }
        }
        if (!chosenIsEnabled && enabledSurfaces.count > 0) {
            selectorName = SPKSelectorForSurfaceIntent(enabledSurfaces.firstObject);
        }
    }

    SEL selector = selectorName.length > 0 ? NSSelectorFromString(selectorName) : nil;
    if (selector && [self respondsToSelector:selector]) {
        ((void (*)(id, SEL))objc_msgSend)(self, selector);
    }

    if (!SPKStabilityGuardIsSafeStartupMode()) {
        if ([self respondsToSelector:@selector(_updateTabBarVisibilityForController:)] && self.selectedViewController) {
            [self _updateTabBarVisibilityForController:self.selectedViewController];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    SPKConfigureSavedTabButton(self);
    if (SPKStabilityGuardIsSafeStartupMode()) {
        return;
    }
    if ([SPKUtils getBoolPref:@"interface_hide_tab_bar_in_messages_only"] && SPKIsMessagesOnlyMode()) {
        if ([self respondsToSelector:@selector(_updateTabBarVisibilityForController:)] && self.selectedViewController) {
            [self _updateTabBarVisibilityForController:self.selectedViewController];
        }
    }
}

- (void)_layoutTabBar {
    // Prevents the wrong icon from being shown as selected because of mismatched surface array indexes
    NSArray *_tabBarSurfaces = [SPKUtils getIvarForObj:self name:"_tabBarSurfaces"];

    [SPKUtils setIvarForObj:self name:"_tabBarSurfaces" value:filterSurfacesArray(_tabBarSurfaces)];

    %orig;
    SPKConfigureSavedTabButton(self);
}

- (id)_buttonForTabBarSurface:(id)surface {
    // Prevents the button from being added to the tab bar
    id button = %orig(surface);

    if (!isSurfaceShown(surface)) {
        return nil;
    }

    return button;
}

- (BOOL)_shouldTabBarBeHiddenForController:(id)controller {
    if (SPKStabilityGuardIsSafeStartupMode()) {
        return %orig;
    }
    if ([SPKUtils getBoolPref:@"interface_hide_tab_bar_in_messages_only"] && SPKIsMessagesOnlyMode()) {
        return YES;
    }
    return %orig;
}
%end

// Demangled name: IGNavConfiguration.IGNavConfiguration
%hook _TtC18IGNavConfiguration18IGNavConfiguration
- (NSInteger)tabOrdering {

    if ([[SPKUtils getStringPref:@"interface_nav_order"] isEqualToString:@"classic"])
        return 0;
    else if ([[SPKUtils getStringPref:@"interface_nav_order"] isEqualToString:@"standard"])
        return 1;
    else if ([[SPKUtils getStringPref:@"interface_nav_order"] isEqualToString:@"alternate"])
        return 2;

    return %orig;
}
- (void)setTabOrdering:(NSInteger)arg1 {
    return;
}

- (BOOL)isTabSwipingEnabled {

    if ([[SPKUtils getStringPref:@"interface_swipe_tabs"] isEqualToString:@"enabled"])
        return YES;
    else if ([[SPKUtils getStringPref:@"interface_swipe_tabs"] isEqualToString:@"disabled"])
        return NO;

    return %orig;
}
- (void)setIsTabSwipingEnabled:(BOOL)arg1 {
    return;
}
%end

%hook IGHomeFeedHeaderView
- (void)didMoveToWindow {
    %orig;
    SPK_PERF_SCOPE(@"Navigation.didMoveToWindow");

    if ([SPKUtils getBoolPref:@"interface_hide_msgs_tab"]) {
        // IG 436+ is a Swift class: the DM button is the `directButton` @property
        // (KVC-safe). `rightButton` is a bare Swift ivar on 436 (KVC throws) but the
        // KVC key on older ObjC builds — resolve via selector first, guard the rest.
        UIView *msgsButton = nil;
        for (NSString *key in @[ @"directButton", @"rightButton" ]) {
            SEL getter = NSSelectorFromString(key);
            if (![self respondsToSelector:getter])
                continue;
            id candidate = ((id (*)(id, SEL))objc_msgSend)(self, getter);
            if ([candidate isKindOfClass:[UIView class]]) {
                msgsButton = candidate;
                break;
            }
        }
        if (msgsButton) {
            SPKLog(@"General", @"[Sparkle] Hiding messages tab (on feed)");

            [msgsButton removeFromSuperview];
        }
    }
}
%end

%hook IGMainAppScrollingContainerViewController
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if ([SPKUtils getBoolPref:@"interface_hide_feed_tab"]) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gesture;
            CGPoint velocity = [pan velocityInView:pan.view];
            CGPoint translation = [pan translationInView:pan.view];
            if (velocity.x > 0 || translation.x > 0) {
                UIViewController *activeVC = [self valueForKey:@"_activeViewController"];
                UIViewController *creationVC = [self valueForKey:@"_creationViewController"];
                if (activeVC && creationVC && activeVC != creationVC) {
                    return NO;
                }
            }
        }
    }
    return %orig;
}
%end

%end

extern "C" void SPKInstallNavigationHooksIfNeeded(void) {
    BOOL shouldInstall = SPKSavedTabPreferenceMayEnable() ||
                         ![[SPKUtils getStringPref:@"interface_nav_order"] isEqualToString:@"default"] ||
                         ![[SPKUtils getStringPref:@"interface_launch_tab"] isEqualToString:@"default"] ||
                         ![[SPKUtils getStringPref:@"interface_swipe_tabs"] isEqualToString:@"default"] ||
                         [SPKUtils getBoolPref:@"interface_hide_feed_tab"] ||
                         [SPKUtils getBoolPref:@"interface_hide_reels_tab"] ||
                         [SPKUtils getBoolPref:@"interface_hide_msgs_tab"] ||
                         [SPKUtils getBoolPref:@"interface_hide_explore_tab"] ||
                         [SPKUtils getBoolPref:@"interface_hide_profile_tab"] ||
                         [SPKUtils getBoolPref:@"interface_hide_create_tab"] ||
                         [SPKUtils getBoolPref:@"interface_hide_tab_bar_in_messages_only"];
    if (!shouldInstall)
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKNavigationHooks,
                       IGHomeFeedHeaderView = SPKResolveIGClass(@"IGHomeFeedHeader.IGHomeFeedHeaderView", @"IGHomeFeedHeaderView"));
        if (SPKSavedTabPreferenceMayEnable()) {
            %init(SPKSavedTabButtonHooks);
            [[NSNotificationCenter defaultCenter] addObserverForName:SPKAccountDidChangeNotification
                                                              object:nil
                                                               queue:NSOperationQueue.mainQueue
                                                          usingBlock:^(__unused NSNotification *notification) {
                SPKScheduleSavedTabButtonReconciliation();
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                SPKScheduleSavedTabButtonReconciliation();
            });
        }
    });
}
