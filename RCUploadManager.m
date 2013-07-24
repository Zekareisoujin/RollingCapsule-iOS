//
//  RCUploadManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUploadManager.h"
#import "RCUtilities.h"

@implementation RCUploadManager
@synthesize uploadQueue = _uploadQueue;
@synthesize uploadList = _uploadList;
- (id) init {
    self = [super init];
    if (self) {
        _uploadQueue = [[NSOperationQueue alloc] init];
        [_uploadQueue setMaxConcurrentOperationCount:1];
        _uploadList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addNewPostOperation: (RCNewPostOperation*)operation shouldStartMediaUpload:(BOOL)startMediaUpload {
    [_uploadList addObject:operation];
    if (!operation.mediaUploadOperation.successfulUpload && startMediaUpload)
        [_uploadQueue addOperation:operation.mediaUploadOperation];
    [_uploadQueue addOperation:operation];
    [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[RCNewPostOperation class]]) {
        RCNewPostOperation *operation = (RCNewPostOperation*)object;
        [_uploadList removeObject:operation];
        if (!operation.successfulPost) {
            RCNewPostOperation *retry = [operation generateRetryOperation];
            [self addNewPostOperation:retry shouldStartMediaUpload:YES];
        } else {     
            NSNotification *notification = [NSNotification notificationWithName:RCNotificationNameMediaUploaded object:self];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
    }
}
@end
