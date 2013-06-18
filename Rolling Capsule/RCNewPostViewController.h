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

@interface RCNewPostViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AmazonServiceRequestDelegate, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnPostImage;
@property (weak, nonatomic) IBOutlet UITextView *txtViewPostContent;
@property (nonatomic, strong) NSMutableArray *landmarks;
@property (nonatomic, strong) RCUser *user;
@property (nonatomic, strong) UITableView *tblViewLandmark;
- (IBAction)backgroundTouchUpInside:(id)sender;
- (IBAction)btnPostImageTouchUpInside:(id)sender;
- (IBAction)callLandmarkTable:(id)sender;
- (id) initWithUser:(RCUser *)user;
@end
