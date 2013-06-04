//
//  RCFriendListTableCell.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"

@interface RCFriendListTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet UILabel *lblEmail;
@property (nonatomic, weak) IBOutlet UIImageView *imgViewAvatar;
-(void) getAvatarImageFromInternet:(RCUser *) user withLoggedInUserID:(int)loggedInUserID;
@end
