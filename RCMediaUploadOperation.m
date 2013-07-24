//
//  RCMediaUploadOperation.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMediaUploadOperation.h"
#import "RCAmazonS3Helper.h"
#import "RCConstants.h"

@implementation RCMediaUploadOperation {
    int nRetry;
    NSData*thumbnailData;
    S3PutObjectResponse *_putObjectResponse;
}

@synthesize key = _key;
@synthesize uploadData = _uploadData;
@synthesize thumbnailImage = _thumbnailImage;
@synthesize isCancel = _isCancel;
@synthesize mediaType = _mediaType;
@synthesize s3 = _s3;
@synthesize amazonException = _amazonException;
@synthesize uploadError = _uploadError;
@synthesize successfulUpload = _successfulUpload;

- (id) initWithKey:(NSString*)key withUploadData:(NSData*)uploadData withThumbnail:(UIImage*)thumbnailImage withMediaType:(NSString*)mediaType {
    self = [super init];
    if (self) {
        _key = key;
        _uploadData = uploadData;
        _thumbnailImage = thumbnailImage;
        _mediaType = mediaType;
        _isCancel = NO;
        nRetry = 3;
        _s3 = nil;
        _successfulUpload = NO;
    }
    return self;
}

- (NSOperation*) generateOperation {
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(main) object:nil];
    return operation;
}

- (void)main {
    // a lengthy operation
    @autoreleasepool {
        thumbnailData = UIImageJPEGRepresentation(_thumbnailImage, 1.0);
        while (nRetry-- && ![self isCancelled]) {
            _amazonException = nil;
            _s3 = [RCAmazonS3Helper s3:[RCUser currentUser].userID forResource:[NSString stringWithFormat:@"%@/*", RCAmazonS3UsersMediaBucket]];
            if (_s3 != nil) {
                // Upload image data.  Remember to set the content type.
                S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:_key
                                                                         inBucket:RCAmazonS3UsersMediaBucket];
                por.contentType = _mediaType;
                por.data = _uploadData;
                
                S3PutObjectRequest *porThumbnail = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@-thumbnail",_key]
                                                                                  inBucket:RCAmazonS3UsersMediaBucket];
                porThumbnail.contentType = @"image/jpeg";
                porThumbnail.data = thumbnailData;
                
                
                @try {
                    NSLog(@"before calling data s3 putObject");
                    _putObjectResponse = [_s3 putObject:por];
                    NSLog(@"done uploading data to s3 result %@",_putObjectResponse);
                    if (_putObjectResponse.error != nil)
                    {
                        NSLog(@"Error: %@", _putObjectResponse.error);
                        _uploadError = _putObjectResponse.error;
                        continue;
                    }
                    if (thumbnailData != nil)
                    {
                        _putObjectResponse = [_s3 putObject:porThumbnail];
#if DEBUG==1
                        NSLog(@"done uploading thumbnail to s3 result %@",_putObjectResponse);
#endif
                    }
                    if (_putObjectResponse.error != nil)
                    {
#if DEBUG==1
                        NSLog(@"Error: %@", _putObjectResponse.error);
#endif
                        _uploadError = _putObjectResponse.error;
                        continue;
                    }
                    _successfulUpload = YES;
                    return;
                }@catch (AmazonServiceException *exception) {
#if DEBUG==1
                    NSLog(@"New-Post: Error: %@", exception);
                    NSLog(@"New-Post: Debug Description: %@",exception.debugDescription);
#endif
                    _amazonException = exception;
                }
            } else {
                NSString* errorString = @"Failed to obtain S3 credentails from backend";
#if DEBUG==1
                NSLog(@"New-Post: Error: %@", errorString);
#endif
                _amazonException = [AmazonServiceException exceptionWithMessage:errorString];
            }
        }
    }
}

@end
