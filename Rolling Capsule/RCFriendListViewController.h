//
//  RCFriendListViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCFriendListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (id)initWithUserID:(int) userID;
@property (weak, nonatomic) IBOutlet UITableView *tblViewFriendList;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic,retain) NSMutableData *receivedData;
@property int userID;
@end
