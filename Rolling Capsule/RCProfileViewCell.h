//
//  RCProfileViewCell.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 7/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "RCPost.h"

@interface RCProfileViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

+ (NSString*) cellIdentifier;
- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache completion:(void (^)(void))callback;

@end
