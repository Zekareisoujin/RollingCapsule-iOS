//
//  RCPhotoDownloadOperation.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCPhotoDownloadOperation.h"
#import "RCAmazonS3Helper.h"
#import "RCConstants.h"
#import "RCResourceCache.h"

@interface RCPhotoDownloadOperation ()

@end
@implementation RCPhotoDownloadOperation {
    BOOL _isExecuting;
    BOOL _isFinished;
    int nRetry;
}

@synthesize key = _key;
@synthesize delegate = _delegate;
@synthesize ownerID = _ownerID;

- (id)initWithPhotokey:(NSString *)key withOwnerID:(int)ownerID
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _key = [key copy];
    _ownerID = ownerID;
    _isExecuting = NO;
    _isFinished = NO;
    nRetry = 3;
    
    return self;
}

- (void)start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    NSLog(@"download photo with started.", _key);
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    
    UIImage *image = [[RCResourceCache centralCache] getResourceForKey:[NSString stringWithFormat:@"media/%@",_key]];
    if (image != nil) {
        [_delegate downloadFinish:image];
        [self finish];
        return;
    }
    
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:_ownerID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
    if (![_key hasSuffix:@".mov"]) {
        [self startS3DownloadRequest];
    } else {
        
        S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
        override.contentType = @"movie/mov";
        S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
        gpsur.key     = _key;
        gpsur.bucket  = RCAmazonS3UsersMediaBucket;
        gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];  // Added an hour's worth of seconds to the current time.
        gpsur.responseHeaderOverrides = override;
        NSURL *url = [s3 getPreSignedURL:gpsur];
        NSLog(@"end generate url");
        [_delegate downloadFinish:url];
        [self finish];
            
    }
}

- (void) startS3DownloadRequest {
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:_ownerID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
    S3GetObjectRequest *downloadRequest = [[S3GetObjectRequest alloc] initWithKey:_key withBucket: RCAmazonS3AvatarPictureBucket];
    [downloadRequest setDelegate: self];
    [s3 getObject:downloadRequest];
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    [_delegate downloadFinish:image];
}

- (void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"failed to download key from s3 reason service exeption: %@",exception);
    if (nRetry--)
        [self startS3DownloadRequest];
    else
        [_delegate downloadFinish:nil];
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"failed to download key from s3 reason network error: %@",error);
    if (nRetry--)
        [self startS3DownloadRequest];
    else
        [_delegate downloadFinish:nil];
}

-(void)request: (S3Request *)request didCompleteWithResponse: (S3Response *) response {
    NSLog(@"Download finished (%d)",response.httpStatusCode);
    /* do something with response.body and response.httpStatusCode */
    /* if you have multiple requests, you can check request arg */
}

- (void) finish {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end
