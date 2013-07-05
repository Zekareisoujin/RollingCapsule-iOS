//
//  RCLightboxViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 3/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCLightboxViewController.h"

@interface RCLightboxViewController ()

@end

@implementation RCLightboxViewController

@synthesize imageViewPreviousView = _imageViewPreviousView;
@synthesize viewDimVeil = _viewDimVeil;
@synthesize backgroundImage = _backgroundImage;
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
    [self.view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    
}

- (void) animateViewAppearance {
    self.view.alpha = 0.0;
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         self.view.alpha = 1.0;
					 }
                     completion:^(BOOL finished) {
                         //[self removePhotoSourceControlAndAddPrivacyControl];
					 }];
}
- (void) animateViewDisapperance:(void (^)(void))completeCallback {
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         self.view.alpha = 0.0;
					 }
                     completion:^(BOOL finished) {
                         completeCallback();
					 }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
