//
//  RCCommentPostingViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCCommentPostingViewController.h"

@interface RCCommentPostingViewController ()

@end

@implementation RCCommentPostingViewController
@synthesize postCancel = _postCancel;
@synthesize postComplete = _postComplete;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_txtViewCommentContent becomeFirstResponder];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) closeView {
    [_txtViewCommentContent resignFirstResponder];
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         CGRect frame = self.view.frame;
                         frame.origin.y += frame.size.height;
                         self.view.frame = frame;
					 }
                     completion:^(BOOL finished) {
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
					 }];
}
- (IBAction)btnCancelTouchUpInside:(id)sender {
    [self closeView];
    if (_postCancel != nil)
        _postCancel();
}

- (IBAction)btnPostTouchUpInside:(id)sender {
    [self closeView];
    if (_postComplete != nil)
        _postComplete(_txtViewCommentContent.text);
}
@end
