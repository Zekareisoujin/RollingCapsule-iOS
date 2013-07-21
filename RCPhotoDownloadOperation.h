//
//  RCPhotoDownloadOperation.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import <AWSS3/S3Request.h>
#import <AWSRuntime/AWSRuntime.h>

@protocol RCPhotoDownloadOperationDelegate

- (void)downloadFinish:(NSObject*) object;

@end

@interface RCPhotoDownloadOperation  : NSOperation <AmazonServiceRequestDelegate>

@property (nonatomic, strong) id<RCPhotoDownloadOperationDelegate> delegate;
@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) int ownerID;
@property (nonatomic, strong) AmazonS3Client *s3;

- (id)initWithPhotokey:(NSString *)key withOwnerID:(int)ownerID;
@end
