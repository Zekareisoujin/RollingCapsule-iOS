//
//  RCMainMenuViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMainMenuViewController.h"
#import "AppDelegate.h"
#import "RCMainFeedViewController.h"
#import "RCUserProfileViewController.h"
#import "RCFriendListViewController.h"
#import "RCSettingViewController.h"
#import "RCUtilities.h"
#import "RCConstants.h"
#import "RCMenuTableCell.h"
#import "RCMenuTableCell2.h"
#import "RCOutboxViewController.h"
#import "RCOperationsManager.h"
#import "UIImage+animatedGIF.h"
#import <Foundation/Foundation.h>
#import "SBJson.h"

@interface RCMainMenuViewController ()

@end

@implementation RCMainMenuViewController {
//    NSArray *menuItemLabel;
//    NSArray *menuItemIcon;
    int     activeMenuIndex;
    BOOL    conciergeInitialized;
//    BOOL    showLogOut;
//    int     plusRows;
}

@synthesize navigationController = _navigationController;
@synthesize menuTable = _menuTable;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithContentView:(UINavigationController *) mainNavigationController
{
    _navigationController = mainNavigationController;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    plusRows = 0;
    activeMenuIndex = 0;
    _menuTable.tableFooterView = [[UIView alloc] init];
    [_menuTable setSeparatorColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
    // Do any additional setup after loading the view from its nib.
    
//    menuItemLabel = [[NSArray alloc] initWithObjects:@"Main Feeds", @"Profile", @"Friends", @"Outbox", @"Settings", nil];
//    menuItemIcon = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"menuIconMainFeeds"],
//                                                    [UIImage imageNamed:@"menuIconProfile"],
//                                                    [UIImage imageNamed:@"menuIconFriends"],
//                                                    [UIImage imageNamed:@"menuIconOutbox"],
//                                                    [UIImage imageNamed:@"menuIconSettings"], nil];
    
    // Set table view background image
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slideMenuBackground"]];
    [backgroundView setFrame:_menuTable.frame];
    [_btnUserAvatar setImage:[UIImage standardLoadingImage] forState:UIControlStateNormal];
    [_menuTable setBackgroundView: backgroundView];
//    [_menuTable reloadData];
//    showLogOut = false;
    
    conciergeInitialized = NO;
    [self initializeMenuTable];
    [self initializeConcierge];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

- (void)initializeConcierge {
    NSDictionary *sgList = [[NSDictionary alloc]
        initWithObjectsAndKeys:@"http://itunes.apple.com/sg/lookup?id=615376522",
                                   RCMenuItemConciergeGame,
                               @"http://itunes.apple.com/sg/lookup?id=486630839", RCMenuItemConciergeUtility,
                               @"http://itunes.apple.com/sg/lookup?id=375971134", RCMenuItemConciergeTravel,
                               @"http://itunes.apple.com/sg/lookup?id=504162619", RCMenuItemConciergeEmergency,
                               @"http://itunes.apple.com/sg/lookup?id=395897074", RCMenuItemConciergeShopping, nil];
    
    NSDictionary *twList = [[NSDictionary alloc]
        initWithObjectsAndKeys:@"http://itunes.apple.com/tw/lookup?id=649232055", RCMenuItemConciergeGame,
                               @"http://itunes.apple.com/tw/lookup?id=366479443", RCMenuItemConciergeUtility,
                               @"http://itunes.apple.com/tw/lookup?id=656617797", RCMenuItemConciergeEmergency,
                               @"http://itunes.apple.com/tw/lookup?id=596652968", RCMenuItemConciergeShopping, nil];

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *country = appDelegate.currentCountry;
    NSDictionary *listToUse;
    
    if ([country isEqualToString:@"SG"])
        listToUse = sgList;
    else if ([country isEqualToString:@"TW"])
        listToUse = twList;
    else
        listToUse = sgList; // lol
    
    for (NSString* key in listToUse) {
        NSURL *url=[NSURL URLWithString:[listToUse objectForKey:key]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            [RCConnectionManager endConnection];
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *jsonData = [responseData JSONValue];
            NSLog(@"App data: %@",jsonData);

            if (jsonData != nil) {
                NSDictionary *appInfo = [[jsonData objectForKey:@"results"] objectAtIndex:0];
                
                // image:
                NSURL *imageURL = [NSURL URLWithString:[appInfo objectForKey:@"artworkUrl60"]];
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                [_menuTree setObject:image forKeyPath:RCMenuKeyIcon2 forTreeItem:key];
                
                // name:
                NSString *appName = [appInfo objectForKey:@"trackName"];
                [_menuTree setObject:appName forKeyPath:RCMenuKeyDisplayedName forTreeItem:key];
                
                // link:
                NSURL *ituneUrl = [NSURL URLWithString:[appInfo objectForKey:@"trackViewUrl"]];
                [_menuTree setObject:ituneUrl forKeyPath:RCMenuKeySelectorLoad forTreeItem:key];
                
                // selector:
                [_menuTree setObject:NSStringFromSelector(@selector(goToURL:)) forKeyPath:RCMenuKeySelector forTreeItem:key];
            }
            conciergeInitialized = YES;
        }];
    }
}

- (void)initializeMenuTable {
    // Initialize menu table
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"menuContent" ofType:@"json"];
    _menuTree = [[RCTreeListModel alloc] initWithJSONFilePath:filePath];
    
    // Initialize menu icons
    [_menuTree setObject:[UIImage imageNamed:@"menuIconMainFeeds"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemMainFeed];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconProfile"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemProfile];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconFriends"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemFriend];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconOutbox"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemOutbox];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconConcierge"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemConcierge];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconSettings"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemSettings];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconLogout"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemSettingsLogOut];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconConciergeGame"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemConciergeGame];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconConciergeUtility"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemConciergeUtility];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconConciergeTravel"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemConciergeTravel];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconConciergeShop"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemConciergeShopping];
    [_menuTree setObject:[UIImage imageNamed:@"menuIconConciergeEmergency"] forKeyPath:RCMenuKeyIcon forTreeItem:RCMenuItemConciergeEmergency];
    
    // Initialize menu selector
    [_menuTree setObject:NSStringFromSelector(@selector(btnActionMainFeedNav:)) forKeyPath:RCMenuKeySelector forTreeItem:RCMenuItemMainFeed];
    [_menuTree setObject:NSStringFromSelector(@selector(btnActionUserProfileNav:)) forKeyPath:RCMenuKeySelector forTreeItem:RCMenuItemProfile];
    [_menuTree setObject:NSStringFromSelector(@selector(btnActionFriendViewNav:)) forKeyPath:RCMenuKeySelector forTreeItem:RCMenuItemFriend];
    [_menuTree setObject:NSStringFromSelector(@selector(btnActionOutboxNav:)) forKeyPath:RCMenuKeySelector forTreeItem:RCMenuItemOutbox];
    [_menuTree setObject:NSStringFromSelector(@selector(btnActionLogOut:)) forKeyPath:RCMenuKeySelector forTreeItem:RCMenuItemSettingsLogOut];
    
    [_menuTable reloadData];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [menuItemLabel count] + plusRows;
    return _menuTree.cellCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Where we configure the cell in each row
