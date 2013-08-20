//
//  RCFacebookSettingsViewController.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 7/08/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFacebookSettingsViewController.h"
#import "RCFacebookHelper.h"
#import "RCConnectionManager.h"

@interface RCFacebookSettingsViewController ()

@end

@implementation RCFacebookSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([self.navigationController.viewControllers count] > 2)
        [self setupBackButton];
    
    // Hack to fix auto layout:
    CGRect viewFrame = _imgUserDisplayPicture.frame;
    [_imgUserDisplayPicture setHidden:YES];
    [_imgUserDisplayPicture removeFromSuperview];
    _imgUserDisplayPicture = [[FBProfilePictureView alloc] init];
    [_imgUserDisplayPicture setFrame:viewFrame];
    [self.view addSubview:_imgUserDisplayPicture];
}

- (void)viewWillAppear:(BOOL)animated {
    [_btnShouldLogInOption setOn:[RCFacebookHelper shouldLogIn]];
    [self setDisplayElements];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDisplayElements {
    if ([FBSession.activeSession isOpen]) {
        // Session is open
        [RCFacebookHelper getCurrentUserWithCompletionHandler:^(NSDictionary<FBGraphUser> *user){
            if (user) {
                [_lblHeadline setText:user.name];
                [_imgUserDisplayPicture setHidden:NO];
                [_imgUserDisplayPicture setProfileID:[user objectForKey:@"id"]];
                [_btnShouldLogInOption setEnabled:YES];
                [_btnLogIn setTitle:NSLocalizedString(@"Log Out",nil) forState:UIControlStateNormal];
                [_btnLogIn setEnabled:YES];
            }
        }];
    } else {
        // Session is closed
        [_lblHeadline setText:NSLocalizedString(@"You are not logged in.",nil)];
        [_imgUserDisplayPicture setHidden:YES];
        [_btnShouldLogInOption setEnabled:NO];
        [_btnShouldLogInOption setOn:NO animated:YES];
        [RCFacebookHelper setShouldLogIn:NO];
        [_btnLogIn setTitle:NSLocalizedString(@"Log In",nil) forState:UIControlStateNormal];
        [_btnLogIn setEnabled:YES];
    }
}

- (IBAction)btnLogInClicked:(id)sender {
    [_btnLogIn setEnabled:NO];
    if ([FBSession.activeSession isOpen]) {
        // Session is open
        [RCFacebookHelper closeCurrentSession];
        [self setDisplayElements];
    } else {
        // Session is closed
        [RCConnectionManager startConnection];
        [RCFacebookHelper openFacebookSessionWithDefaultReadPermission:^{
            [RCConnectionManager endConnection];
            [self setDisplayElements];
        }];
    }
}

- (IBAction)btnShouldLogInOptionChanged:(id)sender {
    [RCFacebookHelper setShouldLogIn:[sender isOn]];
}
@end
