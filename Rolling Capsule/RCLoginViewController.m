//
//  ViewController.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#include "RCConstants.h"

#import "RCLoginViewController.h"
#import "SBJson.h"
#import "RCRegisterViewController.h"
#import "RCMainFeedViewController.h"
#import "RCAboutUsViewController.h"
#import "RCUser.h"
#import "RCUtilities.h"
#import "RMPhoneFormat.h"
#import <QuartzCore/QuartzCore.h>

@interface RCLoginViewController ()
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, assign) int userID;
@property (nonatomic, assign) BOOL isFirstTimeLogin;
@end

@implementation RCLoginViewController

@synthesize delegate;
@synthesize keyboardHandler = _keyboardHandler;
@synthesize email = _email;
@synthesize password = _password;
@synthesize userID = _userID;
@synthesize isFirstTimeLogin = _isFirstTimeLogin;

static int RCActivationAlertOkButtonIndex = 0;
static int RCActivationAlertResendSMSButtonIndex = 1;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _isFirstTimeLogin = NO;
    _txtFieldUsername.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,9,10)];
    _txtFieldUsername.leftViewMode = UITextFieldViewModeAlways;
    _txtFieldPassword.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,9,10)];
    _txtFieldPassword.leftViewMode = UITextFieldViewModeAlways;
    _keyboardHandler = [[RCKeyboardPushUpHandler alloc] init];
    _keyboardHandler.view = self.view;
    _keyboardHandler.bottomScreenGap = self.view.frame.size.height - _txtFieldPassword.frame.origin.y - _txtFieldPassword.frame.size.height - 30;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnAboutUsTouchUpInside:(id)sender {
    RCAboutUsViewController *viewController = [[RCAboutUsViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)btnActionLogIn:(id)sender {
    [self setUIBusy:YES];
    if([[_txtFieldUsername text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] ) {
        showAlertDialog(NSLocalizedString(RCErrorMessageUsernameAndPasswordMissing, nil),  NSLocalizedString(@"Error",nil));
        [self setUIBusy:NO];
    } else {
        [self asynchLogInRequest];
    }
}

- (void)asynchLogInRequest
{
    //Asynchronous Request
    @try {
        _email = [_txtFieldUsername text];
        _password = [_txtFieldPassword text];
        //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSMutableString *post = initQueryString(@"session[email]", _email);
        addArgumentToQueryString(post, @"session[password]", _password);
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCSessionsResource]];
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
            completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            
            SBJsonParser *jsonParser = [SBJsonParser new];
            NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
            //NSLog(@"%@",jsonData);
            
            
            if (jsonData != NULL) {
                if ([[jsonData objectForKey:RCUnactivatedWarningKey] isEqualToString:RCUnactivatedAccountString]) {
                    _userID = [[jsonData objectForKey:@"user_id"] intValue];
                    _isFirstTimeLogin = YES;
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account activation",nil) message:NSLocalizedString(@"Please enter the activation code sent to you via SMS",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:NSLocalizedString(@"Resend SMS",nil), nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    alert.delegate = self;
                    [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
                    [alert show];
                } else {
                    RCUser *user = [[RCUser alloc] initWithNSDictionary:(NSDictionary*)[jsonData objectForKey:@"user"]];
                    [delegate userDidLogIn:user firstTimeLogin:_isFirstTimeLogin];
                    _isFirstTimeLogin = NO;
                }
            }else {
                showAlertDialog(([NSString stringWithFormat:@"%@. %@ ",responseData, NSLocalizedString(RCErrorMessagePleaseTryAgain, nil)]), NSLocalizedString(@"Error",nil));
            }
            [self setUIBusy:NO];
        }];
        
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        showAlertDialog(NSLocalizedString(RCAlertMessageLoginFailed, nil), NSLocalizedString(@"Error",nil));
    }
}

