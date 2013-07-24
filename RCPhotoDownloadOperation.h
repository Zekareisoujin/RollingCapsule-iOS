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

typedef void (^ImageDownloadBlock)(UIImage*);

@interface RCPhotoDownloadOperation  : NSOperation <AmazonServiceRequestDelegate>

@property (nonatomic, strong) NSString* key;
@property (nonatomic, strong) AmazonS3Client *s3;
@property (nonatomic, copy)   ImageDownloadBlock completionHandler;

- (id)initWithPhotokey:(NSString *)key;
@end
