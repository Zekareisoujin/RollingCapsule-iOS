//
//  RCNewPostOperation.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPost.h"

@interface RCNewPostOperation : NSOperation

@property (nonatomic, strong) RCPost* post;
@property (nonatomic, assign) BOOL successfulPost;
- (id) initWithPost: (RCPost*) post;

@end
