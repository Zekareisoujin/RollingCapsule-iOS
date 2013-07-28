//
//  RCFeed.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 29/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFeed.h"
#import "SBJson.h"
#import "RCPost.h"
#import "RCConstants.h"
#import "RCUtilities.h"

@implementation RCFeed {
    int page;
}

@synthesize postList = _postList;
@synthesize numberOfHiddenCapsules = _numberOfHiddenCapsules;
@synthesize feedPath = _feedPath;
@synthesize errorMessage = _errorMessage;
@synthesize errorType = _errorType;

- (id) init {
    self = [super init];
    if (self) {
        _postList = [[NSMutableArray alloc] init];
        _numberOfHiddenCapsules = 0;
        page = 1;
    }
    return self;
}

- (void) appendData:(NSData*) data {
    NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    if ([responseData isEqualToString:@"Unauthorized"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate.menuViewController btnActionLogOut:nil];
        });
        return;
    }
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
#if DEBUG==1
    NSLog(@"feed-data: %@", responseData);
#endif
    
    if (jsonData != NULL) {
        
        NSArray *postJsonList = (NSArray *) [jsonData objectForKey:@"post_list"];
        _numberOfHiddenCapsules = [[jsonData objectForKey:@"unreleased_capsules_count"] intValue];
        NSDictionary *userDictionary = (NSDictionary *) [jsonData objectForKey:@"user"];
        //_user = [[RCUser alloc] initWithNSDictionary:userDictionary];
        RCUser *user = [RCUser getUserWithNSDictionary:userDictionary];
        [RCUser setCurrentUser:user];
        for (NSDictionary *postData in postJsonList) {
            //RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
            RCPost *post = [RCPost getPostWithNSDictionary:postData];
            [_postList addObject:post];
        }

        return;
    } else {
        NSLog(@"feed-data: error parsing json data received%@",responseData);
        _errorMessage = responseData;
        _errorType = RCFeedBadServerResult;
    }
}

- (void) fetchFeedFromBackend:(BOOL) fromBeginning {
    NSURL* url;
    //if page 0 refresh everything
    if (fromBeginning) {
        page = 1;
        [_postList removeAllObjects];
        
    }
    else
        page++;
    _errorType = RCFeedNoError;
    @try {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@&page=%d",RCServiceURL, _feedPath,page]];
        NSMutableURLRequest* request = CreateHttpGetRequest(url);
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             if (error == nil)
                 [self appendData:data];
             else {
                 NSLog(@"feed-data: error sending web request:%@",error);
                 _errorType = RCFeedCantReachServer;
             }
         }];
    } @catch (NSException *exception) {
        NSLog(@"feed-data: exception:%@",exception);
        _errorType = RCFeedClientException;
    }
}

@end
