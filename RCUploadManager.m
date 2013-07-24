//
//  RCUploadManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUploadManager.h"


@implementation RCUploadManager
@synthesize uploadQueue = _uploadQueue;
@synthesize uploadList = _uploadList;
- (id) init {
    self = [super init];
    if (self) {
        _uploadQueue = [[NSOperationQueue alloc] init];
        _uploadList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addUploadMediaOperation:(RCMediaUploadOperation*) operation {
    [_uploadQueue addOperation:operation];
}

- (void) addNewPostOperation: (RCNewPostOperation*)operation {
    [_uploadList addObject:operation];
    [_uploadQueue addOperation:operation];
    [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[RCNewPostOperation class]]) {
        RCNewPostOperation *operation = (RCNewPostOperation*)object;
        if (!operation.successfulPost) {
            NSOperation *retryOperation = [operation generateOperation];
            if (!operation.mediaUploadOperation.successfulUpload) {
                NSOperation* mediaUploadRetryOperation = [operation.mediaUploadOperation generateOperation];
                [retryOperation addDependency:mediaUploadRetryOperation];
                [_uploadQueue addOperation:mediaUploadRetryOperation];
            } else {
            }
            [_uploadQueue addOperation:retryOperation];
        } else [_uploadList removeObject:operation];
    }
}
@end
