//
//  RCCommentPostingViewController.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUtilities.h"

typedef void (^NSStringBlock)(NSString*);

@interface RCCommentPostingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *txtViewCommentContent;
@property (nonatomic, copy) VoidBlock postCancel;
@property (nonatomic, copy) NSStringBlock postComplete;

- (IBAction)btnCancelTouchUpInside:(id)sender;
- (IBAction)btnPostTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblAuthorName;

@end
