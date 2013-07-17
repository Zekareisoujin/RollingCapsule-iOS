//
//  RCFriendListViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"
#import "UIViewController+RCCustomBackButtonViewController.h"

enum RCFriendListViewMode {
    RCFriendListViewModeFriends,
    RCFriendListViewModePendingFriends,
    RCFriendListViewModeFollowees
};
typedef enum RCFriendListViewMode RCFriendListViewMode;

@interface RCFriendListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithUser:(RCUser *)user withLoggedinUser:(RCUser*)loggedinUser;

@property (weak, nonatomic) IBOutlet UITableView *tblViewFriendList;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSMutableArray *requested_friends;
@property (nonatomic, strong) NSMutableArray *followees;
@property (weak, nonatomic) IBOutlet UIButton *btnRequests;
@property (weak, nonatomic) IBOutlet UIButton *btnFriends;
@property (weak, nonatomic) IBOutlet UIButton *btnFollowees;
@property (nonatomic,strong) RCUser *user;
@property (nonatomic,strong) RCUser *loggedinUser;

- (IBAction)btnFriendTouchUpInside:(id)sender;
- (IBAction)btnRequestsTouchUpInside:(id)sender;
- (IBAction)btnFolloweeTouchUpInside:(id)sender;

@end
