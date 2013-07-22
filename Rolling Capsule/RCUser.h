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
@property int      userID;

@property (nonatomic, retain) UIImage *displayAvatar;

- (id) initWithNSDictionary:(NSDictionary *)userData;

- (NSDictionary*) getDictionaryObject;
- (void) updateNewName : (NSString*) newName;
+ (RCUser*) currentUser;
+ (void) setCurrentUser: (RCUser*)user;

+ (void) followUserAsync:(RCUser*) otherUser withSuccessfulFunction:(void (^)(int)) successFunction withFailureFunction:(void (^)(NSString*)) failureFunction;
- (void) getUserFollowRelationAsync:(RCUser*) otherUser completion:(void (^)(BOOL))processFunction withFailureFunction:(void (^)(NSString*)) failureFunction;
- (void) getUserFriendRelationAsync:(RCUser*) otherUser completion:(void (^)(BOOL))processFunction withFailureFunction:(void (^)(NSString*)) failureFunction;
+ (void) addFriendAsync:(RCUser*) otherUser withSuccessfulFunction:(void (^)(int)) successFunction withFailureFunction:(void (^)(NSString*)) failureFunction;
- (void) setUserAvatarAsync: (UIImage*)avatar completionHandler:(void (^)(BOOL, UIImage*))completionFunc;
- (UIImage*) getUserAvatar: (int)viewingUserID;
- (void) getUserAvatarAsync: (int)viewingUserID completionHandler:(void (^)(UIImage*))completionFunc;
+ (void) getUserWithIDAsync: (int)userID completionHandler:(void (^)(RCUser*))completionFunc;
@end
