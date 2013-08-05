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
static NSMutableDictionary* RCUserUserCollection = nil;

+ (void) initUserDataModel {
    RCUserUserCollection = [[NSMutableDictionary alloc] init];
}

+ (RCUser*) currentUser {
    return RCUserCurrentUser;
}

+ (void) setCurrentUser: (RCUser*)user {
    RCUserCurrentUser = user;
}

+ (id) getUserWithNSDictionary: (NSDictionary*)userData {
    int newID = [[userData objectForKey:@"id"] intValue];
    RCUser* cachedUser = [RCUserUserCollection objectForKey:[NSNumber numberWithInt:newID]];
    if (cachedUser != nil) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate* newUpdatedTime = [formatter dateFromString:(NSString*)[userData objectForKey:@"updated_at"]];
        
        if ([newUpdatedTime compare:cachedUser.updatedTime] != NSOrderedDescending)
            return cachedUser;
    }
    
    RCUser *newUser = [[RCUser alloc] initWithNSDictionary:userData];
    return newUser;
}

+ (id) getUserOwnerOfPost: (RCPost*)postData {
    int newID = postData.userID;
    RCUser* cachedUser = [RCUserUserCollection objectForKey:[NSNumber numberWithInt:newID]];
    if (cachedUser != nil)
        return cachedUser;
    else {
        RCUser* newUser = [[RCUser alloc] init];
        newUser.userID = newID;
        newUser.email = postData.authorEmail;
        newUser.name = postData.authorName;
        newUser.updatedTime = [NSDate date];
        [RCUserUserCollection setObject:newUser forKey:[NSNumber numberWithInt:newID]];
        
        return newUser;
    }
}

+ (void) getUserWithIDAsync: (int)userID completionHandler:(void (^)(RCUser*))completionHandle {
    RCUser* cachedUser = [RCUserUserCollection objectForKey:[NSNumber numberWithInt:userID]];
    
    if (cachedUser == nil) {
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%d/details", RCServiceURL, RCUsersResource, userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
             
             if (jsonData != NULL) {
                  RCUser *newUser = [RCUser getUserWithNSDictionary:jsonData];
                 completionHandle(newUser);
             }else {
                 postNotification(@"Failed to retrieve user info");
             }
             
         }];
    }else
        completionHandle(cachedUser);
}

- (id) initWithNSDictionary:(NSDictionary *)userData {
    self = [super init];
    if (self) {
        _name = (NSString *)[userData objectForKey:@"name"];
        _email = (NSString *)[userData objectForKey:@"email"];
        _userID = [[userData objectForKey:@"id"] intValue];
        _displayAvatar = nil;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        _updatedTime = [formatter dateFromString:(NSString*)[userData objectForKey:@"updated_at"]];
    }
    [RCUserUserCollection setObject:self forKey:[NSNumber numberWithInt:_userID]];
    
    return self;
}

- (NSDictionary*) getDictionaryObject {
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    [retval setObject:_name forKey:@"name"];
    [retval setObject:_email forKey:@"email"];
    [retval setValue:[NSNumber numberWithInt:_userID] forKey:@"id"];
    return retval;
}

- (void) setUserAvatar: (UIImage*)avatar completionHandler:(void (^)(UIImage*))completionHandle {
    //dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    //dispatch_async(queue, ^{
        [RCConnectionManager startConnection];
        // Convert the image to JPEG data.
        NSData *imageData = UIImageJPEGRepresentation(avatar, 1.0);
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:_email
                                                                 inBucket:RCAmazonS3AvatarPictureBucket];
        por.contentType = @"image/jpeg";
        por.data        = imageData;
        
        // Put the image data into the specified s3 bucket and object.
        NSString *error = @"Couldn't connect to server, please try again later";
        @try {
            AmazonS3Client *s3 = [RCAmazonS3Helper s3:_userID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
            [RCConnectionManager endConnection];
            
            if (s3 != nil) {
                S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
                error = putObjectResponse.error.description;
                if(putObjectResponse.error != nil) {
                    NSLog(@"Error: %@", putObjectResponse.error);
                }
                
                if(error != nil) {
                    NSLog(@"Error: %@", error);
                    postNotification(error);
                    completionHandle(nil);
                }else {
                    //[[RCResourceCache centralCache] putResourceInCache:[[NSString alloc] initWithFormat:@"%@/%d/avatar", RCUsersResource, _userID] forKey:avatar];
                    [[RCResourceCache centralCache] putResourceInCache:avatar forKey:[[NSString alloc] initWithFormat:@"%@/%d/avatar", RCUsersResource, _userID]];
                    _displayAvatar = avatar;
                    completionHandle(avatar);
                }
            }

            
        }@catch (NSException *e) {
            [RCConnectionManager endConnection];
            NSLog(@"Exception: %@", e);
            postNotification(error);
            completionHandle(nil);
        }
    
    //});
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

- (void) getUserAvatarAsync: (int)viewingUserID completionHandler:(void (^)(UIImage*)) completionHandle {
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
        completionHandle(_displayAvatar);
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
    } else postNotification(@"Could not connect to server to upload user info, please try again");
}

