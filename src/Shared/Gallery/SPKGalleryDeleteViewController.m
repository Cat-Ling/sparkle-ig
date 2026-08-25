#import "SPKStrings.h"
#import "SPKGalleryDeleteViewController.h"
#import "../../AssetUtils.h"
#import "../../Utils.h"
#import "../UI/SPKIGAlertPresenter.h"
#import "SPKGalleryCoreDataStack.h"
#import "SPKGalleryFile.h"

typedef NS_ENUM(NSInteger, SPKGalleryDeleteSection) {
    SPKGalleryDeleteSectionGlobal = 0,
    SPKGalleryDeleteSectionType,
    SPKGalleryDeleteSectionSource,
    SPKGalleryDeleteSectionUser,
    SPKGalleryDeleteSectionCount
};

@interface SPKGalleryDeleteAction : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, strong, nullable) NSPredicate *predicate;
@property (nonatomic, copy, nullable) NSString *successTitle;
@property (nonatomic, assign) BOOL navigatesToUsers;
@end

@implementation SPKGalleryDeleteAction
@end

@interface SPKGalleryDeleteUserItem : NSObject
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, assign) NSInteger count;
@end

@implementation SPKGalleryDeleteUserItem
@end

@interface SPKGalleryDeleteViewController ()
@property (nonatomic, assign) SPKGalleryDeletePageMode mode;
@property (nonatomic, strong) NSArray<NSArray<SPKGalleryDeleteAction *> *> *sections;
@property (nonatomic, strong) NSArray<SPKGalleryDeleteUserItem *> *users;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *countCache;
@end

@implementation SPKGalleryDeleteViewController

- (UIView *)selectionBackgroundView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [SPKUtils SPKColor_InstagramPressedBackground];
    return view;
}

- (instancetype)initWithMode:(SPKGalleryDeletePageMode)mode {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _mode = mode;
        _countCache = @{};
        _sections = @[];
        _users = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.mode == SPKGalleryDeletePageModeRoot ? SPKL(@"GALLERY_GALLERY_DELETE_DELETE_FILES_TITLE") : SPKL(@"ALERT_ACTION_DELETE_USER");
    self.view.backgroundColor = [SPKUtils SPKColor_InstagramGroupedBackground];
    self.tableView.backgroundColor = [SPKUtils SPKColor_InstagramGroupedBackground];
    self.tableView.separatorColor = [SPKUtils SPKColor_InstagramSeparator];
    self.tableView.tintColor = [SPKUtils SPKColor_InstagramBlue];
    [self reloadDataModel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadDataModel];
    [self.tableView reloadData];
}

- (SPKGalleryDeleteAction *)actionWithTitle:(NSString *)title
                                   iconName:(NSString *)iconName
                                  predicate:(nullable NSPredicate *)predicate
                               successTitle:(nullable NSString *)successTitle {
    SPKGalleryDeleteAction *action = [SPKGalleryDeleteAction new];
    action.title = title;
    action.iconName = iconName;
    action.predicate = predicate;
    action.successTitle = successTitle;
    return action;
}

- (void)reloadDataModel {
    if (self.mode == SPKGalleryDeletePageModeUsers) {
        [self reloadUsers];
        return;
    }

    self.sections = @[
        @[ [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_ALL_FILES") iconName:@"trash" predicate:nil successTitle:SPKL(@"GALLERY_GALLERY_DELETE_FILES_DELETED_TEXT")] ],
        @[
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_ALL_IMAGES")
                         iconName:@"photo"
                        predicate:[NSPredicate predicateWithFormat:@"mediaType == %d", SPKGalleryMediaTypeImage]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_IMAGES_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_ALL_VIDEOS")
                         iconName:@"video"
                        predicate:[NSPredicate predicateWithFormat:@"mediaType == %d", SPKGalleryMediaTypeVideo]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_VIDEOS_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_ALL_AUDIO")
                         iconName:@"audio"
                        predicate:[NSPredicate predicateWithFormat:@"mediaType == %d", SPKGalleryMediaTypeAudio]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_AUDIO_DELETED_TEXT")]
        ],
        @[
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_FEED_POSTS")
                         iconName:@"feed"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceFeed]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_FEED_POSTS_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_STORIES")
                         iconName:@"story"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceStories]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_STORIES_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_REELS")
                         iconName:@"reels"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceReels]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_REELS_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_THUMBNAILS")
                         iconName:@"photo_gallery"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceThumbnail]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_THUMBNAILS_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_DM_MEDIA")
                         iconName:@"messages"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceDMs]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_DM_MEDIA_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_PROFILE_PICTURES")
                         iconName:@"user_circle"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceProfile]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_PROFILE_PICTURES_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_INSTANTS")
                         iconName:@"instants"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceInstants]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_INSTANTS_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_AUDIO_PAGE_MEDIA")
                         iconName:@"audio_page"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceAudioPage]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_AUDIO_PAGE_MEDIA_DELETED_TEXT")],
            [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_COMMENT_MEDIA")
                         iconName:@"comment"
                        predicate:[NSPredicate predicateWithFormat:@"source == %d", SPKGallerySourceComments]
                     successTitle:SPKL(@"GALLERY_GALLERY_DELETE_COMMENT_MEDIA_DELETED_TEXT")]
        ],
        @[]
    ];

    SPKGalleryDeleteAction *usersAction = [self actionWithTitle:SPKL(@"ALERT_ACTION_DELETE_USER") iconName:@"users" predicate:nil successTitle:nil];
    usersAction.navigatesToUsers = YES;
    self.sections = @[
        self.sections[0],
        self.sections[1],
        self.sections[2],
        @[ usersAction ]
    ];

    [self rebuildCountCache];
}

