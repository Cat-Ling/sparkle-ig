#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Builds a menu element for IG's native Direct menu (`IGDSPrismMenu`).
///
/// IG's menu takes a fixed array of elements at init, so there is no deferred
/// element here the way `UIMenu` has one: whatever a row displays must be known
/// before the menu is constructed.
///
/// `templateElement` is an existing element from the menu being built; its
/// private `_subtype` is copied so the injected row renders like IG's own.
/// Returns nil when IG's builder classes or ivars are not shaped as expected.
FOUNDATION_EXPORT id _Nullable SPKDirectPrismMenuElement(id templateElement,
                                                         NSString *title,
                                                         UIImage *_Nullable image,
                                                         void (^handler)(void));

/// As above, plus a secondary line when the running IG build's item builder
/// supports one. The subtitle is dropped rather than failing when it does not.
FOUNDATION_EXPORT id _Nullable SPKDirectPrismMenuElementWithSubtitle(id templateElement,
                                                                     NSString *title,
                                                                     NSString *_Nullable subtitle,
                                                                     UIImage *_Nullable image,
                                                                     void (^handler)(void));

/// YES for an element built by the functions above.
///
/// IG re-inits a menu with the array it was previously given, so an injector
/// that is not consumed on first use sees its own rows come back around. Check
/// this before adding a row a second time.
FOUNDATION_EXPORT BOOL SPKDirectMenuContainsSparkleRow(NSArray *_Nullable elements);

NS_ASSUME_NONNULL_END
