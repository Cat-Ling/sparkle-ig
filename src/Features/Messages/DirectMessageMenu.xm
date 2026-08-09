#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <substrate.h>

// Sparkle's injection point for IG's native Direct menus: the composer's plus/
// overflow menu and the per-message long-press menu. Each row's domain logic
// lives in a coordinator or resolver; this file only decides which rows exist
// and splices them into IG's element arrays.

#import "../../AssetUtils.h"
#import "../../Shared/Audio/SPKAudioDMUploadCoordinator.h"
#import "../../Shared/Audio/SPKAudioDownloadCoordinator.h"
#import "../../Shared/Audio/SPKAudioItem.h"
#import "../../Shared/Gallery/SPKGallerySaveMetadata.h"
#import "../../Shared/MediaUpload/SPKMediaDMUploadCoordinator.h"
#import "../../Shared/Messages/SPKDirectAudioResolver.h"
#import "../../Shared/Messages/SPKDirectMenuElement.h"
#import "../../Shared/Messages/SPKDirectReflection.h"
#import "../../Shared/UI/SPKIGAlertPresenter.h"
#import "../../Shared/UI/SPKNotificationCenter.h"
#import "../../Utils.h"
#import "DMGifTitle.h"

static __unsafe_unretained id sSPKDMComposerForOverflowMenu = nil;
static BOOL sSPKDMUploadItemInjectedForOverflowMenu = NO;
static BOOL sSPKDMAudioRowPending = NO;
static id sSPKDMAudioRowViewModel = nil;

static id (*orig_SPKDMPrismMenuViewInit3)(id, SEL, NSArray *, id, BOOL);
static id (*orig_SPKDMPrismMenuViewInit5)(id, SEL, NSArray *, id, BOOL, BOOL, BOOL);
static id (*orig_SPKDMPrismMenuInit3)(id, SEL, NSArray *, id, BOOL);


static id SPKDMComposerSenderTarget(id composer) {
    if ([composer respondsToSelector:@selector(buttonDelegate)]) {
        return ((id (*)(id, SEL))objc_msgSend)(composer, @selector(buttonDelegate));
    }
    // IG 435+: the overflow controller holds a delegate that may be a wrapper
    // around the composer rather than the composer itself.
    id innerComposer = SPKDirectValueForSelectorNamed(composer, @"composer");
    if ([innerComposer respondsToSelector:@selector(buttonDelegate)]) {
        return ((id (*)(id, SEL))objc_msgSend)(innerComposer, @selector(buttonDelegate));
    }
    return nil;
}

// The overflow controller's link back to the composer: `_composer` up to IG 434,
// `_delegate` from IG 435 (which is the composer, conforming to the new
// IGDirectComposerOverflowControllerDelegate protocol).
static id SPKDMComposerFromOverflowController(id overflowController) {
    return SPKDirectIvarValue(overflowController, "_composer")
               ?: SPKDirectIvarValue(overflowController, "_delegate");
}

static BOOL SPKDMUploadMenuEnabled(void) {
    return [SPKUtils getBoolPref:@"msgs_upload_audio_messages"] ||
           [SPKUtils getBoolPref:@"msgs_upload_gallery_media"];
}

static id SPKDMComposerFromView(id view) {
    if ([view isKindOfClass:%c(IGDirectComposer)])
        return view;
    if ([view isKindOfClass:UIView.class]) {
        for (UIView *candidate = (UIView *)view; candidate; candidate = candidate.superview) {
            if ([candidate isKindOfClass:%c(IGDirectComposer)])
                return candidate;
        }
    }
    return nil;
}

