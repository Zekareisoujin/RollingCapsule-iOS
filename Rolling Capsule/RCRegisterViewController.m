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

@implementation RCRegisterViewController

double      _moveUpBy;
double      _keyboardTopPosition;
BOOL        _keyboardVisible;
BOOL        _willMoveKeyboardUp;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _txtFieldPasswordConfirmation.delegate = self;
    _txtFieldPassword.delegate = self;
	_willMoveKeyboardUp = FALSE;
    _keyboardVisible = FALSE;
    [_txtFieldName setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_txtFieldEmail setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_txtFieldPassword setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    [_txtFieldPasswordConfirmation setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
    
    [self animateViewAppearance];
}

#pragma mark - web request

- (void)asynchRegisterRequest
{
    //Asynchronous Request
    @try {
        
        if([[_txtFieldName text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] 
           || [[_txtFieldEmail text] isEqualToString:@""] || [[_txtFieldPasswordConfirmation text] isEqualToString:@""] ) {
            alertStatus(RCErrorMessageInformationMissing, RCAlertMessageLoginFailed,self);
        } else {
            NSMutableString *dataSt = initQueryString(@"user[email]", [_txtFieldEmail text]);
            addArgumentToQueryString(dataSt, @"user[password]", [_txtFieldPassword text]);
            addArgumentToQueryString(dataSt, @"user[name]", [_txtFieldName text]);
            addArgumentToQueryString(dataSt, @"user[password_confirmation]", [_txtFieldPasswordConfirmation text]);
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
                    alertStatus([NSString stringWithFormat:@"Welcome, %@!",name], RCAlertMessageRegistrationSuccess, self);
                }else {
                    alertStatus([NSString stringWithFormat:@"%@ %@",RCErrorMessagePleaseTryAgain, responseData], RCAlertMessageRegistrationFailed, self);
                }

            }];
            
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCAlertMessageRegistrationFailed,RCAlertMessageRegistrationFailed,self);
    }
}

#pragma mark - UI events

- (IBAction)btnBackgroundTap:(id)sender {
    [_txtFieldName resignFirstResponder];
    [_txtFieldPassword resignFirstResponder];
    [_txtFieldPasswordConfirmation resignFirstResponder];
    [_txtFieldEmail resignFirstResponder];
    
}

- (IBAction)registerTouchUpInside:(id)sender {
    [self asynchRegisterRequest];
}

#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field

- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
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

-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    if ([sender isEqual:_txtFieldPasswordConfirmation] || [sender isEqual:_txtFieldPassword])
    {
        _willMoveKeyboardUp = TRUE;
        double oldPosition = _moveUpBy;
        _moveUpBy = sender.frame.origin.y + sender.frame.size.height;
        if (_keyboardVisible) {
            [self setViewMovedUp:YES offset:(_moveUpBy-oldPosition)];
        }
    }
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
