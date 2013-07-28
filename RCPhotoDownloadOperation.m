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

#define RCPHOTODOWNLOADOPERATION_NUMRETRY 2

@interface RCPhotoDownloadOperation ()

@end
@implementation RCPhotoDownloadOperation {
    //BOOL _isExecuting;
    //BOOL _isFinished;
    int nRetry;
}

@synthesize key = _key;
@synthesize s3 = _s3;
@synthesize completionHandler = _completionHandler;

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
        //[RCConnectionManager startConnection];
#if DEBUG==1
        //NSLog(@"download photo with started.", _key);
#endif
        
        
        UIImage *image = [[RCResourceCache centralCache] getResourceForKey:[NSString stringWithFormat:@"media/%@",_key]];
        if (image != nil) {
            if (_completionHandler != nil)
                _completionHandler(image);
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
                
                if (image != nil)
                    [[RCResourceCache centralCache] putResourceInCache:image forKey:[NSString stringWithFormat:@"media/%@", _key]];
                //[RCConnectionManager endConnection];
                if (_completionHandler != nil)
                    _completionHandler(image);
                return;
            } else continue;
        } @catch (AmazonServiceException *e) {
#if DEBUG==1
            NSLog(@"amazon service exception %@",e);
#endif
        }
    }
    //[RCConnectionManager endConnection];
    if (_completionHandler != nil)
        _completionHandler(nil);
}

@end
