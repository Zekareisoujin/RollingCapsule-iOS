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
#import "RCUtilities.h"
#import "TTTAttributedLabel.h"

@interface RCPostDetailsViewController : UIViewController<UITableViewDataSource, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, TTTAttributedLabelDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewImage;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewMainFrame;
@property (weak, nonatomic) IBOutlet UIButton *btnWhistle;
- (IBAction)btnReportInappropriateTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblReportInappropriate;
- (IBAction)btnWhistleTouchUpInside:(id)sender;
- (IBAction)btnReportSubmitTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblReportCopyrightContent;
@property (weak, nonatomic) IBOutlet UIView *viewReport;
@property (weak, nonatomic) IBOutlet UIButton *btnReportCopyrightContent;
@property (weak, nonatomic) IBOutlet UIView *viewCoverStrip;
- (IBAction)btnReportCopyrightContentTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostComment;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet UIButton *btnPostComment;
@property (weak, nonatomic) IBOutlet UILabel *lblLandmark;
@property (strong, nonatomic) IBOutlet UILabel *lblDatePosted;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewCommentTextViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewCommentFrame;
@property (weak, nonatomic) IBOutlet UIButton *btnTopic;
@property (weak, nonatomic) IBOutlet UIButton *btnFollow;
@property (weak, nonatomic) IBOutlet UIButton *btnFriendsWith;
@property (weak, nonatomic) IBOutlet UILabel *lblPostSubject;
@property (weak, nonatomic) IBOutlet UITableView *tblViewPostDiscussion;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewPostImage;
@property (weak, nonatomic) IBOutlet UIButton *btnComment;

@property (nonatomic, strong) RCPost *post;
@property (nonatomic, strong) RCUser *postOwner;
@property (nonatomic, strong) RCUser *loggedInUser;
@property (nonatomic, assign) int     landmarkID;
@property (nonatomic, strong) RCLandmark *landmark;
@property (nonatomic, copy) VoidBlock deleteFunction;
@property (nonatomic, assign) BOOL editable;

- (id) initWithPost:(RCPost *)post withOwner:(RCUser*)owner withLoggedInUser:(RCUser *)loggedInUser editable:(BOOL)editable;
- (IBAction)backgroundTap:(id)sender;
- (IBAction)commentButtonTouchUpInside:(id)sender;
- (IBAction)btnCloseTouchUpInside:(id)sender;
- (IBAction) openCommentPostingView:(id) sender;
- (IBAction)btnFriendsWithTouchUpInside:(id)sender;
- (IBAction)btnFollowTouchUpInside:(id)sender;
- (IBAction)btnTopicTouchUpInside:(id)sender;
+ (void) toggleShowPostID;
@end
