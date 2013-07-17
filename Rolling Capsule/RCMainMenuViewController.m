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

@interface RCMainMenuViewController ()

@end

@implementation RCMainMenuViewController

@synthesize navigationController = _navigationController;
@synthesize user = _user;
@synthesize menuTable = _menuTable;

NSArray *menuItemLabel;
NSArray *menuItemIcon;
int     activeMenuIndex = 0;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)openFriendRequestsView:(id)sender {
}

- (id)initWithContentView:(UINavigationController *) mainNavigationController
{
    _navigationController = mainNavigationController;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    menuItemLabel = [[NSArray alloc] initWithObjects:@"Profile", @"Main Feeds", @"Friends", @"Settings", nil];
    menuItemIcon = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"menuIconProfile"],
                                                    [UIImage imageNamed:@"menuIconMainFeeds"],
                                                    [UIImage imageNamed:@"menuIconFriends"],
                                                    [UIImage imageNamed:@"menuIconSettings"], nil];
    
    // Set table view background image
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slideMenuBackground"]];
    [backgroundView setFrame:self.menuTable.frame];
    self.menuTable.backgroundView = backgroundView;
    
    [_menuTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [menuItemLabel count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Where we configure the cell in each row
    RCMenuTableCell *cell = [RCMenuTableCell createMenuTableCell:_menuTable];
    
    [cell setIcon:[menuItemIcon objectAtIndex:indexPath.row] label:[menuItemLabel objectAtIndex:indexPath.row]];
    [cell setStatePressed: (indexPath.row == activeMenuIndex)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RCMenuTableCell cellHeight];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Not sure of a better way to do this at the moment
    switch (indexPath.row) {
        case 0:
            [self btnActionUserProfileNav:self];
            break;
        case 1:
            [self btnActionMainFeedNav:self];
            break;
        case 2:
            [self btnActionFriendViewNav:self];
            break;
        case 3:
            [self btnActionSetting:self];
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
    [mainFeedViewController setCurrentUser:_user];
    [self navigateToViewControllerFromMenu:mainFeedViewController];
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
}

- (void)initializeUserFromLogIn:(RCUser *)user {
    _user = user;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:RCLogStatusDefault];
    [[NSUserDefaults standardUserDefaults] setObject:[user getDictionaryObject] forKey:RCLogUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate enableSideMenu];

    [self btnActionMainFeedNav:self];
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

-(void) setNavigationBarMenuBttonForViewController:(UIViewController *) viewController {
    UIBarButtonItem *backButton = [self menuBarButton];

    UINavigationItem *navigationItem = viewController.navigationItem;
    navigationItem.leftBarButtonItem = backButton;
}

@end
