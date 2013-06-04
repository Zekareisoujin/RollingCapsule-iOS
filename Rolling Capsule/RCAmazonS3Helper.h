//
//  RCAmazonS3Helper.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 2/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>
#import "RCUser.h"

@interface RCAmazonS3Helper : NSObject 
+ (AmazonS3Client *) s3:(int) userID  forResource:(NSString *)resource;
+ (UIImage *) getAvatarImage:(RCUser*) user withLoggedinUserID:(int)loggedInUserID;
@end
