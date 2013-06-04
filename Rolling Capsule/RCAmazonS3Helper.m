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
#import "Util.h"
#import "SBJson.h"

@interface RCAmazonS3Helper ()

@end

@implementation RCAmazonS3Helper
+ (AmazonS3Client *) s3:(int) userID  forResource:(NSString *)resource {
    AmazonS3Client* s3Client = nil;
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/amazon_s3_temporary_credentials?mobile=1&resource=%@", RCServiceURL, RCUsersResource, userID, resource]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *credsJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
        NSString* accessKey = [credsJson objectForKey:@"access_key_id"];
        NSString* secretKey = [credsJson objectForKey:@"secret_access_key"];
        NSString* sessionToken = [credsJson objectForKey:@"session_token"];
        AmazonCredentials *creds = [[AmazonCredentials alloc] initWithAccessKey:accessKey withSecretKey:secretKey withSecurityToken:sessionToken];
        s3Client = [[AmazonS3Client alloc] initWithCredentials:creds];
        s3Client.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
    return s3Client;
}

+ (void) createAvatarImagesBucket:(int) userID {
    S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:RCAmazonS3AvatarPictureBucket andRegion:[S3Region USWest2]];
    [AmazonErrorHandler shouldNotThrowExceptions];
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:userID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
    S3CreateBucketResponse *createBucketResponse = [s3 createBucket:createBucketRequest];
    if(createBucketResponse.error != nil)
    {
        NSLog(@"Error: %@", createBucketResponse.error);
    }
}

+ (void) createUserMediaBucket:(int)userID {
    S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:RCAmazonS3UsersMediaBucket andRegion:[S3Region USWest2]];
    [AmazonErrorHandler shouldNotThrowExceptions];
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:userID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3UsersMediaBucket]];

    S3CreateBucketResponse *createBucketResponse = [s3 createBucket:createBucketRequest];
    if(createBucketResponse.error != nil)
    {
        NSLog(@"Error: %@", createBucketResponse.error);
    }
}

+ (UIImage *) getAvatarImage:(RCUser *)user withLoggedinUserID:(int)loggedinUserID {
    S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
    override.contentType = @"image/jpeg";
    S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
    gpsur.key     = user.email;
    gpsur.bucket  = RCAmazonS3AvatarPictureBucket;
    gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];  // Added an hour's worth of seconds to the current time.
    gpsur.responseHeaderOverrides = override;
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:loggedinUserID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
    NSURL *imageUrl = [s3 getPreSignedURL:gpsur];
    NSLog(@"%@",imageUrl);
    UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
    return image;
}
@end
