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

typedef void (^TableCellRespondBlock)(BOOL);

@interface RCUserTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblName;
@property (nonatomic, weak) IBOutlet UIImageView *imgViewAvatar;
@property (weak, nonatomic) IBOutlet UIButton *btnAccept;
@property (weak, nonatomic) IBOutlet UIButton *btnReject;
@property (strong, nonatomic) RCUser* user;
@property (assign, nonatomic) int     friendshipID;
@property (nonatomic, copy) TableCellRespondBlock completionHandler;

+ (RCUserTableCell *) getFriendListTableCell:(UITableView *)tableView;
+ (CGFloat) cellHeight;

- (void)populateCellData:(RCUser *) user withLoggedInUserID:(int)loggedInUserID requestCell:(BOOL)isRequest;
- (IBAction)btnAcceptTouchedUpInside:(id)sender;
- (IBAction)btnRejectTouchedUpInside:(id)sender;

@end