+ (void) followUserAsCurrentUserAsync:(RCUser*) otherUser completionHandler:(void (^)(int, NSString*))completionHandle {
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@?mobile=1", RCServiceURL, RCFollowsResource]];
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
                     if ((NSNull*) followObj == [NSNull null])
                         completionHandle(0, @"Server error, please try again later");
                     else {
                         int followID = [[followObj objectForKey:@"id"] intValue];
                         completionHandle(followID, nil);
                     }

                 } else
                     completionHandle(0, @"Server error, please try again later");
                 
             } else
                 completionHandle(0, RCAlertMessageConnectionFailed);
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(0, RCAlertMessageConnectionFailed);
    }
}

- (void) getUserFollowRelationAsync:(RCUser*) otherUser completionHandler:(void (^)(BOOL, int, NSString*))completionHandle {
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

                 if (followJson != NULL) {
                     NSDictionary *followObj = [followJson objectForKey:@"follow"];
                     if ((NSNull*) followObj == [NSNull null]) {
                         completionHandle(NO, 0, nil);
                     }else {
                         NSNumber *num = [followObj objectForKey:@"id"];
                         completionHandle(YES, [num intValue], nil);
                     }

                 }else
                     completionHandle(NO, 0, @"Server error, please try again later");
             } else {
                 NSLog(@"connection error: %@", error);
                 completionHandle(NO, 0, RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(NO, 0, RCAlertMessageConnectionFailed);
    }
}

+ (void) removeFollowRelationAsync: (int)followID completionHandler:(void (^)(NSString*))completionHandle {
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/?mobile=1", RCServiceURL, RCFollowsResource, followID]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);
        
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSDictionary *followJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
             NSLog(@"%@",followJson);
             
             if (followJson != NULL) {
                 NSDictionary *followObj = [followJson objectForKey:@"follow"];
                 if ((NSNull*) followObj == [NSNull null]) {
                     completionHandle(nil);
                 }else
                     completionHandle(@"Server error, please try again later");
             }else {
                 NSLog(@"connection error: %@", error);
                 completionHandle(RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(RCAlertMessageConnectionFailed);
    }
}

+ (void) addFriendAsCurrentUserAsync:(RCUser*) otherUser completionHandler:(void (^)(int, NSString*))completionHandle {
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

                 if (friendJson != NULL) {
                     NSString *statusObj = [friendJson objectForKey:@"status"];
                     if ((NSNull*) statusObj == [NSNull null]) {
                         completionHandle(0, @"Server error, please try again later");
                     }else {
                         int friendshipID = [[friendJson objectForKey:@"id"] intValue];
                         completionHandle(friendshipID, nil);
                     }
                 } else
                     completionHandle(0, @"Server error, please try again later");
             } else {
                 NSLog(@"connection error: %@", error);
                 completionHandle(0, RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(0, RCAlertMessageConnectionFailed);
    }
}

- (void) getUserFriendRelationAsync:(RCUser*) otherUser completionHandler:(void (^)(BOOL, int, NSString*, NSString*))completionHandle {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/relation?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, _userID, otherUser.userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
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
                 
                 if (friendJson != NULL) {
                     NSString *statusObj = [friendJson objectForKey:@"status"];
                     if ((NSNull*) statusObj == [NSNull null]) {
                         completionHandle(NO, 0, nil, nil);
                     }else {
                         NSNumber *num = [friendJson objectForKey:@"id"];
                         completionHandle(YES, [num intValue], statusObj, nil);
                     }
                 } else
                     completionHandle(NO, 0, nil, @"Server error, please try again later");
             } else {
                 NSLog(@"connection error: %@", error);
                 completionHandle(NO, 0, nil, RCAlertMessageConnectionFailed);
             }

         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(NO, 0, nil, RCAlertMessageConnectionFailed);
    }
}

+ (void) acceptFriendRelationAsync: (int)friendshipID completionhandler:(void (^)(NSString*))completionHandle {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d", RCServiceURL, RCFriendshipsResource, friendshipID]];
        NSMutableString* dataSt = initEmptyQueryString();
        NSData *putData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSURLRequest *request = CreateHttpPutRequest(url, putData);
        
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
                 
                 if (friendJson != NULL) {
                     completionHandle(nil);
                 } else
                     completionHandle(@"Server error, please try again later");
             } else {
                 NSLog(@"connection error: %@", error);
                 completionHandle(RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(RCErrorMessageFailedToEditFriendStatus);
    }
    
}

+ (void) removeFriendRelationAsync: (int)friendshipID completionhandler:(void (^)(NSString*))completionHandle {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/?mobile=1", RCServiceURL, RCFriendshipsResource, friendshipID]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);
        
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
                 
                 if (friendJson != NULL) {
                     NSDictionary *statusObj = [friendJson objectForKey:@"status"];
                     if ((NSNull*) statusObj == [NSNull null]) {
                         completionHandle(nil);
                     }else {
                         completionHandle(@"Server error, please try again later");
                     }
                 } else
                     completionHandle(@"Server error, please try again later");
             } else {
                 NSLog(@"connection error: %@", error);
                 completionHandle(RCAlertMessageConnectionFailed);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        completionHandle(RCErrorMessageFailedToEditFriendStatus);
    }

}


@end
