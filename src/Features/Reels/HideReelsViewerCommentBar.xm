#import "../../InstagramHeaders.h"
#import "../../Utils.h"

static CGFloat SPKCommentContentViewTabBarInset(UIView *view) {
    CGFloat inset = 0.0;
    @try {
        id val = [view valueForKey:@"cachedTabBarBottomInset"];
        if ([val respondsToSelector:@selector(doubleValue)]) {
            inset = [val doubleValue];
        }
    } @catch (__unused NSException *e) {}
    return MAX(0.0, inset);
}

static BOOL SPKModernReelsViewerBarIsCommentBar(_TtC19IGSundialFeedFooter24IGSundialViewerBottomBar *bar) {
    Class commentConfigClass = NSClassFromString(@"_TtC19IGSundialFeedFooter37IGSundialViewerBottomBarCommentConfig");
    return commentConfigClass && [bar.config isKindOfClass:commentConfigClass];
}

%group SPKModernReelsViewerCommentBarHooks

%hook _TtC19IGSundialFeedFooter24IGSundialViewerBottomBar

- (CGSize)sizeThatFits:(CGSize)size {
    if (SPKModernReelsViewerBarIsCommentBar(self)) {
        UIView *cv = nil;
        @try {
            cv = [self valueForKey:@"contentView"];
        } @catch (__unused NSException *e) {}
        if (cv) {
            return [cv sizeThatFits:size];
        }
        return CGSizeMake(size.width, 0.0);
    }
    return %orig(size);
}

%end

// Hides only the comment composer UI (the pill container, text field, save button)
// while preserving any tab bar bottom insets on screens where the tab bar is shown.
%hook _TtC19IGSundialFeedFooter42IGSundialViewerBottomBarCommentContentView

- (void)didMoveToWindow {
    %orig;
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
    }
}

- (void)layoutSubviews {
    %orig;
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat tabInset = SPKCommentContentViewTabBarInset(self);
    return CGSizeMake(size.width, tabInset);
}

%end

%end

%group SPKLegacyReelsViewerCommentBarHooks

%hook IGSundialViewerBottomBar

- (instancetype)initWithCTAButtonType:(NSInteger)type
                   fakeComposerEnabled:(BOOL)enabled
                      commentBarDisabled:(BOOL)disabled {
    // Only disable the fake comment composer while preserving the commentBarDisabled flag
    // (modifying commentBarDisabled causes IGSundialFeedViewController to hide the tab bar).
    return %orig(type, NO, disabled);
}

%end

%end


extern "C" void SPKInstallHideReelsViewerCommentBarHooksIfEnabled(void) {
    if (![SPKUtils getBoolPref:@"reels_hide_viewer_comment_bar"])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL installedModern = NSClassFromString(@"_TtC19IGSundialFeedFooter24IGSundialViewerBottomBar") != Nil;
        BOOL installedLegacy = NSClassFromString(@"IGSundialViewerBottomBar") != Nil;

        if (installedModern)
            %init(SPKModernReelsViewerCommentBarHooks);
        if (installedLegacy)
            %init(SPKLegacyReelsViewerCommentBarHooks);

        SPKLog(@"Reels", @"Hide viewer comment bar hooks installed modern=%d legacy=%d",
               installedModern,
               installedLegacy);
    });
}
