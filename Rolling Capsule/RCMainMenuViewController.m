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
#import "RCOutboxViewController.h"
#import "UIImage+animatedGIF.h"

@interface RCMainMenuViewController ()

@end

@implementation RCMainMenuViewController {
    NSArray *menuItemLabel;
    NSArray *menuItemIcon;
    int     activeMenuIndex;
    BOOL    showLogOut;
    int     plusRows;
}

@synthesize navigationController = _navigationController;
@synthesize user = _user;
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
    plusRows = 0;
    activeMenuIndex = 0;
    _menuTable.tableFooterView = [[UIView alloc] init];
    [_menuTable setSeparatorColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
    // Do any additional setup after loading the view from its nib.
    
    menuItemLabel = [[NSArray alloc] initWithObjects:@"Main Feeds", @"Profile", @"Friends", @"Outbox", @"Settings", nil];
    menuItemIcon = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"menuIconMainFeeds"],
                                                    [UIImage imageNamed:@"menuIconProfile"],
                                                    [UIImage imageNamed:@"menuIconFriends"],
                                                    [UIImage imageNamed:@"menuIconFriends"],
                                                    [UIImage imageNamed:@"menuIconSettings"], nil];
    
    // Set table view background image
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slideMenuBackground"]];
    [backgroundView setFrame:_menuTable.frame];
    [_btnUserAvatar setImage:[UIImage standardLoadingImage] forState:UIControlStateNormal];
    [_menuTable setBackgroundView: backgroundView];
    [_menuTable reloadData];
    showLogOut = false;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [menuItemLabel count] + plusRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Where we configure the cell in each row
    RCMenuTableCell *cell = [RCMenuTableCell createMenuTableCell:_menuTable];
    int idx = indexPath.row;
    if (idx >= [menuItemIcon count]) {
        UITableViewCell *newCell = [[UITableViewCell alloc] init];
        [_viewLogoutRow removeFromSuperview];
        [_viewLogoutRow setHidden:NO];
        [newCell addSubview:_viewLogoutRow];
        CGRect frame = _btnLogOut.frame;
        frame.origin.x = frame.origin.y = 0;
        _viewLogoutRow.frame = frame;
        //[cell setIcon:[menuItemIcon objectAtIndex:0] label:@"Log out"];
        return newCell;
    }
    [cell setIcon:[menuItemIcon objectAtIndex:indexPath.row] label:[menuItemLabel objectAtIndex:indexPath.row]];
    [cell setCellStateNormal: (indexPath.row == activeMenuIndex)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 4)
        return [RCMenuTableCell cellHeight];
    else
        return _viewLogoutRow.frame.size.height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Not sure of a better way to do this at the moment
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            [self btnActionMainFeedNav:self];
            break;
        case 1:
            [self btnActionUserProfileNav:self];
            break;
        case 2:
            [self btnActionFriendViewNav:self];
            break;
        case 3:
            [self btnActionOutboxNav:self];
            break;
        case 4:
            //[self btnActionSetting:self];
            //[self btnActionLogOutDropDown:self];
            if (plusRows == 0) {
                plusRows = 1;
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:[menuItemLabel count] inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            } else {
                plusRows = 0;
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:[menuItemLabel count] inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            }
            return;
            //[tableView reloadData];
            break;
        default:
            break;
    }
    
    activeMenuIndex = indexPath.row;
    [tableView reloadData];
}

#pragma mark - Menu actions

- (IBAction)btnActionMainFeedNav:(id)sender {
    RCMainFeedViewController *mainFeedViewController = [[RCMainFeedViewController alloc] init];
    //_navigationController.delegate = mainFeedViewController;
    [mainFeedViewController setCurrentUser:_user];
    [self navigateToViewControllerFromMenu:mainFeedViewController];
}
- (IBAction)btnActionOutboxNav:(id)sender {
    RCOutboxViewController*outboxViewController = [[RCOutboxViewController alloc] init];
    [self navigateToViewControllerFromMenu:outboxViewController];
}
- (IBAction)btnActionUserProfileNav:(id)sender {
    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:_user viewingUser:_user];
    [self navigateToViewControllerFromMenu:userProfileViewController];
}

- (IBAction)btnActionFriendViewNav:(id)sender {
    RCFriendListViewController *friendListViewController = [[RCFriendListViewController alloc] initWithUser:_user withLoggedinUser:_user];
    [self navigateToViewControllerFromMenu:friendListViewController];
}

- (IBAction)btnActionSetting:(id)sender {
    RCSettingViewController *settingViewController = [[RCSettingViewController alloc] initWithUser:_user];
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
    
    [self refreshUserAvatar];
}

- (void)userDidLogIn:(RCUser *)user {
    [self setLoggedInUser:user];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RCLogStatusDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate enableSideMenu];

    [self btnActionMainFeedNav:self];
}

- (void)setLoggedInUser: (RCUser*)user {
    _user = user;
    [[NSUserDefaults standardUserDefaults] setObject:[user getDictionaryObject] forKey:RCLogUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (UIBarButtonItem*) menuBarButton {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"              "
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(showSelfAsSideMenu)];
    UIImage *image = [[UIImage imageNamed:@"menu.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [backButton setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    return backButton;
}

- (void)setNavigationBarMenuBttonForViewController:(UIViewController *) viewController {
    UIBarButtonItem *backButton = [self menuBarButton];

    UINavigationItem *navigationItem = viewController.navigationItem;
    navigationItem.leftBarButtonItem = backButton;
}

- (void) refreshUserAvatar {
    [_lblUserName setText:_user.name];
    [_lblUserName setLinkAttributes:[[_lblUserName attributedText] attributesAtIndex:0 effectiveRange:nil]];
    [_lblUserName setActiveLinkAttributes:[[_lblUserName attributedText] attributesAtIndex:0 effectiveRange:nil]];
    [_lblUserName addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"memcap:/%@/%d?user[name]=%@",RCUsersResource,_user.userID, urlEncodeValue(_user.name)]] withRange:NSMakeRange(0,[_lblUserName.text length])];
    [_lblUserName setDelegate:(AppDelegate*)[[UIApplication sharedApplication] delegate]];
    
    [_user getUserAvatarAsync:_user.userID completionHandler:^(UIImage* img){
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
    [appDelegate disableSideMenu];
    [self slideThenHide];
}

- (IBAction)btnActionLogOutDropDown:(id)sender {
    float offset;
    offset = (!showLogOut?40:-40);
    showLogOut = !showLogOut;
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect rect = _btnLogOut.frame;
        rect.origin.y += offset;
        [_btnLogOut setFrame:rect];
        rect = _btnLogOutIcon.frame;
        rect.origin.y += offset;
        [_btnLogOutIcon setFrame:rect];
    }];
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
        alertStatus(@"Log Out Failed.", @"Log Out Failed!", self);
    }
}

@end
