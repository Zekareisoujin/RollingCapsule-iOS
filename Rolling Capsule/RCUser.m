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

@interface RCUser ()

@end

@implementation RCUser

@synthesize name = _name;
@synthesize email = _email;
@synthesize userID = _userID;

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
@end
