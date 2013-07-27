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
#import "RCUser.h"
#import "RCUtilities.h"
#import <QuartzCore/QuartzCore.h>

@interface RCLoginViewController ()

@end

@implementation RCLoginViewController

@synthesize delegate;
@synthesize keyboardHandler = _keyboardHandler;

- (void)viewDidLoad
{
    _txtFieldUsername.placeholder = RCEmailCapitalString;
    _txtFieldPassword.placeholder = RCPasswordCapitalString;

    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [_btnLogIn setBackgroundImage:[UIImage imageNamed:@"loginBtnLoginPressed"] forState:UIControlStateHighlighted];
    [_btnRegister setBackgroundImage:[UIImage imageNamed:@"loginBtnRegisterPressed"] forState:UIControlStateHighlighted];
    
    _keyboardHandler = [[RCKeyboardPushUpHandler alloc] init];
    _keyboardHandler.view = self.view;
    _keyboardHandler.bottomScreenGap = self.view.frame.size.height - _txtFieldPassword.frame.origin.y - _txtFieldPassword.frame.size.height - 30;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnActionLogIn:(id)sender {
    [self setUIBusy:YES];
    [self asynchLogInRequest];
}

- (void)asynchLogInRequest
{
    //Asynchronous Request
    @try {
        
        if([[_txtFieldUsername text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] ) {
            showAlertDialog(RCErrorMessageUsernameAndPasswordMissing, @"Error");
            [self setUIBusy:NO];
        } else {
            //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSString *post =[[NSString alloc] initWithFormat:@"session[email]=%@&session[password]=%@&mobile=1",[_txtFieldUsername text],[_txtFieldPassword text]];
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
                
                //Temporary:
                if (jsonData != NULL) {
                    RCUser *user = [[RCUser alloc] initWithNSDictionary:(NSDictionary*)[jsonData objectForKey:@"user"]];
                    [delegate userDidLogIn:user];
                }else {
                    showAlertDialog(([NSString stringWithFormat:RCErrorMessagePleaseTryAgain]), @"Error");
                }
                [self setUIBusy:NO];
            }];
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        showAlertDialog(RCAlertMessageLoginFailed, @"Error");
    }
}

- (IBAction)btnActionRegister:(id)sender {
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
    postNotification(@"Not yet implemented!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
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
    [_btnRegister setUserInteractionEnabled:!busy];
}

@end
