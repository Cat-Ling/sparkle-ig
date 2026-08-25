#import "SPKStrings.h"
#import "../../Utils.h"

#ifdef __cplusplus
extern "C" {
#endif
void SPKMarkDirectThreadSeenAfterReaction(id source);
#ifdef __cplusplus
}
#endif

#pragma mark - Hook group

%group SPKDMInteractionConfirmHooks

// ─── Double-tap like ────────────────────────────────────────────────

%hook IGDirectMessageSectionController

- (void)messageCellDidDoubleTap:(id)cell {
    if (![SPKUtils getBoolPref:@"msgs_confirm_double_tap"]) {
        %orig;
        SPKMarkDirectThreadSeenAfterReaction(self);
        return;
    }

    [SPKUtils
        showConfirmation:^{
            %orig;
            SPKMarkDirectThreadSeenAfterReaction(self);
        }
                   title:SPKL(@"MESSAGES_DMINTERACTION_CONFIRM_CONFIRM_MESSAGE_DOUBLE_TAP_MESSAGE")
                 message:SPKL(@"MESSAGES_DMINTERACTION_CONFIRM_DOUBLE_TAP_MESSAGE_CONFIRMATION_MESSAGE")];
}

%end

// ─── Emoji reaction picker ──────────────────────────────────────────
// When the user long-presses a message and picks an emoji, the call
// chain is:
//
//   IGDirectMessageReactionSelectionViewController
//       -reactionContainerView:didSelectEmojiAtIndex:       ← we hook HERE
//           → internally delegates to IGDirectMessageReactionController
//               -messageReactionSelectionViewController:didToggleEmoji:...
//
// We ONLY hook the picker VC entry point. Hooking the delegate too
// causes a double-prompt because %orig on the picker method cascades
// into the delegate.

%hook IGDirectMessageReactionSelectionViewController

- (void)reactionContainerView:(id)containerView didSelectEmojiAtIndex:(NSInteger)index {
    if (![SPKUtils getBoolPref:@"msgs_confirm_reaction"]) {
        %orig;
        SPKMarkDirectThreadSeenAfterReaction(self);
        return;
    }

    [SPKUtils
        showConfirmation:^{
            %orig;
            SPKMarkDirectThreadSeenAfterReaction(self);
        }
                   title:SPKL(@"MESSAGES_DMINTERACTION_CONFIRM_CONFIRM_MESSAGE_REACTION_MESSAGE")
                 message:SPKL(@"MESSAGES_DMINTERACTION_CONFIRM_REACT_MESSAGE_CONFIRMATION_MESSAGE")];
}

%end

%end // group SPKDMInteractionConfirmHooks

#pragma mark - Entry point

extern "C" void SPKInstallDMInteractionConfirmHooksIfEnabled(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKDMInteractionConfirmHooks);
    });
}
