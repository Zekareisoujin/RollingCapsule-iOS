//
//  RCLandmark.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCLandmark : NSObject

@property (nonatomic,retain) NSString *description;
@property (nonatomic,retain) NSString *createdTime;
@property (nonatomic,retain) NSString *updatedTime;
@property (nonatomic,retain) NSString *fileUrl;
@property (nonatomic,retain) NSString *privacyOption;
@property   int     likeCount;
@property   int     viewCount;
@property   double  longitude;
@property   double  latitude;
@property   int     landmarkID;
@property   int     userID;
- (id) initWithNSDictionary:(NSDictionary *)postData;
@end
