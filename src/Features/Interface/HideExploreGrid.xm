#import "../../InstagramHeaders.h"
#import "../../Utils.h"
#import "../../Shared/Account/SPKAccountManager.h"

%group SPKHideExploreGridHooks

%hook IGExploreGridViewController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(spk_updateExploreGridVisibility)
                                                 name:SPKHideExploreGridPreferenceDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(spk_updateExploreGridVisibility)
                                                 name:SPKAccountDidChangeNotification
                                               object:nil];
    [self spk_updateExploreGridVisibility];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self spk_updateExploreGridVisibility];
}

%new
- (void)spk_updateExploreGridVisibility {
    BOOL hidden = [SPKUtils getBoolPref:@"interface_hide_explore_grid"];
    self.view.hidden = hidden;
    SPKLog(@"General", @"[Sparkle] Explore grid visibility updated: %@", hidden ? @"hidden" : @"visible");
}

%end

%hook IGExploreViewController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(spk_updateExploreShimmerVisibility)
                                                 name:SPKHideExploreGridPreferenceDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(spk_updateExploreShimmerVisibility)
                                                 name:SPKAccountDidChangeNotification
                                               object:nil];
    [self spk_updateExploreShimmerVisibility];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self spk_updateExploreShimmerVisibility];
}

%new
- (void)spk_updateExploreShimmerVisibility {
    IGShimmeringGridView *shimmeringGridView = MSHookIvar<IGShimmeringGridView *>(self, "_shimmeringGridView");
    shimmeringGridView.hidden = [SPKUtils getBoolPref:@"interface_hide_explore_grid"];
}

%end

%end

extern "C" void SPKInstallHideExploreGridHooksIfEnabled(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        %init(SPKHideExploreGridHooks);
    });
}
