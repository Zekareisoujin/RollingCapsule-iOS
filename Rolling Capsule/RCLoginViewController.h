//
//  ViewController.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"

@protocol RCLoginViewControllerDelegate

- (void)initializeUserFromLogIn:(RCUser *)user;

@end

@interface RCLoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtFieldUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnLogIn;
@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (nonatomic, assign) id delegate;

- (IBAction)btnActionLogIn:(id)sender;
- (IBAction)btnActionRegister:(id)sender;
- (IBAction)btnBackgroundTap:(id)sender;
- (IBAction)btnForgotPassword:(id)sender;

@end
