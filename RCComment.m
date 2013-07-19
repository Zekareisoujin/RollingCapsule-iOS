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
@synthesize createdTime = _createdTime;

- (id) initWithNSDictionary:(NSDictionary *)userData {
    self = [super init];
    if (self) {
        _authorName = (NSString *)[userData objectForKey:@"author_name"];
        _content = (NSString *)[userData objectForKey:@"content"];
        _commentID = [[userData objectForKey:@"id"] intValue];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        _createdTime = [formatter dateFromString:(NSString*)[userData objectForKey:@"created_at"]];
    }
    return self;
}

@end
