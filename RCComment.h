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
@property (nonatomic, assign) int commentID;
- (id) initWithNSDictionary:(NSDictionary *)userData;

@end
