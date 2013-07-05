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

@interface RCUserProfileViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AmazonServiceRequestDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *btnAvatarImg;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendAction;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UIButton *btnDeclineRequest;

@property (nonatomic, strong) RCUser *profileUser;
@property (nonatomic, strong) RCUser *viewingUser;
@property (nonatomic, strong) NSArray *postList;
@property (nonatomic, assign) int viewingUserID;
- (IBAction)btnFriendActionClicked:(id)sender;
- (IBAction)btnAvatarClicked:(id)sender;
- (id) initWithUser:(RCUser *) profileUser  viewingUser:(RCUser *) viewingUser;
@end
