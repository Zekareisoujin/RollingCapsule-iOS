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

@implementation AppDelegate

@synthesize navigationController = _navigationController;
@synthesize mainViewController = _mainViewController;
@synthesize menuViewController = _menuViewController;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    RCUser *user = [[RCUser alloc] init];
    user.name = @"lolo";
    user.email = @"lolotp@hotmail.com";
    user.userID = 1;
    RCFriendListViewController *firstViewController = [[RCFriendListViewController alloc] initWithUser:user];
    //RCNewPostViewController *firstViewController = [[RCNewPostViewController alloc] initWithUser:user];
    //RCLoginViewController *firstViewController = [[RCLoginViewController alloc] init];
    _navigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];
    _mainViewController = [[RCSlideoutViewController alloc] init];
    _menuViewController = [[RCMainMenuViewController alloc] init];
    
    _mainViewController = [[RCSlideoutViewController alloc] init];
    _mainViewController.contentController = _navigationController;
    _mainViewController.menuViewController = _menuViewController;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Configure Window
    
    [self.window setRootViewController:_mainViewController];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];
    
    /*[[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                           [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8],UITextAttributeTextShadowColor,
                                                           [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                           UITextAttributeTextShadowOffset,
                                                           [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:21.0], UITextAttributeFont, nil]];
    UIImage *backButtonImage = [[UIImage imageNamed:@"back_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(4,4,4,0)];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonImage  forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];*/
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
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
}

@end