//    RCMenuTableCell *cell = [RCMenuTableCell createMenuTableCell:_menuTable];
//    int idx = indexPath.row;
//    if (idx >= [menuItemIcon count]) {
//        UITableViewCell *newCell = [[UITableViewCell alloc] init];
//        [_viewLogoutRow removeFromSuperview];
//        [_viewLogoutRow setHidden:NO];
//        [newCell addSubview:_viewLogoutRow];
//        CGRect frame = _btnLogOut.frame;
//        frame.origin.x = frame.origin.y = 0;
//        _viewLogoutRow.frame = frame;
//        //[cell setIcon:[menuItemIcon objectAtIndex:0] label:@"Log out"];
//        return newCell;
//    }
//    [cell setIcon:[menuItemIcon objectAtIndex:indexPath.row] label:[menuItemLabel objectAtIndex:indexPath.row]];
//    [cell setCellStateNormal: (indexPath.row == activeMenuIndex)];
//    
//    return cell;
    
    NSMutableDictionary *item = [_menuTree itemForRowAtIndexPath:indexPath];
    UIImage *icon = [item objectForKey:RCMenuKeyIcon];
    if (icon == nil)
        icon = [UIImage imageNamed:@"loading2.gif"];
    NSString *label = [item objectForKey:RCMenuKeyDisplayedName];
    if (label == nil)
        label = [item objectForKey:RCMenuKeyKeyPath];
    
    if ([_menuTree levelForRowAtIndexPath:indexPath] < 1) {
        RCMenuTableCell *cell = [RCMenuTableCell createMenuTableCell:_menuTable];
        [cell.imgCellIcon setImage:icon];
        [cell.lblCellTitle setText:label];
        [cell setCellStateNormal:NO];
        if ([[item valueForKeyPath:@"value.@count"] intValue] > 0)
            [cell setDropDownIconVisible:YES openState:[[item valueForKeyPath:@"isOpen"] boolValue]];
        else
            [cell setCellStateNormal: (indexPath.row == activeMenuIndex)];
        return cell;
    }else {
        RCMenuTableCell2 *cell = [RCMenuTableCell2 createMenuTableCell:_menuTable];
        [cell.imgCellIcon setImage:icon];
        [cell.lblCellTitle setText:label];
        
        UIImage *icon2 = [item objectForKey:RCMenuKeyIcon2];
        if (icon2 != nil) [cell.imgCellIcon2 setImage:icon2];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_menuTree levelForRowAtIndexPath:indexPath] < 1)
        return [RCMenuTableCell cellHeight];
    else
        return [RCMenuTableCell2 cellHeight];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Not sure of a better way to do this at the moment
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    switch (indexPath.row) {
//        case 0:
//            [self btnActionMainFeedNav:self];
//            break;
//        case 1:
//            [self btnActionUserProfileNav:self];
//            break;
//        case 2:
//            [self btnActionFriendViewNav:self];
//            break;
//        case 3:
//            [self btnActionOutboxNav:self];
//            break;
//        case 4:
//            //[self btnActionSetting:self];
//            //[self btnActionLogOutDropDown:self];
//            if (plusRows == 0) {
//                plusRows = 1;
//                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:[menuItemLabel count] inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
//            } else {
//                plusRows = 0;
//                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:[menuItemLabel count] inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
//            }
//            return;
//            //[tableView reloadData];
//            break;
//        default:
//            break;
//    }
//    
//    activeMenuIndex = indexPath.row;
//    [tableView reloadData];
//    int item_count = [[item valueForKeyPath:@"value.@count"] intValue];

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSMutableDictionary *item = [_menuTree itemForRowAtIndexPath:indexPath];
    RCMenuTableCell *cell = (RCMenuTableCell*)[tableView cellForRowAtIndexPath:indexPath];
    int item_count = [_menuTree numberOfChildrenForRowAtIndexPath:indexPath];
    if (item_count<=0) {
        activeMenuIndex = indexPath.row;
        NSString* selectorStr = [item valueForKeyPath:RCMenuKeySelector];
        id selectorLoad = [item valueForKeyPath:RCMenuKeySelectorLoad];
        
        if (selectorStr != nil) {
            [self performSelector:NSSelectorFromString(selectorStr) withObject:selectorLoad];
        }
        [tableView reloadData];
        return;
    }
    
    BOOL newState = ![_menuTree isCellOpenForRowAtIndexPath:indexPath];
    [_menuTree setOpenClose:newState forRowAtIndexPath:indexPath];
    
    NSMutableArray *openItems = [[NSMutableArray alloc] init];
    for (int i=0; i<item_count; i++){
        NSIndexPath *idxPath = [NSIndexPath indexPathForItem:(indexPath.row + 1 + i) inSection:0];
        [openItems addObject:idxPath];
    }
    
    if (newState) {
        [tableView insertRowsAtIndexPaths:openItems withRowAnimation:UITableViewRowAnimationTop];
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:(indexPath.row + item_count) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }else {
        [tableView deleteRowsAtIndexPaths:openItems withRowAnimation:UITableViewRowAnimationTop];
    }
    if ([_menuTree levelForRowAtIndexPath:indexPath] < 1)
        [cell setDropDownIconVisible:YES openState:newState];

}

