//
//  RCS3CredentialsWithExpiration.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 20/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCS3CredentialsWithExpiration.h"
#import <AWSRuntime/AWSRuntime.h>

@implementation RCS3CredentialsWithExpiration

@synthesize expiryDate = _expiryDate;
@synthesize s3 = _s3;

- (id)initWithAmazonS3Client:(AmazonS3Client*) s3
{
    self = [super init];
    if (self) {
        s3 = _s3;
        _expiryDate = [[NSDate date] dateByAddingTimeInterval:3600];
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
