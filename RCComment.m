//
//  RCComment.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCComment.h"

@implementation RCComment
@synthesize content = _content;
@synthesize authorName = _authorName;
@synthesize commentID = _commentID;

- (id) initWithNSDictionary:(NSDictionary *)userData {
    self = [super init];
    if (self) {
        _authorName = (NSString *)[userData objectForKey:@"author_name"];
        _content = (NSString *)[userData objectForKey:@"content"];
        _commentID = [[userData objectForKey:@"id"] intValue];
        
    }
    return self;
}

@end
