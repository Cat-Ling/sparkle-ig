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
        descriptor.masterTitle = SPKL(@"STORIES_STORY_AUTO_SAVE_AUTO_SAVE_STORIES_TEXT");
        descriptor.listIcon = @"users";
        descriptor.listProvider = ^UIViewController * {
            return SPKStoryAutoSaveListViewController();
        };
        descriptor.masterHelp = SPKL(@"AUTO_SAVE_STORIES_MASTER_HELP");
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
        descriptor.masterHelp = SPKL(@"AUTO_SAVE_MESSAGES_MASTER_HELP");
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
        descriptor.masterHelp = SPKL(@"AUTO_SAVE_INSTANTS_MASTER_HELP");
    });
    return descriptor;
}

@end
