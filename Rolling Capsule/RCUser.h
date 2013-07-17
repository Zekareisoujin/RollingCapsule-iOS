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
- (UIImage*) getUserAvatar: (int)viewingUserID;
- (void) getUserAvatarAsync: (int)viewingUserID completionHandler:(void (^)(UIImage*))completionFunc;
- (void) updateNewName: (NSString*)newName;

+ (void) getUserWithIDAsync: (int)userID completionHandler:(void (^)(RCUser*))completionFunc;

@end
