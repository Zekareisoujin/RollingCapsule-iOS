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

@implementation RCUploadManager {
    NSMutableDictionary* uploadTasksByKey;
}

@synthesize uploadQueue = _uploadQueue;
@synthesize uploadList = _uploadList;
@synthesize willWriteToCoreData = _willWriteToCoreData;

- (id) init {
    self = [super init];
    if (self) {
        _uploadQueue = [[NSOperationQueue alloc] init];
        [_uploadQueue setMaxConcurrentOperationCount:1];
        _uploadList = [[NSMutableArray alloc] init];
        uploadTasksByKey = [[NSMutableDictionary alloc] init];
        [self readUploadTasksFromCoreData];
        _willWriteToCoreData = YES;
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
        NSLog(@"%d  == %d ? ",[task.userID intValue],[RCUser currentUser].userID);
        if ([task.userID intValue] == [RCUser currentUser].userID) {
            if (task.fileURL == nil || [task.fileURL isKindOfClass:[NSNull class]] || task.key == nil || [task.key isKindOfClass:[NSNull class]]) {
                continue;
            }
            [_uploadList addObject:task];
            [uploadTasksByKey setObject:task forKey:task.key];
            [self reAddTaskOperation:task];
        }
    }
}

- (void) cleanupFinishedOperation {
    NSMutableArray* tobeDeleted = [[NSMutableArray alloc] init];
    @synchronized(_uploadList) {
        for (RCUploadTask* task in _uploadList) {
            if (task.postedSuccessfully)
                [tobeDeleted addObject:task];
        }
        for (RCUploadTask* task in tobeDeleted) {
            [_uploadList removeObject:task];
            [uploadTasksByKey removeObjectForKey:task.currentNewPostOperation.post.fileUrl];
        }
    }
    
}

- (void) cancelNewPostOperation:(RCUploadTask*) task {
    [task.currentNewPostOperation cancel];
    [_uploadList removeObject:task];
    [uploadTasksByKey removeObjectForKey:task.key];
    [self deleteUploadTask:task];
    
}

- (void) pauseNewPostOperation:(RCUploadTask*) task {
    task.paused = YES;
    [task.currentNewPostOperation cancel];
    
}

- (void) unpauseNewPostOperation:(RCUploadTask*) task {
    task.paused = NO;
    if (task.currentNewPostOperation == nil || (task.currentNewPostOperation.isFinished && !task.currentNewPostOperation)) {
        [self reAddTaskOperation:task];
    }
}

- (void) deleteUploadTask:(RCUploadTask*) task {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RCUploadTask" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key == %@", task.key];
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
        NSLog(@"CoreData, couldn't load with key %@: %@", task.key, [error localizedDescription]);
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

- (void) reAddTaskOperation:(RCUploadTask*) task {
    [task generateRetryOperation];
    if (!task.currentNewPostOperation.mediaUploadOperation.successfulUpload)
        [_uploadQueue addOperation:task.currentNewPostOperation.mediaUploadOperation];
    [_uploadQueue addOperation:task.currentNewPostOperation];
    [task.currentNewPostOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) unsuscribeAsObserver {
    for (RCUploadTask* task in _uploadList) {
        if (!task.currentNewPostOperation.isFinished) {
            @try {
                [task.currentNewPostOperation removeObserver:self forKeyPath:@"isFinished"];
            }@catch(NSException *exception) {
                NSLog(@"not observing this task");   
            }
        }
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[RCNewPostOperation class]]) {
        RCNewPostOperation *operation = (RCNewPostOperation*)object;
        if ([keyPath isEqualToString:@"isFinished"]) {
            [operation removeObserver:self forKeyPath:keyPath];
            RCUploadTask *task = [uploadTasksByKey objectForKey:operation.mediaUploadOperation.key];
            if (task == nil) return;
            if (!operation.successfulPost && !task.paused) {
                [self reAddTaskOperation:task];
            } else if (operation.successfulPost) {
                task.currentNewPostOperation.mediaUploadOperation.uploadData = nil;
                task.currentNewPostOperation.mediaUploadOperation.thumbnailImage = nil;
                task.successful = [NSNumber numberWithBool:YES];
                task.postedSuccessfully = YES;
                [self deleteUploadTask:task];
                NSNotification *notification = [NSNotification notificationWithName:RCNotificationNameMediaUploaded object:self];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }
        }
    } else if ([object isKindOfClass:[RCMediaUploadOperation class]]) {
        RCMediaUploadOperation *operation = (RCMediaUploadOperation*)object;
        if ([keyPath isEqualToString:@"fileURL"]) {
            NSLog(@"changed to file url of media upload operation");
            if (operation.fileURL != nil) {
                
                NSLog(@"fileURL received after newPostOperation added, looking for the operation to be modified");
                RCUploadTask *task = [uploadTasksByKey objectForKey:operation.key];
                if (task == nil) return;
                task.fileURL = [operation.fileURL absoluteString];
                [self writeUploadTaskToCoreData:task];
                [operation removeObserver:self forKeyPath:@"fileURL"];
            } // if fileURL is not nil
        }
    }
}

- (void) writeUploadTaskToCoreData:(RCUploadTask*) task {
    if (!_willWriteToCoreData) return;
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSError *error;
    NSLog(@"writing upload task to core data: key:%@ content:%@",task.key,task.content);
    [context insertObject:task];
    [context save:&error];
    if (error != nil) {
        NSLog(@" can't save upload task to coredata: %@",[error localizedDescription]);
    }
    NSLog(@"done saving upload task");
}

- (void) addUploadTaskWithMediaOperation:(RCMediaUploadOperation*) mediaUploadOperation forPost:(RCPost*) post {
    RCUploadTask *task = [[RCUploadTask alloc] initWithMediaUploadOperation:mediaUploadOperation withPost:post];
    [_uploadList addObject:task];
    if (mediaUploadOperation.fileURL != nil) {
        [self writeUploadTaskToCoreData:task];
    } else {
        NSLog(@"no original URL, adding observer to listen to when to write to disk");
        [mediaUploadOperation addObserver:self forKeyPath:@"fileURL" options:0 context:nil];
    }
    [uploadTasksByKey setObject:task forKey:task.key];
    [task.currentNewPostOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    [_uploadQueue addOperation:task.currentNewPostOperation];
    NSLog(@"added to queue, finish adding upload task");
    
}

- (void) cleanupMemory {
    [_uploadQueue setSuspended:YES];
    NSLog(@"cleaning up upload data in memory");
    @synchronized(_uploadList) {
        for (RCUploadTask* task in _uploadList) {
            if (![task.currentNewPostOperation.mediaUploadOperation isExecuting]) {
                task.currentNewPostOperation.mediaUploadOperation.uploadData = nil;
                task.currentNewPostOperation.mediaUploadOperation.thumbnailImage = nil;
            }
        }
    }
    [_uploadQueue setSuspended:NO];
}
@end
