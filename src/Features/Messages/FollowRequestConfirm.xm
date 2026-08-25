#import "SPKStrings.h"
#import "../../Utils.h"

%group SPKFollowRequestConfirmHooks

%hook IGPendingRequestView
- (void)_onApproveButtonTapped {
    if ([SPKUtils getBoolPref:@"msgs_confirm_follow_request"]) {
        SPKLog(@"General", @"[Sparkle] Confirm follow request triggered");

        [SPKUtils
            showConfirmation:^(void) {
                %orig;
            }
                       title:SPKL(@"MESSAGES_FOLLOW_REQUEST_CONFIRM_CONFIRM_ACCEPT_REQUEST_TEXT")
                     message:SPKL(@"MESSAGES_FOLLOW_REQUEST_CONFIRM_ACCEPT_FOLLOW_REQUEST_CONFIRMATION_MESSAGE")];
    } else {
        return %orig;
    }
}
- (void)_onIgnoreButtonTapped {
    if ([SPKUtils getBoolPref:@"msgs_confirm_follow_request"]) {
        SPKLog(@"General", @"[Sparkle] Confirm follow request triggered");

        [SPKUtils
            showConfirmation:^(void) {
                %orig;
            }
                       title:SPKL(@"MESSAGES_FOLLOW_REQUEST_CONFIRM_CONFIRM_DECLINE_REQUEST_TEXT")
                     message:SPKL(@"MESSAGES_FOLLOW_REQUEST_CONFIRM_DECLINE_FOLLOW_REQUEST_CONFIRMATION_MESSAGE")];
    } else {
        return %orig;
    }
}
%end

%end

extern "C" void SPKInstallFollowRequestConfirmHooksIfEnabled(void) {
    if (![SPKUtils getBoolPref:@"msgs_confirm_follow_request"])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKFollowRequestConfirmHooks);
    });
}
