#import "SPKSettingsLockManager.h"
#import "SPKStrings.h"

@implementation SPKSettingsLockManager

+ (instancetype)sharedManager {
    static SPKSettingsLockManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SPKSettingsLockManager alloc] init];
    });
    return instance;
}

- (NSString *)lockEnabledDefaultsKey {
    return @"settings_lock";
}

- (NSString *)keychainService {
    return @"com.sparkle.sparkle.settings.passcode";
}

- (NSString *)protectedContentName {
    return SPKL(@"DATA_GENERAL_SETTINGS_TITLE");
}

- (void)lockSettings {
    [self lockContent];
}

@end
