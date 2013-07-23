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
#import "RCConnectionManager.h"

#define RCPHOTODOWNLOADOPERATION_NUMRETRY 3

@interface RCPhotoDownloadOperation ()

@end
@implementation RCPhotoDownloadOperation {
    //BOOL _isExecuting;
    //BOOL _isFinished;
    int nRetry;
}

@synthesize key = _key;
@synthesize delegate = _delegate;
@synthesize s3 = _s3;

- (id)initWithPhotokey:(NSString *)key
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _key = [key copy];
    nRetry = RCPHOTODOWNLOADOPERATION_NUMRETRY;
    return self;
}

- (void)main {
    // a lengthy operation
    @autoreleasepool {
        [RCConnectionManager startConnection];
#if DEBUG==1
        //NSLog(@"download photo with started.", _key);
#endif
        
        
        UIImage *image = [[RCResourceCache centralCache] getResourceForKey:[NSString stringWithFormat:@"media/%@",_key]];
        if (image != nil) {
            [_delegate downloadFinish:image];
            //[self finish];
            return;
        }
        
        [self startS3DownloadRequest];
    }
}

- (void) startS3DownloadRequest {
    while (nRetry--) {
        @try {
            _s3 = [RCAmazonS3Helper s3:[RCUser currentUser].userID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3UsersMediaBucket]];
            if (_s3 != nil) {
                S3GetObjectRequest *downloadRequest = [[S3GetObjectRequest alloc] initWithKey:_key withBucket: RCAmazonS3UsersMediaBucket];
                //[downloadRequest setDelegate: self];
                S3GetObjectResponse *response = [_s3 getObject:downloadRequest];
                UIImage *image = [UIImage imageWithData:response.body];
                [RCConnectionManager endConnection];
                [_delegate downloadFinish:image];
                return;
            } else continue;
        } @catch (AmazonServiceException *e) {
#if DEBUG==1
            NSLog(@"amazon service exception %@",e);
#endif
        }
    }
    [RCConnectionManager endConnection];
    [_delegate downloadFinish:nil];
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    [[RCResourceCache centralCache] putResourceInCache:image forKey:[NSString stringWithFormat:@"media/%@",_key]];
    [_delegate downloadFinish:image];
}

- (void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception {
    NSLog(@"failed to download key from s3 reason service exeption: %@",exception);
    if (nRetry--)
        [self startS3DownloadRequest];
    else {
        [_delegate downloadFinish:nil];
        //[self finish];
    }
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"failed to download key from s3 reason network error: %@",error);
    if (nRetry--)
        [self startS3DownloadRequest];
    else {
        [_delegate downloadFinish:nil];
        //[self finish];
    }
}

-(void)request: (S3Request *)request didCompleteWithResponse: (S3Response *) response {
#if DEBUG==1
    NSLog(@"Download finished (%d)",response.httpStatusCode);
#endif
    /* do something with response.body and response.httpStatusCode */
    /* if you have multiple requests, you can check request arg */
}

/*
- (void) finish {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}*/
@end
