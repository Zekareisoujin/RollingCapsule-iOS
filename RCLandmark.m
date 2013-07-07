//
//  RCLandmark.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCLandmark.h"

@implementation RCLandmark
@synthesize description = _description;
@synthesize createdTime = _createdTime;
@synthesize updatedTime = _updatedTime;
@synthesize fileUrl = _fileUrl;
@synthesize privacyOption = _privacyOption;
@synthesize likeCount = _likeCount;
@synthesize viewCount = _viewCount;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;
@synthesize landmarkID = _landmarkID;
@synthesize userID = _userID;
@synthesize name = _name;
@synthesize category = _category;

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _description = (NSString*)[postData objectForKey:@"description"];
        _createdTime = (NSString*)[postData objectForKey:@"created_at"];
        _updatedTime = (NSString*)[postData objectForKey:@"updated_at"];
        _fileUrl = (NSString*)[postData objectForKey:@"file_url"];
        _privacyOption = (NSString*)[postData objectForKey:@"privacy_option"];
        _likeCount = [[postData objectForKey:@"like_count"] intValue];
        _viewCount = [[postData objectForKey:@"view_count"] intValue];
        _longitude = [[postData objectForKey:@"longitude"] doubleValue];
        _latitude = [[postData objectForKey:@"latitude"] doubleValue];
        _landmarkID = [[postData objectForKey:@"id"] intValue];
        _userID = [[postData objectForKey:@"user_id"] intValue];
        _name = (NSString*)[postData objectForKey:@"name"];
        _category = (NSString*)[postData objectForKey:@"category"];
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D _theCoordinate;
    _theCoordinate.latitude = _latitude;
    _theCoordinate.longitude = _longitude;
    return _theCoordinate;
}

@end
