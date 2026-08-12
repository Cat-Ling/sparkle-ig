#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SPKAutoSaveFilterConfig;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// This surface's filter: mode + dual lists, keyed by username.
///
/// Username rather than pk because that's all a resolved snap carries -- Instants have
/// no author pk on the item -- which also means the list can be curated by typing a
/// username without a lookup round-trip.
SPKAutoSaveFilterConfig *SPKInstantsAutoSaveFilterConfig(void);

BOOL SPKInstantsAutoSaveAllUsersMode(void);
NSString *SPKInstantsAutoSaveListTitle(void);
BOOL SPKInstantsAutoSaveAppliesToUsername(NSString *_Nullable username);
UIViewController *SPKInstantsAutoSaveListViewController(void);
/// One-line state for the Downloads > Auto-Save surfaces row.
NSString *SPKInstantsAutoSaveSettingsSummary(void);

#pragma mark - Current-user rule (action menu)

/// Menu title for toggling the on-screen instant's author, e.g. "Auto-Save @user".
/// Nil when no username could be read, which is what hides the action.
NSString *_Nullable SPKInstantsAutoSaveActionTitleForUsername(NSString *_Nullable username);
NSString *_Nullable SPKInstantsAutoSaveConfirmationTitleForUsername(NSString *_Nullable username);
NSString *_Nullable SPKInstantsAutoSaveConfirmationMessageForUsername(NSString *_Nullable username);

/// Adds or removes `username` from the filter list. Returns NO when the username is
/// unusable. On success the out-params carry the notification copy for the caller.
BOOL SPKInstantsToggleAutoSaveForUsername(NSString *_Nullable username,
                                          NSString *_Nullable *_Nullable notificationTitle,
                                          NSString *_Nullable *_Nullable notificationSubtitle);

/// Considers an already-resolved snap for auto-save. Resolution lives in the feature
/// hook (the Instants resolver is ObjC++), so this takes the snap object -- the download
/// pipeline duck-types it via its `sparkle*URL` properties, exactly as the action button
/// does.
///
/// `snapKey` is any stable identity for the snap; the caller owns deriving it, since a
/// view-resolved snap often has no media pk to use.
void SPKInstantsAutoSaveConsiderSnap(id _Nullable snap, NSString *_Nullable username, NSString *_Nullable snapKey);
/// Clears the per-session dedupe set when the Instants viewer closes.
void SPKInstantsAutoSaveViewerSessionDidEnd(void);

/// Re-considers the instant currently on screen. Implemented in the feature hook,
/// which owns snap resolution. `viewInHierarchy` is any view in the viewer's window.
void SPKInstantsAutoSaveConsiderCurrentSnapInView(UIView *_Nullable viewInHierarchy);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
