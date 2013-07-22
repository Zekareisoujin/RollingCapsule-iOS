//
//  RCUser.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUser.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "RCResourceCache.h"
#import "RCAmazonS3Helper.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "RCConnectionManager.h"
#import "SBJson.h"

@interface RCUser ()

@end

@implementation RCUser

@synthesize name = _name;
@synthesize email = _email;
@synthesize userID = _userID;
@synthesize displayAvatar = _displayAvatar;

static RCUser* RCUserCurrentUser =  nil;

+ (RCUser*) currentUser {
    return RCUserCurrentUser;
}

+ (void) setCurrentUser: (RCUser*)user {
    RCUserCurrentUser = user;
}

- (id) initWithNSDictionary:(NSDictionary *)userData {
    self = [super init];
    if (self) {
        _name = (NSString *)[userData objectForKey:@"name"];
        _email = (NSString *)[userData objectForKey:@"email"];
        _userID = [[userData objectForKey:@"id"] intValue];
        
    }
    return self;
}

- (NSDictionary*) getDictionaryObject {
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    [retval setObject:_name forKey:@"name"];
    [retval setObject:_email forKey:@"email"];
    [retval setValue:[NSNumber numberWithInt:_userID] forKey:@"id"];
    return retval;
}

- (void) setUserAvatarAsync: (UIImage*)avatar completionHandler:(void (^)(BOOL, UIImage*))completionFunc {
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        [RCConnectionManager startConnection];
        // Convert the image to JPEG data.
        NSData *imageData = UIImageJPEGRepresentation(avatar, 1.0);
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:_email
                                                                 inBucket:RCAmazonS3AvatarPictureBucket];
        por.contentType = @"image/jpeg";
        por.data        = imageData;
        
        // Put the image data into the specified s3 bucket and object.
        AmazonS3Client *s3 = [RCAmazonS3Helper s3:_userID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
        NSString *error = @"Couldn't connect to server, please try again later";
        [RCConnectionManager endConnection];
        if (s3 != nil) {
            S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
            error = putObjectResponse.error.description;
            if(putObjectResponse.error != nil) {
                NSLog(@"Error: %@", putObjectResponse.error);
            }
            
            if(error != nil) {
                NSLog(@"Error: %@", error);
                alertStatus(error,RCAlertMessageUploadError,self);
                completionFunc(NO, nil);
            }else {
                RCResourceCache *cache = [RCResourceCache centralCache];
                NSString *key = [[NSString alloc] initWithFormat:@"%@/%d/avatar", RCUsersResource, _userID];
                [cache invalidateKey:key];
                [cache putResourceInCache:key forKey:avatar];
                completionFunc(YES, avatar);
            }
        }
        
        
    });
}

- (UIImage*) getUserAvatar: (int)viewingUserID {
    if (_displayAvatar == nil) {
        RCResourceCache *cache = [RCResourceCache centralCache];
        NSString *key = [[NSString alloc] initWithFormat:@"%@/%d/avatar", RCUsersResource, _userID];
        
        UIImage *cachedImg = [cache getResourceForKey:key usingQuery:^{
            UIImage *image = [RCAmazonS3Helper getAvatarImage:self withLoggedinUserID:viewingUserID];
            return image;
        }];
        
        if (cachedImg == nil)
            _displayAvatar = [UIImage imageNamed:@"default_avatar.png"];
        else
            _displayAvatar = cachedImg;
    }
    return _displayAvatar;
}

- (void) getUserAvatarAsync: (int)viewingUserID completionHandler:(void (^)(UIImage*)) completionFunc {
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        if (_displayAvatar == nil) {
            RCResourceCache *cache = [RCResourceCache centralCache];
            NSString *key = [[NSString alloc] initWithFormat:@"%@/%d/avatar", RCUsersResource, _userID];
            
            UIImage *cachedImg = [cache getResourceForKey:key usingQuery:^{
                UIImage *image = [RCAmazonS3Helper getAvatarImage:self withLoggedinUserID:viewingUserID];
                return image;
            }];
            
            if (cachedImg == nil)
                _displayAvatar = [UIImage imageNamed:@"default_avatar.png"];
            else
                _displayAvatar = cachedImg;
        }
        completionFunc(_displayAvatar);
    });
}

- (void) updateNewName : (NSString*) newName {
    if ([newName isEqualToString:_name])
        return;
    _name = newName;
    NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCUsersResource, _userID]];
    NSMutableString* dataSt = initEmptyQueryString();
    addArgumentToQueryString(dataSt, @"user[name]", newName);
    addArgumentToQueryString(dataSt, @"user[email]", _email);
    NSData *putData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSURLRequest *request = CreateHttpPutRequest(url, putData);
    NSURLResponse *response;
    NSError *error = nil;
    [RCConnectionManager startConnection];
    NSData *userData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [RCConnectionManager endConnection];
    if (error == nil) {
        NSString *responseData = [[NSString alloc]initWithData:userData encoding:NSUTF8StringEncoding];
        if (![responseData isEqualToString:@"ok"]) {
            NSLog(@"Server error updating user %@",responseData);
        }
    } else alertStatus(@"Could not connect to server to upload user info, please try again", RCAlertMessageConnectionFailed, nil);
}

