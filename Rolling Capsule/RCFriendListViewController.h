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

@interface RCFriendListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITextFieldDelegate>

- (id)initWithUser:(RCUser *)user withLoggedinUser:(RCUser*)loggedinUser;

@property (weak, nonatomic) IBOutlet UIImageView *imgUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblTableTitle;
@property (weak, nonatomic) IBOutlet UITableView *tblViewFriendList;
@property (weak, nonatomic) IBOutlet UIButton *btnRequests;
@property (weak, nonatomic) IBOutlet UIButton *btnFriends;
@property (weak, nonatomic) IBOutlet UIButton *btnFollowees;

@property (weak, nonatomic) IBOutlet UITextField *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *btnSearchBarCancel;

@property (weak, nonatomic) IBOutlet UIImageView *tableTitleBackground;
@property (weak, nonatomic) IBOutlet UILabel *tableTitleLabel;
@property (nonatomic,strong) RCUser *user;
@property (nonatomic,strong) RCUser *loggedinUser;
@property (strong,nonatomic) NSMutableArray *searchResultList;
- (IBAction)btnBackgroundTap:(id)sender;
- (IBAction)btnSearchBarCancelTouchUpInside:(id)sender;

- (IBAction)btnFriendTouchUpInside:(id)sender;
- (IBAction)btnRequestsTouchUpInside:(id)sender;
- (IBAction)btnFolloweeTouchUpInside:(id)sender;

@end
