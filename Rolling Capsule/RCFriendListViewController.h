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
- (id)initWithUser:(RCUser *) user hideBackButton:(BOOL)hideBackbtn;
@property (weak, nonatomic) IBOutlet UITableView *tblViewFriendList;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic,strong) RCUser *user;
@end