- (void)rebuildCountCache {
    NSManagedObjectContext *ctx = [SPKGalleryCoreDataStack shared].viewContext;
    NSMutableDictionary<NSString *, NSNumber *> *counts = [NSMutableDictionary dictionary];
    for (NSArray<SPKGalleryDeleteAction *> *section in self.sections) {
        for (SPKGalleryDeleteAction *action in section) {
            if (action.navigatesToUsers) {
                continue;
            }
            NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:@"SPKGalleryFile"];
            req.predicate = action.predicate;
            NSInteger count = [ctx countForFetchRequest:req error:nil];
            counts[action.title] = @(MAX(count, 0));
        }
    }

    NSFetchRequest *distinctReq = [[NSFetchRequest alloc] initWithEntityName:@"SPKGalleryFile"];
    distinctReq.resultType = NSDictionaryResultType;
    distinctReq.propertiesToFetch = @[ @"sourceUsername" ];
    distinctReq.returnsDistinctResults = YES;
    NSArray<NSDictionary *> *rows = [ctx executeFetchRequest:distinctReq error:nil] ?: @[];
    NSInteger userCount = 0;
    for (__unused NSDictionary *row in rows) {
        userCount += 1;
    }
    counts[@"Delete by User"] = @(userCount);
    self.countCache = counts;
}

- (void)reloadUsers {
    NSManagedObjectContext *ctx = [SPKGalleryCoreDataStack shared].viewContext;
    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:@"SPKGalleryFile"];
    NSArray<SPKGalleryFile *> *files = [ctx executeFetchRequest:req error:nil] ?: @[];

    NSMutableDictionary<NSString *, SPKGalleryDeleteUserItem *> *items = [NSMutableDictionary dictionary];
    for (SPKGalleryFile *file in files) {
        NSString *username = [file.sourceUsername stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *key = username.length > 0 ? username : @"__unknown__";
        SPKGalleryDeleteUserItem *item = items[key];
        if (!item) {
            item = [SPKGalleryDeleteUserItem new];
            item.username = username.length > 0 ? username : nil;
            item.displayName = username.length > 0 ? username : SPKL(@"GALLERY_GALLERY_DELETE_UNKNOWN_USER_TEXT");
            items[key] = item;
        }
        item.count += 1;
    }

    self.users = [[items allValues] sortedArrayUsingComparator:^NSComparisonResult(SPKGalleryDeleteUserItem *lhs, SPKGalleryDeleteUserItem *rhs) {
        return [lhs.displayName localizedCaseInsensitiveCompare:rhs.displayName];
    }];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.mode == SPKGalleryDeletePageModeUsers) {
        return nil;
    }
    switch (section) {
    case SPKGalleryDeleteSectionGlobal:
        return nil;
    case SPKGalleryDeleteSectionType:
        return SPKL(@"GALLERY_GALLERY_DELETE_DELETE_TYPE_TEXT");
    case SPKGalleryDeleteSectionSource:
        return SPKL(@"GALLERY_GALLERY_DELETE_DELETE_SOURCE_TEXT");
    case SPKGalleryDeleteSectionUser:
        return SPKL(@"ALERT_ACTION_DELETE_USER");
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.mode == SPKGalleryDeletePageModeUsers ? 1 : self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.mode == SPKGalleryDeletePageModeUsers) {
        return self.users.count;
    }
    return self.sections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    cell.backgroundColor = [SPKUtils SPKColor_InstagramSecondaryBackground];
    cell.selectedBackgroundView = [self selectionBackgroundView];
    cell.textLabel.textColor = [SPKUtils SPKColor_InstagramDestructive];
    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.textColor = [SPKUtils SPKColor_InstagramSecondaryText];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageView.tintColor = [SPKUtils SPKColor_InstagramDestructive];

    if (self.mode == SPKGalleryDeletePageModeUsers) {
        SPKGalleryDeleteUserItem *item = self.users[indexPath.row];
        cell.textLabel.text = item.displayName;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)item.count];
        cell.imageView.image = [SPKAssetUtils instagramIconNamed:@"user" pointSize:24.0];
        return cell;
    }

    SPKGalleryDeleteAction *action = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = action.title;
    NSNumber *count = self.countCache[action.title];
    if (count) {
        cell.detailTextLabel.text = count.integerValue > 0 ? [NSString stringWithFormat:@"%ld", (long)count.integerValue] : nil;
    }
    cell.imageView.image = [SPKAssetUtils instagramIconNamed:action.iconName pointSize:24.0];
    cell.accessoryType = action.navigatesToUsers ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.mode == SPKGalleryDeletePageModeUsers) {
        SPKGalleryDeleteUserItem *item = self.users[indexPath.row];
        NSPredicate *predicate = item.username.length > 0
                                     ? [NSPredicate predicateWithFormat:@"sourceUsername == %@", item.username]
                                     : [NSPredicate predicateWithFormat:@"sourceUsername == nil OR sourceUsername == ''"];
        NSString *title = [NSString stringWithFormat:SPKL(@"GALLERY_GALLERY_DELETE_DELETE_VALUE_FORMAT"), item.displayName];
        [self confirmDeleteWithTitle:title predicate:predicate successTitle:SPKL(@"GALLERY_GALLERY_DELETE_USER_FILES_DELETED_TEXT")];
        return;
    }

    SPKGalleryDeleteAction *action = self.sections[indexPath.section][indexPath.row];
    if (action.navigatesToUsers) {
        SPKGalleryDeleteViewController *vc = [[SPKGalleryDeleteViewController alloc] initWithMode:SPKGalleryDeletePageModeUsers];
        vc.onDidDelete = self.onDidDelete;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    [self confirmDeleteWithTitle:action.title predicate:action.predicate successTitle:action.successTitle ?: SPKL(@"GALLERY_DELETE_SUCCESS_TITLE")];
}

