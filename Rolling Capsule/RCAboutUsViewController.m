//
//  RCAboutUsViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 16/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCAboutUsViewController.h"

@interface RCAboutUsViewController ()

@end

@implementation RCAboutUsViewController

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
    [self setupBackButton];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
