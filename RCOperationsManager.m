//
//  RCTaskManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOperationsManager.h"
#import "RCUploadManager.h"
#import "RCUtilities.h"
#define MAXIMUM_NUMBER_OF_PHOTO_UPLOADS 10

@implementation RCOperationsManager

static NSOperationQueue* RCStaticOperationQueue = nil;
static RCUploadManager*  RCStaticUploadManager = nil;

+ (void) addOperation:(NSOperation*) operation {
    if (RCStaticOperationQueue == nil) {
        RCStaticOperationQueue = [[NSOperationQueue alloc] init];
        [RCStaticOperationQueue setMaxConcurrentOperationCount:6];
    }
    [RCStaticOperationQueue addOperation:operation];
}

+ (void) addUploadMediaOperation:(RCMediaUploadOperation*) operation {
    if (RCStaticUploadManager == nil) {
        RCStaticUploadManager = [[RCUploadManager alloc] init];
    }
    [RCStaticUploadManager.uploadQueue addOperation:operation];

}
+ (void) addUploadOperation:(RCNewPostOperation*) operation shouldStartMediaUpload:(BOOL)startMediaUpload {
    if (RCStaticUploadManager == nil) {
        RCStaticUploadManager = [[RCUploadManager alloc] init];
    }
    alertStatus(@"Uploading media",@"",nil);
    [RCStaticUploadManager addNewPostOperation:operation shouldStartMediaUpload:startMediaUpload willSaveToDisk:YES];
}

+ (void) suspendUpload {
    if (RCStaticUploadManager == nil) {
        RCStaticUploadManager = [[RCUploadManager alloc] init];
    }
    [RCStaticUploadManager.uploadQueue setSuspended:YES];
}

+ (void) resumeUpload {
    if (RCStaticUploadManager == nil) {
        RCStaticUploadManager = [[RCUploadManager alloc] init];
    }
    [RCStaticUploadManager.uploadQueue setSuspended:NO];
}

+ (void) cleanupUploadData {
    if (RCStaticUploadManager != nil)
        [RCStaticUploadManager cleanupMemory];
}
+ (NSMutableArray*) uploadList {
    if (RCStaticUploadManager == nil) {
        RCStaticUploadManager = [[RCUploadManager alloc] init];
    }
    return RCStaticUploadManager.uploadList;
}
@end
