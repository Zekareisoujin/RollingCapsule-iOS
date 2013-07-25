//
//  RCMediaUploadOperation.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>

@interface RCMediaUploadOperation : NSOperation
@property (nonatomic, strong) NSData*   uploadData;
@property (nonatomic, strong) UIImage*  thumbnailImage;
@property (nonatomic, strong) NSString* key;
@property (nonatomic, strong) NSString* mediaType;
@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, strong) AmazonS3Client* s3;
@property (nonatomic, strong) NSException *uploadException;
@property (nonatomic, strong) NSError *uploadError;
@property (nonatomic, assign) BOOL successfulUpload;
@property (nonatomic, strong) NSURL* fileURL;

- (id) initWithKey:(NSString*)key withMediaType:(NSString*)mediaType withURL:(NSURL*) fileURL;
- (NSOperation*) generateOperation;
@end
