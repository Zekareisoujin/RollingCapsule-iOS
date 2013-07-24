//
//  AppDelegate.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "RCPost.h"
#import "RCUser.h"
#import "RCLoginViewController.h"
#import "RCFriendListViewController.h"
#import "RCMainFeedViewController.h"
#import "RCMainMenuViewController.h"
#import "RCSlideoutViewController.h"
#import "RCNewPostViewController.h"
#import "RCPostDetailsViewController.h"
#import "RCLoadingLocationViewController.h"
#import "RCUserProfileViewController.h"
#import "RCConstants.h"


@implementation AppDelegate

@synthesize navigationController = _navigationController;
@synthesize mainViewController = _mainViewController;
@synthesize menuViewController = _menuViewController;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize userNotifications = _userNotifications;
@synthesize didUpdateLocation = _didUpdateLocation;


BOOL _didQueueOpenMainFeedOption;

+ (NSString*) debugTag {
    return @"AppDelegate";
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"9a1eac62-14de-493e-971e-bea0ff0cb99b"];
    [RCPost initPostDataModel];
    _didUpdateLocation = NO;
    _didQueueOpenMainFeedOption = NO;
    
    //set up location listening
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];

    RCLoginViewController *firstViewController;
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height) {
        firstViewController = [[RCLoginViewController alloc] initWithNibName:@"RCLoginViewController4" bundle:nil];
    }else {
        firstViewController = [[RCLoginViewController alloc] init];
    }
    
    
    _navigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];
    //navigation bar appearance
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationBarBackground.png"] forBarMetrics:UIBarMetricsDefault];
    //[[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:RCAppThemeColorRed green:RCAppThemeColorGreen blue:RCAppThemeColorBlue alpha:1.0]];

    _menuViewController = [[RCMainMenuViewController alloc] initWithContentView:_navigationController];
    
    [firstViewController setDelegate:_menuViewController];
    _mainViewController = [[RCSlideoutViewController alloc] init];
    _mainViewController.contentController = _navigationController;
    _mainViewController.menuViewController = _menuViewController;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:RCLogStatusDefault]) {
        [_menuViewController btnActionMainFeedNav:nil];
        //queue main feed open action so that the main feed is opened automatically
        //when location is updated
        RCLoadingLocationViewController *loadingViewController = [[RCLoadingLocationViewController alloc] init];
        [_navigationController setNavigationBarHidden:YES animated:NO];
        [_navigationController pushViewController:loadingViewController animated:NO];
        _didQueueOpenMainFeedOption = YES;
        //[firstViewController setUIIntera]
    }
    
    // Configure Window
    
    [self.window setRootViewController:_mainViewController];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) showSideMenu
{
    [_mainViewController showSideMenu];
}

- (void) hideSideMenu
{
    [_mainViewController hideSideMenu];
}

- (void) enableSideMenu
{
    [_mainViewController enablePanning];
}

- (void) disableSideMenu
{
    [_mainViewController disablePanning];
}

#pragma mark - CLLocationManager delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!_didUpdateLocation) {
        _didUpdateLocation = YES;
        if (_didQueueOpenMainFeedOption) {
            _didQueueOpenMainFeedOption = NO;
            [_navigationController popCurrentViewController];
            [_navigationController setNavigationBarHidden:NO animated:NO];
            RCUser *currentUser = [[RCUser alloc] initWithNSDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:RCLogUserDefault]];
            [self setCurrentUser:currentUser];
            [_menuViewController btnActionMainFeedNav:_mainViewController];
            [self enableSideMenu];
        }
    }
    _currentLocation = [locations lastObject];
    //NSLog(@"update current location %f,%f", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude);
}
#pragma mark - global data flow
- (void) setCurrentUser:(RCUser *)user {
    [RCUser setCurrentUser:user];
    [_menuViewController setLoggedInUser:user];
    NSLog(@"%@ set current user %d:%@",[AppDelegate debugTag], user.userID,user.email);
}

- (void) setNotificationList:(NSArray*)notifications {
    _userNotifications = notifications;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6] ;
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    
    if ([url.scheme hasPrefix:@"memcap"]) {
        NSLog(@"%@",url.relativePath);
        if ([url.host hasPrefix:@"users"]) {
            NSLog(@"query-str: %@",url.query);
            NSDictionary *params = [self parseQueryString:url.query];
            NSString* userIDStr = [url.relativePath substringFromIndex:[@"/" length]];
            if ([userIDStr intValue] != 0) {
                RCUser *user = [[RCUser alloc] init];
                user.userID = [userIDStr intValue];
                user.name = [params objectForKey:@"user[name]"];
                RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:self.menuViewController.user];
                [self.navigationController pushViewController:userProfileViewController animated:YES];
                [self hideSideMenu];
            }
        }
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([url.scheme hasPrefix:@"memcap"]) {
        if ([url.host hasPrefix:@"users/"]) {
            NSString* userIDStr = [url.relativePath substringFromIndex:[@"/" length]];
            if ([userIDStr intValue] != 0) {
                [RCUser getUserWithIDAsync:[userIDStr intValue] completionHandler:^(RCUser *user){
                    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:self.menuViewController.user];
                    [_navigationController pushViewController:userProfileViewController animated:YES];
                }];
            }
        }
    }
    return NO;
}
@end
