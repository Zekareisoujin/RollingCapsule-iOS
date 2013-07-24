//
//  RCTaskManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOperationsManager.h"
#import "RCUploadManager.h"

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
    [RCStaticUploadManager addUploadMediaOperation:operation];

}
+ (void) addUploadOperation:(RCNewPostOperation*) operation {
    if (RCStaticUploadManager == nil) {
        RCStaticUploadManager = [[RCUploadManager alloc] init];
    }
    [RCStaticUploadManager addNewPostOperation:operation];
}

@end
