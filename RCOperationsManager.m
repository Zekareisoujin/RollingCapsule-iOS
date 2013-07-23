//
//  RCTaskManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOperationsManager.h"

#define MAXIMUM_NUMBER_OF_PHOTO_UPLOADS 10

@implementation RCOperationsManager
static NSOperationQueue* RCStaticOperationQueue = nil;
static NSOperationQueue* RCStaticUploadQueue = nil;
+ (void) addOperation:(NSOperation*) operation {
    if (RCStaticOperationQueue == nil) {
        RCStaticOperationQueue = [[NSOperationQueue alloc] init];
        [RCStaticOperationQueue setMaxConcurrentOperationCount:6];
    }
    [RCStaticOperationQueue addOperation:operation];
}

+ (void) addUploadMediaOperation:(NSOperation*) operation {
    if (RCStaticUploadQueue == nil) {
        RCStaticUploadQueue = [[NSOperationQueue alloc] init];
        [RCStaticUploadQueue setMaxConcurrentOperationCount:6];
    }
    [RCStaticUploadQueue addOperation:operation];

}

@end
