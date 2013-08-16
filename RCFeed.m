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
#import "RCNotification.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "RCMainMenuViewController.h"

@implementation RCFeed {
    int page;
    NSTimer *timer;
    NSMutableSet *postSet;
}

static RCFeed* RCFeedLocationFeed = nil;
static RCFeed* RCFeedFriendFeed = nil;
static RCFeed* RCFeedFollowFeed = nil;

+ (void) updateLocation {
    if (RCFeedLocationFeed == nil)
        RCFeedLocationFeed = [[RCFeed alloc] init];
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;
    
    RCFeedLocationFeed.feedPath = [[NSString alloc] initWithFormat:@"?mobile=1&latitude=%f&longitude=%f&%@", zoomLocation.latitude, zoomLocation.longitude, RCLevelsQueryString];
}

+ (RCFeed*) locationFeed {
    if (RCFeedLocationFeed == nil) {
        RCFeedLocationFeed = [[RCFeed alloc] init];
    }
    return RCFeedLocationFeed;
}

+ (RCFeed*) friendFeed {
    if (RCFeedFriendFeed == nil) {
        RCFeedFriendFeed = [[RCFeed alloc] init];
        RCFeedFriendFeed.feedPath = @"?mobile=1";
    }
    return RCFeedFriendFeed;

}

+ (RCFeed*) followFeed {
    if (RCFeedFollowFeed == nil) {
        RCFeedFollowFeed = [[RCFeed alloc] init];
        RCFeedFollowFeed.feedPath = @"?mobile=1&view_follow=1";
    }
    return RCFeedFollowFeed;

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
        postSet = [[NSMutableSet alloc] init];
        _numberOfHiddenCapsules = 0;
        page = 1;
    }
    return self;
}

- (void) processNotificationListJson:(NSArray*) notificationListJson {
    NSLog(@"RCFeed processing notifications obtained from backend");
    [RCNotification clearNotifications];
    for (NSDictionary *notificationJson in notificationListJson) {
        [RCNotification parseNotification:notificationJson];
    }
    if ([RCNotification numberOfNewFriendRequests] > 0) {
        NSNotification *notification = [NSNotification notificationWithName:RCNotificationNameNewFriendRequest object:self];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (void) appendData:(NSData*) data willAddToFront:(BOOL) toFront {
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
        NSArray *notificationsData = (NSArray*)[jsonData objectForKey:@"notification_list"];
        [self processNotificationListJson:notificationsData];
        //_user = [[RCUser alloc] initWithNSDictionary:userDictionary];
        RCUser *user = [RCUser getUserWithNSDictionary:userDictionary];
        [RCUser setCurrentUser:user];
        NSMutableArray *array = toFront ? [[NSMutableArray alloc] init] : _postList;
        for (NSDictionary *postData in postJsonList) {
            //RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
            RCPost *post = [RCPost getPostWithNSDictionary:postData];
            
            //if append to end then add no matter what
            //if append to front then add only when it's new
            BOOL addPost = (!toFront) || ([postSet containsObject:[NSNumber numberWithInt:post.postID]]);
            if (addPost) {
                [array addObject:post];
                [postSet addObject:[NSNumber numberWithInt:post.postID]];
            }
        }
        if (toFront) {
            [array addObjectsFromArray:_postList];
            _postList = array;
        }
        return;
    } else {
        NSLog(@"feed-data: error parsing json data received%@",responseData);
        _errorMessage = responseData;
        _errorType = RCFeedBadServerResult;
    }
}

- (void) fetchFeedFromBackend:(RCFeedFetchMode) fetchMode completion:(void(^)(void)) completeFunc {
    NSURL* url;
    int loadPage;
    BOOL willAddToFront = NO;
    //if page 0 refresh everything
    switch (fetchMode) {
        case RCFeedFetchModeReset:
            page = loadPage = 1;
            break;
        case RCFeedFetchModeAppendBack:
            page++;
            loadPage = page;
            break;
        case RCFeedFetchModeAppendFront:
            loadPage = 1;
            willAddToFront = YES;
            break;
        default:break;
    }
    _errorType = RCFeedNoError;
    @try {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@&page=%d",RCServiceURL, _feedPath,loadPage]];
        NSMutableURLRequest* request = CreateHttpGetRequest(url);
        NSLog(@"before sending http request");
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSLog(@"obtained feed data");
             if (fetchMode == RCFeedFetchModeReset){
                 [_postList removeAllObjects];
                 [postSet removeAllObjects];
             }
             if (error == nil)
                 [self appendData:data willAddToFront:willAddToFront];
             else {
                 NSLog(@"feed-data: error sending web request:%@",error);
                 _errorType = RCFeedCantReachServer;
             }
             completeFunc();
         }];
    } @catch (NSException *exception) {
        NSLog(@"feed-data: exception:%@",exception);
        _errorType = RCFeedClientException;
        completeFunc();
    }
    
}

@end
