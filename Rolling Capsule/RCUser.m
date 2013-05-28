//
//  RCUser.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUser.h"

@interface RCUser ()

@end

@implementation RCUser

@synthesize name = _name;
@synthesize email = _email;
@synthesize userID = _userID;

- (id) initWithNSDictionary:(NSDictionary *)userData {
    self = [super init];
    if (self) {
        _name = (NSString *)[userData objectForKey:@"name"];
        _email = (NSString *)[userData objectForKey:@"email"];
        NSNumber *num = [userData objectForKey:@"id"];
        _userID = [num intValue];
    }
    return self;
}
@end
