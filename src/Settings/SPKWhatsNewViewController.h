#import "../Shared/UI/SPKPagedSheetViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// A release-notes sheet shown once after upgrading to a new Sparkle version.
/// Feature releases split it across pages; a hotfix uses a single page. A thin
/// subclass of `SPKPagedSheetViewController`; present it
/// with `+presentFromViewController:onFinish:` and stamp `app_last_whatsnew_version`
/// from the `onFinish` block.
@interface SPKWhatsNewViewController : SPKPagedSheetViewController
@end

NS_ASSUME_NONNULL_END
