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
@synthesize landmarkID = _landmarkID;

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _content = (NSString*)[postData objectForKey:@"content"];
        _fileUrl = (NSString*)[postData objectForKey:@"file_url"];
        _privacyOption = (NSString*)[postData objectForKey:@"privacy_option"];
        _likeCount = [[postData objectForKey:@"like_count"] intValue];
        _viewCount = [[postData objectForKey:@"view_count"] intValue];
        _longitude = [[postData objectForKey:@"longitude"] doubleValue];
        _latitude = [[postData objectForKey:@"latitude"] doubleValue];
        _postID = [[postData objectForKey:@"id"] intValue];
        _userID = [[postData objectForKey:@"user_id"] intValue];
        id landmarkObj = [postData objectForKey:@"landmark_id"];
        if ([landmarkObj isKindOfClass:[NSNumber class]]) {
            _landmarkID = [[postData objectForKey:@"landmark_id"] intValue];
        } else
            _landmarkID = -1;
        _authorName = [postData objectForKey:@"author_name"];
        _authorEmail = [postData objectForKey:@"author_email"];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        _createdTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"created_at"]];
        _updatedTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"updated_at"]];
    }
    return self;
}

- (NSString *)title {
    return @"";
}

- (NSString *)subtitle {
    return @"";
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D _theCoordinate;
    _theCoordinate.latitude = _latitude;
    _theCoordinate.longitude = _longitude;
    return _theCoordinate;
}

- (MKMapItem*)mapItem {
    NSDictionary *addressDict = @{@"address" : @"address"};
    
    MKPlacemark *placemark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate
                              addressDictionary:addressDict];
    
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = @"yo";
    
    return mapItem;
}

@end
