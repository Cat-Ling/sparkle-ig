#import "SPKStrings.h"
#import "SPKMediaDMUploadCoordinator.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "../../Utils.h"
#import "../Gallery/SPKGalleryFile.h"
#import "../Gallery/SPKGalleryPickerViewController.h"
#import "../UI/SPKNotificationCenter.h"

static SEL SPKMediaDMSendImageSelector(void) {
    return NSSelectorFromString(@"sendImage:");
}

static id SPKMediaDMIvarValue(id object, const char *name) {
    if (!object || !name)
        return nil;
    @try {
        for (Class cls = [object class]; cls && cls != NSObject.class; cls = class_getSuperclass(cls)) {
            Ivar ivar = class_getInstanceVariable(cls, name);
            if (!ivar)
                continue;
            const char *encoding = ivar_getTypeEncoding(ivar);
            if (encoding && encoding[0] == '@')
                return object_getIvar(object, ivar);
        }
    } @catch (__unused NSException *exception) {
    }
    return nil;
}

static id SPKMediaDMCall(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector])
        return nil;
    @try {
        return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id SPKMediaDMThreadContextFromTarget(id target) {
    return SPKMediaDMCall(target, @"threadViewControllerContext") ?: SPKMediaDMIvarValue(target, "_threadViewControllerContext");
}

static id SPKMediaDMMessageSenderFromTarget(id target) {
    id sender = SPKMediaDMCall(target, @"messageSenderFeatureController") ?: SPKMediaDMIvarValue(target, "_messageSenderFeatureController");
    if (sender)
        return sender;

    id threadContext = SPKMediaDMThreadContextFromTarget(target);
    sender = SPKMediaDMCall(threadContext, @"messageSenderFeatureController") ?: SPKMediaDMIvarValue(threadContext, "_messageSenderFeatureController");
    if (sender)
        return sender;

    id featureDelegate = SPKMediaDMCall(target, @"featureDelegate") ?: SPKMediaDMIvarValue(target, "_featureDelegate");
    return SPKMediaDMCall(featureDelegate, @"messageSenderFeatureController") ?: SPKMediaDMIvarValue(featureDelegate, "_messageSenderFeatureController");
}

static void SPKMediaDMNotify(NSString *title, NSString *message, BOOL success) {
    SPKNotify(kSPKNotificationDownloadShare,
              title,
              message,
              success ? @"checkmark_circle" : @"error_filled",
              success ? SPKNotificationToneSuccess : SPKNotificationToneError);
}

@interface SPKMediaDMUploadCoordinator ()
@property (nonatomic, strong) id senderTarget;
@end

static SPKMediaDMUploadCoordinator *sSPKMediaActiveDMUploadCoordinator;

@implementation SPKMediaDMUploadCoordinator

+ (BOOL)senderTargetSupportsMediaUpload:(id)senderTarget {
    id sender = SPKMediaDMMessageSenderFromTarget(senderTarget) ?: senderTarget;
    return sender && [sender respondsToSelector:SPKMediaDMSendImageSelector()];
}

+ (void)presentGalleryUploadPickerForSenderTarget:(id)senderTarget
                                        presenter:(UIViewController *)presenter
                                       sourceView:(UIView *)sourceView {
    if (![self senderTargetSupportsMediaUpload:senderTarget] || !presenter) {
        SPKMediaDMNotify(SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_MEDIA_UPLOAD_UNAVAILABLE_TEXT"), SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_INSTAGRAM_BUILD_NOT_EXPOSE_DIRECT_MEDIA_SENDER_TEXT"), NO);
        SPKWarnLog(@"MediaUpload", @"Missing direct media sender on target: %@", senderTarget);
        return;
    }

    NSSet<NSNumber *> *mediaTypes = [NSSet setWithObject:@(SPKGalleryMediaTypeImage)];
    if (![SPKGalleryPickerViewController hasSelectableFilesForAllowedMediaTypes:mediaTypes]) {
        SPKMediaDMNotify(SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_NO_GALLERY_PHOTOS_TEXT"), SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_SAVE_PHOTO_GALLERY_FIRST_TEXT"), NO);
        return;
    }

    SPKMediaDMUploadCoordinator *coordinator = [[SPKMediaDMUploadCoordinator alloc] init];
    coordinator.senderTarget = senderTarget;
    sSPKMediaActiveDMUploadCoordinator = coordinator;

    __weak typeof(coordinator) weakCoordinator = coordinator;
    [SPKGalleryPickerViewController presentFromViewController:presenter
                                                        title:SPKL(@"DATA_GENERAL_GALLERY_TITLE")
                                            allowedMediaTypes:mediaTypes
                                      allowsMultipleSelection:NO
                                                   completion:^(NSArray<SPKGalleryFile *> *selectedFiles) {
                                                       SPKGalleryFile *file = selectedFiles.firstObject;
                                                       NSURL *fileURL = [file fileURL];
                                                       if (!file || ![file fileExists] || !fileURL) {
                                                           if (sSPKMediaActiveDMUploadCoordinator == weakCoordinator)
                                                               sSPKMediaActiveDMUploadCoordinator = nil;
                                                           return;
                                                       }
                                                       [weakCoordinator sendImageFromURL:fileURL];
                                                   }];
}

- (void)sendImageFromURL:(NSURL *)url {
    UIImage *image = [UIImage imageWithContentsOfFile:url.path];
    if (!image) {
        SPKMediaDMNotify(SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_MEDIA_UPLOAD_FAILED_TEXT"), SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_COULD_NOT_READ_SELECTED_PHOTO_TEXT"), NO);
        if (sSPKMediaActiveDMUploadCoordinator == self)
            sSPKMediaActiveDMUploadCoordinator = nil;
        return;
    }

    id sender = SPKMediaDMMessageSenderFromTarget(self.senderTarget) ?: self.senderTarget;
    if (![sender respondsToSelector:SPKMediaDMSendImageSelector()]) {
        SPKMediaDMNotify(SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_MEDIA_UPLOAD_UNAVAILABLE_TEXT"), SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_DIRECT_MEDIA_SENDER_DISAPPEARED_BEFORE_SENDING_TEXT"), NO);
        if (sSPKMediaActiveDMUploadCoordinator == self)
            sSPKMediaActiveDMUploadCoordinator = nil;
        return;
    }

    @try {
        ((void (*)(id, SEL, id))objc_msgSend)(sender, SPKMediaDMSendImageSelector(), image);
        SPKMediaDMNotify(SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_PHOTO_SENT_TEXT"), SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_SENT_SELECTED_PHOTO_CHAT_TEXT"), YES);
    } @catch (__unused NSException *exception) {
        SPKMediaDMNotify(SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_MEDIA_UPLOAD_FAILED_TEXT"), SPKL(@"MEDIA_UPLOAD_MEDIA_DMUPLOAD_COORDINATOR_INSTAGRAM_REJECTED_SELECTED_PHOTO_TEXT"), NO);
    }
    if (sSPKMediaActiveDMUploadCoordinator == self)
        sSPKMediaActiveDMUploadCoordinator = nil;
}

@end
