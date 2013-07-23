//
//  RCTaskManager.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 21/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCMediaUploadOperation.h"

@interface RCOperationsManager : NSObject
+ (void) addOperation:(NSOperation*) operation;
+ (void) addUploadMediaOperation:(NSOperation*) operation;
@end
