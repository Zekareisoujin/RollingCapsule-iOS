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
#import "RCUtilities.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation RCMediaUploadOperation {
    int nRetry;
    NSData*thumbnailData;
    S3PutObjectResponse *_putObjectResponse;
    BOOL finishedProcessingLibrary;
}

@synthesize key = _key;
@synthesize uploadData = _uploadData;
@synthesize thumbnailImage = _thumbnailImage;
@synthesize isCancel = _isCancel;
@synthesize mediaType = _mediaType;
@synthesize s3 = _s3;
@synthesize uploadException = _uploadException;
@synthesize uploadError = _uploadError;
@synthesize successfulUpload = _successfulUpload;
@synthesize fileURL = _fileURL;

- (id) initWithKey:(NSString*)key withMediaType:(NSString*)mediaType withURL:(NSURL*) fileURL{
    self = [super init];
    if (self) {
        _key = key;
        //_uploadData = uploadData;
        //_thumbnailImage = thumbnailImage;
        _mediaType = mediaType;
        _fileURL = fileURL;
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
        if (_uploadData == nil) {
            if (_fileURL == nil) return;
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:_fileURL resultBlock:^(ALAsset *asset){
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                Byte *buffer = (Byte*)malloc(rep.size);
                NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
                _uploadData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                if (self.thumbnailImage == nil && ![_mediaType hasSuffix:@"mov"]) {
                    // Retrieve the image orientation from the ALAsset
                    UIImageOrientation orientation = UIImageOrientationUp;
                    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                    if (orientationValue != nil) {
                        orientation = [orientationValue intValue];
                    }
                    UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage] scale:1.0 orientation:orientation];
                    image = generateSquareImageThumbnail(image);
                    self.thumbnailImage = imageWithImage(image, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
                }
                dispatch_semaphore_signal(sema);
            } failureBlock:^(NSError *err){
                [self cancel];
                dispatch_semaphore_signal(sema);
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            //wait till we finished getting asset from file url
            /*while (!self.isCancelled && !finishedProcessingLibrary) {
                ;//sleep(100);
            };*/
            if (self.isCancelled) return;
        }
        if (self.thumbnailImage == nil) {
            
            if ([_mediaType hasSuffix:@"mov"]) {
                UIImage *image;
                image = generateVideoThumbnail(_fileURL);
                image = generateSquareImageThumbnail(image);
                self.thumbnailImage = imageWithImage(image, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
            } else return;
        }
        thumbnailData = UIImageJPEGRepresentation(_thumbnailImage, 1.0);
        while (nRetry-- && ![self isCancelled]) {
            _uploadException = nil;
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
                    NSLog(@"New-Post: AmazonServiceException: %@", exception);
                    NSLog(@"New-Post: Debug Description: %@",exception.debugDescription);
                    _uploadException = exception;
                } @catch (AmazonClientException *clientException) {
                    
                    NSLog(@"New-Post: AmazonClientException: %@", clientException);
                    NSLog(@"New-Post: Debug Description: %@",clientException.debugDescription);
                    _uploadException = clientException;
                } @catch (NSException *unknownException) {
                    
                    NSLog(@"New-Post: unknown exception: %@", unknownException);
                    NSLog(@"New-Post: Debug Description: %@",unknownException.debugDescription);
                    _uploadException = unknownException;
                }
            } else {
                NSString* errorString = @"Failed to obtain S3 credentails from backend";
#if DEBUG==1
                NSLog(@"New-Post: Error: %@", errorString);
#endif
                _uploadException = [AmazonServiceException exceptionWithMessage:errorString];
            }
        }
    }
}
- (void) generateThumbnailImage : (void(^)(UIImage*)) imageProcessBlock {
    if ([_mediaType hasSuffix:@"mov"]) {
        UIImage *image;
        image = generateVideoThumbnail(_fileURL);
        image = generateSquareImageThumbnail(image);
        self.thumbnailImage = imageWithImage(image, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
        imageProcessBlock(self.thumbnailImage);
    } else {
        ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
        [assetLibrary assetForURL:_fileURL resultBlock:^(ALAsset *asset){
                // Retrieve the image orientation from the ALAsset
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage] scale:1.0 orientation:orientation];
            image = generateSquareImageThumbnail(image);
            self.thumbnailImage = imageWithImage(image, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
            imageProcessBlock(self.thumbnailImage);
        } failureBlock:^(NSError *err){
            imageProcessBlock(nil);
        }];
    }
}

@end
