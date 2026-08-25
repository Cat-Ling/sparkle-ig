#import "SPKLanguagePicker.h"
#import "SPKStrings.h"
#import "../Utils.h"

// Endonyms (each language's own name) — best UX for a language picker.
static NSDictionary<NSString *, NSString *> *SPKLangNames(void) {
    static NSDictionary *m = nil; static dispatch_once_t o;
    dispatch_once(&o, ^{ m = @{
        @"en":@"English", @"ar":@"العربية", @"de":@"Deutsch", @"el":@"Ελληνικά",
        @"es-ES":@"Español", @"fr":@"Français", @"hi":@"हिन्दी", @"it":@"Italiano",
        @"ja":@"日本語", @"ko":@"한국어", @"pt-BR":@"Português (Brasil)", @"ru":@"Русский",
        @"ro":@"Română",
        @"tr":@"Türkçe", @"uk":@"Українська", @"vi":@"Tiếng Việt", @"zh-Hans":@"简体中文" }; });
    return m;
}

NSString *SPKLanguageDisplayName(NSString *code) {
    if (code.length == 0 || [code isEqualToString:@"auto"]) return SPKL(@"LANGUAGE_SYSTEM_DEFAULT");
    return SPKLangNames()[code] ?: code;
}

static UIAction *SPKLangAction(NSString *title, NSString *value) {
    UIAction *action = [UIAction actionWithTitle:title
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction *selectedAction) {
                                            (void)selectedAction;
                                            [SPKStrings setLanguageOverride:[value isEqualToString:@"auto"] ? nil : value];
                                            [NSUserDefaults.standardUserDefaults synchronize];
                                            [SPKUtils showRestartConfirmation];
                                        }];
    NSString *selected = [SPKStrings languageOverride] ?: @"auto";
    action.state = [selected isEqualToString:value] ? UIMenuElementStateOn : UIMenuElementStateOff;
    return action;
}

UIMenu *SPKLanguageMenu(void) {
    NSMutableArray<UIMenuElement *> *cmds = [NSMutableArray array];
    [cmds addObject:SPKLangAction(SPKL(@"LANGUAGE_SYSTEM_DEFAULT"), @"auto")];
    for (NSString *code in [SPKStrings supportedLanguages]) {
        [cmds addObject:SPKLangAction(SPKLanguageDisplayName(code), code)];
    }
    return [UIMenu menuWithChildren:cmds];
}
