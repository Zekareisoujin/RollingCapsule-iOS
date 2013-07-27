//
//  RCUploadTask.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 26/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUploadTask.h"
#import "RCUser.h"
#import <CoreData/CoreData.h>

@implementation RCUploadTask

@dynamic userID;
@dynamic key;
@dynamic fileURL;
@dynamic latitude;
@dynamic longitude;
@dynamic subject;
@dynamic content;
@dynamic postedTime;
@dynamic releaseDate;
@dynamic topic;
@dynamic privacyOption;
@dynamic successful;
@synthesize currentNewPostOperation = _currentNewPostOperation;
@synthesize paused = _paused;

- (id) initWithMediaUploadOperation:(RCMediaUploadOperation*) mediaUploadOperation withPost:(RCPost*) post {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *uploadTaskDesctiption = [NSEntityDescription
                                   entityForName:@"RCUploadTask"
                                   inManagedObjectContext:context];
    NSLog(@"creating upload task object");
    self = [super initWithEntity:uploadTaskDesctiption insertIntoManagedObjectContext:nil];
    if (self) {
        self.userID = [NSNumber numberWithInt:[RCUser currentUser].userID];
        self.key = post.fileUrl;
        self.latitude = [NSNumber numberWithDouble:post.latitude];
        self.longitude= [NSNumber numberWithDouble:post.longitude];
        self.subject = post.subject;
        self.content = post.content;
        self.topic = post.topic;
        self.postedTime = post.postedTime;
        self.releaseDate = post.releaseDate;
        self.fileURL = [mediaUploadOperation.fileURL absoluteString];
        self.privacyOption = post.privacyOption;
        self.successful = [NSNumber numberWithBool:NO];
        NSLog(@"before forming newpost operation");
        self.currentNewPostOperation = [[RCNewPostOperation alloc] initWithPost:post withMediaUploadOperation:mediaUploadOperation];
    }
    NSLog(@"finished creating upload task");
    return self;
}

- (RCPost*) respectivePost {
    RCPost *post = [[RCPost alloc] init];
    post.content = self.content;
    post.subject = self.subject;
    post.releaseDate = self.releaseDate;
    if ([post.releaseDate isKindOfClass:[NSNull class]])
        post.releaseDate = nil;
    post.topic = self.topic;
    if ([post.topic isKindOfClass:[NSNull class]])
        post.topic = nil;
    post.latitude = [self.latitude doubleValue];
    post.longitude = [self.longitude doubleValue];
    post.fileUrl = self.key;
    post.privacyOption = self.privacyOption;
    post.thumbnailUrl = [NSString stringWithFormat:@"%@-thumbnail",post.fileUrl];
    return post;

}
- (void) generateRetryOperation {
    RCNewPostOperation *retry;
    NSString *mediaType = [self.key hasSuffix:@"mov"] ? @"movie/mov" : @"image/jpeg";
    RCMediaUploadOperation *mediaUploadRetry;
    RCPost *post;
    if (_currentNewPostOperation != nil) {
        if (_currentNewPostOperation.mediaUploadOperation.successfulUpload)
            mediaUploadRetry = _currentNewPostOperation.mediaUploadOperation;
        else
            mediaUploadRetry = [[RCMediaUploadOperation alloc]
                                initWithKey:self.key
                                withMediaType:mediaType
                                withURL:[NSURL URLWithString:self.fileURL]];
        mediaUploadRetry.uploadData = _currentNewPostOperation.mediaUploadOperation.uploadData;
        mediaUploadRetry.thumbnailImage = _currentNewPostOperation.mediaUploadOperation.thumbnailImage;
        post = _currentNewPostOperation.post;
    } else {
        mediaUploadRetry = [[RCMediaUploadOperation alloc]
                            initWithKey:self.key
                            withMediaType:mediaType
                            withURL:[NSURL URLWithString:self.fileURL]];
        post = [self respectivePost];
    }
    retry = [[RCNewPostOperation alloc] initWithPost:post withMediaUploadOperation:mediaUploadRetry ];
    _currentNewPostOperation = retry;
}
@end
