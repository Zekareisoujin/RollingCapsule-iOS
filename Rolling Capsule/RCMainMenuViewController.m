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
#import "RCFriendListViewController.h"
#import "Util.h"
#import "Constants.h"

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
    RCMainFeedViewController *mainFeedViewController = [[RCMainFeedViewController alloc] initWithUser:_user hideBackButton:YES];
    [_navigationController popToRootViewControllerAnimated:NO];
    [_navigationController pushViewController:mainFeedViewController animated:NO];
    [self slideThenHide];
}

- (IBAction)btnActionFriendViewNav:(id)sender {
    RCFriendListViewController *friendListViewController = [[RCFriendListViewController alloc] initWithUser:_user hideBackButton:YES];
    [_navigationController popToRootViewControllerAnimated:NO];
    [_navigationController pushViewController:friendListViewController animated:NO];
    [self slideThenHide];
}

- (IBAction)btnActionLogOut:(id)sender {
    [self asynchLogOutRequest];
    [self slideThenHide];
    [_navigationController popToRootViewControllerAnimated:YES];
}

- (void)slideThenHide
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate hideSideMenu];
}

- (void)initializeUserFromLogIn:(RCUser *)user {
    _user = user;
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
             /*NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
             NSLog(@"%@",jsonData);*/
             
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Log Out Failed.", @"Log Out Failed!", self);
    }
}

@end
