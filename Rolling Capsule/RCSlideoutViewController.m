//
//  RCSlideoutViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCSlideoutViewController.h"

NSString *const RCSlideOutOptionsSlideValue = @"RCSlideOutOptionsSlideValue";

@interface RCSlideoutViewController ()
@property (strong, nonatomic)	NSMutableDictionary*	options;
@end

@implementation RCSlideoutViewController

- (void)setSlideoutOptions:(NSDictionary *)options
{
	[self.options addEntriesFromDictionary:options];
}

- (NSMutableDictionary*)options
{
	if (_options == nil) {
		_options = [[NSMutableDictionary alloc]
					initWithDictionary:
					@{
					RCSlideOutOptionsSlideValue : @(60.0)}];
    }
    return _options;
}

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
    [self.view addSubview:self.contentController.view];
    UIView *menuView = self.menuViewController.view;
    [self.view addSubview:menuView];
    self.contentController.view.frame = self.view.bounds;
    CGRect frame = self.view.bounds;
    frame.origin.x = -frame.size.width;
    self.menuViewController.view.frame = frame;
    // Do any additional setup after loading the view.
}

- (void) showSideMenu {
    [UIView animateWithDuration:0.15
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 // Move the whole NavigationController view aside
						 CGRect frame = self.contentController.view.frame;
                         CGRect frame2 = self.contentController.view.frame;
						 frame.origin.x = frame.size.width-[self.options[RCSlideOutOptionsSlideValue] floatValue];
                         frame2.origin.x = -[self.options[RCSlideOutOptionsSlideValue] floatValue];
						 self.contentController.view.frame = frame;
                         self.menuViewController.view.frame = frame2;
					 }
                     completion:^(BOOL finished) {
						 /*// Add the overlay that will receive the gestures
						 [self.contentController.view addSubview:self.overlayView];
						 self.menuVisible = YES;
						 if ([self.options[AMOptionsSetButtonDone] boolValue]) {
							 [self.barButton setStyle:UIBarButtonItemStyleDone];
						 }*/
					 }];

}

- (void) hideSideMenu {
    [UIView animateWithDuration:0.15
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 // Move the whole NavigationController view aside
						 CGRect frame = self.view.bounds;
                         CGRect frame2 = self.view.bounds;
                         
                         frame2.origin.x = -self.menuViewController.view.frame.size.width;
						 self.contentController.view.frame = frame;
                         self.menuViewController.view.frame = frame2;
					 }
                     completion:^(BOOL finished) {
						 /*// Add the overlay that will receive the gestures
                          [self.contentController.view addSubview:self.overlayView];
                          self.menuVisible = YES;
                          if ([self.options[AMOptionsSetButtonDone] boolValue]) {
                          [self.barButton setStyle:UIBarButtonItemStyleDone];
                          }*/
					 }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
