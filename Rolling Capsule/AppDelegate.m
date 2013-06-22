//
//  AppDelegate.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "RCLoginViewController.h"
#import "RCFriendListViewController.h"
#import "RCMainFeedViewController.h"
#import "RCMainMenuViewController.h"
#import "RCSlideoutViewController.h"
#import "RCNewPostViewController.h"
#import "RCPostDetailsViewController.h"
#import "RCConstants.h"


@implementation AppDelegate

@synthesize navigationController = _navigationController;
@synthesize mainViewController = _mainViewController;
@synthesize menuViewController = _menuViewController;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize userNotifications = _userNotifications;

+ (NSString*) debugTag {
    return @"AppDelegate";
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"9a1eac62-14de-493e-971e-bea0ff0cb99b"];
    RCUser *user = [[RCUser alloc] init];
    user.name = @"lolo";
    user.email = @"lolotp@hotmail.com";
    user.userID = 1;
    RCPost *post = [[RCPost alloc] init];
    post.postID = 14;
    post.content = @"hh";
    post.fileUrl = @"9EC1DEF34C8047388BBDCBE8682AFEA9";
    post.longitude = -122.406417;
    post.latitude = 37.785834;
    post.userID = 1;
    post.viewCount = post.likeCount = 0;
    post.privacyOption = @"friends";
    RCUser *owner = [[RCUser alloc] init];
    owner.name = @"lolo";
    owner.email = @"lolotp@hotmail.com";
    owner.userID = 1;
    
    //RCPostDetailsViewController *firstViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:user];
    RCLoginViewController *firstViewController = [[RCLoginViewController alloc] init];
    
    
    _navigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];
    _menuViewController = [[RCMainMenuViewController alloc] initWithContentView:_navigationController];
    
    firstViewController.delegate = _menuViewController;
    _mainViewController = [[RCSlideoutViewController alloc] init];
    _mainViewController.contentController = _navigationController;
    _mainViewController.menuViewController = _menuViewController;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:RCLogStatusDefault]) {
        [_menuViewController btnActionMainFeedNav:_mainViewController];
    }
    
    // Configure Window
    
    [self.window setRootViewController:_mainViewController];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
    
    [_menuViewController.view setUserInteractionEnabled:NO];
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

-(void)showSideMenu
{
    [_mainViewController showSideMenu];
}

-(void)hideSideMenu
{
    [_mainViewController hideSideMenu];
}

#pragma mark - CLLocationManager delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    _currentLocation = [locations lastObject];
    //NSLog(@"update current location %f,%f", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude);
}
#pragma mark - global data flow
- (void) setCurrentUser:(RCUser *)user {
    _menuViewController.user = user;
    [_menuViewController.view setUserInteractionEnabled:YES];
    NSLog(@"%@ set current user %d:@",[AppDelegate debugTag], user.userID,user.email);
}

- (void) setNotificationList:(NSArray*)notifications {
    _userNotifications = notifications;
}
@end
