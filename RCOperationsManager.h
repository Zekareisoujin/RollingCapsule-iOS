//
//  RCTaskManager.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCNewPostOperation.h"
#import "RCMediaUploadOperation.h"
#import "RCUploadManager.h"

@interface RCOperationsManager : NSObject
+ (void) addOperation:(NSOperation*) operation;
+ (void) addUploadMediaOperation:(RCMediaUploadOperation*) operation;
+ (void) addUploadOperation:(RCMediaUploadOperation*) operation withPost:(RCPost*) post;
+ (void) suspendUpload;
+ (void) cleanupUploadData;
+ (NSMutableArray*) uploadList;
+ (RCUploadManager*) defaultUploadManager;
+ (void) createUploadManager;
+ (void) clearUploadManager;
@end
