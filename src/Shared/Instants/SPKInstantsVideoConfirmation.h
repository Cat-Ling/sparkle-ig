#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Feeds the on-screen QuickSnap shutter's long-press lifecycle into video
/// confirmation. The receiver validates that the button belongs to the modern
/// QuickSnap camera before arming the writer-completion gate.
FOUNDATION_EXPORT void SPKInstantsVideoConfirmationHandleLongPress(UIView *captureButton,
                                                                   UIGestureRecognizer *gesture);

NS_ASSUME_NONNULL_END
