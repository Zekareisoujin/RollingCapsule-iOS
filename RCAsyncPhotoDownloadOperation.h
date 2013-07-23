//
//  RCAsyncPhotoDownloadOperation.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import <AWSRuntime/AWSRuntime.h>

#define RCASYNCPHOTODOWNLOADOPERATION_NUMRETRY 3

@protocol RCAsyncPhotoDownloadOperationDelegate

- (void)downloadFinish:(NSObject*) object;

@end

@interface RCAsyncPhotoDownloadOperation : NSOperation <AmazonServiceRequestDelegate>

@property (nonatomic, strong) id<RCAsyncPhotoDownloadOperationDelegate> delegate;
@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) int ownerID;
@property (nonatomic, strong) AmazonS3Client *s3;

- (id)initWithPhotokey:(NSString *)key withOwnerID:(int)ownerID;
@end
