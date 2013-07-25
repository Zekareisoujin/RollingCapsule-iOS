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
        if ([keyPath isEqualToString:@"isFinished"]) {
            if (!operation.successfulPost) {
                //only add to retry queue if the data of the media is still there
                //i.e. the fileURL is there or the upload data is there
                if (operation.mediaUploadOperation.fileURL != nil
                    || (   operation.mediaUploadOperation.uploadData != nil
                        && operation.mediaUploadOperation.thumbnailImage != nil)) {
                        [_uploadList removeObject:operation];
                        RCNewPostOperation *retry = [operation generateRetryOperation];
                        [self addNewPostOperation:retry shouldStartMediaUpload:YES];
                    } else {
                        [operation.mediaUploadOperation addObserver:self forKeyPath:@"fileURL" options:0 context:nil];
                    }
            } else {
                operation.mediaUploadOperation.uploadData = nil;
                NSNotification *notification = [NSNotification notificationWithName:RCNotificationNameMediaUploaded object:self];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }
        }
    } else if ([object isKindOfClass:[RCMediaUploadOperation class]]) {
        RCMediaUploadOperation *operation = (RCMediaUploadOperation*)object;
        if ([keyPath isEqualToString:@"fileURL"]) {
            //if a mediaupload operation just gain the file URL needed to upload image
            //and failed the prevous upload then retry it
            if (operation.fileURL != nil && operation.uploadData == nil && operation.isFinished && !operation.successfulUpload) {
                //search for the new post operation associated with the media upload operation
                //that just gained update
                for (RCNewPostOperation* newPostOp in _uploadList) {
                    if (newPostOp.mediaUploadOperation == operation) {
                        [_uploadList removeObject:operation];
                        RCNewPostOperation *retry = [newPostOp generateRetryOperation];
                        [self addNewPostOperation:retry shouldStartMediaUpload:YES];
                    }
                }
                [operation removeObserver:self forKeyPath:@"fileURL"];
            }
        }
    }
}
- (void) cleanupMemory {
    [_uploadQueue setSuspended:YES];
    NSLog(@"cleaning up upload data in memory");
    @synchronized(_uploadList) {
        for (RCNewPostOperation *newPostOp in _uploadList) {
            if (![newPostOp.mediaUploadOperation isExecuting]) {
                if (newPostOp.successfulPost)
                    [_uploadList removeObject:newPostOp];
                else {
                    newPostOp.mediaUploadOperation.uploadData = nil;
                    newPostOp.mediaUploadOperation.thumbnailImage = nil;
                }
            }
        }
    }
    [_uploadQueue setSuspended:NO];
}
@end
