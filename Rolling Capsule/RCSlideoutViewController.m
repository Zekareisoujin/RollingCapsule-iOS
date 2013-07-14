//
//  RCSlideoutViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 31/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCSlideoutViewController.h"
#import <QuartzCore/QuartzCore.h>

NSString *const RCSlideOutOptionsSlideValue = @"RCSlideOutOptionsSlideValue";

@interface RCSlideoutViewController ()
@property (strong, nonatomic)	NSMutableDictionary*	options;
@property (strong, nonatomic)   UIView*                 overlayView;
@property (strong, nonatomic)	UITapGestureRecognizer*	tapGesture;
@property (strong, nonatomic)	UIPanGestureRecognizer*	panGesture;
@end

@implementation RCSlideoutViewController

BOOL _menuVisible;

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
    
    UIView *menuView = self.menuViewController.view;
    [self.view addSubview:menuView];
    [self.view addSubview:self.contentController.view];
    self.contentController.view.frame = self.view.bounds;
    CGRect frame = self.view.bounds;
    frame.origin.x = -frame.size.width;
    self.menuViewController.view.frame = frame;
    
    self.overlayView = [[UIView alloc] initWithFrame:self.contentController.view.frame];
	self.overlayView.userInteractionEnabled = YES;
	self.overlayView.backgroundColor = [UIColor clearColor];
    
    // Detect when the content recieves a single tap
	self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	[self.overlayView addGestureRecognizer:self.tapGesture];
    
	// Detect when the content is touched and dragged
	self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	[self.panGesture setMaximumNumberOfTouches:2];
	[self.panGesture setDelegate:self];
	//[self enablePanning];
}

- (void) disablePanning {
    [self.view removeGestureRecognizer:self.panGesture];
}

- (void) enablePanning {
    [self.view addGestureRecognizer:self.panGesture];
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
                         _menuVisible = YES;
                         [self.contentController.view addSubview:self.overlayView];
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
                         _menuVisible = NO;
                         [self.overlayView removeFromSuperview];
					 }];
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // A single tap hides the slide menu
    [self hideSideMenu];
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = self.contentController.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture;
{
	// The pan gesture moves horizontally the view
    UIView *piece = self.contentController.view;
    UIView *menu = self.menuViewController.view;
    [self adjustAnchorPointForGestureRecognizer:gesture];
    
    float rightBorder = self.view.bounds.size.width - [self.options[RCSlideOutOptionsSlideValue] floatValue];
    
    if ([gesture state] == UIGestureRecognizerStateBegan || [gesture state] == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:[piece superview]];
        [piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y)];
        [menu setCenter:CGPointMake([menu center].x + translation.x, [menu center].y)];
		if (piece.frame.origin.x < 0) {
			[piece setFrame:CGRectMake(0, piece.frame.origin.y, piece.frame.size.width, piece.frame.size.height)];
            [menu setFrame:CGRectMake(-menu.frame.size.width, menu.frame.origin.y, menu.frame.size.width, menu.frame.size.height)];
		}
        
		if (piece.frame.origin.x > rightBorder) {
			[piece setFrame:CGRectMake(rightBorder, piece.frame.origin.y, piece.frame.size.width, piece.frame.size.height)];
            [menu setFrame:CGRectMake(-[self.options[RCSlideOutOptionsSlideValue] floatValue], menu.frame.origin.y, menu.frame.size.width, menu.frame.size.height)];
		}
        [gesture setTranslation:CGPointZero inView:[piece superview]];
    }
    else if ([gesture state] == UIGestureRecognizerStateEnded) {
		// Hide the slide menu only if the view is released under a certain threshold, the threshold is lower when the menu is hidden
		float threshold;
        threshold = rightBorder / 2;
		if (self.contentController.view.frame.origin.x < threshold) {
			[self hideSideMenu];
		} else {
			[self showSideMenu];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
