//
//  RCFriendListViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"

@interface RCFriendListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithUser:(RCUser *)user;

@property (weak, nonatomic) IBOutlet UITableView *tblViewFriendList;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSMutableArray *requested_friends;
- (IBAction)btnFriendTouchUpInside:(id)sender;
- (IBAction)btnRequestsTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnRequests;
@property (weak, nonatomic) IBOutlet UIButton *btnFriends;
@property (nonatomic,strong) RCUser *user;
@end
