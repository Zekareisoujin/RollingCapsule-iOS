//
//  RCUserProfileViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>
#import "RCUser.h"

@interface RCUserProfileViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AmazonServiceRequestDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnAvatarImg;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendAction;

@property (nonatomic, strong) RCUser *user;
@property (nonatomic, assign) int loggedinUserID;
@property (nonatomic,strong)  NSMutableData *receivedData;
@property (nonatomic, strong) AmazonS3Client *s3;
- (IBAction)btnFriendActionClicked:(id)sender;
- (IBAction)btnAvatarClicked:(id)sender;
- (id) initWithUser:(RCUser *) user  loggedinUserID:(int)_loggedinUserID;
@end
