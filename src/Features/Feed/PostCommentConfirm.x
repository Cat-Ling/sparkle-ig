#import "SPKStrings.h"
#import "../../Utils.h"

%group SPKPostCommentConfirmHooks

%hook IGCommentComposer.IGCommentComposerController
- (void)onSendButtonTap {
    if ([SPKUtils getBoolPref:@"feed_confirm_post_comment"]) {
        SPKLog(@"General", @"[Sparkle] Confirm post comment triggered");

        [SPKUtils
            showConfirmation:^(void) {
                %orig;
            }
                       title:SPKL(@"FEED_POST_COMMENT_CONFIRM_CONFIRM_COMMENT_POST_TEXT")
                     message:SPKL(@"FEED_POST_COMMENT_CONFIRM_POST_COMMENT_CONFIRMATION_MESSAGE")];
    } else {
        return %orig;
    }
}
%end

%end

void SPKInstallPostCommentConfirmHooksIfEnabled(void) {
    if (![SPKUtils getBoolPref:@"feed_confirm_post_comment"])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKPostCommentConfirmHooks);
    });
}
