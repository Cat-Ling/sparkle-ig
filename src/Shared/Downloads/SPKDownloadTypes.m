#import "SPKStrings.h"
#import "SPKDownloadTypes.h"

NSErrorDomain const SPKDownloadErrorDomain = @"com.sparkle.download";

NSInteger const SPKDownloadStoreSchemaVersion = 2;

NSString *const kSPKDownloadMaxConcurrentKey = @"downloads_max_concurrent";
NSString *const kSPKDownloadHistoryLimitKey = @"downloads_history_limit";
NSString *const kSPKDownloadDetectDuplicatesKey = @"downloads_detect_duplicates";

NSNotificationName const SPKDownloadServiceDidChangeNotification = @"SPKDownloadServiceDidChangeNotification";
NSNotificationName const SPKDownloadJobDidChangeNotification = @"SPKDownloadJobDidChangeNotification";

NSString *const SPKDownloadNotificationJobIDKey = @"jobID";
NSString *const SPKDownloadNotificationItemIDKey = @"itemID";
NSString *const SPKDownloadNotificationSnapshotKey = @"snapshot";

NSError *SPKDownloadError(SPKDownloadErrorCode code, NSString *description, NSString *recovery) {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (description.length > 0)
        info[NSLocalizedDescriptionKey] = description;
    if (recovery.length > 0)
        info[NSLocalizedRecoverySuggestionErrorKey] = recovery;
    return [NSError errorWithDomain:SPKDownloadErrorDomain code:code userInfo:info];
}

BOOL SPKDownloadStateIsTerminal(SPKDownloadState state) {
    switch (state) {
    case SPKDownloadStateSucceeded:
    case SPKDownloadStateFailed:
    case SPKDownloadStateCancelled:
    case SPKDownloadStateInterrupted:
        return YES;
    default:
        return NO;
    }
}

BOOL SPKDownloadStateAllowsTransition(SPKDownloadState from, SPKDownloadState to) {
    if (from == to)
        return YES;
    if (SPKDownloadStateIsTerminal(from))
        return NO;
    switch (from) {
    case SPKDownloadStatePending:
        return to == SPKDownloadStateWaitingForPreflight || to == SPKDownloadStateQueued || to == SPKDownloadStateCancelled;
    case SPKDownloadStateWaitingForPreflight:
        return to == SPKDownloadStateQueued || to == SPKDownloadStateCancelled;
    case SPKDownloadStateQueued:
        return to == SPKDownloadStateRunning || to == SPKDownloadStateCancelled;
    case SPKDownloadStateRunning:
        return to == SPKDownloadStateFinalizing || to == SPKDownloadStateFailed || to == SPKDownloadStateCancelled || to == SPKDownloadStateInterrupted;
    case SPKDownloadStateFinalizing:
        return to == SPKDownloadStateSucceeded || to == SPKDownloadStateFailed || to == SPKDownloadStateCancelled;
    case SPKDownloadStateFailed:
    case SPKDownloadStateCancelled:
    case SPKDownloadStateInterrupted:
        return to == SPKDownloadStateQueued;
    default:
        return NO;
    }
}

SPKDownloadState SPKDownloadDerivedJobState(NSArray<NSNumber *> *itemStates) {
    if (itemStates.count == 0)
        return SPKDownloadStatePending;
    BOOL anyRunning = NO;
    BOOL anyFinalizing = NO;
    BOOL anyQueuedLike = NO;
    NSUInteger succeeded = 0;
    NSUInteger failed = 0;
    NSUInteger cancelled = 0;
    NSUInteger interrupted = 0;
    for (NSNumber *n in itemStates) {
        SPKDownloadState s = (SPKDownloadState)n.integerValue;
        if (s == SPKDownloadStateRunning)
            anyRunning = YES;
        if (s == SPKDownloadStateFinalizing)
            anyFinalizing = YES;
        if (s == SPKDownloadStatePending || s == SPKDownloadStateWaitingForPreflight || s == SPKDownloadStateQueued)
            anyQueuedLike = YES;
        if (s == SPKDownloadStateSucceeded)
            succeeded++;
        else if (s == SPKDownloadStateFailed)
            failed++;
        else if (s == SPKDownloadStateCancelled)
            cancelled++;
        else if (s == SPKDownloadStateInterrupted)
            interrupted++;
    }
    if (anyRunning || anyFinalizing)
        return SPKDownloadStateRunning;
    if (anyQueuedLike)
        return SPKDownloadStateQueued;
    NSUInteger total = itemStates.count;
    if (succeeded == total)
        return SPKDownloadStateSucceeded;
    if (failed == total)
        return SPKDownloadStateFailed;
    if (cancelled == total)
        return SPKDownloadStateCancelled;
    if (interrupted == total)
        return SPKDownloadStateInterrupted;
    if (succeeded > 0 && (failed + cancelled + interrupted) > 0)
        return SPKDownloadStatePartial;
    if (failed > 0 && succeeded == 0 && cancelled == 0 && interrupted == 0)
        return SPKDownloadStateFailed;
    if (cancelled > 0 && succeeded == 0)
        return SPKDownloadStateCancelled;
    if (interrupted > 0 && succeeded == 0)
        return SPKDownloadStateInterrupted;
    return SPKDownloadStatePartial;
}

NSString *SPKDownloadDestinationDisplayName(SPKDownloadDestination destination) {
    switch (destination) {
    case SPKDownloadDestinationPhotos:
        return SPKL(@"DOWNLOADS_DOWNLOAD_DUPLICATE_POLICY_PHOTOS_TEXT");
    case SPKDownloadDestinationGallery:
        return SPKL(@"GALLERY_TITLE");
    case SPKDownloadDestinationShare:
        return @"Share";
    case SPKDownloadDestinationClipboard:
        return SPKL(@"DOWNLOADS_DOWNLOAD_TYPES_CLIPBOARD_TEXT");
    case SPKDownloadDestinationCacheOnly:
        return @"Download";
    }
    return @"Download";
}

NSString *SPKDownloadSourceSurfaceDisplayName(SPKDownloadSourceSurface surface) {
    switch (surface) {
    case SPKDownloadSourceSurfaceFeed:
        return SPKL(@"FEED_TITLE");
    case SPKDownloadSourceSurfaceReels:
        return @"Reels";
    case SPKDownloadSourceSurfaceStories:
        return SPKL(@"STORIES_OTHER_STORIES_TITLE");
    case SPKDownloadSourceSurfaceDirect:
        return SPKL(@"DOWNLOADS_DOWNLOAD_TYPES_DIRECT_TEXT");
    case SPKDownloadSourceSurfaceAudioPage:
        return @"Audio";
    case SPKDownloadSourceSurfaceMediaPreview:
        return SPKL(@"NOTIFICATION_PREVIEW_HEADER");
    case SPKDownloadSourceSurfaceGallery:
        return SPKL(@"GALLERY_TITLE");
    case SPKDownloadSourceSurfaceProfile:
        return SPKL(@"PROFILE_TITLE");
    case SPKDownloadSourceSurfaceInstants:
        return SPKL(@"INSTANTS_CONFIRMATION_INSTANTS_TITLE");
    case SPKDownloadSourceSurfaceComments:
        return SPKL(@"GENERAL_COMMENTS_HEADER");
    default:
        return SPKL(@"STORIES_OTHER_HEADER");
    }
}
