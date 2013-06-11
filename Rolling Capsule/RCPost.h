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

@property (nonatomic,retain) NSString *content;
@property (nonatomic,retain) NSString *createdTime;
@property (nonatomic,retain) NSString *updatedTime;
@property (nonatomic,retain) NSString *fileUrl;
@property (nonatomic,retain) NSString *privacyOption;
@property   int     likeCount;
@property   int     viewCount;
@property   double  longitude;
@property   double  latitude;
@property   int     postID;
@property   int     userID;

@property (nonatomic,retain) NSString *authorName;
@property (nonatomic,retain) NSString *authorEmail;

- (MKMapItem*)mapItem;
- (id) initWithNSDictionary:(NSDictionary *)userData;
@end
