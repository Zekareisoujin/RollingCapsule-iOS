//
//  RCKeyboardPushUpHandler.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 9/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCKeyboardPushUpHandler : NSObject

@property (nonatomic, weak)   UIView* view;
@property (nonatomic, assign) BOOL   enabled;
@property (nonatomic, assign) double bottomScreenGap;
@property (nonatomic, assign) double movedUpBy;
@property (nonatomic, assign) BOOL   keyboardVisible;
@property (nonatomic, assign) double keyboardTopPosition;

- (void) setViewMovedUp:(BOOL)movedUp offset:(double)kOffsetForKeyboard;
- (void) reset;
@end
