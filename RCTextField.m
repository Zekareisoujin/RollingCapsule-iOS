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

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
       [self prepareTextField];
    }
    return self;
}
- (void) prepareTextField {
    [self setBackground:[UIImage imageNamed:@"text_field.png"]];
    [self setBorderStyle:UITextBorderStyleNone];
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowRadius = 10.0;
    self.layer.shadowOpacity = 0.9;
    self.layer.masksToBounds = NO;
    self.textAlignment = NSTextAlignmentCenter;
}

- (id) initWithCoder:(NSCoder *) aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self prepareTextField];
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
