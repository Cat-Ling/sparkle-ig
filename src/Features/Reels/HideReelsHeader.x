#import "HideReelsHeader.h"
#import "../../Utils.h"
#import "../../App/SPKPerfMeter.h"

NSNotificationName const SPKHideReelsHeaderDidChangeNotification = @"SPKHideReelsHeaderDidChangeNotification";

// Marks a bar Sparkle hid, so turning the preference off only ever restores bars we took down and
// never overrides Instagram hiding its own chrome.
static char kSPKReelsHeaderHiddenKey;

// Bars stay alive for the whole session, so a live preference change has to reach the ones already
// on screen. Weak membership keeps a dismissed viewer's bar from being held here.
static NSHashTable<UIView *> *SPKLiveReelsHeaders(void) {
    static NSHashTable *headers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headers = [NSHashTable weakObjectsHashTable];
    });
    return headers;
}

// Hiding is reversible: removing the bar from its superview drops the constraints that position it
// and there is no faithful way to put it back, so visibility is what gets toggled.
static void SPKApplyReelsHeaderVisibility(UIView *bar) {
    BOOL hide = [SPKUtils getBoolPref:@"reels_hide_header"];
    BOOL hiddenBySparkle = [objc_getAssociatedObject(bar, &kSPKReelsHeaderHiddenKey) boolValue];

    if (hide && !hiddenBySparkle) {
        SPKLog(@"General", @"[Sparkle] Hiding reels header %@", NSStringFromClass([bar class]));
        bar.hidden = YES;
        objc_setAssociatedObject(bar, &kSPKReelsHeaderHiddenKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (!hide && hiddenBySparkle) {
        SPKLog(@"General", @"[Sparkle] Restoring reels header %@", NSStringFromClass([bar class]));
        bar.hidden = NO;
        objc_setAssociatedObject(bar, &kSPKReelsHeaderHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void SPKTrackReelsHeader(UIView *bar) {
    SPK_PERF_SCOPE(@"HideReelsHeader.didMoveToWindow");

    [SPKLiveReelsHeaders() addObject:bar];
    SPKApplyReelsHeaderVisibility(bar);
}

// Two navigation bar implementations ship side by side and which one the reels viewer builds is
// decided server side, so both are hooked. The Swift bar is the one in use on current builds; the
// older bar is kept for IG 410, which is the last version supported on iOS 15.
%group SPKHideReelsHeaderHooks

// Demangled: IGSundialViewerNavigationBarSwift.IGSundialViewerNavigationBar
%hook _TtC33IGSundialViewerNavigationBarSwift28IGSundialViewerNavigationBar
- (void)didMoveToWindow {
    %orig;
    SPKTrackReelsHeader(self);
}

// Instagram restoring its own chrome would otherwise undo the hide for the rest of the session.
- (void)setHidden:(BOOL)hidden {
    if (!hidden && [SPKUtils getBoolPref:@"reels_hide_header"]) {
        return %orig(YES);
    }
    %orig;
}
%end

%hook IGSundialViewerNavigationBarOld
- (void)didMoveToWindow {
    %orig;
    SPKTrackReelsHeader(self);
}

- (void)setHidden:(BOOL)hidden {
    if (!hidden && [SPKUtils getBoolPref:@"reels_hide_header"]) {
        return %orig(YES);
    }
    %orig;
}
%end

%end

void SPKInstallHideReelsHeaderHooksIfEnabled(void) {
    if (![SPKUtils getBoolPref:@"reels_hide_header"])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKHideReelsHeaderHooks);

        // Reconcile bars already built when the preference is turned off from settings.
        [[NSNotificationCenter defaultCenter] addObserverForName:SPKHideReelsHeaderDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(__unused NSNotification *note) {
            for (UIView *bar in [SPKLiveReelsHeaders() allObjects]) {
                SPKApplyReelsHeaderVisibility(bar);
            }
        }];
    });
}
