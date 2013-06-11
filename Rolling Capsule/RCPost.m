//
//  RCPost.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 31/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCPost.h"

@implementation RCPost

@synthesize content = _content;
@synthesize createdTime = _createdTime;
@synthesize updatedTime = _updatedTime;
@synthesize fileUrl = _fileUrl;
@synthesize privacyOption = _privacyOption;
@synthesize likeCount = _likeCount;
@synthesize viewCount = _viewCount;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;
@synthesize postID = _postID;
@synthesize userID = _userID;
@synthesize authorName = _authorName;
@synthesize authorEmail = _authorEmail;

CLLocationCoordinate2D _theCoordinate;

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _content = (NSString*)[postData objectForKey:@"content"];
        _createdTime = (NSString*)[postData objectForKey:@"created_at"];
        _updatedTime = (NSString*)[postData objectForKey:@"updated_at"];
        _fileUrl = (NSString*)[postData objectForKey:@"file_url"];
        _privacyOption = (NSString*)[postData objectForKey:@"privacy_option"];
        _likeCount = [[postData objectForKey:@"like_count"] intValue];
        _viewCount = [[postData objectForKey:@"view_count"] intValue];
        _longitude = [[postData objectForKey:@"longitude"] doubleValue];
        _latitude = [[postData objectForKey:@"latitude"] doubleValue];
        _postID = [[postData objectForKey:@"id"] intValue];
        _userID = [[postData objectForKey:@"user_id"] intValue];
        _authorName = [postData objectForKey:@"author_name"];
        _authorEmail = [postData objectForKey:@"author_email"];
        _theCoordinate.latitude = _latitude;
        _theCoordinate.longitude = _longitude;
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return _theCoordinate;
}

@end
