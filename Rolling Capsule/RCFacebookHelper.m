//
//  RCFacebookHelper.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 6/08/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFacebookHelper.h"

@implementation RCFacebookHelper

// Convenience method to perform some action that requires the "publish_actions" permissions.
+ (void) validatePermissionAndPerformAction:(void (^)(void)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                if (!error) {
                                                    action();
                                                }
                                                //For this example, ignore errors (such as if user cancels).
                                            }];
    } else {
        action();
    }
    
}

@end
