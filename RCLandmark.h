//
//  RCLandmark.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface RCLandmark : NSObject <MKAnnotation>

@property (nonatomic,strong) NSString *description;
@property (nonatomic,strong) NSString *createdTime;
@property (nonatomic,strong) NSString *updatedTime;
@property (nonatomic,strong) NSString *fileUrl;
@property (nonatomic,strong) NSString *privacyOption;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *category;
@property   int     likeCount;
@property   int     viewCount;
@property   double  longitude;
@property   double  latitude;
@property   int     landmarkID;
@property   int     userID;
- (id) initWithNSDictionary:(NSDictionary *)postData;
@end