- (void) requestResendActivation:(NSString*) phoneNumber {
    @try {
    NSMutableString *post = initQueryString(@"password", _password);
    addArgumentToQueryString(post, @"phone_number", phoneNumber);
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/send_activation_code", RCServiceURL, RCUsersResource, _userID]];
    NSURLRequest *request = CreateHttpPostRequest(url, postData);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
         NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
         if (error != nil || httpResponse.statusCode !=  RCHttpOkStatusCode || ![responseData isEqualToString:@"ok"]) {
             showAlertDialog(NSLocalizedString(RCErrorMessagePleaseTryAgain, nil) , NSLocalizedString(@"Error",nil));
         }
     }];
    }@catch (NSException* e) {
        NSLog(@"Exception: %@", e);
        showAlertDialog(NSLocalizedString(RCAlertMessageLoginFailed, nil), NSLocalizedString(@"Error",nil));
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"press button index in alert view: %d", buttonIndex);
    if ([alertView.title isEqualToString:NSLocalizedString(@"Phone number",nil)]) {
        NSString *phoneNumber = [[alertView textFieldAtIndex:0] text];
        if ([phoneNumber length] > 1) {
            if ([phoneNumber hasPrefix:@"+"])
                phoneNumber = [phoneNumber substringFromIndex:1];
            [self requestResendActivation:phoneNumber];
        }
    } else {
        if (buttonIndex == RCActivationAlertOkButtonIndex) {
            NSString* activationCode = [[alertView textFieldAtIndex:0] text];
            NSLog(@"Entered: %@",activationCode);
            //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSString *post = initQueryString(@"confirmation_code", activationCode);
            NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/activate", RCServiceURL, RCUsersResource, _userID]];
            NSURLRequest *request = CreateHttpPostRequest(url, postData);
            [self setUIBusy:YES];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
             {
                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 if (httpResponse.statusCode ==  RCHttpOkStatusCode && [responseData isEqualToString:@"ok"]) {
                     [self asynchLogInRequest];
                 } else {
                     SBJsonParser *parser = [[SBJsonParser alloc] init];
                     NSDictionary* errorJson = [parser objectWithString:responseData];
                     if ([errorJson objectForKey:RCErrorMessageKey] != nil) {
                         showAlertDialog([errorJson objectForKey:RCErrorMessageKey], @"Error");
                     } else {
                         showAlertDialog(NSLocalizedString(@"Error",nil), NSLocalizedString(@"We encountered a problem activating your account. Please try again.",nil));
                     }
                     [self setUIBusy:NO];
                 }
                 
             }];
        } else if (buttonIndex == RCActivationAlertResendSMSButtonIndex) {
            RMPhoneFormat *fmt = [[RMPhoneFormat alloc] init];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Phone number",nil) message:NSLocalizedString(@"Please enter your phone number",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            alert.delegate = self;
            [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"+%@",[fmt defaultCallingCode]];
            [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
            [alert show];
        }
    }
}

- (IBAction)btnActionRegister:(id)sender {
    [_txtFieldPassword resignFirstResponder];
    [_txtFieldUsername resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    RCRegisterViewController *registerViewController = [[RCRegisterViewController alloc]
                                                      init];
    [self addChildViewController:registerViewController];
    registerViewController.view.frame = self.view.frame;
    [self.view addSubview:registerViewController.view];
    [registerViewController didMoveToParentViewController:self];
    //[self.navigationController pushViewController:registerViewController animated:YES];
}

- (IBAction)btnBackgroundTap:(id)sender {
    [_txtFieldUsername resignFirstResponder];
    [_txtFieldPassword endEditing:YES];
    
}

- (IBAction)btnForgotPassword:(id)sender {
    //postNotification(@"Not yet implemented!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:_keyboardHandler
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:_keyboardHandler
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];*/
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
    
    /*[[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];*/
}

- (void)switchToFeedView:(RCUser *)user {
    RCMainFeedViewController *mainFeedViewController = [[RCMainFeedViewController alloc] init];
    [self.navigationController pushViewController:mainFeedViewController animated:YES];
}

- (void)setUIBusy:(BOOL)busy {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:busy];
    [_txtFieldUsername setUserInteractionEnabled:!busy];
    [_txtFieldPassword setUserInteractionEnabled:!busy];
    [_btnLogIn setEnabled:!busy];
    [_btnTickLogIn setEnabled:!busy];
    [_btnRegister setUserInteractionEnabled:!busy];
}

@end