static id SPKDMMenuItem(NSString *title, UIImage *image, void (^handler)(id item)) {
    Class menuItemClass = NSClassFromString(@"IGDSMenuItem");
    SEL titleImageHandler = NSSelectorFromString(@"menuItemWithTitle:image:handler:");
    if (menuItemClass && [menuItemClass respondsToSelector:titleImageHandler]) {
        return ((id (*)(id, SEL, id, id, id))objc_msgSend)(menuItemClass, titleImageHandler, title, image, handler);
    }

    SEL initTitleImageHandler = NSSelectorFromString(@"initWithTitle:image:handler:");
    if (menuItemClass && [menuItemClass instancesRespondToSelector:initTitleImageHandler]) {
        return ((id (*)(id, SEL, id, id, id))objc_msgSend)([menuItemClass alloc], initTitleImageHandler, title, image, handler);
    }

    SEL initTitleImageStyleHandler = NSSelectorFromString(@"initWithTitle:image:style:handler:");
    if (menuItemClass && [menuItemClass instancesRespondToSelector:initTitleImageStyleHandler]) {
        return ((id (*)(id, SEL, id, id, NSInteger, id))objc_msgSend)([menuItemClass alloc], initTitleImageStyleHandler, title, image, 0, handler);
    }

    SEL itemTitleStyleBlock = NSSelectorFromString(@"itemWithTitle:style:block:");
    if (menuItemClass && [menuItemClass respondsToSelector:itemTitleStyleBlock]) {
        return ((id (*)(id, SEL, id, NSInteger, id))objc_msgSend)(menuItemClass, itemTitleStyleBlock, title, 0, handler);
    }
    return nil;
}

static id SPKDMUploadAudioMenuItemForComposer(id composer) {
    id senderTarget = SPKDMComposerSenderTarget(composer);
    BOOL supports = [SPKAudioDMUploadCoordinator senderTargetSupportsAudioUpload:senderTarget];
    if (!supports) {
        SPKWarnLog(@"AudioUpload", @"Missing direct audio sender on composer delegate: %@", senderTarget);
        return nil;
    }

    __weak id weakComposer = composer;
    return SPKDMMenuItem(@"Upload Audio", [SPKAssetUtils instagramIconNamed:@"audio_upload" pointSize:24.0], ^(__unused id item) {
        id strongComposer = weakComposer;
        if (!strongComposer)
            return;
        UIView *composerView = [strongComposer isKindOfClass:UIView.class] ? (UIView *)strongComposer : nil;
        UIViewController *presenter = (composerView ? [SPKUtils viewControllerForAncestralView:composerView] : nil) ?: topMostController();
        [SPKAudioDMUploadCoordinator presentUploadPickerForSenderTarget:senderTarget
                                                              presenter:presenter
                                                             sourceView:composerView];
    });
}

static id SPKDMUploadMediaMenuItemForComposer(id composer) {
    id senderTarget = SPKDMComposerSenderTarget(composer);
    BOOL supports = [SPKMediaDMUploadCoordinator senderTargetSupportsMediaUpload:senderTarget];
    if (!supports) {
        SPKWarnLog(@"MediaUpload", @"Missing direct media sender on composer delegate: %@", senderTarget);
        return nil;
    }

    __weak id weakComposer = composer;
    return SPKDMMenuItem(@"Upload Photo", [SPKAssetUtils instagramIconNamed:@"photo" pointSize:24.0], ^(__unused id item) {
        id strongComposer = weakComposer;
        if (!strongComposer)
            return;
        UIView *composerView = [strongComposer isKindOfClass:UIView.class] ? (UIView *)strongComposer : nil;
        UIViewController *presenter = (composerView ? [SPKUtils viewControllerForAncestralView:composerView] : nil) ?: topMostController();
        [SPKMediaDMUploadCoordinator presentGalleryUploadPickerForSenderTarget:senderTarget
                                                                     presenter:presenter
                                                                    sourceView:composerView];
    });
}

// Builds the Sparkle items appended to the composer overflow (+) menu, in order.
static NSArray *SPKDMComposerExtraMenuItems(id composer) {
    NSMutableArray *items = [NSMutableArray array];
    BOOL audioPref = [SPKUtils getBoolPref:@"msgs_upload_audio_messages"];
    BOOL mediaPref = [SPKUtils getBoolPref:@"msgs_upload_gallery_media"];
    if (audioPref) {
        id audioItem = SPKDMUploadAudioMenuItemForComposer(composer);
        if (audioItem)
            [items addObject:audioItem];
    }
    if (mediaPref) {
        id mediaItem = SPKDMUploadMediaMenuItemForComposer(composer);
        if (mediaItem)
            [items addObject:mediaItem];
    }
    return items;
}

