//
//  RCComment.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 17/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCComment : NSObject

@property (nonatomic,strong) NSString *content;
@property (nonatomic,strong) NSString *authorName;
@property (nonatomic,strong) NSDate *createdTime;
@property (nonatomic, assign) int commentID;
@property (nonatomic, assign) int userID;
- (id) initWithNSDictionary:(NSDictionary *)userData;

@end
