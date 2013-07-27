//
//  RCUploadTask.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 26/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//


#import "RCMediaUploadOperation.h"
#import "RCNewPostOperation.h"
#import "RCPost.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface RCUploadTask : NSManagedObject

@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * fileURL;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * postedTime;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSString * privacyOption;
@property (nonatomic, retain) NSNumber * successful;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, strong) RCNewPostOperation* currentNewPostOperation;

- initWithMediaUploadOperation:(RCMediaUploadOperation*) mediaUploadOperation withPost:(RCPost*) post;
- (void) generateRetryOperation;
- (RCPost*) respectivePost;
@end
