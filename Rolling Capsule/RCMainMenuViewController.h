//
//  RCMainMenuViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"


@interface RCMainMenuViewController : UIViewController

@property (strong, nonatomic) UINavigationController *navigationController;
@property (nonatomic, strong) RCUser* user;

@property (weak, nonatomic) IBOutlet UIButton *btnMainFeedNav;
@property (weak, nonatomic) IBOutlet UIButton *btnUserProfileNav;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendViewNav;
@property (weak, nonatomic) IBOutlet UIButton *btnLogOut;

- (IBAction)openFriendRequestsView:(id)sender;

- (id)initWithContentView:(UINavigationController *) mainNavigationController;

- (IBAction)btnTestTouchUpInside:(id)sender;
- (IBAction)btnActionMainFeedNav:(id)sender;
- (IBAction)btnActionUserProfileNav:(id)sender;
- (IBAction)btnActionFriendViewNav:(id)sender;
- (IBAction)btnActionLogOut:(id)sender;

@end
