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
#import "RCNotification.h"
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
#import "RCOperationsManager.h"
#import "TTTAttributedLabel.h"
#import <CoreData/CoreData.h>
#import "RCFacebookHelper.h"

@implementation AppDelegate

@synthesize navigationController = _navigationController;
@synthesize mainViewController = _mainViewController;
@synthesize menuViewController = _menuViewController;
@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
@synthesize userNotifications = _userNotifications;
@synthesize didUpdateLocation = _didUpdateLocation;

BOOL _didQueueOpenMainFeedOption;
BOOL _hasUpdateCountry;

+ (NSString*) debugTag {
    return @"AppDelegate";
}

/*
 My Apps Custom uncaught exception catcher, we do special stuff here, and TestFlight takes care of the rest
 */
void HandleExceptions(NSException *exception) {
    NSLog(@"Uncaught exception : %@", exception);
    // Save application data on crash
}
/*
 My Apps Custom signal catcher, we do special stuff here, and TestFlight takes care of the rest
 */
void SignalHandler(int sig) {
    NSLog(@"Uncaught signal code %d", sig);
    // Save application data on crash
}

- (void) initDataModelLayer {
    [RCPost initPostDataModel];
    [RCUser initUserDataModel];
    [RCNotification initNotificationDataModel];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FBProfilePictureView class];
    NSSetUncaughtExceptionHandler(&HandleExceptions);
    // create the signal action structure
    struct sigaction newSignalAction;
    // initialize the signal action structure
    memset(&newSignalAction, 0, sizeof(newSignalAction));
    // set SignalHandler as the handler in the signal action structure
    newSignalAction.sa_handler = &SignalHandler;
    // set SignalHandler as the handlers for SIGABRT, SIGILL and SIGBUS
    sigaction(SIGABRT, &newSignalAction, NULL);
    sigaction(SIGILL, &newSignalAction, NULL);
    sigaction(SIGBUS, &newSignalAction, NULL);
    // Call takeOff after install your own unhandled exception and signal handlers
    
    [TestFlight takeOff:@"9a1eac62-14de-493e-971e-bea0ff0cb99b"];
    
    
    [self initDataModelLayer];
    _didUpdateLocation = NO;
    _didQueueOpenMainFeedOption = NO;
    
    //set up location listening
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingLocation];
    _hasUpdateCountry = NO;

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
    
    // Handling facebook authentication    
    if ([RCFacebookHelper shouldLogIn])
        [RCFacebookHelper openFacebookSessionWithDefaultReadPermission:^{/*doing nothing here*/}];
    
    if ([RCUser hasLoggedInUser]) {
//        [_menuViewController btnActionMainFeedNav:nil];
        //queue main feed open action so that the main feed is opened automatically
        //when location is updated
        RCLoadingLocationViewController *loadingViewController = [[RCLoadingLocationViewController alloc] init];
        [_navigationController setNavigationBarHidden:YES animated:NO];
        [_navigationController pushViewController:loadingViewController animated:NO];
        _didQueueOpenMainFeedOption = YES;
        //[firstViewController setUIIntera]
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [RCOperationsManager createUploadManager];
    });
    
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
//            RCUser *currentUser = [[RCUser alloc] initWithNSDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:RCLogUserDefault]];
//            [self setCurrentUser:currentUser];
            [_menuViewController btnActionMainFeedNav:_mainViewController];
            [self enableSideMenu];
        }
    }
    _currentLocation = [locations lastObject];
    //NSLog(@"update current location %f,%f", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude);

    if (!_hasUpdateCountry){
        [self updateCurrentCountry];
        _hasUpdateCountry = YES;
    }
}

#pragma mark - global data flow
- (void) setCurrentUser:(RCUser *)user {
    BOOL needReloadUpload = [RCUser currentUser] == nil || [RCUser currentUser].userID != user.userID;
    [RCUser setCurrentUser:user];
    if (needReloadUpload)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            [RCOperationsManager createUploadManager];
        });
    NSLog(@"%@ set current user %d:%@",[AppDelegate debugTag], user.userID,user.email);
}

- (void) setNotificationList:(NSArray*)notifications {
    _userNotifications = notifications;
}

- (void)updateCurrentCountry {
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
    
    [reverseGeocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         NSLog(@"reverseGeocodeLocation:completionHandler: Completion Handler called!");
         if (error){
             NSLog(@"Geocode failed with error: %@", error);
             return;
         }
         
         NSLog(@"Received placemarks: %@", placemarks);
         
         
         CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
         NSString *countryCode = myPlacemark.ISOcountryCode;
         NSString *countryName = myPlacemark.country;
         NSLog(@"My country code: %@ and countryName: %@", countryCode, countryName);
         _currentCountry = countryCode;
     }];
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
//            NSDictionary *params = [self parseQueryString:url.query];
            NSString* userIDStr = [url.relativePath substringFromIndex:[@"/" length]];
            if ([userIDStr intValue] != 0) {
//                RCUser *user = [[RCUser alloc] init];
//                user.userID = [userIDStr intValue];
//                user.name = [params objectForKey:@"user[name]"];
//                RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:self.menuViewController.user];
//                [self.navigationController pushViewController:userProfileViewController animated:YES];
//                [self hideSideMenu];
                
                [RCUser getUserWithIDAsync:[userIDStr intValue] completionHandler:^(RCUser *user){
                    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:[RCUser currentUser]];
                    [self.navigationController pushViewController:userProfileViewController animated:YES];
                    [self hideSideMenu];
                }];
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
                    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:[RCUser currentUser]];
                    [_navigationController pushViewController:userProfileViewController animated:YES];
                }];
            }
        }
    }
    return NO;
}
+ (void) cleanupMemory {
    [RCOperationsManager cleanupUploadData];
}

- (NSManagedObjectContext *) managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory]
                                               stringByAppendingPathComponent: @"memcap.sqlite"]];
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:[self managedObjectModel]];
    if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil URL:storeUrl options:nil error:&error]) {
        /*Error for store creation should be handled in here*/
    }
    
    return persistentStoreCoordinator;
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
@end
