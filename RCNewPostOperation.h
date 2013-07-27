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


@interface RCNewPostOperation : NSOperation

@property (nonatomic, strong) RCPost* post;
@property (nonatomic, assign) BOOL successfulPost;
@property (atomic, assign) BOOL paused;
@property (nonatomic, strong) RCMediaUploadOperation *mediaUploadOperation;
- (id) initWithPost:(RCPost*) post withMediaUploadOperation:(RCMediaUploadOperation*) mediaUploadOperation;
- (void) writeOperationToCoreDataAsUploadTask;
@end
