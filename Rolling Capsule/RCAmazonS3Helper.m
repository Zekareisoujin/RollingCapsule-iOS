//
//  RCAmazonS3Helper.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 2/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCAmazonS3Helper.h"
#import <AWSRuntime/AWSRuntime.h>
#import "Constants.h"

@interface RCAmazonS3Helper ()

@end

static AmazonS3Client* s3Client = nil;

@implementation RCAmazonS3Helper
+ (AmazonS3Client *) s3 {
    if (s3Client == nil) {
        s3Client = [[AmazonS3Client alloc] initWithAccessKey:RCAmazonS3AccessKey withSecretKey:RCAmazonS3SecretKey];
        s3Client.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
    }
    return s3Client;
}

+ (void) createAvatarImagesBucket {
    S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:RCAmazonS3AvatarPictureBucket andRegion:[S3Region USWest2]];
    [AmazonErrorHandler shouldNotThrowExceptions];
    S3CreateBucketResponse *createBucketResponse = [[RCAmazonS3Helper s3] createBucket:createBucketRequest];
    if(createBucketResponse.error != nil)
    {
        NSLog(@"Error: %@", createBucketResponse.error);
    }
}

+ (UIImage *) getAvatarImage:(RCUser *)user {
    S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
    override.contentType = @"image/jpeg";
    S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
    gpsur.key     = user.email;
    gpsur.bucket  = RCAmazonS3AvatarPictureBucket;
    gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];  // Added an hour's worth of seconds to the current time.
    gpsur.responseHeaderOverrides = override;
    NSURL *imageUrl = [[RCAmazonS3Helper s3] getPreSignedURL:gpsur];
    //NSURL *imageUrl = [NSURL URLWithString:_user.avatarImg];
    NSLog(@"%@",imageUrl);
    UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
    return image;
}
@end
