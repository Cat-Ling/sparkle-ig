#import "SPKStrings.h"
#import "../../Utils.h"

%group SPKStickerInteractConfirmHooks

%hook IGStoryViewerTapTarget
- (void)_didTap:(id)arg1 forEvent:(id)arg2 {
    if ([SPKUtils getBoolPref:@"stories_confirm_sticker"]) {
        SPKLog(@"General", @"[Sparkle] Confirm sticker interact triggered");

        [SPKUtils
            showConfirmation:^(void) {
                %orig;
            }
                       title:SPKL(@"STORIES_CONFIRMATIONS_CONFIRM_STICKER_INTERACTION_TITLE")
                     message:SPKL(@"STORIES_STICKER_INTERACT_CONFIRM_INTERACT_STORY_STICKER_CONFIRMATION_MESSAGE")];
    } else {
        return %orig;
    }
}
%end

%end

void SPKInstallStickerInteractConfirmHooksIfEnabled(void) {
    if (![SPKUtils getBoolPref:@"stories_confirm_sticker"])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKStickerInteractConfirmHooks);
    });
}
