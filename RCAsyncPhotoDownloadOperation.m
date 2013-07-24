//
//  RCAsyncPhotoDownloadOperation.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCAsyncPhotoDownloadOperation.h"
#import "RCAmazonS3Helper.h"
#import "RCConstants.h"
#import "RCResourceCache.h"

@implementation RCAsyncPhotoDownloadOperation {
    BOOL _isExecuting;
    BOOL _isFinished;
    int nRetry;
}

@synthesize key = _key;
@synthesize delegate = _delegate;
@synthesize ownerID = _ownerID;
@synthesize s3 = _s3;

- (id)initWithPhotokey:(NSString *)key withOwnerID:(int)ownerID
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _key = [key copy];
    _ownerID = ownerID;
    _isExecuting = NO;
    _isFinished = NO;
    nRetry = RCASYNCPHOTODOWNLOADOPERATION_NUMRETRY;
    return self;
}

- (void)start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    NSLog(@"opeartion for <%@> started.", _key);
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self startPhotoDownload];
}

- (void) startPhotoDownload {
    NSString* resource = [NSString stringWithFormat:@"%@/*",RCAmazonS3UsersMediaBucket];
    _s3 = [RCAmazonS3Helper s3:_ownerID forResource:resource];
    S3GetObjectRequest *downloadRequest = [[S3GetObjectRequest alloc] initWithKey:_key withBucket: RCAmazonS3UsersMediaBucket];
    [downloadRequest setDelegate: self];
    [_s3 getObject:downloadRequest];
    /*[RCAmazonS3Helper getS3ClientAsyncForUser:_ownerID forResource:resource completion:^(AmazonS3Client *s3) {
        S3GetObjectRequest *downloadRequest = [[S3GetObjectRequest alloc] initWithKey:_key withBucket: RCAmazonS3UsersMediaBucket];
        [downloadRequest setDelegate: self];
        [_s3 getObject:downloadRequest];
    }];*/
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    if (image != nil)
        [[RCResourceCache centralCache] putResourceInCache:image forKey:[NSString stringWithFormat:@"media/%@",_key]];
    [_delegate updateThumbnailImage:image];
    [self finish];
}

- (void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"failed to download key from s3 reason service exeption: %@",exception);
    if (nRetry--)
        [self startPhotoDownload];
    else {
        [_delegate updateThumbnailImage:nil];
        [self finish];
    }
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"failed to download key from s3 reason network error: %@",error);
    if (nRetry--)
        [self startPhotoDownload];
    else {
        [_delegate updateThumbnailImage:nil];
        [self finish];
    }
}

- (void)finish
{
    NSLog(@"finished downloading %@",_key);
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    [self cancel];
}


@end
