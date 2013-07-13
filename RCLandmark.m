//
//  RCLandmark.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCLandmark.h"
#import "RCResourceCache.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "SBJson.h"

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

+ (RCLandmark *) getLandmark:(int) landmark_id {
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@%@/%d", RCServiceURL, RCLandmarksResource,landmark_id];
    RCLandmark *landmark = (RCLandmark*)[cache getResourceForKey:key usingQuery:^{
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@?mobile=1", key]];
        
        NSURLRequest *request = CreateHttpGetRequest(url);
        NSURLResponse *response;
        NSError *error = nil;
        NSData *landmarkData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        RCLandmark *landmark = nil;
        if (error == nil) {
            NSString *responseData = [[NSString alloc]initWithData:landmarkData encoding:NSUTF8StringEncoding];
            
            SBJsonParser *jsonParser = [SBJsonParser new];
            NSDictionary *landmarkJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
            NSDictionary *landmarkDictionary = [landmarkJson objectForKey:@"landmark"];
            if (landmarkDictionary != nil)
                landmark = [[RCLandmark alloc] initWithNSDictionary:landmarkDictionary];
            else {
                NSLog(@"error in response can't find landmark object response:%@",responseData);
            }
            
        } else NSLog(@"error getting landmark: %@",error);
        return landmark;
    }];

    return landmark;
}

@end
