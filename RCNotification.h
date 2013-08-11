//
//  RCNotification.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCNotification : NSObject

@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *createdTime;
@property (nonatomic, strong) NSDate *updatedTime;
@property (nonatomic, strong) NSMutableArray* urls;

@property (nonatomic, assign) BOOL viewed;
@property (nonatomic, assign) int receiverID;
@property (nonatomic, assign) int notificationID;

- (void) updateViewedProperty;
+ (RCNotification*) parseNotification:(NSDictionary*) notificationDict;
+ (void) initNotificationDataModel;
+ (void) clearNotifications;
+ (NSMutableArray*) notificationsForResource:(NSString*)resourceSpecifier;
+ (NSMutableArray*) getNotifiedPosts;
+ (void) loadMissingNotifiedPostsForList:(NSMutableArray*)posts withCompletion:(void(^)(void)) completion;
+ (int) numberOfNewNotifications;
@end
