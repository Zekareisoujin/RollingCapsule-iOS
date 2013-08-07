//
//  RCFacebookHelper.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 6/08/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface RCFacebookHelper : NSObject

+ (BOOL) shouldLogIn;
+ (void) setShouldLogIn: (BOOL)shouldLogIn;
+ (void) openFacebookSessionWithDefaultReadPermission:(void (^)(void))completionHandle;
//+ (void) openFacebookSessionWithDefaultPublishPermission:(void (^)(void))completionHandle; //not working
+ (void) validatePublishPermissionAndPerformAction:(void (^)(void)) action;

@end
