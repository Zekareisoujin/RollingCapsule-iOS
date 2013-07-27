//
//  RCTaskManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOperationsManager.h"
#import "RCUtilities.h"
#define MAXIMUM_NUMBER_OF_PHOTO_UPLOADS 10

@implementation RCOperationsManager
static dispatch_semaphore_t uploadManager_sema = nil;
static NSOperationQueue* RCStaticOperationQueue = nil;
static RCUploadManager*  RCStaticUploadManager = nil;

+ (void) addOperation:(NSOperation*) operation {
    if (RCStaticOperationQueue == nil) {
        RCStaticOperationQueue = [[NSOperationQueue alloc] init];
        [RCStaticOperationQueue setMaxConcurrentOperationCount:6];
    }
    [RCStaticOperationQueue addOperation:operation];
}
+ (void) clearUploadManager {
    RCStaticUploadManager = nil;
}
//need to create this method before calling any other upload manager stuff
+ (void) createUploadManager {
    RCStaticUploadManager = nil;
    uploadManager_sema = dispatch_semaphore_create(0);
    RCStaticUploadManager = [[RCUploadManager alloc] init];
    dispatch_semaphore_signal(uploadManager_sema);
}

+ (void) addUploadMediaOperation:(RCMediaUploadOperation*) operation {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    [RCStaticUploadManager.uploadQueue addOperation:operation];

}
+ (void) addUploadOperation:(RCMediaUploadOperation*) operation withPost:(RCPost*) post {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    [RCStaticUploadManager addUploadTaskWithMediaOperation:operation forPost:post];
    postNotification(@"Uploading media");
}



+(RCUploadManager*) defaultUploadManager {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    return RCStaticUploadManager;
}

+ (void) suspendUpload {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    [RCStaticUploadManager.uploadQueue setSuspended:YES];
}



+ (void) resumeUpload {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    [RCStaticUploadManager.uploadQueue setSuspended:NO];
}

+ (void) cleanupUploadData {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    [RCStaticUploadManager cleanupMemory];
}
+ (NSMutableArray*) uploadList {
    if (RCStaticUploadManager == nil)
        dispatch_semaphore_wait(uploadManager_sema, DISPATCH_TIME_FOREVER);
    return RCStaticUploadManager.uploadList;
}
@end
