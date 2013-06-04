//
//  RCNewPostViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 3/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"

@interface RCNewPostViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnPostImage;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostContent;

@property (nonatomic, strong) RCUser *user;

- (IBAction)backgroundTouchUpInside:(id)sender;
- (IBAction)btnPostImageTouchUpInside:(id)sender;
- (id) initWithUser:(RCUser *)user;
@end
