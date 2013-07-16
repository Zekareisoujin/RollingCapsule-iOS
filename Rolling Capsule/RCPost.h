//
//  RCPost.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 31/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface RCPost : NSObject <MKAnnotation>

@property (nonatomic,retain)  NSString *content;
@property (nonatomic,retain)  NSDate *createdTime;
@property (nonatomic,retain)  NSDate *updatedTime;
@property (nonatomic,retain)  NSString *fileUrl;
@property (nonatomic, strong) NSString *thumbnailUrl;
@property (nonatomic,retain)  NSString *privacyOption;
@property (nonatomic, assign) int     likeCount;
@property (nonatomic, assign) int     viewCount;
@property (nonatomic, assign) double  longitude;
@property (nonatomic, assign) double  latitude;
@property (nonatomic, assign) int     postID;
@property (nonatomic, assign) int     userID;
@property (nonatomic, assign) int     landmarkID;
@property (nonatomic, strong) NSString* subject;

@property (nonatomic,retain) NSString *authorName;
@property (nonatomic,retain) NSString *authorEmail;

- (MKMapItem*)mapItem;
- (id) initWithNSDictionary:(NSDictionary *)userData;
@end