static void SPKDMPresentDownloadAudioActionsForViewModel(id viewModel) {
    UIViewController *presenter = topMostController();
    UIView *sourceView = presenter.view;
    SPKAudioItem *audioItem = [SPKAudioDownloadCoordinator audioItemFromMediaObject:viewModel source:SPKAudioSourceDMs];
    if (!audioItem) {
        SPKNotify(kSPKNotificationDownloadShare,
                  @"Could not find audio URL",
                  @"Refresh the thread and try again if the URL expired.",
                  @"error_filled",
                  SPKNotificationToneError);
        return;
    }

    SPKGallerySaveMetadata *metadata = [[SPKGallerySaveMetadata alloc] init];
    NSString *username = SPKDirectAudioResolvedUsername(viewModel);
    metadata.source = (int16_t)[audioItem gallerySource];
    metadata.sourceUsername = username.length > 0 ? username : (audioItem.artist.length > 0 ? audioItem.artist : @"direct");
    metadata.sourceMediaPK = audioItem.mediaIdentifier;
    metadata.sourceMediaURLString = audioItem.sourceURLString ?: audioItem.url.absoluteString;

    [SPKIGAlertPresenter presentActionSheetFromViewController:presenter
                                                        title:@"Audio"
                                                      message:nil
                                                      actions:@[
                                                          [SPKIGAlertAction actionWithTitle:@"Save Audio to Files"
                                                                                      style:SPKIGAlertActionStyleDefault
                                                                                    handler:^{
                                                                                        [SPKAudioDownloadCoordinator performAction:SPKAudioActionSaveToFiles item:audioItem presenter:presenter sourceView:sourceView metadata:metadata notificationIdentifier:kSPKNotificationDownloadAudio];
                                                                                    }],
                                                          [SPKIGAlertAction actionWithTitle:@"Share Audio"
                                                                                      style:SPKIGAlertActionStyleDefault
                                                                                    handler:^{
                                                                                        [SPKAudioDownloadCoordinator performAction:SPKAudioActionConvertAndShare item:audioItem presenter:presenter sourceView:sourceView metadata:metadata notificationIdentifier:kSPKNotificationDownloadAudioShare];
                                                                                    }],
                                                          [SPKIGAlertAction actionWithTitle:@"Save Audio to Gallery"
                                                                                      style:SPKIGAlertActionStyleDefault
                                                                                    handler:^{
                                                                                        [SPKAudioDownloadCoordinator performAction:SPKAudioActionConvertAndSaveToGallery item:audioItem presenter:presenter sourceView:sourceView metadata:metadata notificationIdentifier:kSPKNotificationDownloadAudioGallery];
                                                                                    }],
                                                          [SPKIGAlertAction actionWithTitle:@"Play Audio"
                                                                                      style:SPKIGAlertActionStyleDefault
                                                                                    handler:^{
                                                                                        [SPKAudioDownloadCoordinator performAction:SPKAudioActionPlay item:audioItem presenter:presenter sourceView:sourceView metadata:metadata notificationIdentifier:kSPKNotificationPlayAudio];
                                                                                    }],
                                                          [SPKIGAlertAction actionWithTitle:@"Copy Audio Download URL"
                                                                                      style:SPKIGAlertActionStyleDefault
                                                                                    handler:^{
                                                                                        [SPKAudioDownloadCoordinator performAction:SPKAudioActionCopyURL item:audioItem presenter:presenter sourceView:sourceView metadata:metadata notificationIdentifier:kSPKNotificationCopyAudioURL];
                                                                                    }],
                                                          [SPKIGAlertAction actionWithTitle:@"Cancel"
                                                                                      style:SPKIGAlertActionStyleCancel
                                                                                    handler:nil]
                                                      ]];
}

