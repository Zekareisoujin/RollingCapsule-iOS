//
//  RCSlideoutViewController.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const RCSlideOutOptionsSlideValue;

@interface RCSlideoutViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic)	UINavigationController*	contentController;
@property (strong, nonatomic)   UIViewController* menuViewController;
- (void) showSideMenu;
- (void) hideSideMenu;
- (void) disablePanning;
- (void) enablePanning;
@end
