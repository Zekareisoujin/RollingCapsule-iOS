//
//  RCSettingViewController.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 18/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCSettingViewController : UIViewController

- (id) initWithUser: (RCUser *)user;

@property (strong, nonatomic) RCUser *user;

- (IBAction)btnActionLogOut:(id)sender;
- (IBAction)switchSaveToDiskValueChanged:(id)sender;
- (IBAction)siwtchClosePostViewValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *switchClosePostView;
@property (weak, nonatomic) IBOutlet UISwitch *switchSaveToDisk;

@end