static id SPKDMDownloadAudioMenuItemForViewModel(id viewModel) {
    if (![SPKUtils getBoolPref:@"downloads_audio_enabled"])
        return nil;
    if (![SPKUtils getBoolPref:@"msgs_download_audio_messages"])
        return nil;
    if (![SPKAudioDownloadCoordinator bestAudioURLFromMediaObject:viewModel])
        return nil;

    __strong id capturedViewModel = viewModel;
    return SPKDMMenuItem(@"Audio Actions", [SPKAssetUtils instagramIconNamed:@"action" pointSize:24.0], ^(__unused id item) {
        SPKDMPresentDownloadAudioActionsForViewModel(capturedViewModel);
    });
}

static id SPKDMPrismAudioDownloadElement(id templateElement, id viewModel) {
    Class builderClass = NSClassFromString(@"IGDSPrismMenuItemBuilder");
    if (!builderClass || !templateElement || !viewModel)
        return nil;
    SEL initSelector = @selector(initWithTitle:);
    SEL imageSelector = @selector(withImage:);
    SEL handlerSelector = @selector(withHandler:);
    SEL buildSelector = @selector(build);
    if (![builderClass instancesRespondToSelector:initSelector] ||
        ![builderClass instancesRespondToSelector:imageSelector] ||
        ![builderClass instancesRespondToSelector:handlerSelector] ||
        ![builderClass instancesRespondToSelector:buildSelector]) {
        return nil;
    }

    __strong id capturedViewModel = viewModel;
    void (^handler)(void) = ^{
        SPKDMPresentDownloadAudioActionsForViewModel(capturedViewModel);
    };

    id builder = ((id (*)(id, SEL, id))objc_msgSend)([builderClass alloc], initSelector, @"Audio Actions");
    builder = ((id (*)(id, SEL, id))objc_msgSend)(builder, imageSelector, [SPKAssetUtils instagramIconNamed:@"action" pointSize:24.0]);
    builder = ((id (*)(id, SEL, id))objc_msgSend)(builder, handlerSelector, handler);
    id menuItem = ((id (*)(id, SEL))objc_msgSend)(builder, buildSelector);
    if (!menuItem)
        return nil;

    id element = [[templateElement class] new];
    Ivar subtypeIvar = class_getInstanceVariable([templateElement class], "_subtype");
    Ivar itemIvar = class_getInstanceVariable([templateElement class], "_item_menuItem");
    if (!element || !subtypeIvar || !itemIvar)
        return nil;

    ptrdiff_t subtypeOffset = ivar_getOffset(subtypeIvar);
    *(uint64_t *)((uint8_t *)(__bridge void *)element + subtypeOffset) =
        *(uint64_t *)((uint8_t *)(__bridge void *)templateElement + subtypeOffset);
    object_setIvar(element, itemIvar, menuItem);
    return element;
}

static NSArray *SPKDMPrismUploadElementsForComposer(id composer, id templateElement) {
    if (!composer || !templateElement || sSPKDMUploadItemInjectedForOverflowMenu)
        return @[];

    id senderTarget = SPKDMComposerSenderTarget(composer);
    NSMutableArray *elements = [NSMutableArray array];

    if ([SPKUtils getBoolPref:@"msgs_upload_audio_messages"] &&
        [SPKAudioDMUploadCoordinator senderTargetSupportsAudioUpload:senderTarget]) {
        __weak id weakComposer = composer;
        id audioElement = SPKDirectPrismMenuElement(templateElement,
                                                @"Upload Audio",
                                                [SPKAssetUtils instagramIconNamed:@"audio_upload"
                                                                        pointSize:24.0],
                                                ^{
                                                    id strongComposer = weakComposer;
                                                    if (!strongComposer)
                                                        return;
                                                    UIView *composerView = [strongComposer isKindOfClass:UIView.class] ? (UIView *)strongComposer : nil;
                                                    UIViewController *presenter = (composerView ? [SPKUtils viewControllerForAncestralView:composerView] : nil) ?: topMostController();
                                                    [SPKAudioDMUploadCoordinator presentUploadPickerForSenderTarget:senderTarget
                                                                                                          presenter:presenter
                                                                                                         sourceView:composerView];
                                                });
        if (audioElement)
            [elements addObject:audioElement];
    }

    if ([SPKUtils getBoolPref:@"msgs_upload_gallery_media"] &&
        [SPKMediaDMUploadCoordinator senderTargetSupportsMediaUpload:senderTarget]) {
        __weak id weakComposer = composer;
        id mediaElement = SPKDirectPrismMenuElement(templateElement,
                                                @"Upload Photo",
                                                [SPKAssetUtils instagramIconNamed:@"photo"
                                                                        pointSize:24.0],
                                                ^{
                                                    id strongComposer = weakComposer;
                                                    if (!strongComposer)
                                                        return;
                                                    UIView *composerView = [strongComposer isKindOfClass:UIView.class] ? (UIView *)strongComposer : nil;
                                                    UIViewController *presenter = (composerView ? [SPKUtils viewControllerForAncestralView:composerView] : nil) ?: topMostController();
                                                    [SPKMediaDMUploadCoordinator presentGalleryUploadPickerForSenderTarget:senderTarget
                                                                                                                 presenter:presenter
                                                                                                                sourceView:composerView];
                                                });
        if (mediaElement)
            [elements addObject:mediaElement];
    }

    return elements;
}

