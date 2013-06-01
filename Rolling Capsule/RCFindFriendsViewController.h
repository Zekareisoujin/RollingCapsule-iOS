//
//  RCFindFriendsViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"
@interface RCFindFriendsViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarFriends;
@property (weak, nonatomic) IBOutlet UITableView *tblViewFoundUsers;
@property (nonatomic,retain) NSMutableData *receivedData;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) RCUser* user;

- (id)initWithUser:(RCUser *)user;
@end
