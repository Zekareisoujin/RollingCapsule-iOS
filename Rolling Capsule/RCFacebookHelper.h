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

+ (void) performPublishAction:(void (^)(void)) action;

@end
