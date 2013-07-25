//
//  RCFriendListTableCell.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"
#import "RCConnectionManager.h"

@interface RCUserTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblName;
//@property (nonatomic, weak) IBOutlet UILabel *lblEmail;
@property (nonatomic, weak) IBOutlet UIImageView *imgViewAvatar;

+ (RCUserTableCell *) getFriendListTableCell:(UITableView *)tableView;
+ (CGFloat) cellHeight;

- (void) populateCellData:(RCUser *) user withLoggedInUserID:(int)loggedInUserID completion:(void (^)(void))callback;

@end
