//
//  RCFacebookSettingsViewController.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 7/08/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFacebookSettingsViewController.h"
#import "RCFacebookHelper.h"

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
                [_btnLogIn.titleLabel setText:@"Log Out"];
                [_imgUserDisplayPicture setHidden:NO];
                [_imgUserDisplayPicture setProfileID:[user objectForKey:@"id"]];
                [_btnShouldLogInOption setEnabled:YES];
            }
        }];
    } else {
        // Session is closed
        [_lblHeadline setText:@"You are not logged in."];
        [_btnLogIn.titleLabel setText:@"Log In"];
        [_imgUserDisplayPicture setHidden:YES];
        [_btnShouldLogInOption setEnabled:NO];
        [_btnShouldLogInOption setOn:NO animated:YES];
        [RCFacebookHelper setShouldLogIn:NO];
    }
}

- (IBAction)btnLogInClicked:(id)sender {
    if ([FBSession.activeSession isOpen]) {
        // Session is open
        [RCFacebookHelper closeCurrentSession];
        [self setDisplayElements];
    } else {
        // Session is closed
        [RCFacebookHelper openFacebookSessionWithDefaultReadPermission:^{
            [self setDisplayElements];
        }];
    }
}

- (IBAction)btnShouldLogInOptionChanged:(id)sender {
    [RCFacebookHelper setShouldLogIn:[sender isOn]];
}
@end
