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
    [_viewDimVeil setBackgroundColor:[UIColor blackColor]];
    [_viewDimVeil setAlpha:0.6];
    [self.view addSubview:_viewDimVeil];
    [self.view sendSubviewToBack:_viewDimVeil];
	_imageViewPreviousView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_imageViewPreviousView];
    [self.view sendSubviewToBack:_imageViewPreviousView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
