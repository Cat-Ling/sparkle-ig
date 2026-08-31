#import <UIKit/UIKit.h>

/// Presents the language picker as a large Sparkle-styled sheet. System Default
/// is selected when no explicit override exists; changing the value synchronizes
/// it and prompts for a restart.
void SPKPresentLanguagePicker(UIViewController *presenter);
NSString *SPKLanguageDisplayName(NSString *code);
