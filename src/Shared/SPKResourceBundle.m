#import "SPKResourceBundle.h"
#import <dlfcn.h>

static NSString *SPKDylibDirectory(void) {
    Dl_info info;
    if (dladdr((const void *)SPKResourceBundle, &info) && info.dli_fname) {
        return [[NSString stringWithUTF8String:info.dli_fname] stringByDeletingLastPathComponent];
    }
    return nil;
}

static NSArray<NSString *> *SPKResourceBundleCandidates(void) {
    NSMutableOrderedSet<NSString *> *paths = [NSMutableOrderedSet orderedSet];
    [paths addObject:@"/var/jb/Library/Application Support/Sparkle.bundle"];
    [paths addObject:@"/Library/Application Support/Sparkle.bundle"];

    NSString *dylibDirectory = SPKDylibDirectory();
    if (dylibDirectory.length > 0) {
        [paths addObject:[dylibDirectory stringByAppendingPathComponent:@"Sparkle.bundle"]];
        [paths addObject:[[dylibDirectory stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Sparkle.bundle"]];
    }

    NSString *appPath = NSBundle.mainBundle.bundlePath;
    if (appPath.length > 0) {
        [paths addObject:[appPath stringByAppendingPathComponent:@"Sparkle.bundle"]];
        [paths addObject:[appPath stringByAppendingPathComponent:@"Frameworks/Sparkle.bundle"]];
    }
    return paths.array;
}

NSBundle *SPKResourceBundle(void) {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fileManager = NSFileManager.defaultManager;
        for (NSString *path in SPKResourceBundleCandidates()) {
            BOOL isDirectory = NO;
            if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                bundle = [NSBundle bundleWithPath:path];
                if (bundle)
                    break;
            }
        }
    });
    return bundle;
}

NSString *SPKResourceBundlePath(void) {
    return SPKResourceBundle().bundlePath;
}

NSString *SPKResourcePath(NSString *relativePath) {
    if (relativePath.length == 0)
        return SPKResourceBundlePath();
    NSString *root = SPKResourceBundlePath();
    return root.length > 0 ? [root stringByAppendingPathComponent:relativePath] : nil;
}
