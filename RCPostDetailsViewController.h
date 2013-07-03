//
//  RCPostDetailsViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 5/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCPost.h"
#import "RCUSer.h"
#import "RCLightboxViewController.h"

@interface RCPostDetailsViewController : RCLightboxViewController<UITableViewDataSource, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate>
- (IBAction)btnCloseTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewMainFrame;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostComment;
@property (strong, nonatomic) UIBarItem *barItemTextField;
@property (weak, nonatomic) IBOutlet UILabel *lblLandmark;
@property (weak, nonatomic) IBOutlet UILabel *lblDatePosted;
- (IBAction)backgroundTap:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewCommentTextViewBackground;
@property (weak, nonatomic) IBOutlet UITableView *tblViewPostDiscussion;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewPostImage;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (nonatomic, strong) RCPost *post;
@property (weak, nonatomic) IBOutlet UIButton *btnComment;
@property (nonatomic, strong) RCUser *postOwner;
@property (nonatomic, strong) RCUser *loggedInUser;

- (id) initWithPost:(RCPost *)post withOwner:(RCUser*)owner withLoggedInUser:(RCUser *) loggedInUser;
@end
