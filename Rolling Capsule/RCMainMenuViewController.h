//
//  RCMainMenuViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"
#import "RCLoginViewController.h"


@interface RCMainMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RCLoginViewControllerDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (nonatomic, strong) RCUser* user;

@property (weak, nonatomic) IBOutlet UIImageView *imgUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblUserName;
@property (weak, nonatomic) IBOutlet UITableView *menuTable;

@property (weak, nonatomic) IBOutlet UIButton *btnLogOutDropdown;
@property (weak, nonatomic) IBOutlet UIButton *btnLogOut;
@property (weak, nonatomic) IBOutlet UIImageView *btnLogOutIcon;

- (id)initWithContentView:(UINavigationController *) mainNavigationController;

- (IBAction)btnActionMainFeedNav:(id)sender;
- (IBAction)btnActionUserProfileNav:(id)sender;
- (IBAction)btnActionFriendViewNav:(id)sender;
- (IBAction)btnActionSetting:(id)sender;
- (IBAction)btnActionLogOut:(id)sender;
- (IBAction)btnActionLogOutDropDown:(id)sender;
- (void)setNavigationBarMenuBttonForViewController:(UIViewController *) viewController;
- (void)setLoggedInUser: (RCUser*)user;
@end
