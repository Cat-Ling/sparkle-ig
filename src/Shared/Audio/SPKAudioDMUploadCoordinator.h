#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Where the audio to send is picked from.
typedef NS_ENUM(NSInteger, SPKAudioDMUploadSource) {
    SPKAudioDMUploadSourcePhotos,
    SPKAudioDMUploadSourceGallery,
    SPKAudioDMUploadSourceFiles,
};

@interface SPKAudioDMUploadCoordinator : NSObject

+ (BOOL)senderTargetSupportsAudioUpload:(nullable id)senderTarget;
+ (void)presentUploadPickerForSenderTarget:(id)senderTarget
                                 presenter:(UIViewController *)presenter
                                sourceView:(nullable UIView *)sourceView;

/// Skips the source action sheet and opens one picker directly, for callers that
/// already let the user choose the source (a submenu row).
+ (void)presentUploadPickerForSource:(SPKAudioDMUploadSource)source
                        senderTarget:(id)senderTarget
                           presenter:(UIViewController *)presenter
                          sourceView:(nullable UIView *)sourceView;

@end

NS_ASSUME_NONNULL_END
