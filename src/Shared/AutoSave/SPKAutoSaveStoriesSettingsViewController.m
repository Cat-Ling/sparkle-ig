#import "SPKStrings.h"
#import "SPKAutoSaveStoriesSettingsViewController.h"

#import "../Instants/SPKInstantsAutoSave.h"
#import "../Messages/SPKDirectAutoSave.h"
#import "../Stories/SPKStoryAutoSave.h"
#import "SPKAutoSaveFilter.h"

@implementation SPKAutoSaveStoriesSettingsViewController

+ (SPKAutoSaveSurfaceDescriptor *)descriptor {
    static SPKAutoSaveSurfaceDescriptor *descriptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        descriptor = [SPKAutoSaveSurfaceDescriptor new];
        descriptor.filter = SPKStoryAutoSaveFilterConfig();
        descriptor.title = SPKL(@"STORIES_OTHER_STORIES_TITLE");
        descriptor.masterTitle = @"Auto-Save Stories";
        descriptor.listIcon = @"users";
        descriptor.listProvider = ^UIViewController * {
            return SPKStoryAutoSaveListViewController();
        };
        descriptor.footerProvider = ^NSString *(BOOL allMode) {
            return allMode ? SPKL(@"AUTO_SAVE_AUTO_SAVE_STORIES_SETTINGS_SAVE_STORIES_WATCH_STORIES_ALREADY_SKIPPED_SO_RE_WATCHING_TEXT")
                           : SPKL(@"AUTO_SAVE_STORIES_SELECTED_USERS_FOOTER");
        };
    });
    return descriptor;
}

@end

@implementation SPKAutoSaveMessagesSettingsViewController

+ (SPKAutoSaveSurfaceDescriptor *)descriptor {
    static SPKAutoSaveSurfaceDescriptor *descriptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        descriptor = [SPKAutoSaveSurfaceDescriptor new];
        descriptor.filter = SPKDirectAutoSaveFilterConfig();
        descriptor.title = SPKL(@"MESSAGES_CONFIRMATION_MESSAGES_TITLE");
        descriptor.masterTitle = SPKL(@"AUTO_SAVE_AUTO_SAVE_STORIES_SETTINGS_AUTO_SAVE_VIEW_ONCE_MEDIA_TEXT");
        descriptor.listIcon = @"messages";
        descriptor.listProvider = ^UIViewController * {
            return SPKDirectAutoSaveListViewController();
        };
        descriptor.footerProvider = ^NSString *(BOOL allMode) {
            return allMode ? SPKL(@"AUTO_SAVE_AUTO_SAVE_STORIES_SETTINGS_SAVE_VIEW_ONCE_REPLAYABLE_PHOTOS_VIDEOS_OPEN_MEDIA_ALREADY_TEXT")
                           : SPKL(@"AUTO_SAVE_VISUAL_MESSAGES_SELECTED_CHATS_FOOTER");
        };
    });
    return descriptor;
}

@end

@implementation SPKAutoSaveInstantsSettingsViewController

+ (SPKAutoSaveSurfaceDescriptor *)descriptor {
    static SPKAutoSaveSurfaceDescriptor *descriptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        descriptor = [SPKAutoSaveSurfaceDescriptor new];
        descriptor.filter = SPKInstantsAutoSaveFilterConfig();
        descriptor.title = SPKL(@"INSTANTS_CONFIRMATION_INSTANTS_TITLE");
        descriptor.masterTitle = SPKL(@"AUTO_SAVE_AUTO_SAVE_STORIES_SETTINGS_AUTO_SAVE_INSTANTS_TEXT");
        descriptor.listIcon = @"users";
        descriptor.listProvider = ^UIViewController * {
            return SPKInstantsAutoSaveListViewController();
        };
        descriptor.footerProvider = ^NSString *(BOOL allMode) {
            return allMode ? SPKL(@"AUTO_SAVE_AUTO_SAVE_STORIES_SETTINGS_SAVE_INSTANTS_OPEN_INCLUDING_EACH_ONE_TAP_THROUGH_INSTANTS_TEXT")
                           : SPKL(@"AUTO_SAVE_INSTANTS_SELECTED_USERS_FOOTER");
        };
    });
    return descriptor;
}

@end