#pragma mark - Menu actions

- (IBAction)btnActionMainFeedNav:(id)sender {
    RCMainFeedViewController *mainFeedViewController = [[RCMainFeedViewController alloc] init];
    //_navigationController.delegate = mainFeedViewController;
    [mainFeedViewController setCurrentUser:[RCUser currentUser]];
    [self navigateToViewControllerFromMenu:mainFeedViewController];
}
- (IBAction)btnActionOutboxNav:(id)sender {
    RCOutboxViewController*outboxViewController = [[RCOutboxViewController alloc] init];
    [self navigateToViewControllerFromMenu:outboxViewController];
}
- (IBAction)btnActionUserProfileNav:(id)sender {
    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:[RCUser currentUser] viewingUser:[RCUser currentUser]];
    [self navigateToViewControllerFromMenu:userProfileViewController];
}

- (IBAction)btnActionFriendViewNav:(id)sender {
    RCFriendListViewController *friendListViewController = [[RCFriendListViewController alloc] initWithUser:[RCUser currentUser] withLoggedinUser:[RCUser currentUser]];
    [self navigateToViewControllerFromMenu:friendListViewController];
}

- (IBAction)btnActionSetting:(id)sender {
    RCSettingViewController *settingViewController = [[RCSettingViewController alloc] initWithUser:[RCUser currentUser]];
    [self navigateToViewControllerFromMenu:settingViewController];
}

