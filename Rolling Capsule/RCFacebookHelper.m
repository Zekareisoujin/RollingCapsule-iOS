//
//  RCFacebookHelper.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 6/08/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFacebookHelper.h"
#import "RCConnectionManager.h"

@implementation RCFacebookHelper

static NSDictionary<FBGraphUser> *currentUser;

+ (void) getCurrentUserWithCompletionHandler:(void (^)(NSDictionary<FBGraphUser>*))completionHandle {
    if (FBSession.activeSession.isOpen) {
        if (currentUser != nil)
            completionHandle(currentUser);
        else {
            [RCConnectionManager startConnection];
            [[FBRequest requestForMe] startWithCompletionHandler:
             ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                 [RCConnectionManager endConnection];
                 if (!error) {
                     currentUser = user;
                     completionHandle(currentUser);
                 }
             }];
        }
    }else
        completionHandle(nil);
}

+ (BOOL) shouldLogIn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FacebookShouldLogIn"];
}

+ (void) setShouldLogIn: (BOOL)shouldLogIn {
    [[NSUserDefaults standardUserDefaults] setBool:shouldLogIn forKey:@"FacebookShouldLogIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) openFacebookSessionWithDefaultReadPermission:(void (^)(void))completionHandle {
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session,
                                                      FBSessionState status,
                                                      NSError *error) {
                                          // Respond to session state changes,
                                          // ex: updating the view
                                          // Not planning to do anything for now
                                          completionHandle();
                                      }];
    
}

//+ (void) openFacebookSessionWithDefaultPublishPermission:(void (^)(void))completionHandle {
//    [FBSession openActiveSessionWithPublishPermissions:@[@"publish_actions"]
//                                       defaultAudience:FBSessionDefaultAudienceFriends
//                                          allowLoginUI:YES
//                                     completionHandler:^(FBSession *session,
//                                                         FBSessionState status,
//                                                         NSError *error) {
//                                         completionHandle();
//                                     }];
//}

// Convenience method to perform some action that requires the "publish_actions" permissions.
+ (void) validatePublishPermissionAndPerformAction:(void (^)(void)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [RCConnectionManager startConnection];
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                [RCConnectionManager endConnection];
                                                if (!error) {
                                                    action();
                                                }
                                                //For this example, ignore errors (such as if user cancels).
                                            }];
    } else {
        action();
    }
    
}

+ (void) closeCurrentSession {
    currentUser = nil;
    [FBSession.activeSession closeAndClearTokenInformation];
}

@end
