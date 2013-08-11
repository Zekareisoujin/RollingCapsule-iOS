//
//  RCFacebookSettingsViewController.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 7/08/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "UIViewController+RCCustomBackButtonViewController.h"

@interface RCFacebookSettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *lblHeadline;
@property (strong, nonatomic) IBOutlet FBProfilePictureView *imgUserDisplayPicture;
@property (weak, nonatomic) IBOutlet UIButton *btnLogIn;
@property (weak, nonatomic) IBOutlet UISwitch *btnShouldLogInOption;

- (IBAction)btnLogInClicked:(id)sender;
- (IBAction)btnShouldLogInOptionChanged:(id)sender;
@end
