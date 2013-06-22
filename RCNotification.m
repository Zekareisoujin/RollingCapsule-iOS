//
//  RCNotification.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCNotification.h"

@implementation RCNotification

@synthesize content = _content;
@synthesize createdTime = _createdTime;
@synthesize updatedTime = _updatedTime;
@synthesize receiverID = _receiverID;
@synthesize notificationID = _notificationID;

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _content = (NSString*)[postData objectForKey:@"content"];
        _createdTime = (NSString*)[postData objectForKey:@"created_at"];
        _updatedTime = (NSString*)[postData objectForKey:@"updated_at"];
        
        _receiverID = [[postData objectForKey:@"receiver_id"] intValue];
        _notificationID = [[postData objectForKey:@"id"] intValue];
    }
    return self;
}

@end
