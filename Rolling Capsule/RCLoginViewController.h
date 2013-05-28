//
//  ViewController.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCLoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtFieldUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;
@property (nonatomic,retain) NSMutableData *receivedData;
@property (retain) id delegate;
- (IBAction)btnLogInClick:(id)sender;
- (IBAction)btnRegisterClick:(id)sender;
- (IBAction)btnBackgroundTap:(id)sender;

@end
