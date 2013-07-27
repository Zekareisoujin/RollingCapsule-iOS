//
//  RCUploadManager.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUploadManager.h"
#import "RCUtilities.h"
#import "RCUploadTask.h"
#import "RCUser.h"
#import <CoreData/CoreData.h>

@implementation RCUploadManager
@synthesize uploadQueue = _uploadQueue;
@synthesize uploadList = _uploadList;
- (id) init {
    self = [super init];
    if (self) {
        _uploadQueue = [[NSOperationQueue alloc] init];
        [_uploadQueue setMaxConcurrentOperationCount:1];
        _uploadList = [[NSMutableArray alloc] init];
        [self readUploadTasksFromCoreData];
    }
    return self;
}

+ (NSArray*) getListOfUploadTasksFromCoreData {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RCUploadTask" inManagedObjectContext:context]];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error != nil)
        NSLog(@"error fetching from core data:%@", [error localizedDescription]);
    return results;
}

- (void) readUploadTasksFromCoreData {
    NSArray *results = [RCUploadManager getListOfUploadTasksFromCoreData];
    for (RCUploadTask *task in results) {
        //if ([task.userID intValue] == [RCUser currentUser].userID) {
            RCNewPostOperation *postOperation = [RCNewPostOperation newPostOperationFromUploadTask:task];
            if (task.fileURL == nil || [task.fileURL isKindOfClass:[NSNull class]]) {
                continue;
            }
            if (!postOperation.successfulPost) {
                [self addNewPostOperation:postOperation shouldStartMediaUpload:YES willSaveToDisk:NO];
            } else
                [_uploadList addObject:postOperation];
        //}
    }
}

- (void) cleanupFinishedOperation {
    NSMutableArray* tobeDeleted = [[NSMutableArray alloc] init];
    @synchronized(_uploadList) {
        for (RCNewPostOperation *newPostOp in _uploadList) {
            if (newPostOp.successfulPost)
                [tobeDeleted addObject:newPostOp];
        }
        for (RCNewPostOperation *newPostOp in tobeDeleted)
            [_uploadList removeObject:newPostOp];
    }
    
}

- (void) cancelNewPostOperation:(RCNewPostOperation*) operation {
    [operation cancel];
    [self deletePostingTask:operation];
}

- (void) pauseNewPostOperation:(RCNewPostOperation*) operation {
    operation.paused = YES;
    [operation cancel];
}

- (void) unpauseNewPostOperation:(RCNewPostOperation*) operation {
    operation.paused = NO;
    if (operation.isFinished && !operation.successfulPost) {
        [_uploadList removeObject:operation];
        RCNewPostOperation *retry = [operation generateRetryOperation];
        [self addNewPostOperation:retry shouldStartMediaUpload:YES willSaveToDisk:NO];
    }
}

- (void) deletePostingTask:(RCNewPostOperation*) operation {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RCUploadTask" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key == %@", operation.post.fileUrl];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error == nil) {
        for (RCUploadTask *task in results) {
            [context deleteObject:task];
        }
        if (![context save:&error]) {
            NSLog(@"CoreData, couldn't save: %@", [error localizedDescription]);
        }
    } else {
        NSLog(@"CoreData, couldn't load with key %@: %@", operation.post.fileUrl, [error localizedDescription]);
    }
}

- (void) updatePostingTask:(RCNewPostOperation*) operation {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RCUploadTask" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key == %@", operation.post.fileUrl];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error == nil) {
        for (RCUploadTask *task in results) {
            task.successful = [NSNumber numberWithBool:YES];
        }
        if (![context save:&error]) {
            NSLog(@"CoreData, couldn't save: %@", [error localizedDescription]);
        }
    } else {
        NSLog(@"CoreData, couldn't load with key %@: %@", operation.post.fileUrl, [error localizedDescription]);
    }
    
    
}

- (void) addNewPostOperation: (RCNewPostOperation*)operation shouldStartMediaUpload:(BOOL)startMediaUpload willSaveToDisk:(BOOL)saveToDisk{
    [_uploadList addObject:operation];
    if (saveToDisk) {
        if (operation.mediaUploadOperation.fileURL != nil)
            [operation writeOperationToCoreDataAsUploadTask];
        else
            [operation.mediaUploadOperation addObserver:self forKeyPath:@"fileURL" options:0 context:nil];
    }
    if (!operation.mediaUploadOperation.successfulUpload && startMediaUpload)
        [_uploadQueue addOperation:operation.mediaUploadOperation];
    [_uploadQueue addOperation:operation];
    [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[RCNewPostOperation class]]) {
        RCNewPostOperation *operation = (RCNewPostOperation*)object;
        if ([keyPath isEqualToString:@"isFinished"]) {
            if (!operation.successfulPost && !operation.paused) {
                //only add to retry queue if the data of the media is still there
                //i.e. the fileURL is there or the upload data is there
                if (operation.mediaUploadOperation.fileURL != nil
                    || (   operation.mediaUploadOperation.uploadData != nil
                        && operation.mediaUploadOperation.thumbnailImage != nil)) {
                        [_uploadList removeObject:operation];
                        RCNewPostOperation *retry = [operation generateRetryOperation];
                        [self addNewPostOperation:retry shouldStartMediaUpload:YES willSaveToDisk:NO];
                    }
            } else {
                operation.mediaUploadOperation.uploadData = nil;
                [self deletePostingTask:operation];
                NSNotification *notification = [NSNotification notificationWithName:RCNotificationNameMediaUploaded object:self];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }
        }
    } else if ([object isKindOfClass:[RCMediaUploadOperation class]]) {
        RCMediaUploadOperation *operation = (RCMediaUploadOperation*)object;
        if ([keyPath isEqualToString:@"fileURL"]) {
            
            //if a mediaupload operation just gain the file URL needed to upload image
            //and failed the prevous upload then retry it
            if (operation.fileURL != nil) {
                
                //search for the new post operation associated with the media upload operation
                //that just gained update
                int nOps = [_uploadList count];
                int i;
                RCNewPostOperation* newPostOp;
                for (i = 0; i < nOps; i++) {
                    newPostOp = [_uploadList objectAtIndex:i];
                    if (newPostOp.mediaUploadOperation == operation) break;
                }
                [newPostOp writeOperationToCoreDataAsUploadTask];
                if (operation.isFinished && !operation.successfulUpload) {
                    [_uploadList removeObject:operation];
                    RCNewPostOperation *retry = [newPostOp generateRetryOperation];
                    [self addNewPostOperation:retry shouldStartMediaUpload:YES willSaveToDisk:NO];
                }

                [operation removeObserver:self forKeyPath:@"fileURL"];
            } // if fileURL is not nil
        }
    }
}

- (void) cleanupMemory {
    [_uploadQueue setSuspended:YES];
    NSLog(@"cleaning up upload data in memory");
    @synchronized(_uploadList) {
        for (RCNewPostOperation *newPostOp in _uploadList) {
            if (![newPostOp.mediaUploadOperation isExecuting]) {
                newPostOp.mediaUploadOperation.uploadData = nil;
                newPostOp.mediaUploadOperation.thumbnailImage = nil;
            }
        }
    }
    [_uploadQueue setSuspended:NO];
}
@end
