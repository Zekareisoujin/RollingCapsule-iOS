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
    _viewDimVeil = [[UIView alloc] initWithFrame:self.view.frame];
    [_viewDimVeil setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    [self.view addSubview:_viewDimVeil];
    [self.view sendSubviewToBack:_viewDimVeil];
	_imageViewPreviousView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,_backgroundImage.size.width,_backgroundImage.size.height)];
    [_imageViewPreviousView setImage:_backgroundImage];
    [self.view addSubview:_imageViewPreviousView];
    [self.view sendSubviewToBack:_imageViewPreviousView];
    
}

- (void) animateViewAppearance {
    for (UIView *view in self.view.subviews) {
        if (view != self.imageViewPreviousView)
            view.alpha = 0.0;
    }
    //_imageViewDimVeil.alpha = 0.0;
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         for (UIView *view in self.view.subviews)
                             if (view != self.imageViewPreviousView)
                                 view.alpha = 1.0;
					 }
                     completion:^(BOOL finished) {
                         //[self removePhotoSourceControlAndAddPrivacyControl];
					 }];
}
- (void) animateViewDisapperance:(void (^)(void))completeCallback {
    //_imageViewDimVeil.alpha = 0.0;
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         for (UIView *view in self.view.subviews)
                             if (view != self.imageViewPreviousView)
                                 view.alpha = 0.0;
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