static NSArray *SPKDMPrismMenuElementsWithAudioDownload(NSArray *elements) {
    if (!sSPKDMAudioRowPending)
        return elements;
    sSPKDMAudioRowPending = NO;

    id viewModel = sSPKDMAudioRowViewModel;
    sSPKDMAudioRowViewModel = nil;
    if (![SPKUtils getBoolPref:@"msgs_download_audio_messages"] || ![elements isKindOfClass:NSArray.class] || elements.count == 0) {
        return elements;
    }

    id newElement = SPKDMPrismAudioDownloadElement(elements.firstObject, viewModel);
    if (!newElement)
        return elements;

    NSMutableArray *updated = [NSMutableArray arrayWithObject:newElement];
    [updated addObjectsFromArray:elements];
    return [updated copy];
}

static NSArray *SPKDMPrismMenuElementsWithGifTitle(NSArray *elements) {
    if (![elements isKindOfClass:NSArray.class] || elements.count == 0)
        return elements;

    NSArray *titleElements = SPKDMGifTitleElementsForMenu(elements);
    if (titleElements.count == 0)
        return elements;

    NSMutableArray *updated = [NSMutableArray arrayWithArray:titleElements];
    [updated addObjectsFromArray:elements];
    return [updated copy];
}

static NSArray *SPKDMPrismMenuElementsWithInjections(NSArray *elements) {
    NSArray *updated = SPKDMPrismMenuElementsWithGifTitle(elements);
    updated = SPKDMPrismMenuElementsWithAudioDownload(updated);
    if (!SPKDMUploadMenuEnabled() || !sSPKDMComposerForOverflowMenu || sSPKDMUploadItemInjectedForOverflowMenu ||
        ![updated isKindOfClass:NSArray.class] || updated.count == 0) {
        return updated;
    }

    NSArray *uploadElements = SPKDMPrismUploadElementsForComposer(sSPKDMComposerForOverflowMenu, updated.firstObject);
    if (uploadElements.count == 0)
        return updated;

    NSMutableArray *merged = [NSMutableArray arrayWithArray:updated];
    [merged addObjectsFromArray:uploadElements];
    sSPKDMUploadItemInjectedForOverflowMenu = YES;
    return [merged copy];
}

static id SPKDMPrismMenuViewInit3(id self, SEL _cmd, NSArray *elements, id headerText, BOOL edrEnabled) {
    id view = orig_SPKDMPrismMenuViewInit3(self, _cmd, SPKDMPrismMenuElementsWithInjections(elements), headerText, edrEnabled);
    SPKDMGifTitleRegisterMenuView(view);
    return view;
}

static id SPKDMPrismMenuViewInit5(id self, SEL _cmd, NSArray *elements, id headerText, BOOL edrEnabled, BOOL allowScrollingItems, BOOL allowMixedTextAlignment) {
    id view = orig_SPKDMPrismMenuViewInit5(self, _cmd, SPKDMPrismMenuElementsWithInjections(elements), headerText, edrEnabled, allowScrollingItems, allowMixedTextAlignment);
    SPKDMGifTitleRegisterMenuView(view);
    return view;
}

