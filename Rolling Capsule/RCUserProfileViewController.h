//
//  RCUserProfileViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"

@interface RCUserProfileViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imgViewAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendAction;

@property (nonatomic, retain) RCUser *user;
@property (nonatomic, assign) int loggedinUserID;
@property (nonatomic,retain)  NSMutableData *receivedData;
- (IBAction)btnFriendActionClicked:(id)sender;
- (id) initWithUser:(RCUser *) user  loggedinUserID:(int)_loggedinUserID;
@end
