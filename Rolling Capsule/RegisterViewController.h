//
//  RegisterViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 26/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegisterViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPasswordConfirmation;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldName;
@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (nonatomic,retain) NSMutableData *receivedData;
@property (nonatomic, assign) BOOL willMoveKeyboardUp;
- (IBAction)registerTouchUpInside:(id)sender;
@end
