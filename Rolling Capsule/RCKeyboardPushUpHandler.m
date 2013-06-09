//
//  RCKeyboardPushUpHandler.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 9/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCKeyboardPushUpHandler.h"

@implementation RCKeyboardPushUpHandler
BOOL _keyboardVisible;
double _keyboardTopPosition;
double _movedUpBy;

@synthesize enabled = _enabled;
@synthesize bottomScreenGap = _bottomScreenGap;

-(id) init {
    self = [super init];
    if (self) {
        _keyboardVisible = FALSE;
        _enabled = YES;
        _bottomScreenGap = 0;
        _movedUpBy = 0;
    }
    return self;
}

-(void) reset {
    _keyboardVisible = FALSE;
    _enabled = YES;
    _bottomScreenGap = 0;
    _movedUpBy = 0;
}

-(void)keyboardWillShow:(NSNotification*)notification {
    if (_enabled) {
        NSDictionary* userInfo = [notification userInfo];
        CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        double moveAmount =  (keyboardFrame.size.height - _bottomScreenGap) - _movedUpBy;
        [self setViewMovedUp:YES offset:moveAmount];
        _movedUpBy += moveAmount;
    }
    
}

- (void) keyboardWillHide:(NSNotification*)notification {
    if (_movedUpBy != 0) {
        [self setViewMovedUp:NO offset:_movedUpBy];
        _movedUpBy = 0;   
    }
    
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void) setViewMovedUp:(BOOL)movedUp offset:(double)kOffsetForKeyboard
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        rect.origin.y -= kOffsetForKeyboard;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOffsetForKeyboard;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

@end
