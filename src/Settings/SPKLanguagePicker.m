#import "SPKLanguagePicker.h"
#import "SPKStrings.h"
#import "SPKSetting.h"
#import "SPKSettingsViewController.h"
#import "SPKTopicSettingsSupport.h"
#import "../AssetUtils.h"
#import "../Shared/UI/SPKMediaChrome.h"
#import "../Utils.h"

static NSString *const kSPKTranslationIssueURL = @"https://github.com/efibalogh/sparkle-ig/issues/new?title=Translation%3A%20";

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

@interface SPKLanguagePickerViewController : SPKSettingsViewController

@property (nonatomic, copy) NSArray<NSString *> *languageCodes;

@end

@implementation SPKLanguagePickerViewController

- (instancetype)init {
    NSMutableArray<NSString *> *codes = [NSMutableArray arrayWithObject:@"auto"];
    [codes addObjectsFromArray:[SPKStrings supportedLanguages]];
    self = [super initWithTitle:SPKL(@"LANGUAGE_TITLE") sections:@[] reduceMargin:NO];
    if (self) {
        _languageCodes = [codes copy];
        [self rebuildSections];
    }
    return self;
}

- (void)rebuildSections {
    NSString *selected = [SPKStrings languageOverride] ?: @"auto";
    __weak typeof(self) weakSelf = self;
    NSMutableArray<SPKSetting *> *languageRows = [NSMutableArray arrayWithCapacity:self.languageCodes.count];
    for (NSString *code in self.languageCodes) {
        BOOL isSelected = [selected isEqualToString:code];
        SPKSetting *row = [SPKSetting buttonCellWithTitle:SPKLanguageDisplayName(code)
                                                 subtitle:nil
                                                     icon:nil
                                                   action:^{
                                                       [weakSelf selectLanguageCode:code];
                                                   }];
        row.userInfo = @{
            @"languageCode" : code,
            @"checkmarked" : @(isSelected),
            @"hidesDisclosure" : @(YES),
        };
        [languageRows addObject:row];
    }

    SPKSetting *helpRow = [SPKSetting linkCellWithTitle:SPKL(@"ABOUT_HELP_TRANSLATE_TITLE")
                                               subtitle:@""
                                                   icon:SPKSettingsIcon(@"translate")
                                                    url:kSPKTranslationIssueURL];
    [self replaceSections:@[
        SPKTopicSection(@"", languageRows, nil),
        SPKTopicSection(@"", @[ helpRow ], SPKL(@"ABOUT_HELP_TRANSLATE_FOOTER")),
    ]];
}

- (void)selectLanguageCode:(NSString *)code {
    NSString *selected = [SPKStrings languageOverride] ?: @"auto";
    if ([selected isEqualToString:code]) {
        return;
    }
    [SPKStrings setLanguageOverride:[code isEqualToString:@"auto"] ? nil : code];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self rebuildSections];
    [self dismissViewControllerAnimated:YES completion:^{
        [SPKUtils showRestartConfirmation];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    SPKSetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (row.userInfo[@"languageCode"]) {
        if ([row.userInfo[@"checkmarked"] boolValue]) {
            UIImage *image = [SPKAssetUtils instagramIconNamed:@"circle_check_filled"
                                                      pointSize:24.0
                                                  renderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *checkmark = [[UIImageView alloc] initWithImage:image];
            checkmark.tintColor = [SPKUtils SPKColor_InstagramBlue];
            cell.accessoryView = checkmark;
        } else {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

@end

void SPKPresentLanguagePicker(UIViewController *presenter) {
    if (!presenter) {
        return;
    }
    SPKLanguagePickerViewController *picker = [SPKLanguagePickerViewController new];
    UINavigationController *navigationController = [[SPKChromeNavigationController alloc] initWithRootViewController:picker];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    UISheetPresentationController *sheet = navigationController.sheetPresentationController;
    if (sheet) {
        sheet.detents = @[ UISheetPresentationControllerDetent.largeDetent ];
        sheet.selectedDetentIdentifier = UISheetPresentationControllerDetentIdentifierLarge;
        sheet.prefersGrabberVisible = YES;
        sheet.prefersScrollingExpandsWhenScrolledToEdge = NO;
    }
    [presenter presentViewController:navigationController animated:YES completion:nil];
}
