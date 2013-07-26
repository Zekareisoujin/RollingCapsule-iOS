//
//  RCNewPostOperation.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPost.h"
#import "RCMediaUploadOperation.h"
#import "RCUploadTask.h"

@interface RCNewPostOperation : NSOperation

@property (nonatomic, strong) RCPost* post;
@property (nonatomic, assign) BOOL successfulPost;
@property (nonatomic, strong) RCMediaUploadOperation *mediaUploadOperation;
- (id) initWithPost:(RCPost*) post withMediaUploadOperation:(RCMediaUploadOperation*) mediaUploadOperation;
- (RCNewPostOperation*) generateRetryOperation;
+ (RCNewPostOperation*) newPostOperationFromUploadTask:(RCUploadTask*) uploadTask;
@end
