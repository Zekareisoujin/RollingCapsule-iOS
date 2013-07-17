//
//  RCNewPostViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 3/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>
#import "RCUser.h"
#import "RCKeyboardPushUpHandler.h"
#import "RCLandmark.h"
#import "RCLightboxViewController.h"
#import "RCUtilities.h"

@interface RCNewPostViewController : RCLightboxViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AmazonServiceRequestDelegate, UITextViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UILabel *lblLandmarkName;

@property (weak, nonatomic) IBOutlet UIButton *btnChooseLandmark;
- (IBAction)closeBtnTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnPostImage;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPostPicture;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPostSubject;
@property (weak, nonatomic) IBOutlet UIButton *btnLandmark;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPostFrame;
@property (weak, nonatomic) IBOutlet UIButton *btnVideoSource;
@property (weak, nonatomic) IBOutlet UIButton *btnCameraSource;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotoLibrarySource;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostContent;
@property (nonatomic, strong) NSMutableArray *landmarks;
@property (nonatomic, strong) RCUser *user;
@property (strong, nonatomic) RCKeyboardPushUpHandler *keyboardPushHandler;
@property (nonatomic, strong) UICollectionView *tblViewLandmark;
@property (nonatomic, strong) RCLandmark *currentLandmark;
@property (nonatomic, copy)   VoidBlock   postComplete;
@property (nonatomic, copy)   VoidBlock   postCancel;

- (void)backgroundTouchUpInside;
- (IBAction)btnActionChooseCameraSource:(id)sender;
- (IBAction)btnActionChoosePhotoLibrarySource:(id)sender;
- (IBAction)btnActionChooseVideSource:(id)sender;
- (IBAction)openLandmarkView:(id)sender;
- (id) initWithUser:(RCUser *)user;
- (id) initWithUser:(RCUser *)user withBackgroundImage:(UIImage*) image;
@end
