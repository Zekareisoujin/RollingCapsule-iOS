//
//  RCMainMenuViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCMainMenuViewController : UIViewController
//@property (weak, nonatomic) IBOutlet UIImageView *screenShotImageView;
@property (strong, nonatomic) IBOutlet UIImageView *screenShotImageView;
- (IBAction)btnTestTouchUpInside:(id)sender;
@property (strong, nonatomic) UIImage* screenShotImage;
@end
