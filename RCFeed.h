//
//  RCFeed.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 29/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCUser.h"

enum RCFeedErrorType {
    RCFeedCantReachServer,
    RCFeedClientException,
    RCFeedBadServerResult,
    RCFeedNoError
};

typedef enum RCFeedErrorType RCFeedErrorType;

@interface RCFeed : NSObject

@property (nonatomic, strong) NSMutableArray* postList;
@property (nonatomic, assign) int numberOfHiddenCapsules;
@property (nonatomic, strong) NSString* feedPath;
@property (nonatomic, strong) NSString* errorMessage;
@property (nonatomic, assign) RCFeedErrorType errorType;
- (id) init;
- (void) appendData:(NSData*) data;
- (void) fetchFeedFromBackend:(BOOL) fromBeginning;
@end
