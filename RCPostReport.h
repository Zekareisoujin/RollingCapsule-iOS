//
//  RCPostReport.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 13/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPost.h"
#import "RCUtilities.h"

@interface RCPostReport : NSObject

+ (void) postReportCategory:(NSString*) category withReason:(NSString*) reason forPost:(RCPost*) post withSuccessHandler:(VoidBlock) successHandler withFailureHandler:(void(^)(NSString*)) failureHandler;

@end