- (void)confirmDeleteWithTitle:(NSString *)title predicate:(nullable NSPredicate *)predicate successTitle:(NSString *)successTitle {
    NSManagedObjectContext *ctx = [SPKGalleryCoreDataStack shared].viewContext;
    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:@"SPKGalleryFile"];
    req.predicate = predicate;
    NSArray<SPKGalleryFile *> *files = [ctx executeFetchRequest:req error:nil] ?: @[];
    if (files.count == 0) {
        SPKNotify(kSPKNotificationGalleryBulkDelete, SPKL(@"GALLERY_GALLERY_DELETE_NO_FILES_DELETE_TEXT"), nil, @"error_filled", SPKNotificationToneError);
        return;
    }

    NSString *message = [NSString stringWithFormat:SPKL(@"GALLERY_GALLERY_DELETE_PERMANENTLY_REMOVE_VALUE_FILE_VALUE_FORMAT"), SPKLP(@"COMMON_FILE_COUNT", files.count)];
    [SPKIGAlertPresenter presentAlertFromViewController:self
                                                  title:title
                                                message:message
                                                actions:@[
                                                    [SPKIGAlertAction actionWithTitle:SPKL(@"ALERT_ACTION_CANCEL")
                                                                                style:SPKIGAlertActionStyleCancel
                                                                              handler:nil],
                                                    [SPKIGAlertAction actionWithTitle:SPKL(@"ALERT_ACTION_DELETE")
                                                                                style:SPKIGAlertActionStyleDestructive
                                                                              handler:^{
                                                                                  NSFileManager *fm = [NSFileManager defaultManager];
                                                                                  for (SPKGalleryFile *file in files) {
                                                                                      NSString *filePath = file.filePath;
                                                                                      if ([fm fileExistsAtPath:filePath]) {
                                                                                          [fm removeItemAtPath:filePath error:nil];
                                                                                      }
                                                                                      NSString *thumbPath = file.thumbnailPath;
                                                                                      if ([fm fileExistsAtPath:thumbPath]) {
                                                                                          [fm removeItemAtPath:thumbPath error:nil];
                                                                                      }
                                                                                      [ctx deleteObject:file];
                                                                                  }
                                                                                  [ctx save:nil];
                                                                                  [self reloadDataModel];
                                                                                  [self.tableView reloadData];
                                                                                  if (self.onDidDelete) {
                                                                                      self.onDidDelete();
                                                                                  }
                                                                                  SPKNotify(kSPKNotificationGalleryBulkDelete, successTitle, nil, @"circle_check_filled", SPKNotificationToneSuccess);
                                                                              }],
                                                ]];
}

@end