static id SPKDMPrismMenuInit3(id self, SEL _cmd, NSArray *elements, id headerText, BOOL edrEnabled) {
    id menu = orig_SPKDMPrismMenuInit3(self, _cmd, SPKDMPrismMenuElementsWithInjections(elements), headerText, edrEnabled);
    SPKDMGifTitleRegisterMenuView(menu);
    return menu;
}

static void SPKDMSetUploadComposerContext(id composer) {
    sSPKDMComposerForOverflowMenu = composer;
    sSPKDMUploadItemInjectedForOverflowMenu = NO;
}

static void SPKDMClearUploadComposerContext(void) {
    sSPKDMComposerForOverflowMenu = nil;
    sSPKDMUploadItemInjectedForOverflowMenu = NO;
}

%group SPKDirectMessageMenuHooks

%hook IGDirectComposerOverflowController

- (id)_setupMenuItemGroup {
    id composer = SPKDMComposerFromOverflowController(self);
    if (!SPKDMUploadMenuEnabled() || !composer) {
        return %orig;
    }

    SPKDMSetUploadComposerContext(composer);
    id result = %orig;
    SPKDMClearUploadComposerContext();
    return result;
}

%end

%hook IGDirectComposer

- (void)menuDidDismiss {
    SPKDMClearUploadComposerContext();
    %orig;
}

- (void)_didTapRedesignOverflowButton:(id)button {
    if (!SPKDMUploadMenuEnabled()) {
        %orig;
        return;
    }
    SPKDMSetUploadComposerContext(self);
    %orig;
}

%end

%hook IGDirectThreadViewController

- (void)inputView:(id)view didTapMoreButton:(id)button {
    id composer = SPKDMComposerFromView(view);
    if (!SPKDMUploadMenuEnabled() || !composer) {
        %orig;
        return;
    }
    SPKDMSetUploadComposerContext(composer);
    %orig;
}

- (void)inputView:(id)view didTapPlusButton:(id)button isExpanded:(_Bool)expanded layoutSpec:(id)layoutSpec {
    id composer = SPKDMComposerFromView(view);
    if (!SPKDMUploadMenuEnabled() || !composer) {
        if (!expanded)
            SPKDMClearUploadComposerContext();
        %orig;
        return;
    }
    if (expanded) {
        SPKDMSetUploadComposerContext(composer);
        %orig;
        return;
    }
    %orig;
    SPKDMClearUploadComposerContext();
}

- (void)composerOverflowButtonMenuWillPrepareExpandWithPlusButton:(id)button {
    id composer = SPKDMComposerFromView(button);
    if (!composer && [button isKindOfClass:UIView.class]) {
        for (UIView *candidate = (UIView *)button; candidate; candidate = candidate.superview) {
            composer = SPKDMComposerFromView(candidate);
            if (composer)
                break;
        }
    }
    if (SPKDMUploadMenuEnabled() && composer) {
        SPKDMSetUploadComposerContext(composer);
    }
    %orig;
}

%end

static id SPKDMProcessMenuItems(id menuItems) {
    if (sSPKDMComposerForOverflowMenu && !sSPKDMUploadItemInjectedForOverflowMenu && [menuItems isKindOfClass:NSArray.class]) {
        NSArray *extraItems = SPKDMComposerExtraMenuItems(sSPKDMComposerForOverflowMenu);
        if (extraItems.count > 0) {
            NSMutableArray *mutableItems = [(NSArray *)menuItems mutableCopy];
            [mutableItems addObjectsFromArray:extraItems];
            sSPKDMUploadItemInjectedForOverflowMenu = YES;
            return [mutableItems copy];
        }
    }
    return menuItems;
}

%hook IGDSMenu

- (id)initWithMenuItems:(id)menuItems {
    return %orig(SPKDMProcessMenuItems(menuItems));
}

- (id)initWithMenuItems:(id)menuItems edr:(_Bool)edr {
    return %orig(SPKDMProcessMenuItems(menuItems), edr);
}

- (id)initWithMenuItems:(id)menuItems edr:(_Bool)edr headerLabelText:(id)headerLabelText {
    return %orig(SPKDMProcessMenuItems(menuItems), edr, headerLabelText);
}

