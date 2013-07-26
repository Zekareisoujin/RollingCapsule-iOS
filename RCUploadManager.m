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

- (void) readUploadTasksFromCoreData {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"RCUploadTask" inManagedObjectContext:context]];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error == nil) {
        for (RCUploadTask *task in results) {
            RCNewPostOperation *postOperation = [RCNewPostOperation newPostOperationFromUploadTask:task];
            if (!postOperation.successfulPost) {
                [self addNewPostOperation:postOperation shouldStartMediaUpload:YES willSaveToDisk:NO];
            } else
                [_uploadList addObject:postOperation];
        }
    } else {
        
    }
}

- (void) writeUploadTaskToCoreData:(RCNewPostOperation*) operation {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSManagedObject *uploadTask = [NSEntityDescription
                                       insertNewObjectForEntityForName:@"RCUploadTask"
                                       inManagedObjectContext:context];
    RCPost* post = operation.post;
    [uploadTask setValue:[NSNumber numberWithInt:post.userID] forKey:@"userID"];
    [uploadTask setValue:post.fileUrl forKey:@"key"];
    [uploadTask setValue:[operation.mediaUploadOperation.fileURL absoluteString] forKey:@"fileURL"];
    [uploadTask setValue:post.content forKey:@"content"];
    [uploadTask setValue:[NSNumber numberWithDouble:post.latitude] forKey:@"latitude"];
    [uploadTask setValue:[NSNumber numberWithDouble:post.longitude] forKey:@"longitude"];
    [uploadTask setValue:post.postedTime forKey:@"postedTime"];
    [uploadTask setValue:post.privacyOption forKey:@"privacyOption"];
    [uploadTask setValue:post.subject forKey:@"subject"];

    if (post.releaseDate != nil)
        [uploadTask setValue:post.releaseDate forKey:@"releaseDate"];
    if (post.topic != nil)
        [uploadTask setValue:post.topic forKey:@"topic"];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"CoreData, couldn't save: %@", [error localizedDescription]);
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
            [self writeUploadTaskToCoreData:operation];
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
            if (!operation.successfulPost) {
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
                [self updatePostingTask:operation];
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
                for (RCNewPostOperation* newPostOp in _uploadList) {
                    if (newPostOp.mediaUploadOperation == operation) {
                        [self writeUploadTaskToCoreData:newPostOp];
                        if (operation.isFinished && !operation.successfulUpload) {
                            [_uploadList removeObject:operation];
                            RCNewPostOperation *retry = [newPostOp generateRetryOperation];
                            [self addNewPostOperation:retry shouldStartMediaUpload:YES willSaveToDisk:YES];
                        }
                    }
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