+ (void) followUserAsync:(RCUser*) otherUser withSuccessfulFunction:(void (^)(int)) successFunction withFailureFunction:(void (^)(NSString*)) failureFunction {
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@?mobile=1", RCServiceURL, RCFollowResource]];
        NSMutableString* dataSt = initQueryString(@"follow[followee_id]",
                                                  [[NSString alloc] initWithFormat:@"%d",otherUser.userID]);
        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             if (error == nil) {
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 
                 SBJsonParser *jsonParser = [SBJsonParser new];
                 NSDictionary *followJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                 NSLog(@"%@",followJson);
                 
                 if (followJson != NULL) {
                     NSDictionary *followObj = [followJson objectForKey:@"follow"];
                     if ((NSNull*) followObj == [NSNull null]) {
                         if (failureFunction != nil)
                             failureFunction(@"Server error, please try again later");
                     }else {
                         int followID = [[followObj objectForKey:@"id"] intValue];
                         successFunction(followID);
                     }

                 } else {
                     if (failureFunction != nil)
                         failureFunction(@"Server error, please try again later");
                 }
                 
             } else {
                 if (failureFunction != nil)
                     failureFunction(RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        if (failureFunction != nil)
            failureFunction(RCAlertMessageConnectionFailed);
    }
}

- (void) getUserFollowRelationAsync:(RCUser*) otherUser completion:(void (^)(BOOL))processFunction withFailureFunction:(void (^)(NSString*)) failureFunction {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/relation_follow?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, _userID, otherUser.userID ]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             if (error == nil) {
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 
                 SBJsonParser *jsonParser = [SBJsonParser new];
                 NSDictionary *followJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                 NSLog(@"%@",followJson);
                 BOOL isFollowing;
                 if (followJson != NULL) {
                     NSDictionary *followObj = [followJson objectForKey:@"follow"];
                     if ((NSNull*) followObj == [NSNull null]) {
                         isFollowing = NO;
                     }else {
                         isFollowing = YES;
                     }
                     processFunction(isFollowing);
                 }else {
                     if (failureFunction != nil)
                         failureFunction(@"Server error, please try again later");
                 }
             } else {
                 NSLog(@"connection error: %@", error);
                 if (failureFunction != nil)
                     failureFunction(RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        if (failureFunction != nil)
            failureFunction(RCAlertMessageConnectionFailed);
    }
}

- (void) getUserFriendRelationAsync:(RCUser*) otherUser completion:(void (^)(BOOL))processFunction withFailureFunction:(void (^)(NSString*)) failureFunction {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/relation?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, _userID, otherUser.userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             if (error == nil) {
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 
                 SBJsonParser *jsonParser = [SBJsonParser new];
                 NSDictionary *friendJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                 NSLog(@"%@",friendJson);
                 BOOL isFriend;
                 if (friendJson != NULL) {
                     NSDictionary *statusObj = [friendJson objectForKey:@"status"];
                     if ((NSNull*) statusObj == [NSNull null]) {
                         isFriend = NO;
                     }else {
                         isFriend = YES;
                     }
                     processFunction(isFriend);
                 } else {
                     if (failureFunction != nil)
                         failureFunction(@"Server error, please try again later");
                 }
             } else {
                 NSLog(@"connection error: %@", error);
                 if (failureFunction != nil)
                     failureFunction(RCAlertMessageConnectionFailed);
             }

         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        if (failureFunction != nil)
            failureFunction(RCAlertMessageConnectionFailed);
    }
}

+ (void) addFriendAsync:(RCUser*) otherUser withSuccessfulFunction:(void (^)(int)) successFunction withFailureFunction:(void (^)(NSString*)) failureFunction {
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCFriendshipsResource]];
        NSMutableString* dataSt = initQueryString(@"friendship[friend_id]",
                                                  [[NSString alloc] initWithFormat:@"%d",otherUser.userID]);
        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             if (error == nil) {
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 
                 SBJsonParser *jsonParser = [SBJsonParser new];
                 NSDictionary *friendJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                 NSLog(@"%@",friendJson);
                 BOOL successfulAdd;
                 if (friendJson != NULL) {
                     NSDictionary *statusObj = [friendJson objectForKey:@"status"];
                     if ((NSNull*) statusObj == [NSNull null]) {
                         successfulAdd = NO;
                         failureFunction(@"Server error, please try again later");
                     }else {
                         successfulAdd = YES;
                         int friendshipID = [[friendJson objectForKey:@"id"] intValue];
                         successFunction(friendshipID);
                     }
                 } else {
                     if (failureFunction != nil)
                         failureFunction(@"Server error, please try again later");
                 }
             } else {
                 NSLog(@"connection error: %@", error);
                 if (failureFunction != nil)
                     failureFunction(RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        if (failureFunction != nil)
            failureFunction(RCAlertMessageConnectionFailed);
    }
}

+ (void) getUserWithIDAsync: (int)userID completionHandler:(void (^)(RCUser*))completionFunc {
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCUsersResource, userID];
    RCUser *retUser = [cache getResourceForKey:key];
    
    if (retUser == nil) {
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%d/details", RCServiceURL, RCUsersResource, userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
             
             RCUser *newUser;
             if (jsonData != NULL) {
                 newUser = [[RCUser alloc] initWithNSDictionary:jsonData];
                 completionFunc(newUser);
             }else {
                 alertStatus(@"Failed to retrieve user info", @"Error", nil);
             }
             [cache putResourceInCache:newUser forKey:key];
             
         }];
    } else
        completionFunc(retUser);
}
@end
