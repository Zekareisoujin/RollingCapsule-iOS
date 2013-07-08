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

- (void)viewDidLoad
{
    _txtFieldUsername.placeholder = RCEmailCapitalString;
    _txtFieldPassword.placeholder = RCPasswordCapitalString;

    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Programmatically customize UIButton:
    /*UIFont *btnFont =[UIFont fontWithName:@"Copperplate" size:18.0];
    [_btnLogIn.titleLabel setFont:btnFont];
    [_btnRegister.titleLabel setFont:btnFont];
    _txtFieldUsername.font = btnFont;
    _txtFieldPassword.font = btnFont;
    
    UIImage *btnBackgroundImageActive = [UIImage imageNamed:@"btnStandard-normal.png"];
    UIImage *btnStretchedImageActive = [btnBackgroundImageActive stretchableImageWithLeftCapWidth:30 topCapHeight:0];
    UIImage *btnBackgroundImageDepressed = [UIImage imageNamed:@"btnStandard-depressed.png"];
    UIImage *btnStretchedImageDepressed = [btnBackgroundImageDepressed stretchableImageWithLeftCapWidth:30 topCapHeight:0];
    
    [_btnLogIn setBackgroundImage:btnStretchedImageActive forState:UIControlStateNormal];
    [_btnRegister setBackgroundImage:btnStretchedImageActive forState:UIControlStateNormal];
    [_btnLogIn setBackgroundImage:btnStretchedImageDepressed forState:UIControlStateHighlighted];
    [_btnRegister setBackgroundImage:btnStretchedImageDepressed forState:UIControlStateHighlighted];*/
    [_btnLogIn setBackgroundImage:[UIImage imageNamed:@"loginBtnLoginPressed"] forState:UIControlStateHighlighted];
    [_btnRegister setBackgroundImage:[UIImage imageNamed:@"loginBtnRegisterPressed"] forState:UIControlStateHighlighted];
    
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
            alertStatus(RCErrorMessageUsernameAndPasswordMissing,RCAlertMessageLoginFailed,self);
            [self setUIBusy:NO];
        } else {
            //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSString *post =[[NSString alloc] initWithFormat:@"session[email]=%@&session[password]=%@&mobile=1",[_txtFieldUsername text],[_txtFieldPassword text]];
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
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
                    [delegate initializeUserFromLogIn:user];
                }else {
                    alertStatus([NSString stringWithFormat:RCErrorMessagePleaseTryAgain], RCAlertMessageLoginFailed, self);
                }
                [self setUIBusy:NO];
            }];
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCAlertMessageLoginFailed,RCAlertMessageLoginFailed, self);
    }
}

- (IBAction)btnActionRegister:(id)sender {
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
    alertStatus(@"Not yet implemented!", @"Error", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
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
