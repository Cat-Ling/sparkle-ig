#import <Foundation/Foundation.h>

// Posted when the Hide Reels Header preference changes from the settings UI. The reels viewer
// builds its navigation bar once per session, so didMoveToWindow never fires again after the first
// attach and a bar hidden earlier would otherwise stay hidden until the next launch.
FOUNDATION_EXPORT NSNotificationName const SPKHideReelsHeaderDidChangeNotification;
