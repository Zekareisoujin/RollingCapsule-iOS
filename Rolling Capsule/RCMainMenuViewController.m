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
#import "RCUtilities.h"
#import "RCConstants.h"

@interface RCMainMenuViewController ()

@end

@implementation RCMainMenuViewController

@synthesize navigationController = _navigationController;
@synthesize user = _user;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)btnTestTouchUpInside:(id)sender
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideSideMenu];
}

- (IBAction)btnActionMainFeedNav:(id)sender {
    RCMainFeedViewController *mainFeedViewController = [[RCMainFeedViewController alloc] init];
    [self navigateToViewControllerFromMenu:mainFeedViewController];
}

- (IBAction)btnActionUserProfileNav:(id)sender {
    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:_user viewingUser:_user];
    [self navigateToViewControllerFromMenu:userProfileViewController];
}

- (IBAction)btnActionFriendViewNav:(id)sender {
    RCFriendListViewController *friendListViewController = [[RCFriendListViewController alloc] initWithUser:_user];
    [self navigateToViewControllerFromMenu:friendListViewController];
}

- (IBAction)btnActionLogOut:(id)sender {
    [self asynchLogOutRequest];
    [self slideThenHide];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RCLogStatusDefault];
    [_navigationController popToRootViewControllerAnimated:YES];
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
    [self btnActionMainFeedNav:self];
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
