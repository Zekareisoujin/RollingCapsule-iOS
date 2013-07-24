//
//  RCUploadManager.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCNewPostOperation.h"

@interface RCUploadManager : NSObject

@property (nonatomic, strong) NSOperationQueue* uploadQueue;
@property (nonatomic,strong) NSMutableArray* uploadList;

- (void) addNewPostOperation: (RCNewPostOperation*)operation;
- (void) addUploadMediaOperation:(RCMediaUploadOperation*) operation;
@end
