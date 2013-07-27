//
//  AppDelegate.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TestFlight.h"
#import "TTTAttributedLabel.h"

#define NSLog TFLog

@class RCMainMenuViewController;
@class RCSlideoutViewController;
@class RCUser;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, TTTAttributedLabelDelegate> {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) RCMainMenuViewController *menuViewController;
@property (strong, nonatomic) RCSlideoutViewController *mainViewController;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation        *currentLocation;
@property (strong, nonatomic) NSArray           *userNotifications;
@property (assign, nonatomic) BOOL               didUpdateLocation;
@property (strong, nonatomic) NSString          *currentCountry;

- (NSString *)applicationDocumentsDirectory;
- (void) showSideMenu;
- (void) hideSideMenu;
- (void) enableSideMenu;
- (void) disableSideMenu;
- (void) setCurrentUser:(RCUser*)user;
- (void) setNotificationList:(NSArray*)notifications;
+ (void) cleanupMemory;
@end
