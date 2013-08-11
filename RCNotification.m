//
//  RCNotification.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCNotification.h"
#import "RCPost.h"
#import "RCUtilities.h"
#import "RCConstants.h"
#import "SBJson.h"
#import "TFHpple.h"

@implementation RCNotification

@synthesize content = _content;
@synthesize createdTime = _createdTime;
@synthesize updatedTime = _updatedTime;
@synthesize receiverID = _receiverID;
@synthesize notificationID = _notificationID;
@synthesize urls = _urls;
@synthesize viewed = _viewed;

static int RCNotficationNumberOfNewNotifications = 0;
static NSMutableArray* RCNotificationNotificationList = nil;
static NSMutableDictionary* RCNotificationObjectsWithNotification = nil;
static NSMutableArray* RCNotificationPostsWithNotification = nil;

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _content = (NSString*)[postData objectForKey:@"content"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        _createdTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"created_at"]];
        _updatedTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"updated_at"]];
        
        _receiverID = [[postData objectForKey:@"receiver_id"] intValue];
        _notificationID = [[postData objectForKey:@"id"] intValue];
        _viewed = [[postData objectForKey:@"viewed"] boolValue];
        _urls = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) updateViewedProperty {
    if (!self.viewed) {
        RCNotficationNumberOfNewNotifications--;
        self.viewed = true;
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%d", RCServiceURL, RCNotificationsResource, _notificationID]];
        NSURLRequest *request = CreateHttpPutRequest(url,nil);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:nil];
    }


}

+ (void) initNotificationDataModel {
    RCNotificationNotificationList = [[NSMutableArray alloc] init];
    RCNotificationObjectsWithNotification = [[NSMutableDictionary alloc] init];
    RCNotificationPostsWithNotification = [[NSMutableArray alloc] init];
}

+ (void) clearNotifications{
    [RCNotificationNotificationList removeAllObjects];
    [RCNotificationObjectsWithNotification removeAllObjects];
    [RCNotificationPostsWithNotification removeAllObjects];
    RCNotficationNumberOfNewNotifications = 0;
}

+ (NSMutableArray*) notificationsForResource:(NSString*)resourceSpecifier {
    return [RCNotificationObjectsWithNotification objectForKey:resourceSpecifier];
}

+ (RCNotification*) parseNotification:(NSDictionary*) notificationDict {
    RCNotification* notification = [[RCNotification alloc] initWithNSDictionary:notificationDict];
    if ([notification.content isKindOfClass:[NSNull class]])
        return nil;
    if (!notification.viewed)
        RCNotficationNumberOfNewNotifications++;
    int daysToAdd = 10;
    NSDate *expiry = [notification.updatedTime dateByAddingTimeInterval:24*60*60*daysToAdd];
    if ([expiry compare:[NSDate date]] == NSOrderedAscending) return notification;
    NSData *htmlData = [notification.content dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    // 2
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    
    // 3
    NSString *tutorialsXpathQueryString = @"//a";
    NSArray *nodes = [parser searchWithXPathQuery:tutorialsXpathQueryString];
    for (TFHppleElement *element in nodes) {
        NSURL *url = [NSURL URLWithString:[element objectForKey:@"href"]];
        [notification.urls addObject:url];
        if ([url.scheme hasSuffix:@"memcap"]) {
            if ([url.host hasSuffix:@"posts"]) {
                NSString* key = [NSString stringWithFormat:@"%@%@",url.host, url.path];
                NSMutableArray* notificationListForObject = [RCNotificationObjectsWithNotification objectForKey:key];
                if (notificationListForObject == nil) {
                    notificationListForObject = [[NSMutableArray alloc] init];
                    [RCNotificationObjectsWithNotification setObject:notificationListForObject forKey:key];
                    int postID = [[url.path substringFromIndex:1] intValue];
                    [RCNotificationPostsWithNotification
                     addObject:[RCPost getPostWithID:postID]];
                }
                [notificationListForObject addObject:notification];
            }
        }
    }
    [RCNotificationNotificationList addObject:notification];
    return notification;
}

+ (NSMutableArray*) getNotifiedPosts {
    return RCNotificationPostsWithNotification;
}

+ (void) loadMissingNotifiedPostsForList:(NSMutableArray*)posts withCompletion:(void(^)(void)) completion {
    NSMutableDictionary* missingIDs = [[NSMutableDictionary alloc] init];
    int currentIdx = 0;
    for (RCPost* post in posts) {
        if (post.subject == nil)
            [missingIDs setObject:[NSNumber numberWithInt:currentIdx] forKey:[NSNumber numberWithInt:post.postID]];
        currentIdx++;
    }
    if ([missingIDs count] > 0 ) {
        NSString *missingIDsQueryString = @"";
        for (id missingID in missingIDs) {
            missingIDsQueryString = [NSString stringWithFormat:@"%@&ids%%5B%%5D=%@", missingIDsQueryString, missingID];
        }
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?mobile=1%@", RCServiceURL, RCPostsResource, missingIDsQueryString]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSArray *jsonData = (NSArray *) [jsonParser objectWithString:responseData error:nil];
             for (NSDictionary* postDictionary in jsonData) {
                 RCPost *post = [RCPost getPostWithNSDictionary:postDictionary];
                 int idx = [[missingIDs objectForKey:[NSNumber numberWithInt:post.postID]] intValue];
                 if (idx < [posts count]) {
                     [posts setObject:post atIndexedSubscript:idx];
                 }
             }
             completion();
         }];
    } else completion();
}
+ (int) numberOfNewNotifications {
    return RCNotficationNumberOfNewNotifications;
}

@end
