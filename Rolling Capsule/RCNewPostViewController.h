//
//  RCNewPostViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 3/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>
#import <FacebookSDK/FacebookSDK.h>
#import "RCUser.h"
#import "RCKeyboardPushUpHandler.h"
#import "RCLandmark.h"
#import "RCLightboxViewController.h"
#import "RCUtilities.h"
#import "RCDatePickerView.h"

@interface RCNewPostViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AmazonServiceRequestDelegate, UITextViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, RCDatePickerDelegate, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblLandmarkName;

@property (weak, nonatomic) IBOutlet UIButton *btnChooseLandmark;
- (IBAction)closeBtnTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnPostImage;
@property (strong, nonatomic) UIImageView *imageViewPostPicture;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPostSubject;
@property (weak, nonatomic) IBOutlet UIButton *btnLandmark;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPostFrame;
@property (weak, nonatomic) IBOutlet UIButton *btnVideoSource;
@property (weak, nonatomic) IBOutlet UIButton *btnCameraSource;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewImage;
@property (weak, nonatomic) IBOutlet UIView *imgViewControlFrame;
@property (weak, nonatomic) IBOutlet UIView *imgViewPrivacyControlFrame;
@property (weak, nonatomic) IBOutlet UIView *imgViewPrivacyOptionFrame;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewMainFrame;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotoLibrarySource;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostContent;
@property (weak, nonatomic) IBOutlet UIView *txtViewPostContentFrame;
@property (weak, nonatomic) IBOutlet UILabel* lblDate;
@property (weak, nonatomic) IBOutlet UIButton* postButton;
@property (weak, nonatomic) IBOutlet UIButton* publicPrivacyButton;
@property (weak, nonatomic) IBOutlet UIView *viewMainFrame;
@property (weak, nonatomic) IBOutlet UIButton* friendPrivacyButton;
@property (weak, nonatomic) IBOutlet UIButton* personalPrivacyButton;
@property (weak, nonatomic) IBOutlet UIButton *timeCapsule;
@property (weak, nonatomic) IBOutlet UIButton *btnPrivacyOption;
@property (weak, nonatomic) IBOutlet UIButton *btnFacebookOption;
@property (nonatomic, strong) NSMutableArray *topics;
@property (nonatomic, strong) RCUser *user;
@property (strong, nonatomic) RCKeyboardPushUpHandler *keyboardPushHandler;
@property (nonatomic, strong) UICollectionView *tblViewLandmark;
@property (nonatomic, strong) RCLandmark *currentLandmark;

- (IBAction)backgroundTouchUpInside:(id)sender;
- (IBAction)btnActionChooseCameraSource:(id)sender;
- (IBAction)btnActionChoosePhotoLibrarySource:(id)sender;
- (IBAction)btnActionChooseVideSource:(id)sender;
- (IBAction)btnPrivacyOptionTouchedUpInside:(id)sender;
- (IBAction)btnFacebookOptionTouchedUpInside:(id)sender;
- (IBAction)openLandmarkView:(id)sender;
- (IBAction) openDatePickerView:(UIButton*) sender;
- (IBAction) postNew:(id) sender;
- (IBAction) setPostPrivacyOption:(UIButton*) sender;
- (id) initWithUser:(RCUser *)user;
- (id) initWithUser:(RCUser *)user withBackgroundImage:(UIImage*) image;
- (id) initWithUser:(RCUser *)user withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil;
+ (void) toggleAutomaticClose;
@end
