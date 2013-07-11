//
//  RCAmazonS3Helper.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 2/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCAmazonS3Helper.h"
#import <AWSRuntime/AWSRuntime.h>
#import "RCConstants.h"
#import "RCUtilities.h"
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
        if (accessKey == nil || secretKey == nil || sessionToken == nil)
            return s3Client;
        //NSLog(@"%@",credsJson);
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

+ (UIImage *) getAvatarImage:(RCUser*) user withLoggedinUserID:(int)loggedinUserID {
    S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
    override.contentType = @"image/jpeg";
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:loggedinUserID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
    if (s3 != nil) {
        @try {
            S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:user.email withBucket:RCAmazonS3AvatarPictureBucket];
            S3GetObjectResponse *response = [s3 getObject:getObjectRequest];
            UIImage *image = [UIImage imageWithData:response.body];
            return image;
        } @catch (AmazonServiceException * e) {
            NSLog(@"%@",e);
            return nil;
        }
    } else return nil;
}

+ (NSObject *) getUserMediaImage:(RCUser *)user withLoggedinUserID:(int)loggedinUserID withImageUrl:(NSString*)url {
    //S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
    //override.contentType = @"image/jpeg";
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:loggedinUserID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3UsersMediaBucket]];
    if (s3 != nil) {
        @try {
            S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:url withBucket:RCAmazonS3UsersMediaBucket];
            S3GetObjectResponse *response = [s3 getObject:getObjectRequest];
            if ([response.contentType isEqualToString:@"image/jpeg"]) {
                UIImage *image = [UIImage imageWithData:response.body];
                return image;
            } else {
                S3GetObjectResponse *response = [s3 getObject:getObjectRequest];
                NSData *yourMovieData = response.body;
                NSString* completeFileName = [NSString stringWithFormat:@"%@.mov",url];
                NSString* filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:completeFileName];
                
                [[NSFileManager defaultManager] createFileAtPath:filename contents:yourMovieData attributes:nil];
                return filename;
            }
        } @catch (AmazonServiceException * e) {
            NSLog(@"%@",e);
            return nil;
        }
    } else return nil;
}

@end
