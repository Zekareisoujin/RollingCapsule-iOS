//
//  AppDelegate.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCMainMenuViewController;
@class RCSlideoutViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) RCMainMenuViewController *menuViewController;
@property (strong, nonatomic) RCSlideoutViewController *mainViewController;
-(void)showSideMenu;
-(void)hideSideMenu;
@end
