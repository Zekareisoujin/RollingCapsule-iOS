//
//  RCUploadManager.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCNewPostOperation.h"
#import "RCMediaUploadOperation.h"
#import "RCUploadTask.h"

@interface RCUploadManager : NSObject

@property (nonatomic, strong) NSOperationQueue* uploadQueue;
@property (nonatomic,strong) NSMutableArray* uploadList;
@property (nonatomic, assign) BOOL willWriteToCoreData;

- (void) addUploadTaskWithMediaOperation:(RCMediaUploadOperation*) mediaUploadOperation forPost:(RCPost*) post;
- (void) addNewPostOperation: (RCNewPostOperation*)operation shouldStartMediaUpload:(BOOL)startMediaUpload willSaveToDisk:(BOOL)saveToDisk;
- (void) cleanupMemory;
- (void) cleanupFinishedOperation;
- (void) cancelNewPostOperation:(RCUploadTask*) task;
- (void) unpauseNewPostOperation:(RCUploadTask*) task;
- (void) pauseNewPostOperation:(RCUploadTask*) task;
- (void) unsuscribeAsObserver;
+ (NSArray*) getListOfUploadTasksFromCoreData;
@end
