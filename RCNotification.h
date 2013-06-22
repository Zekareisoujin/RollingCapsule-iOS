//
//  RCNotification.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCNotification : NSObject

@property (nonatomic,retain) NSString *content;
@property (nonatomic,retain) NSString *createdTime;
@property (nonatomic,retain) NSString *updatedTime;

@property (nonatomic, assign) int receiverID;
@property (nonatomic, assign) int notificationID;

- (id) initWithNSDictionary:(NSDictionary *)postData;
@end
