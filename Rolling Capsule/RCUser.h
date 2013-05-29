//
//  RCUser.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCUser : NSObject

@property (nonatomic,retain) NSString *name;
@property (nonatomic,retain) NSString *email;
@property (nonatomic,retain) NSString *avatarImg;
@property  int      userID;

- (id) initWithNSDictionary:(NSDictionary *)userData;
@end
