//
//  RCTextField.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCTextField.h"
#import <QuartzCore/QuartzCore.h>

@implementation RCTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CALayer *layer = self.layer;
        
        //self.shadowColor = [UIColor whiteColor].CGColor;
        layer.shadowOffset = CGSizeMake(0.0, 0.0);
        layer.shadowRadius = 40.0;
        layer.shadowOpacity = 0.5;
        layer.masksToBounds = NO;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
