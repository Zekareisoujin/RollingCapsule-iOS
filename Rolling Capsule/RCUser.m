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
#import "SBJson.h"

@interface RCUser ()

@end

@implementation RCUser

@synthesize name = _name;
@synthesize email = _email;
@synthesize userID = _userID;
@synthesize displayAvatar = _displayAvatar;

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

- (UIImage*) getUserAvatar: (int)viewingUserID {
    if (_displayAvatar == nil) {
        RCResourceCache *cache = [RCResourceCache centralCache];
        NSString *key = [[NSString alloc] initWithFormat:@"%@/%d-avatar", RCUsersResource, _userID];
        
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
    NSData *userData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error == nil) {
        NSString *responseData = [[NSString alloc]initWithData:userData encoding:NSUTF8StringEncoding];
        if (![responseData isEqualToString:@"ok"]) {
            NSLog(@"Server error updating user %@",responseData);
        }
    } else alertStatus(@"Could not connect to server to upload user info, please try again", RCAlertMessageConnectionFailed, nil);
}

+ (void) getUserWithIDAsync: (int)userID completionHandler:(void (^)(RCUser*))completionFunc {
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCUsersResource, userID];
    
    RCUser* retUser = [cache getResourceForKey:key usingQuery:^{
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%d/details", RCServiceURL, RCUsersResource, userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        NSURLResponse* response;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&error];
        NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        SBJsonParser *jsonParser = [SBJsonParser new];
        NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
        
        RCUser *newUser;
        if (jsonData != NULL) {
            newUser = [[RCUser alloc] initWithNSDictionary:jsonData];
        }else {
            alertStatus(@"Failed to retrieve user info", @"Error", nil);
        }
        return newUser;
    }];
    
    completionFunc(retUser);
}

@end