- (id)initWithMenuItems:(id)menuItems edr:(_Bool)edr headerLabelText:(id)headerLabelText enableScrollToDismiss:(_Bool)enableScrollToDismiss {
    return %orig(SPKDMProcessMenuItems(menuItems), edr, headerLabelText, enableScrollToDismiss);
}

- (id)initWithMenuItemsWithoutUIWindow:(id)menuItems edr:(_Bool)edr headerLabelText:(id)headerLabelText {
    return %orig(SPKDMProcessMenuItems(menuItems), edr, headerLabelText);
}

%end

%hook _TtC32IGDirectMessageMenuConfiguration32IGDirectMessageMenuConfiguration

+ (id)menuConfigurationWithEligibleOptions:(id)options
                          messageViewModel:(id)viewModel
                               contentType:(id)contentType
                                 isSticker:(_Bool)isSticker
                            isMusicSticker:(_Bool)isMusicSticker
                          directNuxManager:(id)directNuxManager
                       sessionUserDefaults:(id)sessionUserDefaults
                               launcherSet:(id)launcherSet
                               userSession:(id)userSession
                                tapHandler:(id)tapHandler {
    id config = %orig(options, viewModel, contentType, isSticker, isMusicSticker, directNuxManager, sessionUserDefaults, launcherSet, userSession, tapHandler);
    SPKDMGifTitleNoteMenuViewModel(viewModel);
    if ([SPKUtils getBoolPref:@"downloads_audio_enabled"] &&
        [SPKUtils getBoolPref:@"msgs_download_audio_messages"] &&
        [SPKAudioDownloadCoordinator bestAudioURLFromMediaObject:viewModel]) {
        sSPKDMAudioRowPending = YES;
        sSPKDMAudioRowViewModel = viewModel;
    }
    return config;
}

%end

%end

extern "C" void SPKInstallDirectMessageMenuHooksIfNeeded(void) {
    // Audio download/upload features sit behind the audio-downloads master switch;
    // gallery photo upload is independent of it.
    BOOL audioFeatureEnabled = [SPKUtils getBoolPref:@"downloads_audio_enabled"] &&
                               ([SPKUtils getBoolPref:@"msgs_download_audio_messages"] ||
                                [SPKUtils getBoolPref:@"msgs_download_notes_audio"] ||
                                [SPKUtils getBoolPref:@"msgs_upload_audio_messages"]);
    BOOL mediaUploadEnabled = [SPKUtils getBoolPref:@"msgs_upload_gallery_media"];
    if (!audioFeatureEnabled && !mediaUploadEnabled && !SPKDMGifTitleEnabled())
        return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKDirectMessageMenuHooks);
        Class prismMenuViewClass = objc_getClass("IGDSPrismMenu.IGDSPrismMenuView");
        SEL init3 = @selector(initWithMenuElements:headerText:edrEnabled:);
        if (prismMenuViewClass && [prismMenuViewClass instancesRespondToSelector:init3]) {
            MSHookMessageEx(prismMenuViewClass,
                            init3,
                            (IMP)SPKDMPrismMenuViewInit3,
                            (IMP *)&orig_SPKDMPrismMenuViewInit3);
        }
        SEL init5 = @selector(initWithMenuElements:headerText:edrEnabled:allowScrollingItems:allowMixedTextAlignment:);
        if (prismMenuViewClass && [prismMenuViewClass instancesRespondToSelector:init5]) {
            MSHookMessageEx(prismMenuViewClass,
                            init5,
                            (IMP)SPKDMPrismMenuViewInit5,
                            (IMP *)&orig_SPKDMPrismMenuViewInit5);
        }
        Class prismMenuClass = objc_getClass("IGDSPrismMenu.IGDSPrismMenu");
        if (prismMenuClass && [prismMenuClass instancesRespondToSelector:init3]) {
            MSHookMessageEx(prismMenuClass,
                            init3,
                            (IMP)SPKDMPrismMenuInit3,
                            (IMP *)&orig_SPKDMPrismMenuInit3);
        }
    });
}
