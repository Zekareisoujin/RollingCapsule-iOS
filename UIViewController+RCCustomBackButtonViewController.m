//
//  UIViewController+RCCustomBackButtonViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 11/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "UIViewController+RCCustomBackButtonViewController.h"

@implementation UIViewController (RCCustomBackButtonViewController)

- (void) popCurrentViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupBackButton {
    //add back button
    UIImage *backButtonImage = [UIImage imageNamed:@"backButton.png"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setFrame:CGRectMake(0,0,backButtonImage.size.width, backButtonImage.size.height)];
    [backButton setBackgroundImage:backButtonImage forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(popCurrentViewController) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton] ;
    self.navigationItem.leftBarButtonItem = backButtonItem;
}

@end