- (void)slideThenHide
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideSideMenu];
}

- (void) navigateToViewControllerFromMenu:(UIViewController*) viewController {
    viewController.navigationItem.hidesBackButton = YES;
    [_navigationController popToRootViewControllerAnimated:NO];
    [_navigationController pushViewController:viewController animated:NO];
    [self setNavigationBarMenuBttonForViewController:viewController];
    [self slideThenHide];
}

- (void) showSelfAsSideMenu {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showSideMenu];
    
    if (!conciergeInitialized)
        [self initializeConcierge];
    [self refreshUserAvatar];
}

- (void)userDidLogIn:(RCUser *)user {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RCLogStatusDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate enableSideMenu];

    [self btnActionMainFeedNav:self];
}

- (UIBarButtonItem*) menuBarButton {
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
//                                   initWithTitle:@"              "
//                                   style:UIBarButtonItemStyleBordered
//                                   target:self
//                                   action:@selector(showSelfAsSideMenu)];
//    UIImage *image = [[UIImage imageNamed:@"menu.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
//    [backButton setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//    return backButton;
    
    UIImage *menuButtonImage = [UIImage imageNamed:@"menu"];
    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [menuButton setFrame:CGRectMake(0,0,menuButtonImage.size.width, menuButtonImage.size.height)];
    [menuButton setBackgroundImage:menuButtonImage forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(showSelfAsSideMenu) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *ret = [[UIBarButtonItem alloc] initWithCustomView:menuButton];
    return ret;
}

- (void)setNavigationBarMenuBttonForViewController:(UIViewController *) viewController {
    UIBarButtonItem *backButton = [self menuBarButton];

    UINavigationItem *navigationItem = viewController.navigationItem;
    navigationItem.leftBarButtonItem = backButton;
}

- (void) refreshUserAvatar {
    [_lblUserName setText:[RCUser currentUser].name];
    [_lblUserName setLinkAttributes:[[_lblUserName attributedText] attributesAtIndex:0 effectiveRange:nil]];
    [_lblUserName setActiveLinkAttributes:[[_lblUserName attributedText] attributesAtIndex:0 effectiveRange:nil]];
    [_lblUserName addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"memcap:/%@/%d?user[name]=%@",RCUsersResource,[RCUser currentUser].userID, urlEncodeValue([RCUser currentUser].name)]] withRange:NSMakeRange(0,[_lblUserName.text length])];
    [_lblUserName setDelegate:(AppDelegate*)[[UIApplication sharedApplication] delegate]];
    
    [[RCUser currentUser] getUserAvatarAsync:[RCUser currentUser].userID completionHandler:^(UIImage* img){
        dispatch_async(dispatch_get_main_queue(), ^{
            [_btnUserAvatar setImage:img forState:UIControlStateNormal];
        });
    }];
}

- (IBAction)btnActionLogOut:(id)sender {
    [self asynchLogOutRequest];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RCLogStatusDefault];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:RCLogUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_navigationController popToRootViewControllerAnimated:YES];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[appDelegate setCurrentUser:nil];
    [RCOperationsManager clearUploadManager];
    [appDelegate disableSideMenu];
    [self slideThenHide];
}

- (IBAction)btnActionLogOutDropDown:(id)sender {
//    float offset;
//    offset = (!showLogOut?40:-40);
//    showLogOut = !showLogOut;
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        CGRect rect = _btnLogOut.frame;
//        rect.origin.y += offset;
//        [_btnLogOut setFrame:rect];
//        rect = _btnLogOutIcon.frame;
//        rect.origin.y += offset;
//        [_btnLogOutIcon setFrame:rect];
//    }];
}

- (void)goToURL: (NSURL*) url {
    NSLog(@"Going to url: %@", url);
    [[UIApplication sharedApplication] openURL:url];
}

- (void)asynchLogOutRequest
{
    //Asynchronous Request
    @try {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCSessionsResource]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(@"Log Out Failed.");
    }
}

- (IBAction)btnOptionsTouchUpInside:(id)sender {
    static RCSettingViewController *vc = nil;
    if (vc == nil) vc = [[RCSettingViewController alloc] init];
    [self navigateToViewControllerFromMenu:vc];
}
@end
