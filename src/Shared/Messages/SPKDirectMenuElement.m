#import "SPKDirectMenuElement.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "../../Utils.h"

static const void *kSPKDirectSparkleRowKey = &kSPKDirectSparkleRowKey;

id SPKDirectPrismMenuElement(id templateElement, NSString *title, UIImage *image, void (^handler)(void)) {
    return SPKDirectPrismMenuElementWithSubtitle(templateElement, title, nil, image, handler);
}

BOOL SPKDirectMenuContainsSparkleRow(NSArray *elements) {
    if (![elements isKindOfClass:NSArray.class])
        return NO;
    for (id element in elements) {
        if (objc_getAssociatedObject(element, kSPKDirectSparkleRowKey))
            return YES;
    }
    return NO;
}

id SPKDirectPrismMenuElementWithSubtitle(id templateElement,
                                         NSString *title,
                                         NSString *subtitle,
                                         UIImage *image,
                                         void (^handler)(void)) {
    Class builderClass = NSClassFromString(@"IGDSPrismMenuItemBuilder");
    if (!builderClass || !templateElement || title.length == 0 || !handler)
        return nil;

    SEL initSelector = @selector(initWithTitle:);
    SEL imageSelector = @selector(withImage:);
    SEL subtitleSelector = @selector(withSubtitle:);
    SEL handlerSelector = @selector(withHandler:);
    SEL buildSelector = @selector(build);
    if (![builderClass instancesRespondToSelector:initSelector] ||
        ![builderClass instancesRespondToSelector:imageSelector] ||
        ![builderClass instancesRespondToSelector:handlerSelector] ||
        ![builderClass instancesRespondToSelector:buildSelector]) {
        return nil;
    }

    id builder = ((id (*)(id, SEL, id))objc_msgSend)([builderClass alloc], initSelector, title);
    if (image)
        builder = ((id (*)(id, SEL, id))objc_msgSend)(builder, imageSelector, image);
    // Not every IG build exposes a subtitle; the row is still worth showing
    // without one.
    BOOL supportsSubtitle = [builderClass instancesRespondToSelector:subtitleSelector];
    if (subtitle.length > 0 && supportsSubtitle)
        builder = ((id (*)(id, SEL, id))objc_msgSend)(builder, subtitleSelector, subtitle);
    if (subtitle.length > 0 && !supportsSubtitle)
        SPKLog(@"GifTitle", @"Builder has no withSubtitle:, dropping '%@'", subtitle);
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
    objc_setAssociatedObject(element, kSPKDirectSparkleRowKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return element;
}
