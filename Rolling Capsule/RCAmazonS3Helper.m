//
//  RCAmazonS3Helper.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 2/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCAmazonS3Helper.h"
#import "RCS3CredentialsWithExpiration.h"
#import <AWSRuntime/AWSRuntime.h>
#import "RCConstants.h"
#import "RCUtilities.h"
#import "SBJson.h"

@interface RCAmazonS3Helper ()

@end

@implementation RCAmazonS3Helper

+ (void) getS3ClientAsyncForUser:(int)userID forResource:(NSString *)resource completion:(void(^)(AmazonS3Client* s3)) useS3Function {
    static NSMutableDictionary* clientPool = nil;
    if (clientPool == nil) {
        clientPool = [[NSMutableDictionary alloc] init];
    }
    
    NSString*key= [NSString stringWithFormat:@"%d %@",userID, resource];
    
    RCS3CredentialsWithExpiration *s3 = nil;
    [clientPool objectForKey:key];
    if (s3 != nil) {
        if ([s3.expiryDate compare:[NSDate date]] == NSOrderedDescending) {
            useS3Function(s3.s3);
            return;
        }
        [clientPool removeObjectForKey:key];
    }
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/amazon_s3_temporary_credentials?mobile=1&resource=%@", RCServiceURL, RCUsersResource, userID, resource]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             if (error != nil) {
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 SBJsonParser *jsonParser = [SBJsonParser new];
                 NSDictionary *credsJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                 NSString* accessKey = [credsJson objectForKey:@"access_key_id"];
                 NSString* secretKey = [credsJson objectForKey:@"secret_access_key"];
                 NSString* sessionToken = [credsJson objectForKey:@"session_token"];
                 if (accessKey == nil || secretKey == nil || sessionToken == nil) {
                     useS3Function(nil);
                 }
                 AmazonS3Client* s3Client = nil;
                 AmazonCredentials *creds = [[AmazonCredentials alloc] initWithAccessKey:accessKey withSecretKey:secretKey withSecurityToken:sessionToken];
                 s3Client = [[AmazonS3Client alloc] initWithCredentials:creds];
                 s3Client.endpoint = [AmazonEndpoints s3Endpoint:AP_SOUTHEAST_1];
                 RCS3CredentialsWithExpiration *s3WithExpiration = [[RCS3CredentialsWithExpiration alloc] initWithAmazonS3Client:(AmazonS3Client*) s3Client];
                 [clientPool setObject:s3WithExpiration forKey:key];
                 useS3Function(s3Client);
             }
         }];
    }@catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        
    }
}


+ (AmazonS3Client *) s3:(int) userID  forResource:(NSString *)resource {
    static NSMutableDictionary* clientPool = nil;
    if (clientPool == nil) {
        clientPool = [[NSMutableDictionary alloc] init];
    }

    NSString*key= [NSString stringWithFormat:@"%d %@",userID, resource];
    
    RCS3CredentialsWithExpiration *s3 = nil;
    s3 = [clientPool objectForKey:key];
    if (s3 != nil) {
        if ([s3.expiryDate compare:[NSDate date]] == NSOrderedDescending)
            return s3.s3;
        [clientPool removeObjectForKey:key];
    }

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
        s3Client.endpoint = [AmazonEndpoints s3Endpoint:AP_SOUTHEAST_1];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(NSLocalizedString(@"Failure connecting to web service",nil));
    }
    s3 = [[RCS3CredentialsWithExpiration alloc] initWithAmazonS3Client:(AmazonS3Client*) s3Client];
    [clientPool setObject:s3 forKey:key];
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
    int nRetry = 3;
    while (nRetry--) {
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
            }
        }
    }
    return nil;
}

/*!
 * Download user's media from Amazon S3, the returned object depend on what kind of media is present 
 * S3 bucket. If it is an image, an image is returned else download the video file to disk and return
 * the path to the video file.
 */

+ (NSObject *) getUserMediaImage:(RCUser *)user withLoggedinUserID:(int)loggedinUserID withImageUrl:(NSString*)url {
    int nRetry = 3;
    while (nRetry--) {
        AmazonS3Client *s3 = [RCAmazonS3Helper s3:loggedinUserID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3UsersMediaBucket]];
        if (s3 != nil) {
            @try {
                if (![url hasSuffix:@".mov"]) {
                    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:url withBucket:RCAmazonS3UsersMediaBucket];
                    S3GetObjectResponse *response = [s3 getObject:getObjectRequest];
                    UIImage *image = [UIImage imageWithData:response.body];
                    if (image != nil)
                        return image;
                } else {
                    NSLog(@"begin generate url");
                    S3ResponseHeaderOverrides *override = [[S3ResponseHeaderOverrides alloc] init];
                    override.contentType = @"movie/mov";
                    S3GetPreSignedURLRequest *gpsur = [[S3GetPreSignedURLRequest alloc] init];
                    gpsur.key     = url;
                    gpsur.bucket  = RCAmazonS3UsersMediaBucket;
                    gpsur.expires = [NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval) 3600];  // Added an hour's worth of seconds to the current time.
                    gpsur.responseHeaderOverrides = override;
                    NSURL *url = [s3 getPreSignedURL:gpsur];
                    NSLog(@"end generate url");
                    return url;
                }
            } @catch (AmazonServiceException * e) {
                NSLog(@"%@",e);
            }
        }
    }
    return nil;
}

@end
