//
//  RegisterViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 26/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCLightboxViewController.h"
#import "RCKeyboardPushUpHandler.h"

@interface RCRegisterViewController : RCLightboxViewController <UITextFieldDelegate, TTTAttributedLabelDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPhoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldEmail;
- (IBAction)btnCloseTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *lblTermsOfUse;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldName;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldConfirmPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldCountryCode;
@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (nonatomic, strong) RCKeyboardPushUpHandler* keyboardHandler;
- (IBAction)registerTouchUpInside:(id)sender;
@end
