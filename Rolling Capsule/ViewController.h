//
//  ViewController.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtFieldUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;
- (IBAction)btnLogInClick:(id)sender;
- (IBAction)btnRegisterClick:(id)sender;
- (IBAction)btnBackgroundTap:(id)sender;

@end
