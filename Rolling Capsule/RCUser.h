//
//  RCUser.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCUser : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, assign) int      userID;
@property (nonatomic, retain) NSDate   *updatedTime;
@property (nonatomic, retain) UIImage  *displayAvatar;

+ (void) initUserDataModel;
+ (id) getUserWithNSDictionary: (NSDictionary*)userData;
+ (void) getUserWithIDAsync: (int)userID completionHandler:(void (^)(RCUser*))completionHandle;
- (id) initWithNSDictionary: (NSDictionary *)userData;

+ (RCUser*) currentUser;
+ (void) setCurrentUser: (RCUser*)user;

- (NSDictionary*) getDictionaryObject;
- (void) updateNewName : (NSString*) newName;

+ (void) followUserAsCurrentUserAsync:(RCUser*) otherUser completionHandler:(void (^)(int, NSString*))completionHandle;
- (void) getUserFollowRelationAsync:(RCUser*) otherUser completionHandler:(void (^)(BOOL, int, NSString*))completionHandle;

+ (void) addFriendAsCurrentUserAsync:(RCUser*) otherUser completionHandler:(void (^)(int, NSString*))completionHandle;
- (void) getUserFriendRelationAsync:(RCUser*) otherUser completionHandler:(void (^)(BOOL, int, NSString*))completionHandle;

- (void) setUserAvatarAsync: (UIImage*)avatar completionHandler:(void (^)(UIImage*))completionHandle;
- (UIImage*) getUserAvatar: (int)viewingUserID;
- (void) getUserAvatarAsync: (int)viewingUserID completionHandler:(void (^)(UIImage*))completionHandle;

@end
