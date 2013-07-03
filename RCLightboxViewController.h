//
//  RCLightboxViewController.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 3/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCLightboxViewController : UIViewController

@property (nonatomic, strong) UIImageView *imageViewPreviousView;
@property (nonatomic, strong) UIView      *viewDimVeil;
@property (nonatomic, weak)   UIImage*     backgroundImage;
- (void) animateViewAppearance;
- (void) animateViewDisapperance:(void (^)(void))completeCallback;
@end
