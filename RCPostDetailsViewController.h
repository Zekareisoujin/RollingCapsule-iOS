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
#import "RCLandmark.h"
#import "RCLightboxViewController.h"

@interface RCPostDetailsViewController : UIViewController<UITableViewDataSource, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewImage;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewMainFrame;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostComment;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *lblLandmark;
@property (weak, nonatomic) IBOutlet UILabel *lblDatePosted;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewCommentTextViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewCommentFrame;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewLandmarkCategory;
@property (weak, nonatomic) IBOutlet UILabel *lblPostSubject;
@property (weak, nonatomic) IBOutlet UITableView *tblViewPostDiscussion;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewPostImage;
@property (nonatomic, strong) RCPost *post;
@property (weak, nonatomic) IBOutlet UIButton *btnComment;
@property (nonatomic, strong) RCUser *postOwner;
- (IBAction)btnFriensWithTouchUpInside:(id)sender;
- (IBAction)btnFollowTouchUpInside:(id)sender;
@property (nonatomic, strong) RCUser *loggedInUser;
@property (nonatomic, assign) int     landmarkID;
@property (nonatomic, strong) RCLandmark *landmark;

- (id) initWithPost:(RCPost *)post withOwner:(RCUser*)owner withLoggedInUser:(RCUser *) loggedInUser;
- (IBAction)backgroundTap:(id)sender;
- (IBAction)commentButtonTouchUpInside:(id)sender;
- (IBAction)btnCloseTouchUpInside:(id)sender;
- (IBAction) openCommentPostingView:(id) sender;
@end
