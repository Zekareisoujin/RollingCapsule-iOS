//
//  RCNotification.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCNotification.h"
#import "TFHpple.h"
#import "RCUtilities.h"
#import "RCConstants.h"

@implementation RCNotification

@synthesize content = _content;
@synthesize createdTime = _createdTime;
@synthesize updatedTime = _updatedTime;
@synthesize receiverID = _receiverID;
@synthesize notificationID = _notificationID;
@synthesize urls = _urls;
@synthesize viewed = _viewed;

static NSMutableArray* RCNotificationNotificationList = nil;

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _content = (NSString*)[postData objectForKey:@"content"];
        _createdTime = (NSString*)[postData objectForKey:@"created_at"];
        _updatedTime = (NSString*)[postData objectForKey:@"updated_at"];
        
        _receiverID = [[postData objectForKey:@"receiver_id"] intValue];
        _notificationID = [[postData objectForKey:@"id"] intValue];
        _viewed = [[postData objectForKey:@"viewed"] boolValue];
        _urls = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) updateViewedProperty {
    self.viewed = true;
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%d", RCServiceURL, RCNotificationsResource, _notificationID]];
    NSURLRequest *request = CreateHttpPutRequest(url,nil);
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:nil];


}

+ (void) initNotificationDataModel {
    RCNotificationNotificationList = [[NSMutableArray alloc] init];
}

+ (RCNotification*) parseNotification:(NSDictionary*) notificationDict {
    RCNotification* notification = [[RCNotification alloc] initWithNSDictionary:notificationDict];
    NSData *htmlData = [notification.content dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    // 2
    TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
    
    // 3
    NSString *tutorialsXpathQueryString = @"//a";
    NSArray *nodes = [parser searchWithXPathQuery:tutorialsXpathQueryString];
    for (TFHppleElement *element in nodes) {
        NSURL *url = [NSURL URLWithString:[element objectForKey:@"href"]];
        NSLog(@"url:%@ path:%@",url,url.path);
        [notification.urls addObject:url];
    }
    [RCNotificationNotificationList addObject:notification];
    return notification;
}

@end
