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

@interface RCNewPostViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AmazonServiceRequestDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnPostImage;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostContent;

@property (nonatomic, strong) RCUser *user;
@property (strong, nonatomic) RCKeyboardPushUpHandler *keyboardPushHandler;

- (IBAction)backgroundTouchUpInside:(id)sender;
- (IBAction)btnPostImageTouchUpInside:(id)sender;
- (id) initWithUser:(RCUser *)user;
@end
