//
//  RegisterViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 26/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//
#include "RCConstants.h"

#import "SBJson.h"
#import "RCUtilities.h"
#import "RCRegisterViewController.h"
#import "RMPhoneFormat.h"

@implementation RCRegisterViewController

@synthesize keyboardHandler = _keyboardHandler;

double      _moveUpBy;
double      _keyboardTopPosition;
BOOL        _keyboardVisible;
BOOL        _willMoveKeyboardUp;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _txtFieldPhoneNumber.delegate = self;
    _txtFieldPassword.delegate = self;
	_willMoveKeyboardUp = FALSE;
    _keyboardVisible = FALSE;
    [_txtFieldName setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_txtFieldEmail setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_txtFieldPassword setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_txtFieldPhoneNumber setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    NSString *text = [_lblTermsOfUse.text copy];
    _lblTermsOfUse.text = text;
    _lblTermsOfUse.delegate = self;
    
    RMPhoneFormat *fmt = [[RMPhoneFormat alloc] init];
    self.txtFieldPhoneNumber.text = [NSString stringWithFormat:@"+%@",[fmt defaultCallingCode]];
    
    NSRange termsRange = [_lblTermsOfUse.text rangeOfString:@"Memcap terms"];
    [_lblTermsOfUse addLinkToURL:[NSURL URLWithString:RCTermsOfUseURL] withRange:termsRange];
    [self animateViewAppearance];
    _keyboardHandler = [[RCKeyboardPushUpHandler alloc] init];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}
#pragma mark - web request

- (void)asynchRegisterRequest
{
    //Asynchronous Request
    @try {
        
        if([[_txtFieldName text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] 
           || [[_txtFieldEmail text] isEqualToString:@""] || [[_txtFieldPhoneNumber text] isEqualToString:@""] ) {
            showAlertDialog(RCErrorMessageInformationMissing, @"Error");
        } else {
            NSMutableString *dataSt = initQueryString(@"user[email]", [_txtFieldEmail text]);
            addArgumentToQueryString(dataSt, @"user[password]", [_txtFieldPassword text]);
            addArgumentToQueryString(dataSt, @"user[name]", [_txtFieldName text]);
            addArgumentToQueryString(dataSt, @"user[password_confirmation]", [_txtFieldPassword text]);
            NSString *phoneNumber = [_txtFieldPhoneNumber text];
            if ([phoneNumber hasPrefix:@"+"])
                phoneNumber = [phoneNumber substringFromIndex:1];
            addArgumentToQueryString(dataSt, @"phone_number", phoneNumber);
            NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCUsersResource]];
            NSURLRequest *request = CreateHttpPostRequest(url, postData);
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                NSLog(@"%@",jsonData);
                
                //Temporary:
                if (jsonData != NULL) {
                    NSDictionary *userData = (NSDictionary *) [jsonData objectForKey: @"user"];
                    NSString *name = (NSString *) [userData objectForKey:@"name"];
                    showAlertDialog(([NSString stringWithFormat:@"Welcome %@! We have sent you an activation code via SMS to the phone number you provided. You can now login and activate your account using the aforementioned code.",name]), @"Welcome");
                    [self btnCloseTouchUpInside:nil];
                }else {
                    showAlertDialog(([NSString stringWithFormat:@"%@. %@",responseData, RCErrorMessagePleaseTryAgain]), @"Error");
                }

            }];
            
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        showAlertDialog(RCAlertMessageRegistrationFailed, @"Error");
    }
}

#pragma mark - UI events

- (IBAction)btnBackgroundTap:(id)sender {
    [_txtFieldName resignFirstResponder];
    [_txtFieldPassword resignFirstResponder];
    [_txtFieldPhoneNumber resignFirstResponder];
    [_txtFieldEmail resignFirstResponder];
    
}

- (IBAction)registerTouchUpInside:(id)sender {
    [self asynchRegisterRequest];
}

#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:_keyboardHandler
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:_keyboardHandler
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    _keyboardVisible = TRUE;
    if (_willMoveKeyboardUp) {
        NSDictionary* userInfo = [notification userInfo];
        CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        _keyboardTopPosition = self.view.frame.size.height - keyboardFrame.size.height;
        [self setViewMovedUp:YES offset:(_moveUpBy - _keyboardTopPosition)];
    }
}

- (void) keyboardWillHide:(NSNotification*)notification {
    _keyboardVisible = FALSE;
    if (_willMoveKeyboardUp) {
        [self setViewMovedUp:NO offset:(_moveUpBy - _keyboardTopPosition)];
        _willMoveKeyboardUp = FALSE;
    }
    
}
-(BOOL)textFieldShouldBeginEditing:(UITextField *)sender {
    if ([sender isEqual:_txtFieldPhoneNumber] )
    {
        _keyboardHandler.enabled = YES;
        _keyboardHandler.view = self.view;
        _keyboardHandler.bottomScreenGap = self.view.frame.size.height - (_txtFieldPhoneNumber.frame.origin.y + _txtFieldPhoneNumber.frame.size.height);
    } else _keyboardHandler.enabled = NO;
    return YES;
}
-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void) setViewMovedUp:(BOOL)movedUp offset:(double)kOffsetForKeyboard
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        rect.origin.y -= kOffsetForKeyboard;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOffsetForKeyboard;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}
- (IBAction)btnCloseTouchUpInside:(id)sender {
    [self animateViewDisapperance:^ {
        [[self parentViewController] viewWillAppear:NO];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
    }];
}
@end
