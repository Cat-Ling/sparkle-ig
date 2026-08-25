#import <UIKit/UIKit.h>
/// Menu for the root settings translate button. System Default is selected when
/// no explicit override exists; changing the value synchronizes it and prompts a restart.
UIMenu *SPKLanguageMenu(void);
NSString *SPKLanguageDisplayName(NSString *code);
